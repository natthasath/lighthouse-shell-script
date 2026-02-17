# 🎉 Lighthouse Shell Script

Lighthouse is an open-source, automated tool by Google for improving the quality of web pages. It audits performance, accessibility, SEO, best practices, and Progressive Web Apps (PWAs). Lighthouse runs in Chrome DevTools, via the command line, or as a Node module.

![version](https://img.shields.io/badge/version-1.0-blue)
![rating](https://img.shields.io/badge/rating-★★★★★-yellow)
![uptime](https://img.shields.io/badge/uptime-100%25-brightgreen)

### 📦 Package

```
npm install -g lighthouse
```

### Run
```shell
lighthouse https://nida.ac.th --form-factor=desktop --screenEmulation.disabled --chrome-flags="--no-sandbox --disable-gpu" --throttling-method=provided
```