# import libraries
import boto3
import time

# create aws resources
ec2 = boto3.resource('ec2', region_name = 'us-east-1')
s3 = boto3.client('s3', region_name = 'us-east-1')
ses = boto3.client('ses', region_name = 'us-east-1')

def lambda_handler(event, context):
    # obtain instance_id from lambda event trigger and get ec2 resource
    instance_id = event['detail']['instance-id']
    instance = ec2.Instance(instance_id)

    # break out of lamba if not a windows instance
    if instance.platform != 'windows':
        return None

    # break out of lambda if not a shiny-submited instance
    # else get urban username
    for tag in instance.tags:
        if tag['Key'] == 'Name':
            if 'elastic-analytics-' in tag['Value']:
                user = tag['Value'].replace('elastic-analytics-', "")
                user_email = '{}@urban.org'.format(user)
            else:
                return None
        else:
            continue

    # get instance metadata
    dns = instance.public_dns_name
    ip = instance.private_ip_address

    # set email headers
    email_from = 'AWSAdmin@urban.org'
    email_to = user_email
    email_copy = ['AWSAdmin@urban.org'] 
    email_subject = 'Your Cloud Computing Environment'    

    # set operating system specific login information
    if instance.platform == 'windows':
        login = """
        To access your Windows session:
        <ul>
        <li>Enter your instance IP into Windows Remote Desktop Connection.</li>
        <li>Log in using your Urban username and password. </li>
        </ul>
        If you are using the SAS3 share drive, please note that the network is 
        available 7AM-8PM EST.<br/><br/>
        """
    else:
        login = """
        To access R (via RStudio):
        <ul>
        <li>Point your browser to: <a href="http://{dns}:8787">{dns}:8787</a></li>
        <li>Username: rstudio</li>
        <li>Password: rstudio</li>
        </ul>
        To access Python (via Jupyter Notebook):
        <ul>
        <li>Point your browser to: <a href="http://{dns}:8888">{dns}:8888</a></li>
        <li>Password: jupyter</li>
        </ul>
        """.format(dns = dns)

    # set email body
    body = """<p>
    Your cloud computing environment is ready. Be sure to store these details
    for future use.<br/>

    To get started, please consult the
    <a href="https://ui-research.github.io/elastic-analytics-tutorial/">Cloud Computing User Guide</a><br/><br/>

    Your instance ID is: <b>{instance_id}</b><br/>
    Your instance IP is: <b>{instance_ip}</b><br/><br/>

    {login}

    <b>Be sure to terminate your instance when you are done!</b><br/>

    To terminate, enter your instance ID at the bottom of the
    <a href="https://tech-tools.urban.org/ec2-submission/">submission form</a><br/><br/>

    Questions? Contact <a href="mailto:AWSAdmin@urban.org?subject=Cloud Computing Environment">the AWS Admin team.</a>
    </p>""".format(instance_id = instance_id,
                   instance_ip = ip,
                   login = login
                   )
                   
    # pause
    time.sleep(15.0)

    # send notification email
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
