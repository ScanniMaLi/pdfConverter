#!/usr/bin/env bash
# setup_venv.sh
# Create a Python virtual environment (venv) in the project, upgrade pip, and install requirements.
# Usage (bash/zsh):
#   chmod +x setup_venv.sh
#   ./setup_venv.sh

set -euo pipefail

PYTHON_CMD=python
if ! command -v "$PYTHON_CMD" >/dev/null 2>&1; then
  if [ -f "./python" ]; then
    PYTHON_CMD="./python"
  elif [ -f "./python.exe" ]; then
    PYTHON_CMD="./python.exe"
  else
    echo "ERROR: Python not found in PATH and no local python binary present. Please install Python or place python.exe in project root." >&2
    exit 1
  fi
fi

echo "Using Python: $($PYTHON_CMD --version 2>&1)"

# Ensure uploads folder exists
if [ ! -d "uploads" ]; then
  echo "Creating uploads directory..."
  mkdir -p uploads
fi

if [ ! -d "venv" ]; then
  echo "Creating virtual environment in ./venv..."
  "$PYTHON_CMD" -m venv venv
  echo "Virtual environment created."
else
  echo "Virtual environment already exists at ./venv"
fi

# Use venv python
VENV_PY=venv/bin/python
if [ ! -f "$VENV_PY" ]; then
  # Might be Windows style within WSL etc.
  VENV_PY=venv/Scripts/python.exe
fi
if [ ! -f "$VENV_PY" ]; then
  echo "ERROR: Could not find python in venv at venv/bin/python or venv/Scripts/python.exe" >&2
  exit 1
fi

echo "Upgrading pip, setuptools, wheel..."
"$VENV_PY" -m pip install --upgrade pip setuptools wheel

if [ -f requirements.txt ]; then
  echo "Installing requirements from requirements.txt..."
  "$VENV_PY" -m pip install -r requirements.txt
else
  echo "No requirements.txt found. Skipping package installation."
fi

echo "\nSetup complete. Activate the environment with:" 
echo "  source venv/bin/activate" 
echo "Then run the app with: python app.py"
