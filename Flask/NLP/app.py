from flask import Flask, request, jsonify
from dynamodb_utils import fetch_words_from_dynamodb
from text_utils import correct_korean_text, translate_korean_to_english
from vector_utils import get_vector, calculate_similarity

# Flask 앱 초기화
app = Flask(__name__)

# DynamoDB 테이블 이름
TABLE_NAME = "categories"

# DynamoDB에서 단어 리스트 가져오기
word_list = fetch_words_from_dynamodb(TABLE_NAME)

@app.route('/find_related_words', methods=['POST'])
def api_find_related_words():
    """
    Flutter에서 POST 요청으로 단어를 받아 연관 단어를 반환하는 API
    """
    if not word_list:
        return jsonify({"error": "DynamoDB에서 데이터를 가져오지 못했습니다."}), 500

    # 요청 데이터에서 입력 단어 가져오기
    data = request.get_json()
    user_input = data.get('word', '')

    if not user_input:
        return jsonify({"error": "단어 입력이 필요합니다."}), 400

    # 1. 한국어 오타 교정
    corrected_input = correct_korean_text(user_input)
    # 2. 번역
    translated_word = translate_korean_to_english(corrected_input)
    # 3. 벡터화
    input_vector = get_vector(translated_word)
    word_vectors = [get_vector(word) for word in word_list]
    # 4. 유사도 계산
    related_words = calculate_similarity(input_vector, word_vectors, word_list)

    # 결과 반환
    response = [{"word": word, "similarity": similarity} for word, similarity in related_words]
    return jsonify({"related_words": response})

# Flask 앱 실행
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
