import os
import cv2
import numpy as np
from keras.utils import img_to_array
from .dynamodb import save_predictions_to_dynamodb
from .s3 import upload_to_s3  # S3 업로드 함수 임포트
from ..models.efficientnet import load_model, predict_batch
from ..config import Config

model = load_model()

def prepare_image(image, target_size=(224, 224)):
    resized_image = cv2.resize(image, target_size)
    img_array = img_to_array(resized_image)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

def sliding_window(image, window_size, stride):
    h, w, _ = image.shape
    win_w, win_h = window_size
    for y in range(0, h - win_h + 1, stride):
        for x in range(0, w - win_w + 1, stride):
            yield (x, y, image[y:y+win_h, x:x+win_w])


def process_folder(uid, folder_path, window_size=(256, 256), stride=128):
    image_files = [os.path.join(folder_path, f) for f in os.listdir(folder_path)
                   if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.webp'))]

    for image_file in image_files:
        image = cv2.imread(image_file)
        if image is None:
            continue
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        windows = [prepare_image(window) for _, _, window in sliding_window(image, window_size, stride)
                   if window.shape[:2] == window_size]

        if windows:
            batch_predictions = predict_batch(model, np.vstack(windows))
            save_predictions_to_dynamodb(uid, os.path.basename(image_file), batch_predictions[:9])

        # S3 업로드
        upload_to_s3(image_file, Config.S3_BUCKET_NAME)
