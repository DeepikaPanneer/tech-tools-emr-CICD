import boto3


def get_latest_emr_version(emr_client):
    
    response = emr_client.list_release_labels()
    release_labels = response['ReleaseLabels']
    return release_labels[0]


def lambda_handler(event, context):
    region = 'us-east-2'
    
    # Create a Boto3 EMR client
    emr_client = boto3.client('emr', region_name=region)
    release_label = get_latest_emr_version(emr_client)

    # EMR Cluster configuration
    cluster_name = 'Rstudio-Sparklyr'
    master_instance_type = 'm5.xlarge'
    core_instance_type = 'm5.xlarge'
    core_instance_count = 1

    # Tags for the EMR Cluster
    tags = [
        {'Key': 'Name', 'Value': 'dpanneerselvam'},
        {'Key': 'Project-Name', 'Value': 'DE-Intern-2024'},
        {'Key': 'Project-code', 'Value': '920000-8201-000-00001'},
        {'Key': 'Tech-team', 'Value': 'RP'},
        {'Key': 'Center', 'Value': 'Tech'},
        {'Key': 'Requested-By', 'Value': 'dpanneerselvam'},
        {'Key': 'Created-By', 'Value': 'dpanneerselvam'}
    ]
    
    # EMR software configurations
    configurations = [
        {
            "Classification": "spark",
            "Properties": {
                "maximizeResourceAllocation": "true"
            }
        }
    ]

    # Bootstrap actions
    bootstrap_actions = [
        {
            'Name': "R Bootstrap",
            'ScriptBootstrapAction': {
                'Path': "s3://ui-spark-social-science/emr-scripts/rstudio_sparkr_emr5lyr-proc.sh"
            }
        }
    ]

    # EMR Cluster launch parameters with tags and bootstrap actions
    response = emr_client.run_job_flow(
        Name=cluster_name,
        ReleaseLabel = release_label,
        Instances={
            'InstanceGroups': [
                {
                    'Name': "Master nodes",
                    'Market': 'ON_DEMAND',
                    'InstanceRole': 'MASTER',
                    'InstanceType': master_instance_type,
                    'InstanceCount': 1,
                },
                {
                    'Name': "Core nodes",
                    'Market': 'ON_DEMAND',
                    'InstanceRole': 'CORE',
                    'InstanceType': core_instance_type,
                    'InstanceCount': core_instance_count,
                }
            ],
            'Ec2KeyName': 'dpanneerselvam-de-intern-2024',
            'KeepJobFlowAliveWhenNoSteps': True,
            'TerminationProtected': False,
        },
        Applications=[
            {'Name': 'Hadoop'},
            {'Name': 'Spark'},
            {'Name': 'Hive'},
        ],
        Configurations=configurations,
        VisibleToAllUsers=True,
        LogUri='s3://aws-logs-672001523455-us-east-2/elasticmapreduce/',
        JobFlowRole='EMR_EC2_DefaultRole',
        ServiceRole='EMR_DefaultRole',
        Tags=tags,
        BootstrapActions=bootstrap_actions
    )

    # Get the master node public DNS
    cluster_id = response['JobFlowId']
   
    # Return the master node public DNS as part of the response
    return {
         'statusCode': 200,
        'body': f"Cluster ID {cluster_id} created"
    }
