from flask import Blueprint, request, jsonify
from ..utils.dynamodb import register_user, get_user
from werkzeug.security import check_password_hash

auth_blueprint = Blueprint('auth', __name__)

@auth_blueprint.route('/register', methods=['POST'])
def register():
    data = request.json
    if not data:
        return jsonify({"status": "error", "message": "잘못된 입력입니다."}), 400

    id = data.get('id')
    password = data.get('password')

    if not id or not password:
        return jsonify({"status": "error", "message": "id와 password가 필요합니다."}), 400

    existing_user = get_user(id)
    if existing_user:
        return jsonify({"status": "error", "message": "이미 존재하는 id입니다."}), 400

    register_user(id, password)
    return jsonify({"status": "success", "message": "회원가입 성공"}), 201

@auth_blueprint.route('/login', methods=['POST'])
def login():
    data = request.json
    if not data:
        return jsonify({"status": "error", "message": "잘못된 입력입니다."}), 400

    id = data.get('id')
    password = data.get('password')

    if not id or not password:
        return jsonify({"status": "error", "message": "id와 password가 필요합니다"}), 400

    try:
        user_data = get_user(id) 
        if not user_data:
            return jsonify({"status": "error", "message": "id가 존재하지 않습니다."}), 401

        # 비밀번호 확인
        if not check_password_hash(user_data['password'], password):
            return jsonify({"status": "error", "message": "잘못된 password입니다."}), 401

        return jsonify({"status": "success", "message": "Login 성공"}), 200
    except Exception as e:
        print(f"Error in login: {e}")
        return jsonify({"status": "error", "message": "서버 오류가 발생했습니다."}), 500
