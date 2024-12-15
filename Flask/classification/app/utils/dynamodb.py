import boto3
import uuid
from werkzeug.security import generate_password_hash
from ..config import Config
from boto3.dynamodb.conditions import Attr


dynamodb = boto3.resource('dynamodb', region_name=Config.DYNAMODB_REGION)
photos_table = dynamodb.Table(Config.PHOTOS_TABLE)
user_table = dynamodb.Table(Config.USER_TABLE)

def save_predictions_to_dynamodb(uid, title, predictions):
    pid = str(uuid.uuid4())
    photos_table.put_item(
        Item={
            'pid': pid,
            'uid': uid,
            'title': title,
            'predictions': predictions
        }
    )

# 사용자 조회
def get_user(user_id):
    try:
        response = user_table.get_item(Key={'uid': user_id})
        return response.get('Item', None)
    except Exception as e:
        print(f"Error in get_user: {e}")
        raise

# 사용자 가입
def register_user(user_id, password):
    hashed_password = generate_password_hash(password)
    response = user_table.put_item(
        Item={
            'uid': user_id,
            'password': hashed_password
        },
        ConditionExpression="attribute_not_exists(uid)"  # 중복 방지
    )
    return response

# 검색
def search_photos_by_category(query, uid):
    try:
        response = photos_table.scan(
            FilterExpression="contains(predictions, :query) AND uid = :uid",
            ExpressionAttributeValues={
                ":query": query,
                ":uid": uid
            }
        )
        return response.get('Items', [])
    except Exception as e:
        print(f"검색 중 오류 발생: {e}")
        raise


def get_photo_predictions(title):
    """
    특정 사진의 이름을 기반으로 DynamoDB에서 predictions 필드를 가져오는 함수. 
    """
    if not title:
        return {"error": "Photo title is required"}, 400

    try:
        # title 필드로 스캔
        response = photos_table.scan(
            FilterExpression=Attr('title').eq(title)
        )
        items = response.get('Items', [])

        if not items:
            return {"message": "No photos found with the given title"}, 404

        # predictions 합치기
        predictions = []
        for item in items:
            predictions.extend(item.get('predictions', []))

        # 중복 제거 및 정렬
        unique_predictions = sorted(set(predictions)) if predictions else ["Unknown"]
        return unique_predictions, 200
    except Exception as e:
        print(f"Error in get_photo_predictions: {e}")
        return {"error": "Failed to fetch photo category"}, 500