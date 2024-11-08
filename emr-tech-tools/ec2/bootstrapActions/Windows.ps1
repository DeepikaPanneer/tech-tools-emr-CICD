$instance=(curl http://169.254.169.254/latest/meta-data/instance-id).Content
$instance | out-file -encoding Ascii $instance'.txt'
$filename=$instance+'.txt'
Write-S3Object -BucketName ui-elastic-analytics -File $filename -Key notifications/$filename