import boto3
from ..config import Config

dynamodb = boto3.resource('dynamodb', region_name=Config.DYNAMODB_REGION)
table = dynamodb.Table(Config.DYNAMODB_TABLE)

def save_predictions_to_dynamodb(uid, title, predictions):
    table.put_item(
        Item={
            'uid': uid,
            'title': title,
            'predictions': predictions
        }
    )
