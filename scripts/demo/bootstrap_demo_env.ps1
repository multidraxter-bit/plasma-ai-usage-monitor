$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$venvPath = Join-Path $repoRoot '.venv-host'
$requirementsPath = Join-Path $PSScriptRoot 'requirements.txt'

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw 'python is required to bootstrap the host demo environment'
}

if (-not (Test-Path $venvPath)) {
    python -m venv $venvPath
}

$pythonExe = Join-Path $venvPath 'Scripts\python.exe'
& $pythonExe -m pip install --upgrade pip | Out-Null

if (Test-Path $requirementsPath) {
    $requirements = Get-Content $requirementsPath | Where-Object { $_ -and -not $_.Trim().StartsWith('#') }
    if ($requirements.Count -gt 0) {
        & $pythonExe -m pip install -r $requirementsPath
    }
}

Write-Host 'Host demo environment ready.'
Write-Host ''
Write-Host 'Use this for local script validation from Windows:'
Write-Host "  $pythonExe scripts/demo/mock_ai_usage_server.py --help"
Write-Host ''
Write-Host 'For real live testing and screenshots, create .venv inside the Fedora KDE VM using scripts/demo/bootstrap_demo_env.sh.'
