# AWS Terraform

## Prerequisites
* terraform 0.13+
* `make` command available
* `python 3.7+`
    * boto3 library
* `awscli` available
    * upload the terraform state file to s3 bucket
    * create the lock id to block multiple executions for terraform

## Deployment steps
* Ensure you are connected to the correct AWS account
    * use `aws sts get-caller-identity` to confirm the account ID and the assumed role
    * run `aws configure get region` to confirm you are in the correct region
* Run `make set-env` to pull the latest values from SSM parameters
* Run `make init` which executes terraform init and uses the S3 bucket for the state file
* Run `make plan` executes terraform using the S3 bucket state file and the variables.tfvars file
* Run `make apply` to apply the latest changes to the AWS environment.

## Details
* The naming convention is enforced. 
* All environments are saved in the specific region using the ssm paramater called `environments`
* All variables used by terraform are individually saved into dedicated ssm parameters.
  * SSM parameters are used with path so they are saved dedicately for the specific environment.
