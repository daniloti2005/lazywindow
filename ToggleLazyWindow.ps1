# ToggleLazyWindow.ps1
# Starts LazyWindow (src\main.ahk) if not running; if running, stops it.

$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'src\main.ahk'
if (!(Test-Path $scriptPath)) {
  throw "LazyWindow script not found: $scriptPath"
}

function Test-IsAutoHotkeyV2($path) {
  try {
    $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path)
    if ($info -and $info.FileVersion) {
      try {
        $v = [version]$info.FileVersion
        return $v.Major -ge 2
      } catch { }
    }
  } catch { }
  return $false
}

function Get-AutoHotkeyExe {
  if ($env:AUTOHOTKEY_EXE -and (Test-Path $env:AUTOHOTKEY_EXE) -and (Test-IsAutoHotkeyV2 $env:AUTOHOTKEY_EXE)) {
    return $env:AUTOHOTKEY_EXE
  }

  # Prefer AutoHotkey v2 install locations over PATH (PATH may point to v1).
  $candidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey32.exe'),
    (Join-Path $env:LocalAppData 'Programs\AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:LocalAppData 'Programs\AutoHotkey\v2\AutoHotkey.exe'),
    (Join-Path $env:LocalAppData 'Programs\AutoHotkey\v2\AutoHotkey32.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey64.exe'),
    (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey.exe'),
    (Join-Path $env:LocalAppData 'Programs\AutoHotkey\AutoHotkey64.exe'),
    (Join-Path $env:LocalAppData 'Programs\AutoHotkey\AutoHotkey.exe')
  )

  foreach ($p in $candidates) {
    if ($p -and (Test-Path $p) -and (Test-IsAutoHotkeyV2 $p)) { return $p }
  }

  $cmd = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
  if ($cmd -and (Test-IsAutoHotkeyV2 $cmd.Source)) { return $cmd.Source }
  $cmd = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
  if ($cmd -and (Test-IsAutoHotkeyV2 $cmd.Source)) { return $cmd.Source }

  return $null
}

$ahkExe = Get-AutoHotkeyExe
if (!$ahkExe) {
  $msg = "AutoHotkey v2 não encontrado. Instale o AutoHotkey v2 ou defina AUTOHOTKEY_EXE apontando para AutoHotkey64.exe."
  try {
    Add-Type -AssemblyName PresentationFramework | Out-Null
    [System.Windows.MessageBox]::Show($msg, 'LazyWindow', 'OK', 'Error') | Out-Null
  } catch {
    Write-Error $msg
  }
  exit 2
}

$escaped = [regex]::Escape($scriptPath)
$running = Get-CimInstance Win32_Process |
  Where-Object {
    $_.Name -match '^AutoHotkey(64)?\.exe$' -and $_.CommandLine -match $escaped
  }

if ($running) {
  foreach ($p in $running) {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
  }
  exit 0
}

Start-Process -FilePath $ahkExe -ArgumentList @('"' + $scriptPath + '"') -WorkingDirectory (Split-Path $scriptPath -Parent)
exit 0
