# lighthouse.ps1 - Run Lighthouse audits for all URLs in list.txt

# Check if list.txt exists
if (-not (Test-Path "list.txt")) {
    Write-Error "Error: list.txt not found!"
    exit 1
}

# Create output directory
$OutputDir = "lighthouse_reports"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Read each URL from list.txt and run Lighthouse
$urls = Get-Content "list.txt" | Where-Object { $_.Trim() -ne "" }

foreach ($url in $urls) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $Domain = ([System.Uri]$url).Host
    $OutputFile = Join-Path $OutputDir "${Domain}_${Timestamp}.report"

    Write-Host "Running Lighthouse for: $url"
    lighthouse $url `
        --form-factor=desktop `
        --screenEmulation.disabled `
        --chrome-flags="--no-sandbox --disable-gpu --incognito" `
        --throttling-method=provided `
        --output html,json `
        --output-path $OutputFile `
        --view
}

Write-Host "Lighthouse audits completed. Reports are saved in $OutputDir"

# Generate dashboard
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DashboardScript = Join-Path $ScriptDir "generate_dashboard.ps1"
if (Test-Path $DashboardScript) {
    Write-Host "Generating dashboard..."
    & $DashboardScript
}
