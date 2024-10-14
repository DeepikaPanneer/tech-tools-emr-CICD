# import json
# import pytest
# import boto3
# from moto import mock_emr

# from hello_world import app


# @pytest.fixture()
# def s3_event():
#     """Generates an S3 event."""

#     return {
#         "Records": [
#             {
#                 "eventVersion": "2.1",
#                 "eventSource": "aws:s3",
#                 "awsRegion": "us-east-2",
#                 "eventTime": "2024-10-12T12:34:56.789Z",
#                 "eventName": "ObjectCreated:Put",
#                 "userIdentity": {
#                     "principalId": "EXAMPLE"
#                 },
#                 "requestParameters": {
#                     "sourceIPAddress": "127.0.0.1"
#                 },
#                 "responseElements": {
#                     "x-amz-request-id": "EXAMPLE123456789",
#                     "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
#                 },
#                 "s3": {
#                     "s3SchemaVersion": "1.0",
#                     "configurationId": "testConfigRule",
#                     "bucket": {
#                         "name": "example-bucket",
#                         "arn": "arn:aws:s3:::example-bucket"
#                     },
#                     "object": {
#                         "key": "test/key.txt",
#                         "size": 1024,
#                         "eTag": "0123456789abcdef0123456789abcdef",
#                         "sequencer": "0A1B2C3D4E5F678901"
#                     }
#                 }
#             }
#         ]
#     }


# @mock_emr
# def test_lambda_handler(s3_event):
#     # Mock Boto3 EMR client
#     region = 'us-east-2'
#     emr_client = boto3.client('emr', region_name=region)
    
#     # Run the Lambda handler with the mocked S3 event
#     response = app.lambda_handler(s3_event, "")
#     data = response['body']

#     # Verify that the Lambda function returns a success status code
#     assert response["statusCode"] == 200
#     assert "Cluster ID" in data

#     # Verify that an EMR cluster was created
#     clusters = emr_client.list_clusters()
#     assert len(clusters['Clusters']) > 0
#     assert clusters['Clusters'][0]['Name'] == 'Rstudio-Sparklyr'
