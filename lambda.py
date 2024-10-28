import boto3
from botocore.exceptions import ClientError

def send_sns_notification(file_name):
    TOPIC_ARN = "arn:aws:sns:us-east-1:535998477374:UploadTriggerNotification"  # Your SNS topic ARN

    SUBJECT = "File Uploaded to S3!"
    MESSAGE = (
        f"An image file '{file_name}' was uploaded to the S3 bucket.\r\n"
        "This notification was sent via SNS."
    )
    
    # Create a new SNS resource
    client = boto3.client('sns', region_name='us-east-1')

    # Try to publish the message to SNS
    try:
        response = client.publish(
            TopicArn=TOPIC_ARN,
            Message=MESSAGE,
            Subject=SUBJECT
        )
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        print("Notification sent! Message ID:"),
        print(response['MessageId'])

def lambda_handler(event, context):
    # Extract the file name from the event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    file_name = event['Records'][0]['s3']['object']['key']
    
    # Log bucket and file details (optional for debugging)
    print(f"Bucket: {bucket_name}, File: {file_name}")
    
    # Send SNS notification with file name
    send_sns_notification(file_name)