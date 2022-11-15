from datetime import datetime
def upload_image(image):
    # import module
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

    # Upload to S3 with the put_object call
    client = boto3.client('s3', region_name='us-east-1')
    bucket = 'qa-tasks'
    # The key name is the full path within your bucket to the object.
    s3keyname = open(file_name, 'w')
    # Specify the MIME type manually -- S3 does not guess that for you unless you use the web UI
    # and this should be specified if you need S3 to serve it as content.
    #contenttype = 'image/txt'
    try:
        uploadfile = client.put_object(
            Bucket=bucket,
            Body=file,
            Key=s3keyname,
            #ContentType=contenttype,
            # IMPORTANT -- the ACL setting determines the security settings for your object
            # This can be 'public-read', 'private' or specified to other IAM targets.
            #ACL='public-read'
        )
    except Exception:
        print("There has been an error in uploading the image to S3")