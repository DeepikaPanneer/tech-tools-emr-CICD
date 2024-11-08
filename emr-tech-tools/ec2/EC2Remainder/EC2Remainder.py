# import libraries
import boto3
import datetime

# create aws resources
ec2 = boto3.resource('ec2', region_name = 'us-east-1')
ses = boto3.client('ses', region_name = 'us-east-1')

# set on-demand pricing
prices = {
'Linux/UNIX':
    {
    "c5.large" : 0.085,
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
    },
'Windows':
    {
    "c5.large" : 0.177,
    "c5.xlarge" : 0.36,
    "c5.2xlarge" : 0.71,
    "c5.4xlarge" : 1.42,
    "c5.9xlarge" : 3.19,
    "c5.18xlarge" : 6.38,
    "x1e.8xlarge" : 8.14,
    "x1e.16xlarge" : 16.29,
    "r5.2xlarge" : 0.87,
    "r5.4xlarge" : 1.74,
    "r5.8xlarge" : 3.45,
    "r5.12xlarge" : 5.23,
    }
}

# set email body
body_template = """<p>
This is a reminder that your {instance_type} instance with ID {instance_id}
is currently running.<br/>

This instance has been up for a total of <b>{running_hours} hours and
{running_minutes} minutes</b> at a cost of approximately ${cost} so far.<br/><br/>

Note that for Spot instances, this cost is an approximation based on
the current Spot price, which may have fluctuated during usage.<br/><br/>

Please consider terminating your instance if it is no longer in use.<br/>

To terminate, enter your instance ID at the bottom of the
<a href="https://tech-tools.urban.org/ec2-submission/">submission form</a><br/><br/>

Questions? Contact <a href="mailto:AWSAdmin@urban.org?subject=Cloud Computing Environment">the AWS Admin team.</a>
</p>"""

def lambda_handler(event, context):
    # get list of running elastic analytic instances
    instances = ec2.instances.filter(
        Filters = [
                {'Name': 'instance-state-name',
                 'Values' : ['running']
                 },
                {'Name': 'tag:Name',
                 'Values': ['elastic-analytics*']}
                ]
        )

    # iterate over instances
    for instance in instances:
        # derive user email from ec2 tag
        for tag in instance.tags:
            if tag['Key'] == 'Name':
                user = tag['Value'].replace('elastic-analytics-', "")
                user_email = '{}@urban.org'.format(user)
        # derive running time
        running_time = (datetime.datetime.now(datetime.timezone.utc) - instance.launch_time).total_seconds()
        running_hours = int(running_time // 3600)
        running_minutes = int((running_time % 3600) / 60)

        # set email headers
        email_from = 'AWSAdmin@urban.org'
        email_to = user_email
        email_copy = ['AWSAdmin@urban.org'] 
        email_subject = 'REMINDER Your Cloud Computing Session is Running'
        
        # get instance platform
        if instance.platform == 'windows':
            instance_platform = 'Windows'
        else:
            instance_platform = 'Linux/UNIX'
        # get storage information
        storage = 0
        for volume in instance.volumes.all():
            storage += volume.size
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
            instance_cost = prices[instance_platform][instance.instance_type] * (running_time / 3600.0)
        # calculate storage and total cost
        storage_cost = (0.10 * storage) / (24 * 30)
        cost = instance_cost + storage_cost
        # format email body
        body = body_template.format(instance_type = instance.instance_type,
                                    instance_id = instance.instance_id,
                                    running_hours = running_hours,
                                    running_minutes = running_minutes,
                                    cost = round(cost, 2)
                                    )
        # send notification email
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