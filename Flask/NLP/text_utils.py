from googletrans import Translator
import openai

# Google Translator 초기화
translator = Translator()

# OpenAI API 키 설정
openai.api_key = ""

def correct_korean_text(word):
    """
    OpenAI GPT API를 사용하여 한국어 단어의 맞춤법을 교정하는 함수.
    """
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "당신은 한국어 텍스트 교정 전문가입니다."},
                {"role": "user", "content": f"다음 단어를 맞춤법과 문법에 맞게 교정해 주세요: {word}"}
            ],
            temperature=0.2
        )
        corrected_word = response['choices'][0]['message']['content'].strip().strip('"')
        return corrected_word
    except Exception as e:
        print(f"오류 발생: {e}")
        return word  # 오류 발생 시 원래 단어 반환

def translate_korean_to_english(text):
    """
    Google Translator를 사용하여 한국어를 영어로 번역하는 함수.
    """
    try:
        translated_word = translator.translate(text, src='ko', dest='en').text
        return translated_word
    except Exception as e:
        print(f"번역 중 오류 발생: {e}")
        return text  # 오류 발생 시 원래 텍스트 반환
