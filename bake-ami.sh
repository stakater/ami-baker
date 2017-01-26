#!/bin/bash

###############################################################################
# Copyright 2016 Aurora Solutions
#
#    http://www.aurorasolutions.io
#
# Aurora Solutions is an innovative services and product company at
# the forefront of the software industry, with processes and practices
# involving Domain Driven Design(DDD), Agile methodologies to build
# scalable, secure, reliable and high performance products.
#
# Stakater is an Infrastructure-as-a-Code DevOps solution to automate the
# creation of web infrastructure stack on Amazon. Stakater is a collection
# of Blueprints; where each blueprint is an opinionated, reusable, tested,
# supported, documented, configurable, best-practices definition of a piece
# of infrastructure. Stakater is based on Docker, CoreOS, Terraform, Packer,
# Docker Compose, GoCD, Fleet, ETCD, and much more.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

AWS_REGION=""
SUBNET_ID=""
VPC_ID=""
AMI_NAME=""
INSTANCE_TYPE=t2.nano # default value
DOCKER_IMAGE=""
DOCKER_OPTS=""
DOCKER_REGISTRY_DIR=""
BUILD_UUID=""
CLOUD_CONFIG_TMPL=""

#EBS Vars
DATA_EBS_DEVICE_NAME=""
DATA_EBS_VOL_SIZE=""
LOGS_EBS_DEVCE_NAME=""
LOGS_EBS_VOL_SIZE=""

# Flags to make sure all options are given
rOptionFlag=false;
nOptionFlag=false;
dOptionFlag=false;
bOptionFlag=false;
cOptionFlag=false;
volOptionCnt=0;
# Get options from the command line
while getopts ":r:n:d:o:i:s:v:g:b:c:e:z:l:x:" OPTION
do
    case $OPTION in
        r)
          rOptionFlag=true
          AWS_REGION=$OPTARG
          ;;
        n)
          nOptionFlag=true
          AMI_NAME=$OPTARG
          ;;
        d)
          dOptionFlag=true
          DOCKER_IMAGE=$OPTARG
          ;;
        o)
          DOCKER_OPTS=$OPTARG #optional
          ;;
        i)
          INSTANCE_TYPE=$OPTARG #optional
          ;;
        s)
          SUBNET_ID=$OPTARG
          ;;
        v)
          VPC_ID=$OPTARG
          ;;
        g)
          DOCKER_REGISTRY_CRTS_DIR=$OPTARG
          ;;
        b)
          bOptionFlag=true
          BUILD_UUID=$OPTARG
          ;;
        c)
          cOptionFlag=true
          CLOUD_CONFIG_TMPL=$OPTARG
          ;;
        e)
          if [ ! -z "$OPTARG" ]; then volOptionCnt=$((volOptionCnt+1)); fi #if not empty string, then set flag true
          DATA_EBS_DEVICE_NAME=$OPTARG
          ;;
        z)
          if [ ! -z "$OPTARG" ]; then volOptionCnt=$((volOptionCnt+1)); fi #if not empty string, then set flag true
          DATA_EBS_VOL_SIZE=$OPTARG
          ;;
        l)
          if [ ! -z "$OPTARG" ]; then volOptionCnt=$((volOptionCnt+1)); fi #if not empty string, then set flag true
          LOGS_EBS_DEVCE_NAME=$OPTARG
          ;;
        x)
          if [ ! -z "$OPTARG" ]; then volOptionCnt=$((volOptionCnt+1)); fi #if not empty string, then set flag true
          LOGS_EBS_VOL_SIZE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -c <Cloud config template file path> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -b <Build UUID> -s <Subnet ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional) -g <Docker registry certificates directory path> (optional) -e <EBS data volume device name>(optional) -z <EBS data volume device size>(optional)  -l <EBS logs volume device name>(optional)  -x <EBS logs volume size>(optional) "
          exit 0
          ;;
    esac
done
if [[ ! $rOptionFlag || ! $nOptionFlag || ! $dOptionFlag || ! $bOptionFlag || ! $cOptionFlag ]] ;
then
  echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -c <Cloud config template file path> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -b <Build UUID> -s <Subnet_ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional) -g <Docker registry certificates directory path> (optional)  -e <EBS data volume device name>(optional)  -z <EBS data volume device size>(optional)  -l <EBS logs volume device name>(optional)  -x <EBS logs volume size>(optional) "
  exit 0;
fi

# Fetch core-os ami id
COREOS_UPDATE_CHANNEL=stable;
VM_TYPE=hvm;
url=`printf "http://%s.release.core-os.net/amd64-usr/current/coreos_production_ami_%s_%s.txt" $COREOS_UPDATE_CHANNEL $VM_TYPE $AWS_REGION`

AMI_ID=$(curl -s $url)

######################
## Replace values for
## docker image and opts
## in cloud config file
######################
# create file from template
CLOUD_CONFIG_FILE="${CLOUD_CONFIG_TMPL%%.tmpl*}.yaml"
cp $CLOUD_CONFIG_TMPL $CLOUD_CONFIG_FILE
# replace in file
perl -p -i -e "s|<#DOCKER_IMAGE#>|$DOCKER_IMAGE|g" $CLOUD_CONFIG_FILE
perl -p -i -e "s|<#DOCKER_OPTS#>|$DOCKER_OPTS|g" $CLOUD_CONFIG_FILE

# Bash output colors
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# If all volume variables are specified only then run packer with EBS attached
if [[ "$volOptionCnt" -lt  "4" ]];
then
  echo "${CYAN}All variables for extra EBS not specified, Creating AMI without EBS attached${NC}"
  # Run packer without EBS attached
  packer build \
      -var "aws_region=$AWS_REGION" \
      -var "subnet_id=$SUBNET_ID" \
      -var "vpc_id=$VPC_ID" \
      -var "source_ami=$AMI_ID" \
      -var "instance_type=$INSTANCE_TYPE" \
      -var "ami_name=$AMI_NAME" \
      -var "docker_registry_crts_dir=$DOCKER_REGISTRY_CRTS_DIR" \
      -var "build_uuid=$BUILD_UUID" \
      -var "cloud_config_file=$CLOUD_CONFIG_FILE" \
      -var "app_docker_image=$DOCKER_IMAGE" \
      templates/amibaker.json 2>&1 | sudo tee output.txt
else
  echo "${CYAN}All variables for extra EBS specified, Creating AMI with EBS attached${NC}"
  # Run packer with EBS attached
  packer build \
      -var "aws_region=$AWS_REGION" \
      -var "subnet_id=$SUBNET_ID" \
      -var "vpc_id=$VPC_ID" \
      -var "source_ami=$AMI_ID" \
      -var "instance_type=$INSTANCE_TYPE" \
      -var "ami_name=$AMI_NAME" \
      -var "docker_registry_crts_dir=$DOCKER_REGISTRY_CRTS_DIR" \
      -var "build_uuid=$BUILD_UUID" \
      -var "cloud_config_file=$CLOUD_CONFIG_FILE" \
      -var "app_docker_image=$DOCKER_IMAGE" \
      -var "data_ebs_device_name=$DATA_EBS_DEVICE_NAME" \
      -var "data_ebs_vol_size=$DATA_EBS_VOL_SIZE" \
      -var "logs_ebs_device_name=$LOGS_EBS_DEVCE_NAME" \
      -var "logs_ebs_vol_size=$LOGS_EBS_VOL_SIZE" \
      templates/amibaker.json 2>&1 | sudo tee output.txt
fi
