# OC Monitor

macOS menu bar monitor for [OpenCode](https://opencode.ai) usage & spending limits.

## Features

- 📊 Menu bar popover with dark theme
- 💰 Tracks cost across 3 windows: 5h / weekly / monthly
- 📈 Progress bars with color thresholds (>85% = red)
- ⚡ Auto-refresh every 60s

## Install

```bash
# Download latest release from:
# https://github.com/rtobart/agent-orchestrator-monitor/releases

# Unzip and open
open OCMonitor.app
```

Or build from source:

```bash
git clone https://github.com/rtobart/agent-orchestrator-monitor.git
cd agent-orchestrator-monitor
swift build -c release
./build-app.sh
open OCMonitor.app
```

## Development

```bash
# Branch: dev (default for development)
git checkout dev

# Build
swift build

# Run
swift run

# Validate
./Validation/validate.sh

# Package .app
./build-app.sh
```

## Release flow

1. Work on `dev` branch → push → CI verifies build
2. Merge `dev` → `main`
3. Tag: `git tag v1.0.0 && git push --tags`
4. GitHub Actions builds, packages, creates release

## Architecture

```
Sources/OCMonitor/
├── App.swift              # Entry point
├── Models/
│   └── UsageWindow.swift  # Data model
├── Services/
│   └── DatabaseService.swift  # Protocol + SQLite impl + Mock
├── ViewModels/
│   └── MonitorViewModel.swift # Business logic (DIP)
└── Views/
    ├── ContentView.swift  # Layout + design tokens
    ├── UsageCard.swift    # Metric card
    └── BarView.swift      # Progress bar
```
