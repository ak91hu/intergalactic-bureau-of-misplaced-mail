[CmdletBinding()]
param(
    [string]$Godot = $env:GODOT_EXECUTABLE,
    [ValidateSet('All', 'Web', 'Windows', 'Tests')][string]$Target = 'All'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $Godot) {
    $engineCommand = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($engineCommand) { $Godot = $engineCommand.Source }
    else {
        $portableEngine = Join-Path $projectRoot '..\.ibmm-tools\godot\Godot_v4.7.2-stable_win64_console.exe'
        if (Test-Path -LiteralPath $portableEngine) { $Godot = [IO.Path]::GetFullPath($portableEngine) }
    }
}
if (-not $Godot) { throw 'Pass -Godot <path to Godot 4.7.2>, or set GODOT_EXECUTABLE.' }
$version = (& $Godot --version | Out-String).Trim()
if ($version -notmatch '^4\.7\.2\.stable') { throw "Expected Godot 4.7.2 stable; found $version" }
function Invoke-Engine([string[]]$EngineArgs) {
    $runtimeRoot = $projectRoot
    if ($EngineArgs -contains '--main-pack') {
        $packIndex = [Array]::IndexOf($EngineArgs, '--main-pack')
        $runtimeRoot = Split-Path -Parent $EngineArgs[$packIndex + 1]
    }
    $output = & $Godot --path $runtimeRoot @EngineArgs 2>&1
    $engineExit = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($engineExit -ne 0 -or ($output | Out-String) -match '(?m)^(SCRIPT ERROR|ERROR):') {
        throw "Godot failed: $($EngineArgs -join ' ') (exit $engineExit)"
    }
}
function Copy-Notices([string]$Destination) {
    foreach ($notice in @('OFL-Inter.txt', 'LICENSE-Godot.txt', 'COPYRIGHT-Godot.txt', 'MUSIC-LICENSE.txt')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot "assets/$notice") -Destination (Join-Path $Destination $notice) -Force
    }
}
Invoke-Engine @('--headless', '--editor', '--import', '--quit')
Invoke-Engine @('--headless', '--script', 'res://tests/runner.gd')
Invoke-Engine @('--headless', '--script', 'res://tests/ui_smoke.gd')
Invoke-Engine @('--headless', '--script', 'res://tests/courier_ui.gd')
Invoke-Engine @('--headless', '--script', 'res://tests/tree_ui.gd')
if ($Target -eq 'Tests') { return }
$exportCache = [IO.Path]::GetFullPath((Join-Path $projectRoot '.godot\exported'))
if (-not $exportCache.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Export cache must stay inside the project.'
}
if (Test-Path -LiteralPath $exportCache) { Remove-Item -LiteralPath $exportCache -Recurse -Force }
if ($Target -in @('All', 'Web')) {
    $webDir = Join-Path $projectRoot 'export/web'
    New-Item -ItemType Directory -Path $webDir -Force | Out-Null
    Invoke-Engine @('--headless', '--export-release', 'Web', (Join-Path $webDir 'index.html'))
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'server.py') -Destination (Join-Path $webDir 'server.py') -Force
    Copy-Notices $webDir
    Invoke-Engine @('--headless', '--main-pack', (Join-Path $webDir 'index.pck'), '--script', (Join-Path $projectRoot 'tests/export_smoke.gd'))
}
if ($Target -in @('All', 'Windows')) {
    $windowsDir = Join-Path $projectRoot 'export/windows'
    New-Item -ItemType Directory -Path $windowsDir -Force | Out-Null
    Invoke-Engine @('--headless', '--export-release', 'Windows Desktop', (Join-Path $windowsDir 'MisplacedMail.exe'))
    Copy-Notices $windowsDir
    Invoke-Engine @('--headless', '--main-pack', (Join-Path $windowsDir 'MisplacedMail.exe'), '--script', (Join-Path $projectRoot 'tests/export_smoke.gd'))
}
Write-Host "Build ready in $projectRoot/export"
