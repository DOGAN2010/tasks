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
# with open("istiklal.txt") as f :
#     lines_new = f.readlines()
import boto3

client = boto3.client("s3")
# client.upload_file("/home/dogan/AWS-&_DEVOPS_FİLES/tüm_projeler/tasks/2022-11-12 21:58:18.498100.txt", "qa-tasks", "file")
s3keyname = str(open(file_name, 'rb'))
with open(file_name, "rb") as f:
    client.put_object(
        Bucket="qa-tasks",
        Body=f,
        Key=s3keyname
    )

 #s3 = boto3.client('s3')
# with open("FILE_NAME", "rb") as f:
#     s3.upload_fileobj(f, "BUCKET_NAME", "OBJECT_NAME")