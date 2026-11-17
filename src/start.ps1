param([switch]$NoBrowser, [switch]$CheckRuntime)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$nodePath = $null
foreach ($candidate in @((Join-Path $PSScriptRoot 'runtime/node.exe'),(Join-Path $PSScriptRoot 'runtime/node/node.exe'),(Join-Path $PSScriptRoot 'nodejs/node.exe'))) {
    if (Test-Path -LiteralPath $candidate) { $nodePath = $candidate; break }
}
if (!$nodePath) { $installedNode = Get-Command node -ErrorAction SilentlyContinue; if ($installedNode) { $nodePath = $installedNode.Source } }
if (!$nodePath) { throw 'Put portable Node.js 24 or newer in runtime/node.exe, then run Start QEMS.bat again.' }
$nodeMajor = [int](& $nodePath -p "process.versions.node.split('.')[0]")
if ($nodeMajor -lt 24) { throw 'QEMS requires portable Node.js 24 or newer.' }
if ($CheckRuntime) { Write-Host "Portable runtime ready: $nodePath (Node $nodeMajor)"; exit 0 }
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'server-config.json') -Raw | ConvertFrom-Json
$port = if ($env:PORT) { [int]$env:PORT } else { [int]$config.port }
$protocol = if ($env:QEMS_PFX -or $env:QEMS_TLS_KEY) { 'https' } else { 'http' }
$url = "${protocol}://localhost:$port"
$serverScript = Join-Path $PSScriptRoot 'server.mjs'
$logDir = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
function Get-QemsHealth {
    try { return Invoke-RestMethod -Uri "${protocol}://127.0.0.1:$port/api/health" -TimeoutSec 1 -UseBasicParsing } catch { return $null }
}
$health = Get-QemsHealth
if ($health) {
    if ($health.app -ne 'QEMS') { throw "Port $port is in use by another application." }
    $running = Get-CimInstance Win32_Process -Filter "ProcessId = $($health.pid)" -ErrorAction SilentlyContinue
    if (!$running -or $running.CommandLine -notmatch [regex]::Escape($serverScript)) { throw 'A QEMS server from another folder is using this port. Stop it or change port in server-config.json.' }
    Write-Host 'QEMS is already running. Opening the workspace.'
} else {
    $arguments = '"' + $serverScript + '"'
    $started = Start-Process -FilePath $nodePath -ArgumentList $arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logDir 'server.log') -RedirectStandardError (Join-Path $logDir 'server-error.log')
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        Start-Sleep -Milliseconds 250
        $health = Get-QemsHealth
        if ($health -and $health.app -eq 'QEMS') { break }
        if ($started.HasExited) { throw "Server failed to start. Check logs/server-error.log." }
    }
    if (!$health -or $health.app -ne 'QEMS') { throw 'Server did not become ready. Check the logs folder.' }
    Write-Host 'QEMS started in the background.'
}
Write-Host "This PC: $url"
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { Write-Host "Other devices: ${protocol}://$($_.IPAddress):$port" }
Write-Host 'Keep this PC powered on. Use Stop QEMS.bat to stop the server.'
if (!$NoBrowser) { Start-Process -FilePath $url }
