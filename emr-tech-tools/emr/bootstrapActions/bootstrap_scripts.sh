# #!/bin/bash

# set -x -e

# # Default values (can be overridden by args)
# rspasswd="hadoop"
# rsuser="hadoop"

# # Extract username and password from arg_list
# arglist=("$@")  # Capture all arguments as an array
# for ((i=0; i<${#arglist[@]}; i++)); do
#   case ${arglist[$i]} in
#     --user)
#       rsuser=${arglist[$((i+1))]}   # Get the next element after --user
#       ;;
#     --user-pw)
#       rspasswd=${arglist[$((i+1))]} # Get the next element after --user-pw
#       ;;
#   esac
# done

# # Check whether we're running on the main node
# main_node=false
# if grep isMaster /mnt/var/lib/info/instance.json | grep true;
# then
#   main_node=true
# fi

# # install some additional R and R package dependencies
# sudo yum install -y bzip2-devel cairo-devel \
#      gcc gcc-c++ gcc-gfortran libXt-devel \
#      libcurl-devel libjpeg-devel libpng-devel \
#      libtiff-devel pcre2-devel readline-devel \
#      texinfo texlive-collection-fontsrecommended

# # Compile R from source; install to /usr/local/*
# mkdir /tmp/R-build
# cd /tmp/R-build
# curl -OL https://cran.r-project.org/src/base/R-latest.tar.gz
# tar -xzf R-latest.tar.gz
# extracted_dir=$(find . -type d -name 'R-*' -print -quit)
# cd "$extracted_dir"
# ./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr/local --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
# make -j 8
# sudo make install

# # Set some R environment variables for EMR
# cat << 'EOF' > /tmp/Renvextra
# JAVA_HOME="/etc/alternatives/jre"
# HADOOP_HOME_WARN_SUPPRESS="true"
# HADOOP_HOME="/usr/lib/hadoop"
# HADOOP_PREFIX="/usr/lib/hadoop"
# HADOOP_MAPRED_HOME="/usr/lib/hadoop-mapreduce"
# HADOOP_YARN_HOME="/usr/lib/hadoop-yarn"
# HADOOP_COMMON_HOME="/usr/lib/hadoop"
# HADOOP_HDFS_HOME="/usr/lib/hadoop-hdfs"
# YARN_HOME="/usr/lib/hadoop-yarn"
# HADOOP_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"
# YARN_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"

# HIVE_HOME="/usr/lib/hive"
# HIVE_CONF_DIR="/usr/lib/hive/conf"

# HBASE_HOME="/usr/lib/hbase"
# HBASE_CONF_DIR="/usr/lib/hbase/conf"

# SPARK_HOME="/usr/lib/spark"
# SPARK_CONF_DIR="/usr/lib/spark/conf"

# PATH=${PWD}:${PATH}
# EOF
# cat /tmp/Renvextra | sudo  tee -a /usr/local/lib64/R/etc/Renviron

# # Reconfigure R Java support before installing packages
# sudo /usr/local/bin/R CMD javareconf

# # get_latest_Rstudio() function extracts the latest version of Rstudio
# get_latest_Rstudio() {
#     local url='https://www.rstudio.com/wp-content/downloads.json'
#     local Rstudio_link=$(curl -s "$url" | jq -r '.rstudio.open_source.stable.server.installer.rhel9.url')
#     echo "$Rstudio_link"
# }

# Rstudio_link=$(get_latest_Rstudio)
# rstudio=$(basename "$Rstudio_link")
# echo "Latest RStudio Server installer URL for RHEL 9: $Rstudio_link"

# # Download, verify checksum, and install RStudio Server
# # Only install / start RStudio on the main node

# if [ "$main_node" = true ]; then
#     curl -OL $Rstudio_link
#     sudo mkdir -p /etc/rstudio
#     sudo sh -c "echo 'auth-minimum-user-id=100' >> /etc/rstudio/rserver.conf"
#     sudo yum install -y $rstudio
#     sudo rstudio-server start
# fi

# # Set password for hadoop user for R Studio
# sudo sh -c "echo '$rspasswd' | passwd hadoop --stdin"

# # Install common R packages
# sudo /usr/local/bin/R --no-save <<R_SCRIPT
# install.packages(c('dplyr', 'tidyr', 'aws.s3', 'broom', 'remotes', 'sparklyr'), repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/centos7/latest'))
# R_SCRIPT

#!/bin/bash

set -x -e

# Default values (can be overridden by args)
rspasswd="hadoop"
rsuser="hadoop"

# Extract username and password from arg_list
arglist=("$@")  # Capture all arguments as an array
for ((i=0; i<${#arglist[@]}; i++)); do
  case ${arglist[$i]} in
    --user)
      rsuser=${arglist[$((i+1))]}   # Get the next element after --user
      ;;
    --user-pw)
      rspasswd=${arglist[$((i+1))]} # Get the next element after --user-pw
      ;;
    --rstudio-link)
      rstudio_link_bt=${arglist[$((i+1))]} # Get the next element after --rstudio-link
      ;;
  esac
done

# Check whether we're running on the main node
main_node=false
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
  main_node=true
fi

# Install some additional R and R package dependencies
sudo yum install -y bzip2-devel cairo-devel \
     gcc gcc-c++ gcc-gfortran libXt-devel \
     libcurl-devel libjpeg-devel libpng-devel \
     libtiff-devel pcre2-devel readline-devel \
     texinfo texlive-collection-fontsrecommended

# Compile R from source; install to /usr/local/*
mkdir /tmp/R-build
cd /tmp/R-build
curl -OL https://cran.r-project.org/src/base/R-latest.tar.gz
tar -xzf R-latest.tar.gz
extracted_dir=$(find . -type d -name 'R-*' -print -quit)
cd "$extracted_dir"
./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr/local --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
make -j 8
sudo make install

# Set some R environment variables for EMR
cat << 'EOF' > /tmp/Renvextra
JAVA_HOME="/etc/alternatives/jre"
HADOOP_HOME_WARN_SUPPRESS="true"
HADOOP_HOME="/usr/lib/hadoop"
HADOOP_PREFIX="/usr/lib/hadoop"
HADOOP_MAPRED_HOME="/usr/lib/hadoop-mapreduce"
HADOOP_YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_COMMON_HOME="/usr/lib/hadoop"
HADOOP_HDFS_HOME="/usr/lib/hadoop-hdfs"
YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"
YARN_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"

HIVE_HOME="/usr/lib/hive"
HIVE_CONF_DIR="/usr/lib/hive/conf"

HBASE_HOME="/usr/lib/hbase"
HBASE_CONF_DIR="/usr/lib/hbase/conf"

SPARK_HOME="/usr/lib/spark"
SPARK_CONF_DIR="/usr/lib/spark/conf"

PATH=${PWD}:${PATH}
EOF
cat /tmp/Renvextra | sudo tee -a /usr/local/lib64/R/etc/Renviron

# Reconfigure R Java support before installing packages
sudo /usr/local/bin/R CMD javareconf

# get_latest_Rstudio() function extracts the latest version of Rstudio
get_latest_Rstudio() {
    local url='https://www.rstudio.com/wp-content/downloads.json'
    local Rstudio_link=$(curl -s "$url" | jq -r '.rstudio.open_source.stable.server.installer.rhel9.url')
    echo "$Rstudio_link"
}

Rstudio_link=$(get_latest_Rstudio)
rstudio=$(basename "$rstudio_link_bt")
echo "Latest RStudio Server installer URL for RHEL 9: $rstudio_link_bt"

# Download, verify checksum, and install RStudio Server
# Only install / start RStudio on the main node

if [ "$main_node" = true ]; then
    curl -OL $rstudio_link_bt
    sudo mkdir -p /etc/rstudio
    sudo sh -c "echo 'auth-minimum-user-id=100' >> /etc/rstudio/rserver.conf"
    sudo yum install -y $rstudio
    sudo rstudio-server start
fi

# Set password for the specified user for RStudio
sudo useradd -m "$rsuser" || echo "User $rsuser already exists"
echo "$rsuser:$rspasswd" | sudo chpasswd

# Install common R packages
sudo /usr/local/bin/R --no-save <<R_SCRIPT
install.packages(c('dplyr', 'tidyr', 'aws.s3', 'broom', 'remotes', 'sparklyr'), repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/centos7/latest'))
R_SCRIPT
