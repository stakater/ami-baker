#!/bin/bash
AWS_REGION=""
SUBNET_ID=""
VPC_ID=""
AMI_NAME=""
INSTANCE_TYPE=t2.medium # default value
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
          volOptionCnt=$((volOptionCnt+1));
          DATA_EBS_DEVICE_NAME=$OPTARG
          ;;
        z)
          volOptionCnt=$((volOptionCnt+1));
          DATA_EBS_VOL_SIZE=$OPTARG
          ;;
        l)
          volOptionCnt=$((volOptionCnt+1));
          LOGS_EBS_DEVCE_NAME=$OPTARG
          ;;
        x)
          volOptionCnt=$((volOptionCnt+1));
          LOGS_EBS_VOL_SIZE=$OPTARG
          ;;
        *)
          echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -c <Cloud config template file path> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -b <Build UUID> -s <Subnet ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional) -g <Docker registry certificates directory path> (optional) -e <EBS data volume device name> -z <EBS data volume device size> -l <EBS logs volume device name> -x <EBS logs volume size>"
          exit 0
          ;;
    esac
done
echo "Volume opt cnt:$volOptionCnt
Dataebs: $DATA_EBS_DEVICE_NAME - $DATA_EBS_VOL_SIZE
logsebs: $LOGS_EBS_DEVCE_NAME - $LOGS_EBS_VOL_SIZE";
if [ ! $rOptionFlag || ! $nOptionFlag || ! $dOptionFlag || ! $bOptionFlag || ! $cOptionFlag ] || [[ "$volOptionCnt" -le 4 ]];
then
  echo "Usage: $(basename $0) -r <AWS region> -n <AMI NAME> -c <Cloud config template file path> -d <DOCKER IMAGE> -o <DOCKER OPTS> (optional) -b <Build UUID> -s <Subnet_ID> (optional) -v <VPC ID> (optional) -i <INSTANCE TYPE> (optional) -g <Docker registry certificates directory path> (optional)  -e <EBS data volume device name> -z <EBS data volume device size> -l <EBS logs volume device name> -x <EBS logs volume size>"
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

# Run packer
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