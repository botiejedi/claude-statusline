#Requires -Version 5.1
# Claude Code Statusline Installer for Windows
# One-liner: irm https://raw.githubusercontent.com/botiejedi/claude-statusline/master/claude-statusline-install.ps1 | iex

$ErrorActionPreference = "Stop"
$binDir = "$env:USERPROFILE\.local\bin"
$claudeDir = "$env:USERPROFILE\.claude"

# Create directories
@($binDir, $claudeDir) | ForEach-Object { if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null } }

# Write statusline script
@'
param()
$input_text = [Console]::In.ReadToEnd()
try { $data = $input_text | ConvertFrom-Json } catch { Write-Output ""; exit 0 }

$icons = @{
    model = [char]::ConvertFromUtf32(0xF035B); cost = [char]::ConvertFromUtf32(0xF1049)
    context = [char]::ConvertFromUtf32(0xF01BC); clock = [char]::ConvertFromUtf32(0xF0954)
    calendar = [char]::ConvertFromUtf32(0xF00ED); command = [char]0x2318
    blockFull = [char]0x2588; blockLight = [char]0x2591
}

$esc = [char]27
$c = @{
    blue = "$esc[38;2;122;162;247m"; green = "$esc[38;2;158;206;106m"; cyan = "$esc[38;2;125;207;255m"
    gray = "$esc[38;2;169;177;214m"; dimGray = "$esc[38;2;86;95;137m"; yellow = "$esc[38;2;224;175;104m"
    red = "$esc[38;2;247;118;142m"; bold = "$esc[1m"; reset = "$esc[0m"
}

$usageLimits = $null
Get-ChildItem -Path "$env:USERPROFILE\.claude\projects" -Directory -EA SilentlyContinue | ForEach-Object {
    $cshipPath = Join-Path $_.FullName "cship"
    if ((Test-Path $cshipPath) -and !$usageLimits) {
        $f = Get-ChildItem -Path $cshipPath -Filter "*-usage-limits" -EA SilentlyContinue | Sort-Object LastWriteTime -Desc | Select-Object -First 1
        if ($f) { try { $usageLimits = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch {} }
    }
}

$parts = @()

$modelName = if ($data.model.display_name) { $data.model.display_name } elseif ($data.model.id) { $data.model.id } elseif ($data.model -is [string]) { $data.model } else { "unknown" }
$parts += "$($c.bold)$($c.blue)$($icons.model) $modelName$($c.reset)"

if ($data.cost -and $null -ne $data.cost.total_cost_usd) {
    $cost = [double]$data.cost.total_cost_usd
    $style = if ($cost -ge 5) { "$($c.bold)$($c.red)" } elseif ($cost -ge 2) { $c.yellow } else { $c.gray }
    $parts += "$style$($icons.cost) `$$($cost.ToString('F2'))$($c.reset)"
}

if ($data.context_window -and $null -ne $data.context_window.used_percentage) {
    $pct = [double]$data.context_window.used_percentage
    $style = if ($pct -ge 70) { "$($c.bold)$($c.red)" } elseif ($pct -ge 40) { $c.yellow } else { $c.cyan }
    $filled = [int][math]::Round(($pct / 100) * 10); $empty = 10 - $filled
    $bar = ([string]$icons.blockFull * $filled) + ([string]$icons.blockLight * $empty)
    $parts += "$style$($icons.context) $bar $([math]::Round($pct))%$($c.reset)"
}

if ($usageLimits -and $usageLimits.data) {
    $nowUnix = [int][double]::Parse((Get-Date -UFormat %s))
    if ($null -ne $usageLimits.data.five_hour_pct -and $null -ne $usageLimits.five_hour_resets_at) {
        $pct = [double]$usageLimits.data.five_hour_pct; $secsLeft = [int]$usageLimits.five_hour_resets_at - $nowUnix
        if ($secsLeft -gt 0) {
            $h = [math]::Floor($secsLeft / 3600); $m = [math]::Floor(($secsLeft % 3600) / 60)
            $cd = if ($h -gt 0) { "${h}h${m}m" } else { "${m}m" }
            $style = if ($pct -ge 80) { "$($c.bold)$($c.red)" } elseif ($pct -ge 60) { $c.yellow } else { $c.green }
            $parts += "$style$($icons.clock) 5h $([math]::Round($pct))% ($cd)$($c.reset)"
        }
    }
    if ($null -ne $usageLimits.data.seven_day_pct -and $null -ne $usageLimits.seven_day_resets_at) {
        $pct = [double]$usageLimits.data.seven_day_pct; $secsLeft = [int]$usageLimits.seven_day_resets_at - $nowUnix
        if ($secsLeft -gt 0) {
            $d = [math]::Floor($secsLeft / 86400); $h = [math]::Floor(($secsLeft % 86400) / 3600)
            $cd = if ($d -gt 0) { "${d}d${h}h" } else { "${h}h" }
            $style = if ($pct -ge 80) { "$($c.bold)$($c.red)" } elseif ($pct -ge 60) { $c.yellow } else { $c.green }
            $parts += "$style$($icons.calendar) 7d $([math]::Round($pct))% ($cd)$($c.reset)"
        }
    }
}

if ($data.session_id) { $parts += "$($c.dimGray)$($icons.command) $($data.session_id.Substring(0,8))$($c.reset)" }

Write-Output ($parts -join "  ")
'@ | Set-Content "$binDir\claude-statusline.ps1" -Encoding UTF8

# Write CMD wrapper
'@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\claude-statusline.ps1"' | Set-Content "$binDir\claude-statusline.cmd" -Encoding ASCII

# Update settings.json
$settings = @{}
if (Test-Path "$claudeDir\settings.json") {
    try { $settings = Get-Content "$claudeDir\settings.json" -Raw | ConvertFrom-Json -AsHashtable } catch { $settings = @{} }
}
$settings["statusLine"] = @{ type = "command"; command = "$env:USERPROFILE\.local\bin\claude-statusline.cmd" -replace '\\','\\' }
$settings | ConvertTo-Json -Depth 10 | Set-Content "$claudeDir\settings.json" -Encoding UTF8

Write-Host "`n  Claude Code statusline installed!" -ForegroundColor Green
Write-Host "  Restart Claude Code to activate.`n" -ForegroundColor Yellow
Write-Host "  Note: Install a Nerd Font (CaskaydiaCove) for icons." -ForegroundColor Gray
Write-Host "  https://www.nerdfonts.com/font-downloads`n" -ForegroundColor DarkGray
