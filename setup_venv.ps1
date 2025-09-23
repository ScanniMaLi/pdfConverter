# setup_venv.ps1
# Create a Python virtual environment (venv) in the project, upgrade pip, and install requirements.
# Usage (PowerShell):
#   .\setup_venv.ps1
# After running, activate with: .\venv\Scripts\Activate.ps1

Set-StrictMode -Version Latest

function Write-ErrorAndExit($msg) {
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

# Try to find python on PATH
$pythonCmd = $null
$cmd = Get-Command python -ErrorAction SilentlyContinue
if ($cmd) {
    $pythonCmd = $cmd.Source
}

# Fall back to local python.exe if present
if (-not $pythonCmd -and (Test-Path .\python.exe)) {
    $pythonCmd = (Resolve-Path .\python.exe).Path
}

if (-not $pythonCmd) {
    Write-ErrorAndExit "Python executable not found. Please install Python and ensure it's on PATH, or place python.exe in the project root."
}

Write-Host "Using Python: $pythonCmd"

# Ensure uploads folder exists
if (-not (Test-Path .\uploads)) {
    Write-Host "Creating uploads directory..."
    New-Item -ItemType Directory -Path .\uploads | Out-Null
}

# Create virtual environment
if (-not (Test-Path .\venv)) {
    Write-Host "Creating virtual environment in .\venv..."
    & $pythonCmd -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "Failed to create virtual environment (exit code $LASTEXITCODE)."
    }
    Write-Host "Virtual environment created."
} else {
    Write-Host "Virtual environment already exists at .\venv"
}

# Resolve venv python path
$venvPython = Join-Path -Path (Resolve-Path .\venv\Scripts).Path -ChildPath "python.exe"
if (-not (Test-Path $venvPython)) {
    Write-ErrorAndExit "Could not find venv python at $venvPython"
}

Write-Host "Upgrading pip, setuptools, wheel..."
& $venvPython -m pip install --upgrade pip setuptools wheel
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: pip upgrade returned exit code $LASTEXITCODE" -ForegroundColor Yellow
}

# Install requirements if present
if (Test-Path .\requirements.txt) {
    Write-Host "Installing packages from requirements.txt..."
    & $venvPython -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorAndExit "pip install returned exit code $LASTEXITCODE"
    }
} else {
    Write-Host "No requirements.txt found. Skipping package installation." -ForegroundColor Yellow
}

Write-Host "\nSetup complete. To activate the virtual environment run (PowerShell):" -ForegroundColor Green
Write-Host "    .\\venv\\Scripts\\Activate.ps1" -ForegroundColor Cyan
Write-Host "Or in cmd.exe (Windows):" -ForegroundColor Cyan
Write-Host "    .\\venv\\Scripts\\activate.bat" -ForegroundColor Cyan
Write-Host "Then run the app with:\n    python app.py" -ForegroundColor Green
