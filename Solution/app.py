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

client = boto3.client("s3")
s3keyname = str_current_datetime+".txt"

with open(file_name, "rb") as f:
    client.put_object(
        Bucket="qa-firstname-lastname-stormreply-platform-challenge",
        Body=f,
        Key=s3keyname
    )

with open(file_name, "rb") as f:
    client.put_object(
        Bucket="staging-firstname-lastname-stormreply-platform-challenge",
        Body=f,
        Key=s3keyname
    )