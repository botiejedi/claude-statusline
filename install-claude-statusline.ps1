#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Claude Code statusline for Windows.

.DESCRIPTION
    Sets up a custom statusline for Claude Code that displays:
    - Model name
    - Session cost
    - Context usage bar
    - 5-hour and 7-day usage limits with countdown
    - Session ID

.NOTES
    Requires a Nerd Font (CaskaydiaCove, JetBrainsMono, etc.) for icons to render.
    Download from: https://www.nerdfonts.com/font-downloads
#>

param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# Paths
$binDir = "$env:USERPROFILE\.local\bin"
$claudeSettingsDir = "$env:USERPROFILE\.claude"
$statuslineScript = "$binDir\claude-statusline.ps1"
$statuslineCmd = "$binDir\claude-statusline.cmd"
$settingsFile = "$claudeSettingsDir\settings.json"

function Write-Status($msg) { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  $msg" -ForegroundColor Yellow }

# ============================================================================
# UNINSTALL
# ============================================================================
if ($Uninstall) {
    Write-Host "`n  Uninstalling Claude Code statusline...`n" -ForegroundColor Magenta

    if (Test-Path $statuslineScript) { Remove-Item $statuslineScript -Force; Write-Status "Removed $statuslineScript" }
    if (Test-Path $statuslineCmd) { Remove-Item $statuslineCmd -Force; Write-Status "Removed $statuslineCmd" }

    if (Test-Path $settingsFile) {
        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
        if ($settings.statusLine) {
            $settings.PSObject.Properties.Remove('statusLine')
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
            Write-Status "Removed statusLine from settings.json"
        }
    }

    Write-Success "`n  Uninstall complete. Restart Claude Code.`n"
    exit 0
}

# ============================================================================
# INSTALL
# ============================================================================
Write-Host "`n  Installing Claude Code statusline...`n" -ForegroundColor Magenta

# Create directories
if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    Write-Status "Created $binDir"
}

# Write the main PowerShell script
$statuslineContent = @'
# Claude Code statusline for Windows (PowerShell)
# Reads JSON from stdin and outputs formatted statusline

param()

$input_text = [Console]::In.ReadToEnd()

try {
    $data = $input_text | ConvertFrom-Json
} catch {
    Write-Output ""
    exit 0
}

# Nerd Font icons
$icons = @{
    model = [char]::ConvertFromUtf32(0xF035B)    # 󰍛
    cost = [char]::ConvertFromUtf32(0xF1049)     # 󱁉
    context = [char]::ConvertFromUtf32(0xF01BC)  # 󰆼
    clock = [char]::ConvertFromUtf32(0xF0954)    # 󰥔
    calendar = [char]::ConvertFromUtf32(0xF00ED) # 󰃭
    command = [char]0x2318                        # ⌘
    blockFull = [char]0x2588                      # █
    blockLight = [char]0x2591                     # ░
}

# ANSI escape codes
$esc = [char]27
$c = @{
    blue = "$esc[38;2;122;162;247m"
    green = "$esc[38;2;158;206;106m"
    cyan = "$esc[38;2;125;207;255m"
    gray = "$esc[38;2;169;177;214m"
    dimGray = "$esc[38;2;86;95;137m"
    yellow = "$esc[38;2;224;175;104m"
    red = "$esc[38;2;247;118;142m"
    bold = "$esc[1m"
    reset = "$esc[0m"
}

# Try to find and read usage limits from cship cache
$usageLimits = $null
$cshipDirs = Get-ChildItem -Path "$env:USERPROFILE\.claude\projects" -Directory -ErrorAction SilentlyContinue
foreach ($dir in $cshipDirs) {
    $cshipPath = Join-Path $dir.FullName "cship"
    if (Test-Path $cshipPath) {
        $limitFiles = Get-ChildItem -Path $cshipPath -Filter "*-usage-limits" -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First 1
        if ($limitFiles) {
            try {
                $usageLimits = Get-Content $limitFiles.FullName -Raw | ConvertFrom-Json
                break
            } catch {}
        }
    }
}

$parts = @()

# Model display
$modelName = "unknown"
if ($data.model) {
    if ($data.model.display_name) {
        $modelName = $data.model.display_name
    } elseif ($data.model.id) {
        $modelName = $data.model.id
    } elseif ($data.model -is [string]) {
        $modelName = $data.model
    }
}
$parts += "$($c.bold)$($c.blue)$($icons.model) $modelName$($c.reset)"

# Cost
if ($data.cost -and $null -ne $data.cost.total_cost_usd) {
    $cost = [double]$data.cost.total_cost_usd
    $style = $c.gray
    if ($cost -ge 5.0) { $style = "$($c.bold)$($c.red)" }
    elseif ($cost -ge 2.0) { $style = $c.yellow }
    $parts += "$style$($icons.cost) `$$($cost.ToString('F2'))$($c.reset)"
}

# Context usage bar
if ($data.context_window -and $null -ne $data.context_window.used_percentage) {
    $pct = [double]$data.context_window.used_percentage

    $style = $c.cyan
    if ($pct -ge 70) { $style = "$($c.bold)$($c.red)" }
    elseif ($pct -ge 40) { $style = $c.yellow }

    $width = 10
    $filled = [int][math]::Round(($pct / 100) * $width)
    $empty = [int]($width - $filled)
    $bar = ([string]$icons.blockFull * $filled) + ([string]$icons.blockLight * $empty)

    $parts += "$style$($icons.context) $bar $([math]::Round($pct))%$($c.reset)"
}

# Usage limits from cship cache
if ($usageLimits -and $usageLimits.data) {
    $nowUnix = [int][double]::Parse((Get-Date -UFormat %s))

    # 5-hour limit
    if ($null -ne $usageLimits.data.five_hour_pct -and $null -ne $usageLimits.five_hour_resets_at) {
        $pct = [double]$usageLimits.data.five_hour_pct
        $resetAt = [int]$usageLimits.five_hour_resets_at
        $secsLeft = $resetAt - $nowUnix

        if ($secsLeft -gt 0) {
            $hours = [math]::Floor($secsLeft / 3600)
            $mins = [math]::Floor(($secsLeft % 3600) / 60)
            $countdown = if ($hours -gt 0) { "${hours}h${mins}m" } else { "${mins}m" }

            $style = $c.green
            if ($pct -ge 80) { $style = "$($c.bold)$($c.red)" }
            elseif ($pct -ge 60) { $style = $c.yellow }

            $parts += "$style$($icons.clock) 5h $([math]::Round($pct))% ($countdown)$($c.reset)"
        }
    }

    # 7-day limit
    if ($null -ne $usageLimits.data.seven_day_pct -and $null -ne $usageLimits.seven_day_resets_at) {
        $pct = [double]$usageLimits.data.seven_day_pct
        $resetAt = [int]$usageLimits.seven_day_resets_at
        $secsLeft = $resetAt - $nowUnix

        if ($secsLeft -gt 0) {
            $days = [math]::Floor($secsLeft / 86400)
            $hours = [math]::Floor(($secsLeft % 86400) / 3600)
            $countdown = if ($days -gt 0) { "${days}d${hours}h" } else { "${hours}h" }

            $style = $c.green
            if ($pct -ge 80) { $style = "$($c.bold)$($c.red)" }
            elseif ($pct -ge 60) { $style = $c.yellow }

            $parts += "$style$($icons.calendar) 7d $([math]::Round($pct))% ($countdown)$($c.reset)"
        }
    }
}

# Session ID
if ($data.session_id) {
    $shortId = $data.session_id.Substring(0, [math]::Min(8, $data.session_id.Length))
    $parts += "$($c.dimGray)$($icons.command) $shortId$($c.reset)"
}

# Output final statusline with double-space separators
Write-Output ($parts -join "  ")
'@

Set-Content -Path $statuslineScript -Value $statuslineContent -Encoding UTF8
Write-Status "Created $statuslineScript"

# Write the CMD wrapper
$cmdContent = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\claude-statusline.ps1"
'@

Set-Content -Path $statuslineCmd -Value $cmdContent -Encoding ASCII
Write-Status "Created $statuslineCmd"

# Update Claude Code settings
if (!(Test-Path $claudeSettingsDir)) {
    New-Item -ItemType Directory -Path $claudeSettingsDir -Force | Out-Null
}

$settings = @{}
if (Test-Path $settingsFile) {
    try {
        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        $settings = @{}
    }
}

$settings["statusLine"] = @{
    type = "command"
    command = "$env:USERPROFILE\.local\bin\claude-statusline.cmd" -replace '\\', '\\'
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
Write-Status "Updated $settingsFile"

# Done
Write-Host ""
Write-Success "Installation complete!"
Write-Host ""
Write-Host "  Statusline format:" -ForegroundColor White
Write-Host "  󰍛 Model  󱁉 `$Cost  󰆼 ██░░░░░░░░ Context%  󰥔 5h Usage%  󰃭 7d Usage%  ⌘ SessionID" -ForegroundColor Gray
Write-Host ""
Write-Warn "  IMPORTANT: Install a Nerd Font for icons to display correctly."
Write-Host "  Download CaskaydiaCove from: https://www.nerdfonts.com/font-downloads" -ForegroundColor Gray
Write-Host ""
Write-Warn "  Restart Claude Code to activate the statusline."
Write-Host ""
