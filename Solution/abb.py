# import module
from datetime import datetime
  
# get current date and time
current_datetime = datetime.now()
# print("Current date & time :", current_datetime)
  
# convert datetime obj to string
str_current_datetime = str(current_datetime)
  
# create a file object along with extension
file_name = str_current_datetime+".txt"
file = open(file_name, 'w')
  
# print("File created :", file.name)
file.close()

import boto3

# Create an S3 access object
s3 = boto3.client("s3")

s3.upload_file(
    Filename="./task.txt",
    Bucket="qa-tasks",
    Key=None,
)
# s3 = boto3.client('s3')
# with open("FILE_NAME", "rb") as f:
#     s3.upload_fileobj(f, "BUCKET_NAME", "OBJECT_NAME")