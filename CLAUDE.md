# Claude Code Statusline for Windows

This directory contains a custom statusline for Claude Code on Windows that displays session info at the bottom of the terminal.

## What It Shows

```
󰍛 Opus 4.5  󱁉 $1.25  󰆼 ███░░░░░░░ 30%  󰥔 5h 45% (3h16m)  󰃭 7d 10% (17h)  ⌘ abc12345
```

| Icon | Field | Description |
|------|-------|-------------|
| 󰍛 | Model | Current model name (blue, bold) |
| 󱁉 | Cost | Session cost in USD (gray < $2, yellow < $5, red ≥ $5) |
| 󰆼 | Context | Context window usage bar (cyan < 40%, yellow < 70%, red ≥ 70%) |
| 󰥔 | 5h | 5-hour usage limit % with reset countdown (green < 60%, yellow < 80%, red ≥ 80%) |
| 󰃭 | 7d | 7-day usage limit % with reset countdown (green < 60%, yellow < 80%, red ≥ 80%) |
| ⌘ | Session | First 8 chars of session ID (dim gray) |

## Installation Instructions

### For Claude Code AI Assistants

When a user asks to install this statusline, follow these steps:

1. **Check for Nerd Font**: The user needs a Nerd Font installed (CaskaydiaCove, JetBrainsMono, etc.) for icons to render. If icons show as boxes/question marks, they need to install one from https://www.nerdfonts.com/font-downloads

2. **Run the installer**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "PATH_TO/claude-statusline-install.ps1"
   ```

   Or if hosted online:
   ```powershell
   irm https://raw.githubusercontent.com/USER/REPO/main/claude-statusline-install.ps1 | iex
   ```

3. **Restart Claude Code**: The statusline won't appear until Claude Code is restarted.

4. **Set terminal font**: Ensure the terminal is using a Nerd Font:
   - **Windows Terminal**: Settings → Profiles → Defaults → Font face → "CaskaydiaCove Nerd Font"
   - **VS Code**: Settings → Terminal › Integrated: Font Family → "CaskaydiaCove Nerd Font"

### Manual Installation

If the installer doesn't work, manually create these files:

1. Create directory: `~\.local\bin\`

2. Create `~\.local\bin\claude-statusline.ps1` with the PowerShell script

3. Create `~\.local\bin\claude-statusline.cmd`:
   ```batch
   @echo off
   powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\claude-statusline.ps1"
   ```

4. Add to `~\.claude\settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "C:\\Users\\USERNAME\\.local\\bin\\claude-statusline.cmd"
     }
   }
   ```

## Troubleshooting

### Icons show as boxes or question marks
- Install a Nerd Font from https://www.nerdfonts.com/font-downloads
- Set the terminal font to the Nerd Font
- Recommended: CaskaydiaCove Nerd Font or JetBrainsMono Nerd Font

### Statusline not appearing
1. Check `~\.claude\settings.json` has the `statusLine` config
2. Verify the path to `claude-statusline.cmd` is correct
3. Test manually:
   ```powershell
   echo '{"model":{"display_name":"Test"},"cost":{"total_cost_usd":0.5},"context_window":{"used_percentage":25}}' | & "$env:USERPROFILE\.local\bin\claude-statusline.cmd"
   ```

### Usage limits (5h/7d) not showing
- Usage limits are read from cship cache files in `~\.claude\projects\*\cship\`
- These files are created by cship (Linux/macOS) and may not exist on Windows-only installs
- The statusline will still work, just without usage limit display

### Colors look wrong
- Ensure your terminal supports 24-bit color (true color)
- Windows Terminal and VS Code terminal both support this by default

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File "PATH_TO/install-claude-statusline.ps1" -Uninstall
```

Or manually:
1. Delete `~\.local\bin\claude-statusline.ps1`
2. Delete `~\.local\bin\claude-statusline.cmd`
3. Remove the `statusLine` key from `~\.claude\settings.json`

## Files

| File | Purpose |
|------|---------|
| `claude-statusline-install.ps1` | Compact one-liner installer |
| `install-claude-statusline.ps1` | Full installer with uninstall support |
| `CLAUDE.md` | This guide (for Claude Code AI assistants) |
