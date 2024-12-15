import boto3
from botocore.exceptions import NoCredentialsError
from ..config import Config

s3_client = boto3.client('s3', region_name=Config.DYNAMODB_REGION)

def upload_to_s3(file_path, bucket_name, object_name=None):
    """
    Upload a file to an S3 bucket
    :param file_path: File to upload
    :param bucket_name: Bucket to upload to
    :param object_name: S3 object name. If not specified, file_path is used
    :return: True if file was uploaded, else False
    """
    if object_name is None:
        object_name = file_path.split("/")[-1]

    try:
        s3_client.upload_file(file_path, bucket_name, object_name)
        print(f"File {file_path} uploaded to {bucket_name}/{object_name}")
        return True
    except FileNotFoundError:
        print(f"The file {file_path} was not found.")
        return False
    except NoCredentialsError:
        print("Credentials not available.")
        return False
