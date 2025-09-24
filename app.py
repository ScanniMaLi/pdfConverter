from flask import Flask, render_template, request, send_file, jsonify
from werkzeug.utils import secure_filename
from PIL import Image
import os
import PyPDF2
from io import BytesIO
import zipfile

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

def convert_image_to_pdf(input_path, output_path):
    try:
        image = Image.open(input_path)
        # Convert to RGB if necessary (for PNG with transparency)
        if image.mode in ('RGBA', 'LA') or (image.mode == 'P' and 'transparency' in image.info):
            background = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            background.paste(image, mask=image.split()[-1])
            image = background
        elif image.mode != 'RGB':
            image = image.convert('RGB')
        image.save(output_path, 'PDF', resolution=100.0)
        return True
    except Exception as e:
        print(f"Error converting image to PDF: {e}")
        return False

# Ensure upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return 'No file uploaded', 400
    
    file = request.files['file']
    if file.filename == '':
        return 'No file selected', 400

    if file:
        try:
            filename = secure_filename(file.filename)
            input_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(input_path)
            
            # Get file extension
            file_ext = os.path.splitext(filename)[1].lower()
            
            # Generate PDF filename
            pdf_filename = os.path.splitext(filename)[0] + '.pdf'
            output_path = os.path.join(app.config['UPLOAD_FOLDER'], pdf_filename)
            
            # Handle image files
            if file_ext in ['.png', '.jpg', '.jpeg']:
                if convert_image_to_pdf(input_path, output_path):
                    try:
                        return_data = send_file(output_path, as_attachment=True, download_name=pdf_filename)
                        # Clean up files after sending
                        os.remove(input_path)  # Remove original file
                        os.remove(output_path)  # Remove converted PDF
                        return return_data
                    except Exception as e:
                        print(f"Error cleaning up files: {e}")
                        return send_file(output_path, as_attachment=True, download_name=pdf_filename)
                else:
                    if os.path.exists(input_path):
                        os.remove(input_path)
                    return 'Error converting image to PDF', 500
                    
            # TODO: Add conversion logic for other file types
            return 'File uploaded successfully'
        except Exception as e:
            # Clean up any files if there's an error
            if os.path.exists(input_path):
                os.remove(input_path)
            if os.path.exists(output_path):
                os.remove(output_path)
            return f'An error occurred: {str(e)}', 500

@app.route('/split_pdf', methods=['POST'])
def split_pdf():
    if 'file' not in request.files:
        return 'No file uploaded', 400
    
    file = request.files['file']
    if file.filename == '':
        return 'No file selected', 400

    if file:
        try:
            # Read the PDF file
            pdf_reader = PyPDF2.PdfReader(file)
            total_pages = len(pdf_reader.pages)
            
            # Create a BytesIO object to store the ZIP file
            zip_buffer = BytesIO()
            
            # Create a ZIP file
            with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
                split_type = request.form.get('split_type', 'all')
                
                if split_type == 'range':
                    # Handle page ranges
                    ranges = request.form.get('page_range', '').strip()
                    if not ranges:
                        return 'No page ranges specified', 400
                    
                    # Parse the ranges
                    for range_str in ranges.split(','):
                        try:
                            start, end = map(int, range_str.strip().split('-'))
                            if 1 <= start <= end <= total_pages:
                                # Create a new PDF for this range
                                output = PyPDF2.PdfWriter()
                                for page_num in range(start - 1, end):
                                    output.add_page(pdf_reader.pages[page_num])
                                
                                # Save the PDF to a temporary buffer
                                temp_buffer = BytesIO()
                                output.write(temp_buffer)
                                temp_buffer.seek(0)
                                
                                # Add to ZIP
                                zip_file.writestr(f'pages_{start}_to_{end}.pdf', temp_buffer.getvalue())
                        except ValueError:
                            continue
                else:
                    # Split into individual pages
                    for page_num in range(total_pages):
                        output = PyPDF2.PdfWriter()
                        output.add_page(pdf_reader.pages[page_num])
                        
                        # Save the PDF to a temporary buffer
                        temp_buffer = BytesIO()
                        output.write(temp_buffer)
                        temp_buffer.seek(0)
                        
                        # Add to ZIP
                        zip_file.writestr(f'page_{page_num + 1}.pdf', temp_buffer.getvalue())
            
            zip_buffer.seek(0)
            return send_file(
                zip_buffer,
                mimetype='application/zip',
                as_attachment=True,
                download_name='split_pdfs.zip'
            )
            
        except Exception as e:
            return f'Error processing PDF: {str(e)}', 500

@app.route('/merge_pdfs', methods=['POST'])
def merge_pdfs():
    if 'files[]' not in request.files:
        return 'No files uploaded', 400
    
    files = request.files.getlist('files[]')
    if not files or files[0].filename == '':
        return 'No files selected', 400

    try:
        merger = PyPDF2.PdfMerger()
        
        # Merge all PDFs
        for file in files:
            merger.append(file)
        
        # Save to BytesIO buffer
        output_buffer = BytesIO()
        merger.write(output_buffer)
        output_buffer.seek(0)
        
        return send_file(
            output_buffer,
            mimetype='application/pdf',
            as_attachment=True,
            download_name='merged.pdf'
        )
        
    except Exception as e:
        return f'Error merging PDFs: {str(e)}', 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)