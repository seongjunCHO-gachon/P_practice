import boto3

def fetch_words_from_dynamodb(table_name):
    """
    DynamoDB에서 단어 리스트를 가져오는 함수.
    """
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(table_name)

    try:
        response = table.scan()
        items = response.get('Items', [])
        word_list = [item['category'] for item in items]
        return word_list
    except Exception as e:
        print(f"DynamoDB에서 데이터를 가져오는 중 오류 발생: {e}")
        return []
