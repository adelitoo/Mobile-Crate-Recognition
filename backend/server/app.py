from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
from ultralytics import YOLO
import json
import mysql.connector
import math
import bcrypt

app = Flask(__name__)
CORS(app, expose_headers=['Item-Counts'])  

# MySQL connection setup
db_connection = mysql.connector.connect(
    host="127.0.0.1", 
    user="root",  
    password="test1234", 
    database="inventory_db" 
)
db_cursor = db_connection.cursor(dictionary=True)

# Load YOLO model
model_path = "../runs/detect/train3/weights/best.pt"
model = YOLO(model_path)

# Ensure upload and output directories exist
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), "..", "uploads")
OUTPUT_FOLDER = os.path.join(os.path.dirname(__file__), "..", "outputs")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

def get_item_prices():
    """Fetch item prices from the database."""
    query = "SELECT item_name, price FROM item_prices"
    db_cursor.execute(query)
    result = db_cursor.fetchall()
    item_prices = {item['item_name']: item['price'] for item in result}
    return item_prices

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
        
        # Track counts by specific type
        item_counts = {}
        
        for result in results:
            for box in result.boxes:
                cls_id = int(box.cls)
                cls_name = model.names[cls_id]
                
                # Format the display name (convert from model class name to user-friendly name)
                display_name = cls_name
                
                if "lightblue_cp_rectangle_perrier" in cls_name:
                    display_name = "Perrier"
                elif "lightblue_rectangle_sanclemente" in cls_name:
                    display_name = "San Clemente"
                elif "lightblue_rectangle_valser" in cls_name:
                    display_name = "Valser"
                elif "beer_keg_large" in cls_name:
                    display_name = "Beer keg"
                elif "beer_keg_medium" in cls_name:
                    display_name = "Beer keg"
                elif "beer_keg_small" in cls_name:
                    display_name = "Beer keg"
                elif "black_square_chopfabdoppelleu" in cls_name:
                    display_name = "Chopfab Doppelleu"
                elif "black_square_epti" in cls_name:
                    display_name = "Epti"
                elif "blue_rectangle_feldschlosschenbier" in cls_name:
                    display_name = "Feldschlösschen Bier"
                elif "blue_rectangle_gazzosi" in cls_name:
                    display_name = "Gazzose"
                elif "blue_rectangle_hackerpschorr" in cls_name:
                    display_name = "Hacker-Pschorr"
                elif "blue_square_henniez" in cls_name:
                    display_name = "Henniez"
                elif "brown_square_appenzellerbier" in cls_name:
                    display_name = "Appenzeller Bier"
                elif "green_square_pomdorsuisse" in cls_name:
                    display_name = "Pomd'or Suisse"
                elif "red_cp_rectangle_michel" in cls_name:
                    display_name = "Michel"
                elif "red_rectangle_cocacola" in cls_name:
                    display_name = "Coca-Cola"
                elif "red_rectangle_noname" in cls_name:
                    display_name = "Unknown red crate"
                elif "red_square_drinks" in cls_name:
                    display_name = "Drinks"
                elif "red_square_rivella" in cls_name:
                    display_name = "Rivella"
                elif "water_bottle_large" in cls_name:
                    display_name = "Water bottle"
                elif "water_bottle_small" in cls_name:
                    display_name = "Water bottle"
                elif "yellow_rectangle_schweppes" in cls_name:
                    display_name = "Schweppes"
                elif "yellow_square_acquapanna" in cls_name:
                    display_name = "Acqua Panna"

                # Increment the count for this type
                if display_name in item_counts:
                    item_counts[display_name] += 1
                else:
                    item_counts[display_name] = 1
        
        print(f"Counted items by type: {item_counts}")
        
        # Get item prices from the database
        item_prices = get_item_prices()
        
        # Add prices to the item counts (we assume the display names match the item names in the database)
        item_counts_with_prices = {}
        for item, count in item_counts.items():
            price = item_prices.get(item, None)
            if price is not None:
                item_counts_with_prices[item] = {"count": count, "price": float(price)}
            else:
                item_counts_with_prices[item] = {"count": count, "price": "N/A"}
        
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
        
        # Convert the counts and prices dictionary to JSON and add it as a header
        response.headers['Item-Counts'] = json.dumps(item_counts_with_prices)
        print(f"Response: {response.headers['Item-Counts']}")
        
        return response
    except Exception as e:
        print(f"Error during processing: {e}")
        return jsonify({'error': 'Error processing the image'}), 500

@app.route('/clients', methods=['GET'])
def get_clients():
    try:
        query = "SELECT id, name, longitude, latitude FROM clients"
        db_cursor.execute(query)
        clients = db_cursor.fetchall()
        print(clients)
        return jsonify(clients), 200
    except Exception as e:
        print(f"Error fetching clients: {e}")
        return jsonify({'error': 'Failed to fetch clients'}), 500

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the distance between two points on Earth using the Haversine formula.
    Returns distance in kilometers.
    """
    R = 6371  # Earth's radius in kilometers
    
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Calculate differences
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    # Haversine formula
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

@app.route('/nearest_client', methods=['GET'])
def get_nearest_client():
    try:
        # Get user's current location from query parameters
        user_lat = float(request.args.get('lat'))
        user_lon = float(request.args.get('lon'))
        
        # Get all clients from the database
        query = "SELECT id, name, longitude, latitude FROM clients"
        db_cursor.execute(query)
        clients = db_cursor.fetchall()
        
        if not clients:
            return jsonify({'error': 'No clients found'}), 404
        
        # Find the nearest client
        nearest_client = None
        min_distance = float('inf')
        
        for client in clients:
            distance = calculate_distance(
                user_lat, user_lon,
                client['latitude'], client['longitude']
            )
            
            if distance < min_distance:
                min_distance = distance
                nearest_client = client
        
        if nearest_client:
            return jsonify({
                'id': nearest_client['id'],
                'name': nearest_client['name'],
                'distance': min_distance
            }), 200
        else:
            return jsonify({'error': 'Could not find nearest client'}), 404
            
    except ValueError:
        return jsonify({'error': 'Invalid latitude or longitude parameters'}), 400
    except Exception as e:
        print(f"Error finding nearest client: {e}")
        return jsonify({'error': 'Failed to find nearest client'}), 500

@app.route('/employees', methods=['GET'])
def get_employees():
    try:
        query = "SELECT username FROM employees"
        db_cursor.execute(query)
        employees = db_cursor.fetchall()
        return jsonify([emp['username'] for emp in employees]), 200
    except Exception as e:
        print(f"Error fetching employees: {e}")
        return jsonify({'error': 'Failed to fetch employees'}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            return jsonify({'error': 'Username and password are required'}), 400

        # Get employee's hashed password from database
        query = "SELECT password_hash FROM employees WHERE username = %s"
        db_cursor.execute(query, (username,))
        result = db_cursor.fetchone()

        if not result:
            return jsonify({'error': 'Invalid username or password'}), 401

        # Verify password
        hashed_password = result['password_hash']
        if bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8')):
            return jsonify({'message': 'Login successful'}), 200
        else:
            return jsonify({'error': 'Invalid username or password'}), 401

    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({'error': 'Login failed'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
