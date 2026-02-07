using System.Reflection;
using DockerImageBuilder.Alpine;
using DockerImageBuilder.Alpine.BuildArgs;
using DockerImageBuilder.Alpine.Download;
using DockerImageBuilder.Alpine.Scraping;
using DockerImageBuilder.Alpine.Scraping.Interface;
using DockerImageBuilder.Core;
using DockerImageBuilder.Core.Docker;
using DockerImageBuilder.Core.Docker.Interface;
using DockerImageBuilder.Core.Git;
using DockerImageBuilder.Core.Git.Interface;
using DockerImageBuilder.Core.Git.Model;
using DockerImageBuilder.Core.HealthChecks;
using DockerImageBuilder.Core.HealthChecks.Interface;
using DockerImageBuilder.Core.Images;
using DockerImageBuilder.Core.Images.Interface;
using DockerImageBuilder.Core.Images.Service;
using DockerImageBuilder.Core.Process;
using DockerImageBuilder.Core.Registry;
using DockerImageBuilder.Core.Registry.Service;
using DockerImageBuilder.Core.Scanner;
using DockerImageBuilder.Core.Utilities;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;

Console.WriteLine("Starting Alpine Automatic Build...");

var projectRoot = ProjectInfo.ProjectRoot;
var alpineGitRoot = Path.Combine(projectRoot, "Alpine");
var manifestGitPath = Path.Combine(alpineGitRoot, "manifest.json");

var workspace = Environment.GetEnvironmentVariable("GITHUB_WORKSPACE");
var repoRoot = !string.IsNullOrWhiteSpace(workspace)
    ? workspace
    : Directory.GetCurrentDirectory();

try
{
    Console.WriteLine($"Repository root determined as: {repoRoot}");

    Environment.Exit(0);

    DotEnv.Load(Path.Combine(repoRoot, ".env"));

    Environment.SetEnvironmentVariable("APP_CURRENT_PATH", repoRoot);

    var configuration = new ConfigurationBuilder()
        .SetBasePath(repoRoot)
        .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
        .AddEnvironmentVariables()
        .Build();

    var logger = new LoggerConfiguration()
        .ReadFrom.Configuration(configuration)
        .Enrich.FromLogContext()
        .CreateLogger();

    logger.Information("═══════════════════════════════════════════════════");
    logger.Information("Alpine Automatic Build - Starting");
    logger.Information("Repository root: {RepoRoot}", repoRoot);
    logger.Information("═══════════════════════════════════════════════════");

    // ==================== SETTINGS ====================
    var settings = Settings.Load(configuration, repoRoot);

    logger.Information("Configuration loaded:");
    logger.Information("  Architectures: {Architectures}", string.Join(", ", settings.Architectures));
    logger.Information("  Image name: {ImageName}", settings.ImageName);
    logger.Information("  Push enabled: {DoPush}", settings.DoPush);
    logger.Information("  Dockerfile: {Dockerfile}", settings.DockerfilePath);
    logger.Information("  Parallel builds: {Enabled}", configuration.GetValue<bool>("ENABLE_PARALLEL_BUILDS", true));
    logger.Information("  Health checks: {Enabled}", configuration.GetValue<bool>("ENABLE_HEALTH_CHECKS", true));
    logger.Information("  Vulnerability scanning: {Enabled}", configuration.GetValue<bool>("ENABLE_VULN_SCAN", true));
    logger.Information("  Alpine Rootfs cache: {CacheRoot}", settings.CacheRoot);
    logger.Information("  Manifest Git Path: {ManifestGitPath}", manifestGitPath);
    logger.Information("  Limit: {Limit}", Environment.GetEnvironmentVariable("LIMIT") ?? "unlimited");

    Directory.CreateDirectory(settings.AlpineRoot);
    Directory.CreateDirectory(settings.CacheRoot);
    Directory.CreateDirectory(Path.GetDirectoryName(settings.ManifestPath)!);

    var builder = Host.CreateApplicationBuilder(args);
    builder.Configuration.AddConfiguration(configuration);
    builder.Logging.ClearProviders();
    builder.Logging.AddSerilog();
    builder.Services.AddSingleton<Serilog.ILogger>(logger);
    builder.Services.AddSingleton<IAlpineRootFsDownloader, AlpineRootFsDownloader>();
    builder.Services.AddDockerServices(configureBuild =>
                                       {
                                           configureBuild.WorkingDirectory = settings.RepoRoot;
                                           configureBuild.DockerFilePath = settings.DockerfilePath;
                                           configureBuild.BuildArgsProvider = new AlpineBuildArgsProvider();
                                       },
                                       configurePush =>
                                       {
                                           configurePush.WorkingDirectory = settings.RepoRoot;
                                       });
    builder.Services.AddAlpineSupport(configureDownloader => configureDownloader.CacheRoot = settings.CacheRoot);
    builder.Services.AddProcessService();
    builder.Services.AddDockerHealthChecking();
    builder.Services.AddVulnerabilityScanning();
    builder.Services.AddAlpineScraping();
    builder.Services.AddImageManifest(configureManifestCreator =>
    {
        configureManifestCreator.WorkingDirectory = settings.RepoRoot;
    });
    builder.Services.AddContainerRegistries(builder =>
    {
        builder.AddDockerHub(Environment.GetEnvironmentVariable("DOCKER_USERNAME") ?? "", Environment.GetEnvironmentVariable("DOCKER_PASSWORD") ?? "", Environment.GetEnvironmentVariable("DOCKER_NAMESPACE") ?? "");
    });

    // Registrazione DI
    builder.Services.AddManifestGitService(o =>
    {
        o.WorkingDirectory = settings.RepoRoot;
        o.ManifestRelativePath = manifestGitPath;
        o.AuthorName = "github-actions[bot]";
        o.AuthorEmail = "github-actions[bot]@users.noreply.github.com";
    });

    var app = builder.Build();

    // ==================== PROCESSING ====================
    var manifestStore = app.Services.GetRequiredService<IManifestStore>();
    var scraper = app.Services.GetRequiredService<IAlpineScraper>();
    var downloader = app.Services.GetRequiredService<IAlpineRootFsDownloader>();
    var dockerbuilder = app.Services.GetRequiredService<IDockerBuildExecutor>();
    var dockerpusher = app.Services.GetRequiredService<IDockerPushExecutor>();
    var healthChecker = app.Services.GetRequiredService<IHealthChecker>();
    var pushStrategy = app.Services.GetRequiredService<IImagePushStrategy>();
    var gitService = app.Services.GetRequiredService<IManifestGitService>();

    logger.Information("");
    logger.Information("Loading manifest...");
    var manifest = await manifestStore.LoadAsync(settings.ManifestPath, settings.Architectures);
    logger.Information("");

    logger.Information("Scraping Alpine releases...");
    var scrapedReleases = await scraper.ScrapeAsync();
    logger.Information("Found {Count} release versions on website", scrapedReleases.Count);

    var today = DateTime.UtcNow.Date;
    var activeReleases = scrapedReleases
        .Where(r => r.EndOfLifeDate > today)
        .ToList();

    logger.Information("Active releases (EOS > today): {Count}", activeReleases.Count);

    logger.Information("Merging releases into manifest...");
    ManifestMerger.MergeActiveIntoManifest(activeReleases, manifest);

    await manifestStore.SaveAsync(settings.ManifestPath, manifest);
    logger.Information("Manifest saved to {ManifestPath}", settings.ManifestPath);
    logger.Information("");

    var images = ManifestPlanner.GetImagesToProcess(manifest, activeReleases);

    if (images.Count == 0)
    {
        logger.Information("✓ Nothing to do: all active versions already pushed");

        var stats = ManifestPlanner.GetStats(manifest);
        logger.Information("Manifest stats: Total={Total}, Pushed={Pushed}, Built={Built}, Failed={Failed}", stats.Total, stats.Pushed, stats.Built, stats.Failed);

        return 0;
    }

    var limitEnv = Environment.GetEnvironmentVariable("LIMIT");
    if (!int.TryParse(limitEnv, out var limit))
        limit = 5;

    logger.Information("Images to process: {Count}", images.Count);
    logger.Information("Images Processable (Limit): {Limit}", limit);
    logger.Information("═══════════════════════════════════════════════════");

    var successCount = 0;
    var failureCount = 0;
    var latestVersion = activeReleases.DetermineLatestVersion();
    var current = 1;

    foreach (var image in images.Take(limit))
    {
        logger.Information("");
        logger.Information(" Processing Image {Version} (status={Status}) - {current}/{limit}", image.Version, image.Status, current, limit);

        try
        {
            // Step 1: Download rootfs
            logger.Information("  [1/5] Downloading rootfs...");
            await downloader.DownloadMissingAsync(image, settings.Architectures);

            image.Status = "downloaded";
            await manifestStore.SaveAsync(settings.ManifestPath, manifest);

            // Step 2: Build (parallelo o sequenziale)
            logger.Information("  [2/5] Building Docker images...");
            var buildImages = await dockerbuilder.BuildAsync(image, settings.ImageName);

            image.Status = "built";
            image.BuiltAtUtc = DateTime.UtcNow;
            await manifestStore.SaveAsync(settings.ManifestPath, manifest);

            // Step 3: Health checks (opzionale, solo prima arch per velocità)
            if (configuration.GetValue("ENABLE_HEALTH_CHECKS", true))
            {
                logger.Information("  [3/5] Performing health checks...");
                await healthChecker.CheckImageHealthAsync(settings.ImageName, image.Version, "x86_64");
            }
            else
                logger.Information("  [3/5] Skipping health checks (disabled)...");

            // Step 4: Pushing to Registries
            logger.Information("Step 4/4: Pushing to registries");

            foreach (var buildImage in buildImages)
            {
                var pushResult = await pushStrategy.PushImageAsync(buildImage.Value);
                logger.Information(pushResult.FormatReport());

                if (!pushResult.AnySuccessful)
                    throw new Exception("Failed to push to any registry");

                logger.Information(
                    "✓ Successfully pushed to {Success}/{Total} registries",
                    pushResult.SuccessCount,
                    pushResult.RegistryResults.Count);
            }

            // Step 5: Create multi-architecture manifest (only if multiple architectures)
            if (buildImages.Count > 1)
            {
                logger.Information("  [5/5] Creating multi-architecture manifest...");
                var manifestCreator = app.Services.GetRequiredService<IManifestCreator>();
                var isLatest = image.Version == latestVersion;

                await manifestCreator.CreateUnifiedManifestsAsync(
                    image,
                    settings.ImageName,
                    [.. buildImages.Keys],
                    isLatest);

                logger.Information(
                    "✓ Created unified manifest for {Version} with {Count} architectures{Latest}",
                    image.Version,
                    buildImages.Count,
                    isLatest ? " (latest)" : "");
            }
            else
            {
                logger.Information("  [5/5] Skipping manifest creation (single architecture)");
            }

            image.Status = "pushed";
            image.PushedAtUtc = DateTime.UtcNow;
            await manifestStore.SaveAsync(settings.ManifestPath, manifest);

            successCount++;
        }
        catch (Exception ex)
        {
            image.Status = "failed";
            await manifestStore.SaveAsync(settings.ManifestPath, manifest);

            logger.Error(ex, "✗ FAILED: {Version}", image.Version);

            failureCount++;
        }

        current++;
    }

    // Ensure manifest is copied to the git repository if it's different
    File.Move(settings.ManifestPath, manifestGitPath, true);
    logger.Information("Updated manifest copied to git repository");

    // ==================== GIT COMMIT ====================
    var gitResult = await gitService.CommitAndPushManifestAsync();

    switch (gitResult.Action)
    {
        case GitCommitAction.NoChanges:
            logger.Information("Manifest unchanged, nothing to commit");
            break;
        case GitCommitAction.CommittedAndPushed:
            logger.Information("Manifest pushed: {Hash}", gitResult.CommitHash);
            break;
        case GitCommitAction.Failed:
            logger.Error("Git failed: {Error}", gitResult.ErrorMessage);
            break;
    }

    // ==================== SUMMARY ====================
    logger.Information("");
    logger.Information("═══════════════════════════════════════════════════");
    logger.Information("Build Summary");
    logger.Information("═══════════════════════════════════════════════════");
    logger.Information("Processed: {Processed}", images.Count);
    logger.Information("Success:   {Success}", successCount);
    logger.Information("Failed:    {Failed}", failureCount);

    var finalStats = ManifestPlanner.GetStats(manifest);
    logger.Information("");
    logger.Information("Manifest Statistics:");
    logger.Information("  Total:      {Total}", finalStats.Total);
    logger.Information("  Pushed:     {Pushed}", finalStats.Pushed);
    logger.Information("  Built:      {Built}", finalStats.Built);
    logger.Information("  Downloaded: {Downloaded}", finalStats.Downloaded);
    logger.Information("  New:        {New}", finalStats.New);
    logger.Information("  Failed:     {Failed}", finalStats.Failed);
    logger.Information("═══════════════════════════════════════════════════");

    return failureCount > 0 ? 1 : 0;
}
catch (Exception ex)
{
    Console.WriteLine(ex.Message);
    return 1;
}
finally
{
    await Log.CloseAndFlushAsync();
}

public static class ProjectInfo
{
    public static string ProjectRoot =>
        Assembly.GetExecutingAssembly()
            .GetCustomAttributes<AssemblyMetadataAttribute>()
            .First(a => a.Key == "ProjectRoot")
            .Value!;
}
