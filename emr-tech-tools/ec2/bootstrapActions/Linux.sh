#!/bin/bash

# install docker
sudo yum update -y

sudo yum install docker -y

sudo service docker start

# start rstudio container
sudo docker run -d -p 8787:8787 -e PASSWORD=UrbanCloud2019 -e ROOT=true -v /home/ec2-user:/home/rstudio --name rstudio rocker/geospatial:4.1

# install urbnverse
sudo docker exec rstudio R -e "remotes::install_github('UrbanInstitute/urbnmapr', repos = 'http://cran.rstudio.com')"
sudo docker exec rstudio R -e "remotes::install_github('UrbanInstitute/urbnthemes', repos = 'http://cran.rstudio.com')"

# install awscli into rocker container
sudo docker exec rstudio sudo apt-get install -y python-pip
sudo docker exec rstudio sudo pip install awscli

# pull and run anaconda3 container
sudo docker run -d -p 8888:8888 --name jupyter jupyter/scipy-notebook start-notebook.sh --NotebookApp.password='sha1:b2d1b4eee6e8:af2ca564c2db504fb659b501bb01bd9d50250bf3'

# write instance id to s3
instance=$(sudo curl http://169.254.169.254/latest/meta-data/instance-id)
sudo echo $instance > $instance.txt
sudo aws s3 cp $instance.txt s3://ui-elastic-analytics/notifications/$instance.txt