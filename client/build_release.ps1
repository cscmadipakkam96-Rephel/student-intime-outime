# Bumps the patch version + build number in pubspec.yaml (e.g. 1.0.14+15 -> 1.0.15+16),
# then builds the release AAB. Run this instead of hand-editing pubspec.yaml every time.

$ErrorActionPreference = "Stop"
$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"

$content = Get-Content $pubspecPath -Raw
$pattern = 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    throw "Could not find a 'version: X.Y.Z+N' line in pubspec.yaml"
}

$major = [int]$match.Groups[1].Value
$minor = [int]$match.Groups[2].Value
$patch = [int]$match.Groups[3].Value + 1
$build = [int]$match.Groups[4].Value + 1

$newVersion = "$major.$minor.$patch+$build"
$newContent = [regex]::Replace($content, $pattern, "version: $newVersion")
Set-Content -Path $pubspecPath -Value $newContent -NoNewline -Encoding utf8

Write-Host "Version bumped: $($match.Value) -> version: $newVersion"

# Kill any stale Gradle/Java daemons that tend to eat RAM on this machine before building.
try { Stop-Process -Name java -Force -ErrorAction Stop } catch {}

Write-Host "Building release AAB..."
Push-Location $PSScriptRoot
try {
    flutter build appbundle --release
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Done. New version: $newVersion"
Write-Host "AAB: client\build\app\outputs\bundle\release\app-release.aab"
