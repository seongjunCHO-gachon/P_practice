from flask import Blueprint, request, jsonify
from .utils.dynamodb import save_predictions_to_dynamodb
from .utils.preprocess import process_folder
from .config import Config
import shutil

api_blueprint = Blueprint('api', __name__)

@api_blueprint.route('/predict', methods=['POST'])
def predict():
    data = request.json
    uid = data.get('uid')
    if not uid:
        return jsonify({"status": "error", "message": "UID is required."}), 400

    image_folder = Config.IMAGE_FOLDER
    process_folder(uid, image_folder)
    shutil.rmtree(image_folder)

    return jsonify({"status": "success", "message": "Processing completed."})
