# AMI-baker
AMI-Baker is a tool to create a Core OS based AMI which runs a docker based application.


### AWS Setup:
AWS access is required in order to create an AMI.
As we use packer, packer has four methods of providing AWS credentials (more details at https://www.packer.io/docs/builders/amazon.html#_aws_credentials).

We use this code on an ec2 instance so packer uses the IAM role attached with that instance.
If you're using it else where, expose credential details as environmental variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

### How to run
To build your Core OS based AMI, you need to run the scrip `bake-ami.sh`.
The parameters for the script are as follows:

###### -r <AWS Region> (required)
The AWS region in which the AMI is to be created.

###### -n <Name of the AMI> (required)
The name of the AMI to be created.

###### -d <Name of the Docker image> (required)
Name of the docker image of your application which will be used to create a systemd unit, in order to run your application on Core OS.

###### -o <Docker options> (optional)
Docker options used with the docker run command in order to run your application.

###### -i <Instance Type> (optional)
Instance type to be specified in the AMI, it defaults to `t2.medium`