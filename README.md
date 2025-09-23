# PDFConverter

A small Flask web app to convert images to PDF, split PDFs, and merge PDFs.

Features
- Convert PNG/JPG/JPEG images to PDF (handles transparency)
- Split PDFs by page ranges or into individual pages (downloads a ZIP of pages)
- Merge multiple PDFs into a single PDF
- Drag-and-drop and visual selection indicators in the UI
- Clear-selection buttons to remove chosen files before upload

Quick setup (Windows PowerShell)
1. Create a venv and install packages (helper script included):

   .\setup_venv.ps1

2. Activate and run (if you prefer manual activation):

   .\venv\Scripts\Activate.ps1
   python app.py

Or use the provided wrapper to run directly (no activation needed):

   .\run_app.ps1

Quick setup (macOS / Linux / WSL)
1. Make the script executable and run it:

   chmod +x setup_venv.sh
   ./setup_venv.sh

2. Activate and run:

   source venv/bin/activate
   python app.py

Run the server on a different port
- Edit `app.py` to change the default port or run with a small one-liner:

  # PowerShell example
  .\python.exe - <<'PY'
from app import app
app.run(port=5001, debug=True)
PY

Where files go
- Temporary uploads and generated PDFs are placed in the `uploads/` folder and are removed automatically after download.

Troubleshooting
- If the browser says "site can't be reached":
  - Make sure the app is running and shows "Running on http://127.0.0.1:5000" in the terminal.
  - Check that nothing else is listening on port 5000: `netstat -ano | Select-String ":5000"` (Windows)
  - If accessing from another machine, run the app with `host='0.0.0.0'` and ensure firewall allows the port.

# How to build
1. Navigate to the repo root directory
2. Activate venv 

   Windows:

   `
   ./venv/Scripts/activate
   `

   Linux:

   `
   source venv/bin/activate
   `
3. (Install pyinstaller inside venv)

   `
   pip install pyinstaller  
   `
4. Build .exe

   `
   pyinstaller --onefile app.py    
   `
