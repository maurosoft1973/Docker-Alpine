param(
    [string]$SolutionOrProject = "",             # Path a .sln o .csproj (default: directory corrente)
    [string]$Configuration = "Debug",            # Debug/Release
    [string]$Filter = "",                        # Esempio: '[MyApp.*]*' o '-[MyApp.Tests]*'
    [int]$Threshold = 0                          # Soglia minima % (0 = disabilitata)
)

$ErrorActionPreference = "Stop"

function Ensure-ReportGenerator {
    try {
        $rg = & reportgenerator -? 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "ReportGenerator già installato." -ForegroundColor Green
            return
        }
    } catch { }
    Write-Host "Installazione ReportGenerator (global tool)..." -ForegroundColor Yellow
    dotnet tool install -g dotnet-reportgenerator-globaltool
}

function Resolve-Target {
    if ([string]::IsNullOrWhiteSpace($SolutionOrProject)) {
        $sln = Get-ChildItem -Path . -Filter *.sln -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($sln) { return $sln.FullName }
        $proj = Get-ChildItem -Path . -Recurse -Filter *.csproj -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*Tests.csproj" } | Select-Object -First 1
        if ($proj) { return $proj.FullName }
        throw "Nessun .sln o progetto test trovato nella cartella corrente. Specifica -SolutionOrProject."
    }
    return (Resolve-Path $SolutionOrProject).Path
}

$target = Resolve-Target
$reportDir = Join-Path (Get-Location) "coveragereport"
$testResultsDir = Join-Path (Get-Location) "TestResults"

if (Test-Path $reportDir) { Remove-Item $reportDir -Recurse -Force }
if (Test-Path $testResultsDir) { Remove-Item $testResultsDir -Recurse -Force }

Write-Host "Eseguo test con code coverage su: $target" -ForegroundColor Cyan

# Collector XPlat produce coverage.cobertura.xml
$collectArgs = @(
    "--collect:XPlat Code Coverage"
    "--logger:trx"
    "-c:$Configuration"
)

dotnet test $target $collectArgs

# Trova tutti i report Cobertura generati
$reports = Get-ChildItem -Path . -Recurse -Filter "coverage.cobertura.xml" -File
if (-not $reports) {
    throw "Nessun report 'coverage.cobertura.xml' trovato. Verifica che i test siano stati eseguiti."
}

Ensure-ReportGenerator

$reportPaths = ($reports | ForEach-Object { $_.FullName }) -join ";"
Write-Host "Genero report HTML in: $reportDir" -ForegroundColor Cyan

reportgenerator `
    -reports:"$reportPaths" `
    -targetdir:"$reportDir" `
    -reporttypes:"HtmlInline;TextSummary;SonarQube;JsonSummary" `
    -assemblyfilters:"+*" `
    -classfilters:"+*" | Out-Host

# Stampa il riassunto in console (TextSummary.txt)
$summaryFile = Join-Path $reportDir "Summary.txt"
if (Test-Path $summaryFile) {
    Write-Host "`n=== Coverage Summary ===" -ForegroundColor Green
    Get-Content $summaryFile | Out-Host
}

# Controllo soglia (se richiesta)
if ($Threshold -gt 0 -and (Test-Path $summaryFile)) {
    $line = (Get-Content $summaryFile | Select-String -Pattern "Line coverage")
    if ($line) {
        # Estraggo percentuale (es: "Line coverage: 78.9%")
        if ($line -match "(\d+(\.\d+)?)%") {
            $pct = [double]$Matches[1]
            if ($pct -lt $Threshold) {
                Write-Host ("Coverage {0}% < threshold {1}% → FAIL" -f $pct, $Threshold) -ForegroundColor Red
                exit 1
            } else {
                Write-Host ("Coverage {0}% >= threshold {1}% → OK" -f $pct, $Threshold) -ForegroundColor Green
            }
        }
    }
}

Write-Host "`nFatto. Apri: $reportDir\index.html" -ForegroundColor Green
