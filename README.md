# Claude Code Statusline for Windows

A custom statusline for [Claude Code](https://claude.ai/claude-code) on Windows that displays real-time session information.

![Statusline Preview](https://img.shields.io/badge/󰍛_Opus_4.5_󱁉_$1.25_󰆼_███░░░░░░░_30%_󰥔_5h_45%_󰃭_7d_10%_⌘_abc12345-1a1b26?style=flat-square&labelColor=1a1b26)

## Features

- **Model name** - Currently active model
- **Session cost** - Running total in USD with color warnings
- **Context usage** - Visual progress bar of context window
- **5-hour limit** - Usage percentage with reset countdown
- **7-day limit** - Usage percentage with reset countdown
- **Session ID** - Quick reference identifier

## Quick Install

```powershell
irm https://raw.githubusercontent.com/botiejedi/claude-statusline/master/claude-statusline-install.ps1 | iex
```

Then restart Claude Code.

## Requirements

- Windows 10/11 with PowerShell 5.1+
- Claude Code CLI
- **Nerd Font** for icons ([Download CaskaydiaCove](https://www.nerdfonts.com/font-downloads))

## Manual Install

```powershell
powershell -ExecutionPolicy Bypass -File install-claude-statusline.ps1
```

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File install-claude-statusline.ps1 -Uninstall
```

## Color Thresholds

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Cost | < $2 | $2-5 | ≥ $5 |
| Context | < 40% | 40-70% | ≥ 70% |
| Usage Limits | < 60% | 60-80% | ≥ 80% |

## License

MIT
