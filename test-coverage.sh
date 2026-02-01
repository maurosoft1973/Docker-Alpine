#!/usr/bin/env bash
set -euo pipefail

# Default values
SOLUTION_OR_PROJECT=""
CONFIGURATION="Debug"
THRESHOLD=0          # 0 = disabled
REPORT_DIR="coveragereport"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-s <solution|project>] [-c <Configuration>] [-t <threshold%>]
  -s   Path to .sln or .csproj (default: auto-detect)
  -c   Build configuration (Debug|Release). Default: Debug
  -t   Minimum coverage threshold in percent (integer). Default: 0 (disabled)
EOF
}

# Parse args
while getopts "s:c:t:h" opt; do
  case "$opt" in
    s) SOLUTION_OR_PROJECT="$OPTARG" ;;
    c) CONFIGURATION="$OPTARG" ;;
    t) THRESHOLD="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

resolve_target() {
  if [[ -n "$SOLUTION_OR_PROJECT" ]]; then
    realpath "$SOLUTION_OR_PROJECT"
    return
  fi
  # try solution in current dir
  sln=$(ls *.sln 2>/dev/null | head -n1 || true)
  if [[ -n "$sln" ]]; then
    realpath "$sln"
    return
  fi
  # try first *Tests.csproj
  proj=$(find . -name "*Tests.csproj" -print -quit)
  if [[ -n "$proj" ]]; then
    realpath "$proj"
    return
  fi
  echo "No solution or test project found. Use -s <path>." >&2
  exit 1
}

TARGET="$(resolve_target)"
TEST_RESULTS_DIR="TestResults"

rm -rf "$REPORT_DIR" "$TEST_RESULTS_DIR"

echo ">> Running tests with coverage on: $TARGET"
dotnet test "$TARGET" \
  --collect:"XPlat Code Coverage" \
  --logger "trx" \
  -c "$CONFIGURATION"

# find Cobertura reports
mapfile -t REPORTS < <(find . -type f -name "coverage.cobertura.xml")
if [[ ${#REPORTS[@]} -eq 0 ]]; then
  echo "No 'coverage.cobertura.xml' found. Ensure tests ran successfully." >&2
  exit 1
fi

# ensure ReportGenerator (use local tool if you prefer)
if ! command -v reportgenerator >/dev/null 2>&1; then
  echo ">> Installing ReportGenerator (dotnet tool) ..."
  dotnet tool install -g dotnet-reportgenerator-globaltool
  export PATH="$PATH:$HOME/.dotnet/tools"
fi

REPORTS_JOINED=$(IFS=';'; echo "${REPORTS[*]}")
echo ">> Generating HTML report → $REPORT_DIR"
reportgenerator \
  -reports:"$REPORTS_JOINED" \
  -targetdir:"$REPORT_DIR" \
  -reporttypes:"Html;TextSummary" \
  -assemblyfilters:"+*" \
  -classfilters:"+*"

echo ">> Coverage report at: $REPORT_DIR/index.html"

# threshold check (optional)
if [[ "$THRESHOLD" -gt 0 ]]; then
  SUMMARY_FILE="$REPORT_DIR/Summary.txt"
  if [[ -f "$SUMMARY_FILE" ]]; then
    LINE=$(grep -E "Line coverage" "$SUMMARY_FILE" || true)
    if [[ "$LINE" =~ ([0-9]+(\.[0-9]+)?)% ]]; then
      PCT="${BASH_REMATCH[1]}"
      pct_int=${PCT%.*}
      if (( pct_int < THRESHOLD )); then
        echo "Coverage ${PCT}% < threshold ${THRESHOLD}% → FAIL"
        exit 2
      else
        echo "Coverage ${PCT}% >= threshold ${THRESHOLD}% → OK"
      fi
    fi
  fi
fi

