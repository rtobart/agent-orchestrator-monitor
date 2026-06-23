# OC Monitor

macOS menu bar monitor for [OpenCode](https://opencode.ai) usage & spending limits.

## Features

- 📊 Menu bar popover with dark theme (#0f1117)
- 💰 Tracks cost across configurable time windows
- 📈 Progress bars with color thresholds (>85% = red)
- ⚡ Auto-refresh every 60s
- 👻 Menu bar only (no Dock icon)
- ⚙️ Configurable windows & limits via `~/.config/agent-orchestrator-monitor/config.json`

## Configuration

On first launch, a default config is created at `~/.config/agent-orchestrator-monitor/config.json`. Edit it to customize time windows and spending limits:

```json
{
  "windows": [
    {"label": "Últimas 5 horas", "key": "5h",  "seconds": 18000,   "limit": 12},
    {"label": "Esta semana",     "key": "7d",  "seconds": 604800,  "limit": 30},
    {"label": "Este mes",        "key": "30d", "seconds": 2592000, "limit": 60}
  ]
}
```

- `seconds` — time window in seconds
- `limit` — spending limit in USD
- `label` — display name in the popover
- `key` — internal ID (must be unique)

Add or remove windows as needed. Restart the app after changes.

## Auto-start on login

**Option A**: System Settings → General → Login Items & Extensions → add OCMonitor.app

**Option B**: Create a LaunchAgent:

```bash
cat > ~/Library/LaunchAgents/dev.agent-orchestrator.ocmonitor.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.agent-orchestrator.ocmonitor</string>
    <key>Program</key>
    <string>/Applications/OCMonitor.app/Contents/MacOS/OCMonitor</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
launchctl load ~/Library/LaunchAgents/dev.agent-orchestrator.ocmonitor.plist
```

## Install

Download the latest `OCMonitor-*.zip` from [Releases](https://github.com/rtobart/agent-orchestrator-monitor/releases), unzip, and move to `/Applications`.

macOS will show a security warning because the app is not notarized (requires a paid Apple Developer account). To open it:

```bash
# Option 1: Remove quarantine flag (terminal)
xattr -cr /Applications/OCMonitor.app

# Option 2: Right-click → Open → Open (Finder)
```

Then launch it from Applications or:

```bash
open /Applications/OCMonitor.app
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
