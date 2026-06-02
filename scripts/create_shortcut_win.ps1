# Creates Desktop and Start Menu shortcuts for the built Windows app.
# Usage (from repo root, after building the Windows runner):
#   powershell -ExecutionPolicy Bypass -File scripts/create_shortcut_win.ps1 -ExePath "C:\path\to\caisse_1.exe" -Name "Caisse POS"
param(
  [string]$ExePath = "$PSScriptRoot\..\build\windows\x64\runner\Release\caisse_1.exe",
  [string]$Name = "Caisse POS"
)

# Resolve to absolute path
$ExePath = Resolve-Path $ExePath -ErrorAction SilentlyContinue

if (-not (Test-Path $ExePath)) {
  Write-Error "Executable not found at $ExePath. Build first with: flutter build windows --release"
  exit 1
}

$shell = New-Object -ComObject WScript.Shell

function New-Shortcut($destination) {
  $lnk = $shell.CreateShortcut($destination)
  $lnk.TargetPath = $ExePath
  $lnk.WorkingDirectory = Split-Path $ExePath
  $lnk.IconLocation = "$ExePath,0"
  $lnk.Description = "Caisse POS - Point of Sale System"
  $lnk.Save()
  Write-Output "✓ Shortcut created: $destination"
}

Write-Output "Creating shortcuts for: $ExePath"

$desktop = [Environment]::GetFolderPath("Desktop")
New-Shortcut (Join-Path $desktop "$Name.lnk")

$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
if (-not (Test-Path $startMenu)) {
  New-Item -ItemType Directory -Force -Path $startMenu | Out-Null
}
New-Shortcut (Join-Path $startMenu "$Name.lnk")

Write-Output "✓ Shortcuts created successfully!"
