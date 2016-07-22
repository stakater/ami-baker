# AMI-baker
AMI-Baker is a tool to create a Core OS based AMI which runs a docker based application.


### AWS Setup:
AWS access is required in order to create an AMI.
As we use packer, packer has four methods of providing AWS credentials (more details at https://www.packer.io/docs/builders/amazon.html#_aws_credentials).

You can use the method that requires environmental variables to be set up or the one which requires a `~/.aws/credentials` file to be present, or run it on an EC2 instance which has an IAM role attached which is allowed to create instances, snapshots and AMIs.
Please refer to the given link for details.


### How to run
To build your Core OS based AMI, you need to run the scrip `bake-ami.sh`.

The parameters for the script are as follows:

###### -r `<AWS Region>` (required)
The AWS region in which the AMI is to be created.

###### -n `<Name of the AMI>` (required)
The name of the AMI to be created.

###### -d `<Name of the Docker image>` (required)
Name of the docker image of your application which will be used to create a systemd unit, in order to run your application on Core OS.

###### -o `<Docker options>` (optional)
Docker options used with the docker run command in order to run your application.

###### -i `<Instance Type>` (optional)
Instance type to be specified in the AMI, it defaults to `t2.medium`

###### -v `<VPC ID>` (optional)
The VPC in which packer will create a base instance in order to create an AMI.
Specify if you do not want to use default VPC.

###### -s `<SUBNET ID>` (optional)
The subnet in which packer will create a base instance in order to create an AMI.
Specify if you do not want to use default VPC.

###### -g `<Docker registry certificates path>` (optional)
Complete path to folder where docker registry certificates are placed.
It will usually be like `/etc/docker/certs.d/<registry-host>:<registry-port>`


Example:
```
./bake-ami.sh -r us-east-1 -n myAmi -d hello-world
```
