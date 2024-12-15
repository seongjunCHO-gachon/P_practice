import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0  # 수정된 부분
from tensorflow.keras.applications.efficientnet import decode_predictions  # 수정된 부분

def load_model():
    model = EfficientNetB0(weights='imagenet', include_top=True)
    return model

def predict_batch(model, images):
    try:
        predictions = model.predict(images)

        if len(predictions.shape) == 1:
            predictions = np.expand_dims(predictions, axis=0)

        decoded_predictions = [
            decode_predictions(predictions[i:i+1], top=1)[0][0][1] for i in range(predictions.shape[0])
        ]
        return decoded_predictions
    
    except Exception as e:
        print(f"Error during prediction: {e}")
        raise