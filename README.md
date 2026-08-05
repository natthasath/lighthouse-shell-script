# 🎉 Lighthouse Shell Script

Lighthouse is an open-source, automated tool by Google for improving the quality of web pages. It audits performance, accessibility, SEO, best practices, and Progressive Web Apps (PWAs). This repo wraps the Lighthouse CLI with batch auditing over a URL list and an auto-generated HTML dashboard, for both Linux/macOS (Bash) and Windows (PowerShell).

![platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-lightgrey)
![license](https://img.shields.io/github/license/natthasath/lighthouse-shell-script)

### ✨ Features

- Batch audit every URL in `list.txt` in one run
- Outputs both HTML and JSON reports per site
- Auto-generates an HTML dashboard summarizing scores across all reports
- Bash and PowerShell versions of every script

### 🧊 Folder Structure

| File | Purpose |
| --- | --- |
| `scripts/lighthouse.sh` / `.ps1` | Run Lighthouse audits for every URL in `list.txt` |
| `scripts/generate_dashboard.sh` / `.ps1` | Build an HTML dashboard from the Lighthouse JSON reports |
| `scripts/install.sh` | Install Chrome/Chromium and set `CHROME_PATH` (Debian/Ubuntu) |
| `scripts/list.txt` | Target URLs, one per line |

### ✅ Requirements

- Node.js and npm (for the `lighthouse` CLI)
- Google Chrome or Chromium
- `jq` (only for `generate_dashboard.sh`)

### 🚀 Installation

```shell
npm install -g lighthouse
```

On Debian/Ubuntu, install Chrome/Chromium and set `CHROME_PATH` automatically:

```shell
bash scripts/install.sh
```

### ⚙️ Configuration

Edit `scripts/list.txt` and add one target URL per line:

```
https://nida.ac.th/
https://mba.nida.ac.th/en/home
https://law.nida.ac.th/
```

### 🏆 Usage

Audit a single URL directly:

```shell
lighthouse https://nida.ac.th --form-factor=desktop --screenEmulation.disabled --chrome-flags="--no-sandbox --disable-gpu" --throttling-method=provided
```

Batch-audit every URL in `list.txt` and build the dashboard:

```shell
bash scripts/lighthouse.sh
```

```powershell
scripts\lighthouse.ps1
```

Regenerate only the dashboard from existing reports:

```shell
bash scripts/generate_dashboard.sh
```

```powershell
scripts\generate_dashboard.ps1
```

Reports and the dashboard (`index.html`) are written to `scripts/lighthouse_reports/`.

### 📜 License

This project is licensed under the [MIT License](LICENSE).

### ✉️ Contact

**Natthasath Saksupanara** — Computer Technical Officer, NIDA  

natthasath.sak@gmail.com
