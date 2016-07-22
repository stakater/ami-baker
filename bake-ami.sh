#!/bin/bash
AWS_REGION=""
SUBNET_ID=""
VPC_ID=""
AMI_NAME=""
INSTANCE_TYPE=t2.medium # default value
DOCKER_IMAGE=""
DOCKER_OPTS=""
# Flags to make sure all options are given
rOptionFlag=false;
nOptionFlag=false;
dOptionFlag=false;
# Get options from the command line
while getopts ":r:n:d:o:i:s:v:" OPTION
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
        *)
          echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -s <Subnet ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional)"
          exit 0
          ;;
    esac
done
if ! $rOptionFlag || ! $nOptionFlag || ! $dOptionFlag ;
then
  echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -s <Subnet_ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional)"
  exit 0;
fi

# Fetch core-os ami id
COREOS_UPDATE_CHANNEL=beta;
VM_TYPE=hvm;
url=`printf "http://%s.release.core-os.net/amd64-usr/current/coreos_production_ami_%s_%s.txt" $COREOS_UPDATE_CHANNEL $VM_TYPE $AWS_REGION`

AMI_ID=$(curl -s $url)

######################
## Replace values for
## docker image and opts
## in cloud config file
######################
files=$(grep -s -l -e \<#DOCKER_IMAGE#\> -e \<#DOCKER_OPTS#\> -r "cloud-config/cloud-config.tmpl.yaml")
echo ${files[@]}
if [ "X$files" != "X" ];
then
  for f in $files
  do
    newFile="${f%%.tmpl*}.yaml"
    cp $f $newFile
    perl -p -i -e "s|<#DOCKER_IMAGE#>|$DOCKER_IMAGE|g" $newFile
    perl -p -i -e "s|<#DOCKER_OPTS#>|$DOCKER_OPTS|g" $newFile
  done
fi

# Run packer
packer build \
    -var "aws_region=$AWS_REGION" \
    -var "subnet_id=$SUBNET_ID" \
    -var "vpc_id=$VPC_ID" \
    -var "source_ami=$AMI_ID" \
    -var "instance_type=$INSTANCE_TYPE" \
    -var "ami_name=$AMI_NAME" \
    templates/amibaker.json
