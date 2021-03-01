import logging
import boto3
from botocore.exceptions import ClientError
import pdb
import os
import sys
import threading
import pandas as pd


class ProgressPercentage(object):

    def __init__(self, filename):
        self._filename = filename
        self._size = float(os.path.getsize(filename))
        self._seen_so_far = 0
        self._lock = threading.Lock()

    def __call__(self, bytes_amount):
        # To simplify, assume this is hooked up to a single filename
        with self._lock:
            self._seen_so_far += bytes_amount
            percentage = (self._seen_so_far / self._size) * 100
            sys.stdout.write(
                "\r%s  %s / %s  (%.2f%%)" % (
                    self._filename, self._seen_so_far, self._size,
                    percentage))
            sys.stdout.flush()


def list_buckets():
    #
    # setting up configured profile on your machine.
    # You can ignore this step if you want use default AWS CLI profile.
    #
    # boto3.setup_default_session(profile_name='admin-analyticshut')
    #
    # Option 1: S3 client list of buckets with name and is creation date
    #
    s3 = boto3.client('s3')
    response = s3.list_buckets()['Buckets']
    for bucket in response:
        print('Bucket name: {}, Created on: {}'.format(
            bucket['Name'], bucket['CreationDate']))


def create_bucket(bucket_name, region=None):
    """Create an S3 bucket in a specified region

    If a region is not specified, the bucket is created in the S3 default
    region (us-east-1).

    :param bucket_name: Bucket to create
    :param region: String region to create bucket in, e.g., 'us-west-2'
    :return: True if bucket created, else False
    """

    # Create bucket
    try:
        if region is None:
            s3_client = boto3.client('s3')
            s3_client.create_bucket(Bucket=bucket_name)
        else:
            s3_client = boto3.client('s3', region_name=region)
            location = {'LocationConstraint': region}
            s3_client.create_bucket(Bucket=bucket_name,
                                    CreateBucketConfiguration=location)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')

    if create_bucket(bucket):

        try:
            response = s3_client.upload_file(file_name, bucket, object_name,
                                             Callback=ProgressPercentage(file_name))
        except ClientError as e:
            logging.error(e)
            return False
        return True


def download_file(s3_file_path, bucket, save_as=None):

    if save_as is None:
        save_as = s3_file_path
    s3 = boto3.client('s3')

    s3.download_file(bucket, s3_file_path, save_as,
                     Callback=ProgressPercentage(file_name))

    print('success')


def list_files_in_bucket(bucket_name):

    conn = boto3.client('s3')  # again assumes boto.cfg setup, assume AWS S3
    for key in conn.list_objects(Bucket=bucket_name)['Contents']:
        print(key['Key'])


def delete_file_in_bucket(bucket_name, filename):

    s3 = boto3.resource("s3")
    obj = s3.Object(bucket_name, filename)
    obj.delete()


def read_df_from_s3(historical_file_name, bucket):

    # define s3 client
    s3 = boto3.client('s3')
    # define file names

    # load historical data from s3
    data_obj = s3.get_object(Bucket=bucket, Key=historical_file_name)
    data = pd.read_csv(data_obj['Body'], low_memory=False)
    return data


if __name__ == '__main__':
    bucket = 'bruvio-training-data'
    name = 'workouts_bruvio_2020.csv'

    folder = '/Users/bruvio/Documents/Dropbox/Documenti/SpOrT/Triathlon/Training/bruvio_tri'
#
    # list_buckets()
    # create_bucket(bucket)
    # list_buckets()
    # print('aaa')
    # file_name = '/'.join((folder, name))
    # upload_file(file_name, bucket, object_name=name)
    # list_files_in_bucket(bucket)

    # delete_file_in_bucket(bucket, file_name)
    # list_files_in_bucket(bucket)
    # download_file(name, bucket)
