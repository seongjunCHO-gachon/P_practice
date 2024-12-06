import tensorflow as tf
from keras.api.applications import EfficientNetB0
from keras.api.applications.efficientnet import decode_predictions

def load_model():
    model = EfficientNetB0(weights='imagenet', include_top=True)
    return model

def predict_batch(model, images):
    predictions = model.predict(images)
    decoded_predictions = [decode_predictions(pred, top=1)[0][0][1] for pred in predictions]
    return decoded_predictions
