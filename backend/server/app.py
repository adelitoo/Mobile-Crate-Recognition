from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
from ultralytics import YOLO

app = Flask(__name__)
CORS(app, expose_headers=['Crate-Count', 'Keg-Count'])  # Expose custom headers

# Load YOLO model
model_path = "../runs/detect/train3/weights/best.pt" 
model = YOLO(model_path)

# Ensure upload and output directories exist
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), "..", "uploads")
OUTPUT_FOLDER = os.path.join(os.path.dirname(__file__), "..", "outputs")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

def get_latest_prediction_folder(output_folder):
    # Get all subdirectories in the 'predict' folder
    subdirs = [d for d in os.listdir(output_folder) if os.path.isdir(os.path.join(output_folder, d)) and d.startswith('predict')]
    
    # Sort the directories and get the latest one (based on numeric value or timestamp)
    subdirs.sort(reverse=True)  # Sort in reverse order to get the latest one
    if subdirs:
        return os.path.join(output_folder, subdirs[0])
    return None

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'image' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Ensure the file has a valid extension
    allowed_extensions = {'jpg', 'jpeg', 'png', 'bmp', 'gif'}
    if not file.filename.split('.')[-1].lower() in allowed_extensions:
        return jsonify({'error': 'Invalid file type'}), 400

    # Save uploaded image
    image_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(image_path)

    try:
        # Process image with YOLO
        results = model.predict(image_path, save=True, project=OUTPUT_FOLDER)

        crate_count = 0
        keg_count = 0

        print("Detected classes:")

        # Count detected crates and kegs
        # counts = {'crate': 0, 'keg': 0}
        for result in results:
            for box in result.boxes:
                cls_id = int(box.cls)
                cls_name = model.names[cls_id]
                print(f"Detected class: {cls_name}")
                
                # Check if class name contains keywords for categorization
                if 'rectangle' in cls_name.lower() or 'cp' in cls_name.lower():
                    crate_count += 1
                elif 'keg' in cls_name.lower():
                    keg_count += 1
        print(f"Counted crates: {crate_count}, kegs: {keg_count}")


        # Get the processed image path (existing code)...
        # Get the most recent 'predict' folder
        latest_predict_folder = get_latest_prediction_folder(OUTPUT_FOLDER)
        if not latest_predict_folder:
            return jsonify({'error': 'Processing failed, no prediction folder found'}), 500

        # Check if the processed image exists in the latest prediction folder
        processed_image_path = os.path.join(latest_predict_folder, file.filename)

        if not os.path.exists(processed_image_path):
            return jsonify({'error': 'Processing failed, image not found in prediction folder'}), 500


        # Create response with the processed image
        response = send_file(processed_image_path, mimetype='image/jpeg')
        # Add detection counts to headers
        response.headers['Crate-Count'] = str(crate_count)
        response.headers['Keg-Count'] = str(keg_count)
        print(f"Response headers: ${response.headers}");
        print(f"Crate count: ${response.headers['crate-count']}");
        print(f"Keg count: ${response.headers['keg-count']}");
        return response

    except Exception as e:
        print(f"Error during processing: {e}")
        return jsonify({'error': 'Error processing the image'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
