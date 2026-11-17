$ErrorActionPreference = 'Stop'
$dataPath = if ($env:QEMS_DATA_DIR) { $env:QEMS_DATA_DIR } else { Join-Path $PSScriptRoot 'data' }
$pidPath = Join-Path $dataPath 'server.pid'
if (!(Test-Path -LiteralPath $pidPath)) { Write-Host 'QEMS is already stopped.'; exit }
$serverPid = [int](Get-Content -LiteralPath $pidPath)
$serverProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $serverPid"
$expectedScript = Join-Path $PSScriptRoot 'server.mjs'
if (!$serverProcess) { Write-Host 'QEMS is already stopped.'; exit }
if ($serverProcess.Name -ne 'node.exe' -or $serverProcess.CommandLine -notmatch [regex]::Escape($expectedScript)) { throw 'PID belongs to another process. Nothing was stopped.' }
Stop-Process -Id $serverPid
Wait-Process -Id $serverPid -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $pidPath -ErrorAction SilentlyContinue
Write-Host 'QEMS server stopped. The app folder can now be copied.'
