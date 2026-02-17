# generate_dashboard.ps1 - Generate PageSpeed Insights Dashboard (index.html)
# Parses Lighthouse JSON reports and creates an overview dashboard
# No external dependencies required - uses built-in ConvertFrom-Json

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ReportDir = Join-Path $ScriptDir "lighthouse_reports"
$OutputFile = Join-Path $ReportDir "index.html"

# Check if report directory exists
if (-not (Test-Path $ReportDir)) {
    Write-Error "Error: lighthouse_reports directory not found!"
    Write-Host "Run lighthouse.ps1 first to generate reports."
    exit 1
}

# Collect JSON reports
$JsonFiles = Get-ChildItem -Path $ReportDir -Filter "*.report.json" -File

if ($JsonFiles.Count -eq 0) {
    Write-Error "Error: No JSON report files found in $ReportDir"
    Write-Host "Make sure lighthouse.ps1 outputs JSON format (--output html,json)"
    exit 1
}

Write-Host "Found $($JsonFiles.Count) report(s). Generating dashboard..."

# Extract data from each JSON report
$ReportEntries = @()

foreach ($jsonFile in $JsonFiles) {
    $BaseName = $jsonFile.BaseName -replace '\.report$', ''
    $HtmlFile = "${BaseName}.report.html"

    $json = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json

    # Extract scores (0-1 scale from Lighthouse, convert to 0-100)
    $PerfScore = if ($json.categories.performance.score) { [math]::Round($json.categories.performance.score * 100) } else { 0 }
    $A11yScore = if ($json.categories.accessibility.score) { [math]::Round($json.categories.accessibility.score * 100) } else { 0 }
    $BpScore = if ($json.categories.'best-practices'.score) { [math]::Round($json.categories.'best-practices'.score * 100) } else { 0 }
    $SeoScore = if ($json.categories.seo.score) { [math]::Round($json.categories.seo.score * 100) } else { 0 }

    # Extract metadata
    $FinalUrl = if ($json.finalDisplayedUrl) { $json.finalDisplayedUrl } elseif ($json.finalUrl) { $json.finalUrl } else { "N/A" }
    $FetchTime = if ($json.fetchTime) { $json.fetchTime } else { "N/A" }

    # Extract key metrics
    $Fcp = if ($json.audits.'first-contentful-paint'.displayValue) { $json.audits.'first-contentful-paint'.displayValue } else { "N/A" }
    $Lcp = if ($json.audits.'largest-contentful-paint'.displayValue) { $json.audits.'largest-contentful-paint'.displayValue } else { "N/A" }
    $Tbt = if ($json.audits.'total-blocking-time'.displayValue) { $json.audits.'total-blocking-time'.displayValue } else { "N/A" }
    $Cls = if ($json.audits.'cumulative-layout-shift'.displayValue) { $json.audits.'cumulative-layout-shift'.displayValue } else { "N/A" }
    $Si = if ($json.audits.'speed-index'.displayValue) { $json.audits.'speed-index'.displayValue } else { "N/A" }

    $ReportEntries += @{
        domain       = $BaseName
        url          = $FinalUrl
        htmlFile     = $HtmlFile
        fetchTime    = $FetchTime
        performance  = $PerfScore
        accessibility = $A11yScore
        bestPractices = $BpScore
        seo          = $SeoScore
        fcp          = $Fcp
        lcp          = $Lcp
        tbt          = $Tbt
        cls          = $Cls
        si           = $Si
    }
}

# Build JavaScript data array
$jsEntries = @()
foreach ($r in $ReportEntries) {
    $entry = @"
    {
      "domain": "$($r.domain)",
      "url": "$($r.url)",
      "htmlFile": "$($r.htmlFile)",
      "fetchTime": "$($r.fetchTime)",
      "scores": {
        "performance": $($r.performance),
        "accessibility": $($r.accessibility),
        "bestPractices": $($r.bestPractices),
        "seo": $($r.seo)
      },
      "metrics": {
        "fcp": "$($r.fcp)",
        "lcp": "$($r.lcp)",
        "tbt": "$($r.tbt)",
        "cls": "$($r.cls)",
        "si": "$($r.si)"
      }
    }
"@
    $jsEntries += $entry
}

$ReportData = $jsEntries -join ","

# Generate HTML
$htmlContent = @"
<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PageSpeed Insights Dashboard</title>
<style>
  :root {
    --color-pass: #0cce6b;
    --color-average: #ffa400;
    --color-fail: #ff4e42;
    --color-bg: #f5f5f5;
    --color-card: #ffffff;
    --color-text: #333333;
    --color-text-light: #666666;
    --color-border: #e0e0e0;
    --shadow: 0 2px 8px rgba(0,0,0,0.08);
    --radius: 12px;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    background: var(--color-bg);
    color: var(--color-text);
    line-height: 1.6;
  }

  .header {
    background: linear-gradient(135deg, #1a73e8, #4285f4);
    color: white;
    padding: 32px 24px;
    text-align: center;
  }

  .header h1 {
    font-size: 28px;
    font-weight: 700;
    margin-bottom: 8px;
  }

  .header p {
    font-size: 14px;
    opacity: 0.9;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 24px;
  }

  /* Overview Cards */
  .overview {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    margin-bottom: 32px;
  }

  .overview-card {
    background: var(--color-card);
    border-radius: var(--radius);
    padding: 24px;
    text-align: center;
    box-shadow: var(--shadow);
    transition: transform 0.2s;
  }

  .overview-card:hover {
    transform: translateY(-2px);
  }

  .overview-card .label {
    font-size: 13px;
    color: var(--color-text-light);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 12px;
  }

  .gauge {
    position: relative;
    width: 100px;
    height: 100px;
    margin: 0 auto 12px;
  }

  .gauge svg {
    transform: rotate(-90deg);
    width: 100px;
    height: 100px;
  }

  .gauge circle {
    fill: none;
    stroke-width: 8;
    stroke-linecap: round;
  }

  .gauge .bg {
    stroke: #e8e8e8;
  }

  .gauge .fill {
    transition: stroke-dashoffset 1s ease;
  }

  .gauge .score-text {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 28px;
    font-weight: 700;
  }

  /* Score Distribution */
  .section-title {
    font-size: 20px;
    font-weight: 600;
    margin-bottom: 16px;
    padding-bottom: 8px;
    border-bottom: 2px solid var(--color-border);
  }

  .distribution {
    background: var(--color-card);
    border-radius: var(--radius);
    padding: 24px;
    margin-bottom: 32px;
    box-shadow: var(--shadow);
  }

  .dist-row {
    display: flex;
    align-items: center;
    margin-bottom: 12px;
    gap: 12px;
  }

  .dist-label {
    font-size: 13px;
    color: var(--color-text-light);
    min-width: 80px;
    text-align: right;
  }

  .dist-bar-container {
    flex: 1;
    display: flex;
    height: 24px;
    border-radius: 4px;
    overflow: hidden;
    background: #f0f0f0;
  }

  .dist-bar-segment {
    height: 100%;
    transition: width 0.5s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    color: white;
    font-weight: 600;
    min-width: 0;
  }

  .dist-bar-segment span {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    padding: 0 4px;
  }

  .legend {
    display: flex;
    gap: 20px;
    margin-top: 16px;
    justify-content: center;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 13px;
    color: var(--color-text-light);
  }

  .legend-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
  }

  /* Reports Table */
  .reports-section {
    margin-bottom: 32px;
  }

  .filters {
    display: flex;
    gap: 12px;
    margin-bottom: 16px;
    flex-wrap: wrap;
    align-items: center;
  }

  .search-input {
    flex: 1;
    min-width: 200px;
    padding: 10px 16px;
    border: 1px solid var(--color-border);
    border-radius: 8px;
    font-size: 14px;
    outline: none;
    transition: border-color 0.2s;
  }

  .search-input:focus {
    border-color: #4285f4;
  }

  .sort-select {
    padding: 10px 16px;
    border: 1px solid var(--color-border);
    border-radius: 8px;
    font-size: 14px;
    outline: none;
    background: white;
    cursor: pointer;
  }

  .report-card {
    background: var(--color-card);
    border-radius: var(--radius);
    padding: 20px;
    margin-bottom: 12px;
    box-shadow: var(--shadow);
    transition: transform 0.2s, box-shadow 0.2s;
    cursor: pointer;
    text-decoration: none;
    color: inherit;
    display: block;
  }

  .report-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.12);
  }

  .report-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 16px;
    flex-wrap: wrap;
    gap: 8px;
  }

  .report-url {
    font-size: 16px;
    font-weight: 600;
    color: #1a73e8;
    word-break: break-all;
  }

  .report-time {
    font-size: 12px;
    color: var(--color-text-light);
    white-space: nowrap;
  }

  .report-scores {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 12px;
    margin-bottom: 12px;
  }

  .score-item {
    text-align: center;
    padding: 8px;
    border-radius: 8px;
    background: var(--color-bg);
  }

  .score-item .score-label {
    font-size: 11px;
    color: var(--color-text-light);
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }

  .score-item .score-value {
    font-size: 24px;
    font-weight: 700;
    margin: 4px 0;
  }

  .report-metrics {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
    padding-top: 12px;
    border-top: 1px solid var(--color-border);
  }

  .metric-item {
    font-size: 12px;
    color: var(--color-text-light);
  }

  .metric-item strong {
    color: var(--color-text);
  }

  .badge {
    display: inline-block;
    padding: 2px 8px;
    border-radius: 10px;
    font-size: 11px;
    font-weight: 600;
    color: white;
  }

  .badge-pass { background: var(--color-pass); }
  .badge-average { background: var(--color-average); }
  .badge-fail { background: var(--color-fail); }

  /* Summary Stats */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 12px;
    margin-bottom: 32px;
  }

  .stat-card {
    background: var(--color-card);
    border-radius: var(--radius);
    padding: 16px;
    text-align: center;
    box-shadow: var(--shadow);
  }

  .stat-card .stat-number {
    font-size: 36px;
    font-weight: 700;
    color: #1a73e8;
  }

  .stat-card .stat-label {
    font-size: 12px;
    color: var(--color-text-light);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .footer {
    text-align: center;
    padding: 24px;
    color: var(--color-text-light);
    font-size: 13px;
  }

  @media (max-width: 600px) {
    .container { padding: 12px; }
    .header { padding: 20px 12px; }
    .header h1 { font-size: 22px; }
    .overview { grid-template-columns: repeat(2, 1fr); }
    .report-scores { grid-template-columns: repeat(2, 1fr); }
  }
</style>
</head>
<body>

<div class="header">
  <h1>PageSpeed Insights Dashboard</h1>
  <p id="headerSubtitle"></p>
</div>

<div class="container">
  <!-- Summary Stats -->
  <div class="stats-grid" id="statsGrid"></div>

  <!-- Average Score Gauges -->
  <h2 class="section-title">Average Scores</h2>
  <div class="overview" id="overviewGauges"></div>

  <!-- Score Distribution -->
  <h2 class="section-title">Score Distribution</h2>
  <div class="distribution" id="distributionChart"></div>

  <!-- Reports List -->
  <h2 class="section-title">All Reports</h2>
  <div class="reports-section">
    <div class="filters">
      <input type="text" class="search-input" id="searchInput" placeholder="Search by URL or domain...">
      <select class="sort-select" id="sortSelect">
        <option value="date-desc">Latest First</option>
        <option value="date-asc">Oldest First</option>
        <option value="perf-desc">Performance (High to Low)</option>
        <option value="perf-asc">Performance (Low to High)</option>
        <option value="a11y-desc">Accessibility (High to Low)</option>
        <option value="seo-desc">SEO (High to Low)</option>
      </select>
    </div>
    <div id="reportsList"></div>
  </div>
</div>

<div class="footer">
  Generated by Lighthouse Shell Script &mdash; PageSpeed Insights Dashboard
</div>

<script>
const reports = [$ReportData
];

// Utility functions
function getScoreColor(score) {
  if (score >= 90) return '#0cce6b';
  if (score >= 50) return '#ffa400';
  return '#ff4e42';
}

function getScoreLabel(score) {
  if (score >= 90) return 'pass';
  if (score >= 50) return 'average';
  return 'fail';
}

function formatDate(dateStr) {
  if (!dateStr || dateStr === 'N/A') return 'N/A';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('th-TH', {
      year: 'numeric', month: 'short', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  } catch { return dateStr; }
}

function createGaugeSVG(score, size) {
  size = size || 100;
  const r = (size - 16) / 2;
  const circumference = 2 * Math.PI * r;
  const offset = circumference - (score / 100) * circumference;
  const color = getScoreColor(score);
  return ``
    + '<div class="gauge" style="width:' + size + 'px;height:' + size + 'px">'
    + '<svg style="width:' + size + 'px;height:' + size + 'px">'
    + '<circle class="bg" cx="' + (size/2) + '" cy="' + (size/2) + '" r="' + r + '" />'
    + '<circle class="fill" cx="' + (size/2) + '" cy="' + (size/2) + '" r="' + r + '"'
    + ' stroke="' + color + '"'
    + ' stroke-dasharray="' + circumference + '"'
    + ' stroke-dashoffset="' + offset + '" />'
    + '</svg>'
    + '<div class="score-text" style="color:' + color + '">' + score + '</div>'
    + '</div>';
}

// Calculate averages
function calcAverage(key) {
  if (reports.length === 0) return 0;
  const sum = reports.reduce(function(acc, r) { return acc + r.scores[key]; }, 0);
  return Math.round(sum / reports.length);
}

// Render header subtitle
document.getElementById('headerSubtitle').textContent =
  reports.length + ' reports from NIDA websites \u2022 Lighthouse Desktop Audit';

// Render summary stats
(function() {
  var totalPerf = 0, passCount = 0, avgCount = 0, failCount = 0;
  reports.forEach(function(r) {
    var avg = Math.round((r.scores.performance + r.scores.accessibility + r.scores.bestPractices + r.scores.seo) / 4);
    totalPerf += avg;
    if (avg >= 90) passCount++;
    else if (avg >= 50) avgCount++;
    else failCount++;
  });

  var html = '';
  html += '<div class="stat-card"><div class="stat-number">' + reports.length + '</div><div class="stat-label">Total Reports</div></div>';
  html += '<div class="stat-card"><div class="stat-number" style="color:#0cce6b">' + passCount + '</div><div class="stat-label">Good (90+)</div></div>';
  html += '<div class="stat-card"><div class="stat-number" style="color:#ffa400">' + avgCount + '</div><div class="stat-label">Needs Work (50-89)</div></div>';
  html += '<div class="stat-card"><div class="stat-number" style="color:#ff4e42">' + failCount + '</div><div class="stat-label">Poor (&lt;50)</div></div>';
  document.getElementById('statsGrid').innerHTML = html;
})();

// Render overview gauges
(function() {
  var categories = [
    { key: 'performance', label: 'Performance' },
    { key: 'accessibility', label: 'Accessibility' },
    { key: 'bestPractices', label: 'Best Practices' },
    { key: 'seo', label: 'SEO' }
  ];
  var html = '';
  categories.forEach(function(cat) {
    var avg = calcAverage(cat.key);
    html += '<div class="overview-card">';
    html += '<div class="label">' + cat.label + '</div>';
    html += createGaugeSVG(avg, 100);
    html += '</div>';
  });
  document.getElementById('overviewGauges').innerHTML = html;
})();

// Render score distribution
(function() {
  var categories = [
    { key: 'performance', label: 'Performance' },
    { key: 'accessibility', label: 'Accessibility' },
    { key: 'bestPractices', label: 'Best Practices' },
    { key: 'seo', label: 'SEO' }
  ];

  var html = '';
  categories.forEach(function(cat) {
    var pass = 0, avg = 0, fail = 0;
    reports.forEach(function(r) {
      var s = r.scores[cat.key];
      if (s >= 90) pass++;
      else if (s >= 50) avg++;
      else fail++;
    });
    var total = reports.length || 1;
    var passPct = (pass / total * 100).toFixed(1);
    var avgPct = (avg / total * 100).toFixed(1);
    var failPct = (fail / total * 100).toFixed(1);

    html += '<div class="dist-row">';
    html += '<div class="dist-label">' + cat.label + '</div>';
    html += '<div class="dist-bar-container">';
    if (pass > 0) html += '<div class="dist-bar-segment" style="width:' + passPct + '%;background:#0cce6b"><span>' + pass + '</span></div>';
    if (avg > 0) html += '<div class="dist-bar-segment" style="width:' + avgPct + '%;background:#ffa400"><span>' + avg + '</span></div>';
    if (fail > 0) html += '<div class="dist-bar-segment" style="width:' + failPct + '%;background:#ff4e42"><span>' + fail + '</span></div>';
    html += '</div></div>';
  });

  html += '<div class="legend">';
  html += '<div class="legend-item"><div class="legend-dot" style="background:#0cce6b"></div> Good (90-100)</div>';
  html += '<div class="legend-item"><div class="legend-dot" style="background:#ffa400"></div> Needs Work (50-89)</div>';
  html += '<div class="legend-item"><div class="legend-dot" style="background:#ff4e42"></div> Poor (0-49)</div>';
  html += '</div>';

  document.getElementById('distributionChart').innerHTML = html;
})();

// Render reports list
function renderReports(filteredReports) {
  var html = '';
  if (filteredReports.length === 0) {
    html = '<div style="text-align:center;padding:40px;color:#999">No reports found.</div>';
  }
  filteredReports.forEach(function(r) {
    html += '<a class="report-card" href="' + r.htmlFile + '" target="_blank">';
    html += '<div class="report-header">';
    html += '<div class="report-url">' + r.url + '</div>';
    html += '<div class="report-time">' + formatDate(r.fetchTime) + '</div>';
    html += '</div>';
    html += '<div class="report-scores">';

    var cats = [
      { key: 'performance', label: 'Performance' },
      { key: 'accessibility', label: 'Accessibility' },
      { key: 'bestPractices', label: 'Best Practices' },
      { key: 'seo', label: 'SEO' }
    ];
    cats.forEach(function(cat) {
      var s = r.scores[cat.key];
      html += '<div class="score-item">';
      html += '<div class="score-label">' + cat.label + '</div>';
      html += '<div class="score-value" style="color:' + getScoreColor(s) + '">' + s + '</div>';
      html += '<span class="badge badge-' + getScoreLabel(s) + '">' + getScoreLabel(s).toUpperCase() + '</span>';
      html += '</div>';
    });

    html += '</div>';
    html += '<div class="report-metrics">';
    html += '<div class="metric-item"><strong>FCP:</strong> ' + r.metrics.fcp + '</div>';
    html += '<div class="metric-item"><strong>LCP:</strong> ' + r.metrics.lcp + '</div>';
    html += '<div class="metric-item"><strong>TBT:</strong> ' + r.metrics.tbt + '</div>';
    html += '<div class="metric-item"><strong>CLS:</strong> ' + r.metrics.cls + '</div>';
    html += '<div class="metric-item"><strong>SI:</strong> ' + r.metrics.si + '</div>';
    html += '</div>';
    html += '</a>';
  });
  document.getElementById('reportsList').innerHTML = html;
}

// Sorting
function sortReports(list, sortKey) {
  var sorted = list.slice();
  switch (sortKey) {
    case 'date-desc':
      sorted.sort(function(a, b) { return (b.fetchTime || '').localeCompare(a.fetchTime || ''); });
      break;
    case 'date-asc':
      sorted.sort(function(a, b) { return (a.fetchTime || '').localeCompare(b.fetchTime || ''); });
      break;
    case 'perf-desc':
      sorted.sort(function(a, b) { return b.scores.performance - a.scores.performance; });
      break;
    case 'perf-asc':
      sorted.sort(function(a, b) { return a.scores.performance - b.scores.performance; });
      break;
    case 'a11y-desc':
      sorted.sort(function(a, b) { return b.scores.accessibility - a.scores.accessibility; });
      break;
    case 'seo-desc':
      sorted.sort(function(a, b) { return b.scores.seo - a.scores.seo; });
      break;
  }
  return sorted;
}

function applyFilters() {
  var query = document.getElementById('searchInput').value.toLowerCase();
  var sortKey = document.getElementById('sortSelect').value;
  var filtered = reports.filter(function(r) {
    return r.url.toLowerCase().indexOf(query) !== -1 ||
           r.domain.toLowerCase().indexOf(query) !== -1;
  });
  renderReports(sortReports(filtered, sortKey));
}

document.getElementById('searchInput').addEventListener('input', applyFilters);
document.getElementById('sortSelect').addEventListener('change', applyFilters);

// Initial render
applyFilters();
</script>
</body>
</html>
"@

# Write HTML file with UTF-8 encoding
$htmlContent | Out-File -FilePath $OutputFile -Encoding utf8

Write-Host "Dashboard generated: $OutputFile"
Write-Host "Open in browser: $OutputFile"

# Auto-open in default browser
Start-Process $OutputFile
