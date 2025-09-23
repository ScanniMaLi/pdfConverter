# run_app.ps1
# Wrapper to run the Flask app using the venv python if available.
# Usage: .\run_app.ps1 [port]

param(
    [int]$Port = 5000
)

# Try to find venv python
$venvPython = $null
if (Test-Path .\venv\Scripts\python.exe) {
    $venvPython = (Resolve-Path .\venv\Scripts\python.exe).Path
} elseif (Test-Path .\python.exe) {
    # fallback to local python in project root
    $venvPython = (Resolve-Path .\python.exe).Path
} else {
    Write-Host "No venv python found. Run .\setup_venv.ps1 first or ensure python is on PATH." -ForegroundColor Yellow
}

if ($venvPython) {
    Write-Host "Starting app with: $venvPython app.py (port $Port)"
    & $venvPython app.py
} else {
    # Try system python
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) {
        Write-Host "Starting app with system python (port $Port)"
        python app.py
    } else {
        Write-Host "Python not found. Please run setup_venv or install Python." -ForegroundColor Red
        exit 1
    }
}