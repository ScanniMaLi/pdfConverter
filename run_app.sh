#!/usr/bin/env bash
# run_app.sh - POSIX wrapper to run the Flask app using the venv python if available
# Usage: ./run_app.sh [port]

set -euo pipefail

PORT=${1:-5000}

# Prefer venv python
if [ -x "./venv/bin/python" ]; then
  PY="./venv/bin/python"
elif [ -x "./python" ]; then
  PY="./python"
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "No Python interpreter found. Run ./setup_venv.sh or install Python." >&2
  exit 1
fi

echo "Starting app with: $PY (port $PORT)"

# Export PORT for the python process, then run a small snippet that imports app and starts it
PORT=$PORT "$PY" - <<'PY'
import os
from app import app
port = int(os.environ.get('PORT', '5000'))
app.run(host='127.0.0.1', port=port, debug=True)
PY
