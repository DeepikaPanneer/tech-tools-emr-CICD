# import libraries
import boto3
import json
import time
import datetime

# define windows error/warning emails
def windows_warning():
    # create ses client
    ses = boto3.client('ses', region_name = 'us-east-1')

    # set email headers
    email_from = 'AWSAdmin@urban.org'
    email_to = 'AWSAdmin@urban.org'
    email_subject = 'Cloud Computing - Windows Instances Warning'

    # set email body
    body = """<p>
    The last Windows Cloud Computing instance has just been started.
    Consider creating another instance for use.
    </p>"""

    ses.send_email(
        Source = email_from,
        Destination={
            'ToAddresses': [
                email_to
            ],
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

def windows_error(submission):
    # create ses client
    ses = boto3.client('ses', region_name = 'us-east-1')

    # set email headers
    email_from = 'AWSAdmin@urban.org'
    email_to = submission['email']
    email_copy = ['AWSAdmin@urban.org'] 
    email_subject = 'Your Windows Cloud Computing Environment'

    # set email body
    body = """<p>
    All Windows instances are currently in use.</br>
    Consider using a Linux instance instead.</br>
    Contact
    <a href="mailto:AWSAdmin@urban.org?subject=Cloud Computing Environment">the AWS Admin team.</a>
    for further assistance.</br>
    </p>"""

    ses.send_email(
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

# define windows spinup process
def spinup_windows(submission):
    # create ec2 resource
    ec2 = boto3.resource('ec2', region_name = 'us-east-1')

    # set windows instances
    WINDOWS_INSTANCES = [
        'i-00f81667c5388a1b4',
        'i-059abf4a32cafe17f',
        'i-0b84951dce0f42c18'
        ]

    # get info from submission form
    INSTANCE_TYPE = submission['instance_type']
    NAME = 'elastic-analytics-{}'.format(submission['email'].replace('@urban.org', ''))
    PROJECT_CODE = submission['project']
    if PROJECT_CODE == 'DI': # catch old form
        PROJECT_CODE = '920000-8201-005-00001'

    # get available instances
    instances = ec2.instances.filter(
        Filters = [
                {'Name': 'instance-state-name',
                 'Values' : ['stopped']
                 },
                {'Name': 'instance-id',
                 'Values': WINDOWS_INSTANCES
                 }
                ]
        )

    AVAILABLE_INSTANCES = [instance.id for instance in instances]

    # determine if instances are available
    if len(AVAILABLE_INSTANCES) == 0:
        # send error email
        windows_error(submission)
    else:
        # start SAS3 
        # sas3 = ec2.Instance("i-0ce1e084ff6d5588c")
        current_time = datetime.datetime.utcnow().time()
        valid_time = current_time >= datetime.time(11, 0, 0) and current_time <= datetime.time(23, 59, 0)
        # if sas3.state["Name"] != "running" and valid_time:
        #     sas3.start()
        # get instance resource
        instance = ec2.Instance(AVAILABLE_INSTANCES[0])
        # update instance name
        instance.create_tags(
            Tags = [
                {
                    'Key': 'Name',
                    'Value': NAME
                },
                {
                    'Key':'Project-Code',
                    'Value':PROJECT_CODE
                }
            ]
        )
        # update instance type
        instance.modify_attribute(
            InstanceType = {
                'Value' : INSTANCE_TYPE
                }
        )
        # start instance
        instance.start()

        # send warning email
        if len(AVAILABLE_INSTANCES) == 1:
            windows_warning()


# helper function to get parameters in SSM 
def get_resources_from_ssm(ssm_details):
  results = ssm_details['Parameters']
  resources = [result for result in results]
  next_token = ssm_details.get('NextToken', None)
  return resources, next_token


# helper function to get user's public key from SSM for SSH access  
def get_public_key(user): 
    ssm = boto3.client('ssm', region_name='us-east-1')
    next_token = ' '
    resources = []
    while next_token is not None:
        ssm_details = ssm.describe_parameters(MaxResults=50, NextToken=next_token)
        current_batch, next_token = get_resources_from_ssm(ssm_details)
        resources += current_batch
    keys = [r['Name'] for r in resources]
    try: 
        if f'{user}-publickey' in keys: 
            print(f"Adding SSH access: {user}-publickey")
            return ssm.get_parameter(Name=f'{user}-publickey')['Parameter']['Value']
        else: 
            return None 
    except: 
        return None 
    

# define linux spinup process
def spinup_linux(submission):
        # set instance defaults
        REGION_NAME = 'us-east-1'
        SECURITY_GROUP_IDS = ['sg-417b5434']
        IMAGE_ID = 'ami-05f408238af346b4f' 
        SUBNET_ID = 'subnet-ff8e42d5'

        # get fields from shiny submission
        INSTANCE_TYPE = submission['instance_type']
        VOLUME_SIZE = int(submission['storage'])
        NAME = 'elastic-analytics-{}'.format(submission['email'].replace('@urban.org', ''))
        PROJECT_CODE = submission['project']
        if PROJECT_CODE == 'DI': # catch old form
            PROJECT_CODE = '920000-8201-005-00001'
        PROJECT_NAME = 'DATA TECH-OH'
        KEY_PAIR = 'aws-admin'
        IAM_ROLE = 'ElasticAnalytics'
        OS = submission['os']
        if 'spot_instance' in submission.keys():
            SPOT_INSTANCE = submission['spot_instance']
        else:
            SPOT_INSTANCE = False

        # set instance tags
        TAG_SPECIFICATIONS = [
            {
                'ResourceType':'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': NAME
                    },
                    {
                        'Key': 'Center',
                        'Value': 'Tech'
                    },
                    {
                        'Key':'Project-Name',
                        'Value': PROJECT_NAME
                    },
                    {
                        'Key':'Project-Code',
                        'Value':PROJECT_CODE
                    }, 
                    {
                        'Key': 'DS-New-Access', 
                        'Value': 'True'
                    }
                ]
            },
            {
                'ResourceType':'volume',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': NAME
                    },
                    {
                        'Key': 'Center',
                        'Value': 'IT'
                    },
                    {
                        'Key':'Project-Name',
                        'Value': PROJECT_NAME
                    },
                    {
                        'Key':'Project-Code',
                        'Value':PROJECT_CODE
                    }
                ]
            }
        ]

        # set ebs storage
        BLOCK_DEVICE_MAPPINGS = [
            {
                'DeviceName' : '/dev/xvda',
                'Ebs': {
                    'VolumeSize': VOLUME_SIZE
                }
            }
        ]

        # set iam role
        IAM_INSTANCE_PROFILE = {
            'Name': IAM_ROLE
            }

        # set instance market
        if SPOT_INSTANCE:
            INSTANCE_MARKET_OPTIONS = {
                'MarketType':'spot'
            }
        else:
            INSTANCE_MARKET_OPTIONS = {}

        # get bootstrap script
        s3 = boto3.client('s3', region_name = 'us-east-1')
        USER_DATA = s3.get_object(Bucket = 'ui-elastic-analytics',
                                  Key = 'os/Linux-2023.sh')['Body'].read().decode()
        
        # pass public key for SSH access into bootstrap script       
        user = submission['email'].replace('@urban.org', '').lower()
        user_public_key = get_public_key(user)    
        aws_admin_public_key = get_public_key('techtools-aws-admin')
        FORMATTED_USER_DATA = USER_DATA.format(
            USERNAME1 = user,
            PUBLICKEY1 = user_public_key, 
            USERNAME2 = 'aws-admin', 
            PUBLICKEY2 = aws_admin_public_key
        )

        # create instance
        ec2 = boto3.resource('ec2', region_name = REGION_NAME)
        instances = ec2.create_instances(ImageId = IMAGE_ID,
                                         InstanceType = INSTANCE_TYPE,
                                         SecurityGroupIds = SECURITY_GROUP_IDS,
                                         TagSpecifications = TAG_SPECIFICATIONS,
                                         KeyName = KEY_PAIR,
                                         MinCount = 1,
                                         MaxCount = 1,
                                         UserData = FORMATTED_USER_DATA,
                                         SubnetId = SUBNET_ID,
                                         IamInstanceProfile = IAM_INSTANCE_PROFILE,
                                         BlockDeviceMappings = BLOCK_DEVICE_MAPPINGS,
                                         InstanceMarketOptions = INSTANCE_MARKET_OPTIONS)

# main lambda function
def lambda_handler(event, context):
    print(event)
    # create s3 resources
    s3 = boto3.client('s3', region_name = 'us-east-1')
    # get s3 bucket and object key from trigger
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # read submission data
    obj = s3.get_object(Bucket = bucket, Key = key)
    submission = json.load(obj['Body'])
    print(submission)

    # get operating system from shiny submission
    OS = submission['os']

    # create instance by OS
    if OS == 'Windows':
        spinup_windows(submission)
    else:
        spinup_linux(submission)
