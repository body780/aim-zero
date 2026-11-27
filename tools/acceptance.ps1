param(
    [ValidateSet('grid','micro','head','track','reactive','stop','peek')] [string]$Scene = 'track',
    [ValidateSet(1000,2000,4000,8000)] [int]$PollingHz = 1000,
    [int]$DisplayHz = 500
)
$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'AIM-ZERO.exe'
if (!(Test-Path $exe)) { throw 'Run the copy next to AIM-ZERO.exe.' }
$dir = Join-Path $env:TEMP ('aim-zero-' + [guid]::NewGuid())
New-Item -ItemType Directory $dir | Out-Null
$csv = Join-Path $dir 'frames.csv'
$p = Start-Process -FilePath $exe -ArgumentList @('--','--acceptance',$Scene,('"' + $csv + '"')) -Wait -PassThru
if ($p.ExitCode -ne 0 -or !(Test-Path $csv)) { throw "Incomplete run: $dir" }
$rows = @(Import-Csv $csv)
# Discard five active seconds at startup using measured frame intervals.
$elapsed = 0L
$warm = 0
while ($warm -lt $rows.Length -and $elapsed -lt 5000000) { $elapsed += [long]$rows[$warm].frame_us; $warm++ }
if ($rows.Length -le $warm) { throw 'Run too short.' }
$samples = $rows[$warm..($rows.Length-1)]
$us = [long[]]@($samples | ForEach-Object { [long]$_.frame_us })
[Array]::Sort($us)
$total = ($us | Measure-Object -Sum).Sum
$tail = [int][Math]::Ceiling($us.Length * 0.01)
$slow = ($us[($us.Length-$tail)..($us.Length-1)] | Measure-Object -Sum).Sum
$report = [ordered]@{
    scene = $Scene; requested_mouse_hz = $PollingHz; configured_display_hz = $DisplayHz
    sha256 = (Get-FileHash $exe).Hash; os = [Environment]::OSVersion.VersionString
    cpu = (Get-CimInstance Win32_Processor).Name; gpu = (Get-CimInstance Win32_VideoController).Name
    samples = $us.Length; seconds = $total / 1e6; average_fps = $us.Length * 1e6 / $total
    low_1pct_fps = $tail * 1e6 / $slow; p99_ms = $us[[int][Math]::Ceiling(.99 * $us.Length)-1] / 1000
    mouse_events_per_second = ($samples | Measure-Object mouse_events -Sum).Sum * 1e6 / $total
}
$report | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $dir 'summary.json')
$report
Write-Output $dir
