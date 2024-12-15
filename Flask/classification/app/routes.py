from flask import Blueprint, request, jsonify, send_from_directory
from .utils.dynamodb import search_photos_by_category, get_photo_predictions
from .utils.preprocess import process_folder
from .config import Config
import shutil
import os

api_blueprint = Blueprint('api', __name__)

# 루트 경로 처리
@api_blueprint.route('/')
def index():
    return "Welcome to the Image Classification API!"  # 루트 경로에 대한 응답

# 예측 처리
@api_blueprint.route('/predict', methods=['POST'])
def predict():
    try:
        
        uid = request.form.get('uid')
        if not uid:
            return jsonify({"status": "error", "message": "UID is required."}), 400
        
        file = request.files.get('file')
        if not file or file.filename == '':
            return jsonify({"status": "error", "message": "File is required."}), 400
        

        image_folder = Config.IMAGE_FOLDER
        save_path = os.path.join(image_folder, uid)
        os.makedirs(save_path, exist_ok=True)


        file_path = os.path.join(save_path, file.filename)
        file.save(file_path)
        print(f"File saved to: {file_path}")

        if os.path.exists(save_path):
            process_folder(uid, save_path) 
        else:
            raise FileNotFoundError(f"Directory not found: {save_path}")
        

        return jsonify({"status": "success", "message": "Processing completed."})
    
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500
    
# 검색 API
@api_blueprint.route('/search', methods=['POST'])
def search():
    data = request.get_json()
    query = data.get('query')
    uid = data.get('uid')

    if not query or not uid:
        return jsonify({"status": "error", "message": "검색어(query)가 필요합니다."}), 400

    try:
        photos = search_photos_by_category(query, uid)
        return jsonify({"status": "success", "data": photos}) ,200 
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
    


@api_blueprint.route('/get_photo_category', methods=['POST'])
def get_photo_category():
    """
    특정 사진의 title를 기반으로 predictions를 반환하는 API
    """
    data = request.get_json()
    title = data.get('title')

    if not title:
        return jsonify({"error": "Title is required"}), 400


    response, status_code = get_photo_predictions(title)
    return jsonify(response), status_code
    