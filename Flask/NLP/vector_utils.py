import fasttext
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# FastText 모델 로드
en_model = fasttext.load_model('cc.en.300.bin')  # 영어 모델 로드

def get_vector(word):
    """
    FastText 모델을 사용하여 단어를 벡터화하는 함수.
    """
    return en_model.get_word_vector(word)

def calculate_similarity(input_vector, word_vectors, word_list, top_k=3):
    """
    코사인 유사도를 계산하고 상위 k개의 단어를 반환.
    """
    similarities = cosine_similarity([input_vector], word_vectors)
    top_indices = np.argsort(similarities[0])[::-1][:top_k]
    related_words = [(word_list[idx], similarities[0][idx]) for idx in top_indices]
    return related_words
