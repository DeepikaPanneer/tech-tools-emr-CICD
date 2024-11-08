# import libraries
import boto3
import datetime
import json

# set on-demand pricing
prices = {
'Linux/UNIX':
    {
    "c5.xlarge" : 0.17,
    "c5.2xlarge" : 0.34,
    "c5.4xlarge" : 0.68,
    "c5.9xlarge" : 1.53,
    "c5.18xlarge" : 3.06,
    "x1e.8xlarge" : 6.67,
    "x1e.16xlarge" : 13.34,
    "r5.2xlarge" : 0.50,
    "r5.4xlarge" : 1.01,
    "r6g.4xlarge" : 0.81,
    "r5.8xlarge" : 2.02,
    "r5.12xlarge" : 3.03,
    "spot_factor" : 0.40
    },
'Windows':
    {
    "r4.16xlarge" : 7.20,
    "c5.xlarge" : 0.36,
    "c5.2xlarge" : 0.71,
    "c5.4xlarge" : 1.42,
    "c5.9xlarge" : 3.19,
    "c5.18xlarge" : 6.38,
    "x1.16xlarge" : 9.61,
    "x1.32xlarge" : 19.23,
    "x1e.8xlarge" : 8.144,
    "x1e.16xlarge" : 16.288,
    "x1e.32xlarge" : 32.576,
    "r5.2xlarge" : 0.87,
    "r5.4xlarge" : 1.74,
    "r5.8xlarge" : 3.45,
    "r5.12xlarge" : 5.23,
    "spot_factor" : 0.60
    }
}

# set windows instances mapping
WINDOWS_INSTANCES = {
    'i-00f81667c5388a1b4':'UrbanAnalytics1',
    'i-059abf4a32cafe17f':'UrbanAnalytics2',
    'i-0b84951dce0f42c18':'UrbanAnalytics3'
    }

PROJECT_CODE = '920000-8201-005-00001'

# create aws resources
ec2 = boto3.resource('ec2', region_name = 'us-east-1')
s3 = boto3.client('s3')
ses = boto3.client('ses', region_name = 'us-east-1')

def lambda_handler(event, context):
    # get s3 bucket and object key from trigger
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # read termination data from s3
    obj = s3.get_object(Bucket=bucket, Key=key)
    termination = json.load(obj['Body'])

    # get termination input
    instance_id = termination['instance_id']
    user_email = termination['email']

    # get list of running instances
    instances = ec2.instances.filter(
        Filters = [
                {'Name': 'instance-state-name',
                 'Values' : ['running', 'pending']
                 },
                {'Name': 'instance-id',
                 'Values': [instance_id]
                 },
                {'Name': 'tag:Name',
                 'Values': ['elastic-analytics*']}
                ]
        )

    # set email headers
    email_from = 'AWSAdmin@urban.org'
    email_to = user_email
    email_copy = ['AWSAdmin@urban.org']
    email_subject = 'Your Cloud Computing Termination Request'

    # attempt to terminate and set email body
    if len([instance.id for instance in instances]) > 0:
        # get instance information
        instance = ec2.Instance(instance_id)
        instance_type = instance.instance_type
        if instance.platform == 'windows':
            instance_platform = 'Windows'
        else:
            instance_platform = 'Linux/UNIX'
        # get storage information
        storage = 0
        for volume in instance.volumes.all():
            storage += volume.size
        # get uptime
        running_time = (datetime.datetime.now(datetime.timezone.utc) - instance.launch_time).total_seconds()
        running_hours = int(running_time // 3600)
        running_minutes = int((running_time % 3600) / 60)
        # calculate total cost for spot
        if type(instance.spot_instance_request_id) == str:
            client = boto3.client('ec2', region_name = 'us-east-1')
            response = client.describe_spot_price_history(
                AvailabilityZone = 'us-east-1a',
                InstanceTypes = [instance.instance_type],
                ProductDescriptions = [instance_platform])
            instance_cost = float(response['SpotPriceHistory'][0]['SpotPrice']) * (running_time / 3600.0)
        # calculate total cost for on-demand
        else:
            instance_cost = prices[instance_platform][instance_type] * (running_time / 3600.0)
        # calculate storage and total cost
        storage_cost = (0.10 * storage) / (24 * 30)
        cost = instance_cost + storage_cost
        # terminate instance
        if instance_platform == 'Windows':
            #
            # sas3
            windows_running = list(ec2.instances.filter(
                Filters = [
                    {'Name': 'instance-state-name',
                    'Values' : ['running', 'pending']
                    },
                    {'Name': 'platform',
                    'Values': ['Windows', 'windows']
                    },
                    {'Name': 'tag:Name',
                    'Values': ['elastic-analytics*']}
                ]
            ))
            # windows_count = len(windows_running)
            # if windows_count == 1 and windows_running[0].id == instance_id:
            #     sas3 = ec2.Instance("i-0ce1e084ff6d5588c")
            #     if sas3.state["Name"] == "running":
            #         sas3.stop()
            # instance
            instance = ec2.Instance(instance_id)
            instance.create_tags(
                Tags = [
                    {
                        'Key': 'Name',
                        'Value': WINDOWS_INSTANCES[instance_id]
                    },
                    {
                        'Key':'Project-Code',
                        'Value':PROJECT_CODE
                    }
                ]
            )
            instance.stop()
        else:
            ec2.instances.terminate(InstanceIds=[instance_id])
        email_subject = 'Cloud Computing Instance Terminated'
        body = """<p>
        Your {instance_type} instance with ID {instance_id} has been successfully terminated.<br/>

        This instance was running for a total of {running_hours} hours and
        {running_minutes} minutes at a cost of approximately ${cost}.<br/><br/>

        Note that for Spot instances, this cost is an approximation based on
        the current Spot price, which may have fluctuated during usage.<br/><br/>

        Questions? Contact
        <a href="mailto:AWSAdmin@urban.org?subject=Cloud Computing Environment">the AWS Admin team.</a>
        </p>""".format(instance_type = instance_type,
                       instance_id = instance_id,
                       running_hours = running_hours,
                       running_minutes = running_minutes,
                       cost = round(cost, 2)
                       )
    else:
        email_subject = 'FAILED: Cloud Computing Termination Request'
        body = """<p>
        Your instance {0} was not found, or has already been terminated.<br/>

        Please double-check your instance-id if you believe this message is in error.<br/>

        Questions? Contact
        <a href="mailto:AWSAdmin@urban.org?subject=Cloud Computing Environment">the AWS Admin team.</a>
        </p>""".format(instance_id)

    # send confirmation email
    response = ses.send_email(
        Source = email_from,
        Destination={
            'ToAddresses': [
                email_to
            ],
            'CcAddresses': email_copy
        },
        Message={
        'Body': {
            'Html': {
                'Charset': 'UTF-8',
                'Data': body
            }
        },
        'Subject': {
            'Charset': 'UTF-8',
            'Data': email_subject
        }
    }
    )
