<#
.SYNOPSIS
    Automates the release trigger for AucorsaBus via GitHub Actions.
    - Bumps version in pubspec.yaml
    - Commits and Tags
    - Pushes to GitHub to trigger Actions Build & Release

.EXAMPLE
    .\release.ps1 -Version "1.5.9"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

# Resolve path relative to the script file location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PubspecPath = Join-Path $ScriptDir "..\pubspec.yaml"

# 1. Update pubspec.yaml
Write-Host " [?] Updating pubspec.yaml to version: $Version" -ForegroundColor Cyan
$content = Get-Content $PubspecPath
$newContent = $content -replace '^version: .*', "version: $Version"
$newContent | Set-Content $PubspecPath

# 2. Git Operations
Write-Host " [?] Committing and Tagging v$Version..." -ForegroundColor Cyan
git add $PubspecPath
git commit -m "chore: release v$Version"
git tag "v$Version"

# 3. Push to Trigger Action
Write-Host " [?] Pushing to GitHub (Triggers CI/CD)..." -ForegroundColor Cyan
git push origin main
git push origin "v$Version"

Write-Host " [v] Release v$Version Triggered!" -ForegroundColor Green
Write-Host "     Watch the build at: https://github.com/ncc-288/AucorsaBus/actions" -ForegroundColor Yellow
