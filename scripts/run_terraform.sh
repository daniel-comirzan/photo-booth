#!/usr/bin/env bash

#TODO Create the dynamoDB table for the RemoteLocking state for Terraform
#TODO
#   Add the prerequisites for the account ( in case they don't exist already)
#       - keys required by Jenkins and the rest of the machines
#       - Issue certificates for the Jenking endpoint which will be created on Route53. [ fra-slgi-oks-jenkins.[ott].[stage | live].irdeto.com ]
#       - Pick the environment variable from the environment name once created


i=1
verbose="false"
while [ $i -le $# ]; do
  var="$1"
  case "$var" in
    -v )
      verbose="true"
      i=$(($i-1))
      ;;
    *)
      set -- "$@" "$var"
      ;;
  esac
  shift
  i=$(($i+1))
done

action=$1
tfvar_file="variables.tfvars"
environments="environments"
script_dir=$(cd $(dirname $0) && pwd)
current_project_filename=".current_project.out"


function enable_colours() {
  # Let's paint this dull world!

  if [ -t 1 ]; then
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    LIME_YELLOW=$(tput setaf 190)
    POWDER_BLUE=$(tput setaf 153)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    BRIGHT=$(tput bold)
    NORMAL=$(tput sgr0)
    BLINK=$(tput blink)
    REVERSE=$(tput smso)
    UNDERLINE=$(tput smul)
  else
    BLACK=''
    RED=''
    GREEN=''
    YELLOW=''
    LIME_YELLOW=''
    POWDER_BLUE=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BRIGHT=''
    NORMAL=''
    BLINK=''
    REVERSE=''
    UNDERLINE=''
  fi
}

function usage(){
    echo "${CYAN}This is a wrapper script over terraform to create an infrastructure"
    echo "This wrapper script allows multiple developers to work in parallel and test multiple feature branches per developer"
    echo "This script takes 1 parameters${NORMAL}"
    echo "Usage:"
    echo "/run_terraform.sh [action] [<project_name>]"
    echo "[action] is mandatory"
    echo "[action] can be any of [show-projects/new-project/show-current-project/set-project/show-env/new-env/set-env/get/init/plan/apply/destroy/show/reset/exterminate]"
    echo "$0 show-projects - Show available local projects"
    echo "$0 new-project - Create new local projects"
    echo "$0 show-current-project - Show current local project"
    echo "$0 set-project - Set current local project"

    echo "$0 show-env - Show available environments in parameter store"
    echo "$0 new-env - Add new environment to parameter store"
    echo "$0 set-env - Choose your environment for which you want to create/update infra"

    echo "$0 init - Initialize working directory containing terraform configuration files"
    echo "$0 get - Download and update the modules mentioned in the root module"
    echo "$0 plan - Creates an execution plan for your the set of changes are you are expecting"
    echo "$0 apply [resource] - Apply the changes required to reach the desired state of the configuration. Allows executions on specific resources."
    echo "$0 show  - Display a human-readable output from a state or plan file"
    echo "$0 state - Allow state operations to be executed on the state file. Use without parameters for help"
    echo "$0 output - Displays the outputs of the main terraform stack"

    echo "$0 reset - Reset the current working environment so a new configuration can be picked."
    echo "$0 destroy - Destroy the Terraform-managed infrastructure."
    echo "$0 add-vars <var_name> <var_value> [list] - Add new variables required for project. In case you need to add a StringList use [list]"
    echo "$0 fmt [file_name] - Format the Terraform code based on the Terraform fmt function. Specify the file if one file needs to be updated."
    echo "$0 check-vars - Adds the missing parameter store with the values from the variables.tfvars"

    printf '\n%s' " Other functionalities ..."
    echo "$0 change-region - Update the AWS Region. [dub/fra/ore/mum]"
    echo "$0 account  - Display the AWS account which is in use."
}

function terraform_init() {
    pick_values $tfvar_file

    log "Checking the bucket ${bucket_name} for environment state" ${YELLOW}
    log "Validating the state for [${environment}]" ${YELLOW}

    terraform init  \
        -backend-config="bucket=${bucket_name}" \
        -backend-config="key=${key_name}" \
        -backend-config="region=${region}" \
        -backend-config="dynamodb_table=${table_name}"

    # terraform_show
}

function terraform_fmt() {
  #Apply format on terraform code
  if [ "$#" -gt 0 ]; then
      terraform fmt $1
  else
      terraform fmt
  fi
}

function terraform_output() {
  terraform output
}

function terraform_plan() {
    resource=$1
    if [ $verbose == "true" ]; then
      terraform_fmt
    else
      terraform_fmt > /dev/null 2>&1  #hide the list of files formatted
    fi

    terraform_get
    log "Checking the plan for [${environment}]" ${YELLOW}
    check_vars
    if [ "$#" -gt 0 ]; then
        target="-target=${resource}"
    else
        target=""
    fi
    log "Running terraform plan for [${environment}]" ${YELLOW}
    if [ ${verbose} == "true" ]; then
      tf_output=$(terraform plan \
              -var-file=${tfvar_file} \
              -out ${environment}-plan.out \
              ${target} | tee /dev/tty )
    else
      tf_output=$(terraform plan \
              -var-file=${tfvar_file} \
              -out ${environment}-plan.out \
              ${target}) > /dev/null 2>&1
    fi
    if [ $? != 0 ]; then
        log "Plan failed to complete. Please check the below errors." ${RED}
        log "--------------------------------------------------------------" ${RED}
            printf '%s\n' "${tf_output}" | sed -n '/---/,/---/p'
        log "--------------------------------------------------------------" ${RED}
        exit 0
    fi
    if [ ${verbose} == "false" ]; then
      log "Displaying the changes (if any) for [${environment}]" ${YELLOW}
      log "--------------------------------------------------------------" ${GREEN}
      #terraform show ${environment}-plan.out
      printf '%s\n' "${tf_output}" | sed -n '/---/,/---/p'
      log "--------------------------------------------------------------" ${GREEN}
    fi
}
function terraform_apply() {
    terraform_plan $1
    if [ "$?" -gt 0 ]; then
        #stoping the execution due to errors in plan
        exit 1
    fi
    log "Applies the changes on the [${environment}]" ${YELLOW}
    terraform apply ${environment}-plan.out
}
function terraform_destroy() {
    log "Destroy the environment [${environment}]" ${YELLOW}

    env_name=$(cat .current_env.out)
    read -p "${RED}Please confirm that you want to destroy ${env_name}. Type the environment name for confirmation${NORMAL}" confirm_destroy

    if [[ ${confirm_destroy} == ${env_name} ]]; then
        terraform destroy \
            -var-file=${tfvar_file}
        return $?
    else
        echo "${CYAN}Destroy aborted.${NORMAL}"
        exit 0
    fi
}
function terraform_exterminate() {
    echo "${YELLOW}<-------- Exterminate the environment [${environment}] together with the state file ------->${NORMAL}"
    # TODO remove also the parameters created together with the environment
    terraform_destroy
    if [ "$?" -eq 0 ]; then
        log "Removing the state file" ${YELLOW}
        aws s3 rm s3://${bucket_name}/${key_name}
#        aws s3api delete-object --bucket my-bucket --key ${bucket_name}/${key_name}
        export table_primary_key="LockID"
        export table_item="${bucket_name}/${key_name}-md5"
        aws dynamodb delete-item \
            --table-name ${table_name} \
            --key "{\"${table_primary_key}\":{\"S\":\"${table_item}\"}}"
    else
        log "!!!There were errors during the terraform destroy command. Please troubleshoot and retry!!!" ${RED}
        exit 1
    fi
    # removing values from parameter store
    export env_name=$(cat .current_env.out)
    region_prefix=$(echo $env_name | cut -d '-' -f 1)
    env=$(echo $env_name | cut -d '-' -f 2)
    product=$(echo $env_name | cut -d '-' -f 3)
    parameter_path="/$region_prefix/${env:0:1}${env:1:3}/$product"

    parameter_values=$(aws ssm get-parameters-by-path --path=$parameter_path --query 'Parameters[].Name' --output text | tr '\t' '\n')

    for parameter_value in ${parameter_values}
    do
        aws ssm delete-parameter --name=$parameter_value
    done

    remove_env_from_environments $env_name
    reset_local_env
}
function terraform_get() {
    log "Download and update all required modules" ${YELLOW}
    terraform get -update
}
function terraform_show() {
    log "Show the environment details for [${environment}]" ${YELLOW}
    terraform show
}
function terraform_state() {
    action=$1
    resource_1=$2
    resource_2=$3
    output=$4
    if [[ ${action} == "show" ]]; then
        resource_count=$(terraform state list | grep ${resource_1} | wc -l | xargs)  >/dev/null 2>&1
        if [[ ${resource_count} -eq 1 ]]; then
            terraform state ${action} ${resource_1}
        else
            for (( i=0; i<=${resource_count} - 1 ; i++ ))
            do
                log "Printing ${resource_1}[${i}]" ${LIME_YELLOW}
                terraform state ${action} ${resource_1}[${i}]
            done
        fi
    else
        terraform state ${action} ${resource_1} ${resource_2} ${output}
    fi
}
function terraform_import() {
  type=$1
  resource=$2
  terraform import ${type} ${resource}
}
function terraform_lint() {
    command -v tflint >/dev/null 2>&1 || (echo "Lint command not installed properly." ; exit 0)
    module_folder=$(find . -type d -maxdepth 1 | grep "module" )
    cd $module_folder ; \
      find . -type d -exec echo ">> Linting {}" \; -exec tflint {} \;
      cd - >/dev/null
}
function terraform_docs() {
    command -v terraform-docs || ( echo "Terraform docs is not installed" ; exit 0)
    export=$1
    [ -z $export ] && export="markdown"
    terraform-docs $export $(pwd)
}
function terraform_validate() {
    terraform_get
    log "Validating the plan for [${environment}]" ${YELLOW}
    terraform validate \
        -var-file=${tfvar_file}
    if [[ "$?" -eq 0 ]]; then
        log "Terraform code is valid!" ${YELLOW}
    fi
}
function reset_local_env() {
    log "Reset the current working environment" ${YELLOW}
    rm -rf .terraform/
    rm -rf .current_env.out
    rm -rf *.out
    rm -rf variables.tfvars
    log "Please run [$0 set-env] to choose a different environment to work on" ${CYAN}
}
function pick_values() {
    export account_id=$( cat $1 | grep account_id | cut -d \" -f 2 )
    export region=$( cat $1 | grep region | cut -d \" -f 2 )
    export product=$( cat $1 | grep product | cut -d \" -f 2 )
    export bucket_name="tf-remotestate-${region}-${account_id}"
    export table_name="tf-remotestate-lock-${region}-${account_id}"
    export project_name=$(cat ${script_dir}/${current_project_filename})
    # export branch_name=$(git symbolic-ref -q HEAD | rev | cut -d '/' -f 1 | rev)
    # if [ ${branch_name} == master ]; then
    #    export USER="jenkins"
    # fi
    export key_name="${environment}/${project_name}.tfstate"
}
function build_path() {
    env_name=$(cat ./.current_env.out)
    export region_prefix=$(echo ${env_name} | cut -d '-' -f 1)
    export env=$(echo ${env_name} | cut -d '-' -f 2)
    export product=$(echo ${env_name} | cut -d '-' -f 3)
    export parameter_path="/${region_prefix}/${env:0:1}${env:1:3}/${product}"
}
function change_region() {
    if [[ "$#" -eq 0 ]]; then
        read -p "enter new region you want to change to , [e.g. dub/fra/ore/mum]: " region
    else
        region="$1"
    fi
    #aws_region=$(cat *.tf | grep $region -i | head -1 | cut -d '=' -f 1 | xargs)
    aws_region=$(lookup_region $region)
    aws configure set default.region ${aws_region}
    log "AWS REGION updated to ${aws_region}" ${YELLOW}
    if [[ ! "$2" == "new" ]]; then
        exit 0
    fi
}
function missing_vars() {

    log "Checking for any missing parameters" ${YELLOW}
    grep "^variable" *.tf > missing_vars.out # check all tf files vor any variables

    while read -r var_line; do
    #for var_line in $(cat missing_vars.out); do
        var_file=$(echo ${var_line} | cut -d ':' -f 1 )
        var_value=$(echo ${var_line} | cut -d ' ' -f 2)
        current_var=$(cat ${var_file} | sed -n "/${var_value}/,/^}\$/p")

        have_default=$(echo ${current_var} | grep -c "default")
        if [[ ${have_default} == "0" ]]; then
            actual_value=$(echo ${var_value} | tr -d "\"")
            #is_tfvars=$(cat ${tfvar_file} | grep -c ${actual_value})
            [[ `cat ${tfvar_file} | grep -c ${actual_value}` == "0" ]] && \
                read -p "${YELLOW}Variable ${RED}${actual_value}${YELLOW} is required for the execution. Please input a value for ${actual_value} :${NORMAL} " new_missing_value < /dev/tty && \
                add_vars ${actual_value} ${new_missing_value}
        fi
    done < missing_vars.out

    rm -f missing_vars.out # Cleaning up the temporary file

}
function check_vars() {

    #add required variables as parameter stores
    build_path

    log "Checking for newly added parameters" ${YELLOW}

    ssm_vars=$( aws ssm get-parameters-by-path --path=${parameter_path} --query 'Parameters[].Name' --output=text | tr '\t' '\n' | awk -F'/' '{print $NF}' )
    local_vars=$(cat ${tfvar_file} | awk -F"=" '{print $1}')

    # check for existing local variables which needs to pushed to
    for local_var in ${local_vars} ; do
        cnt=$(echo ${ssm_vars} | grep -c ${local_var})
        if [[ "${cnt}"  -eq 0 ]]; then
            #get the value to add
            new_value=$(cat ${tfvar_file} | grep -e ${local_var} | tr -d "\""| awk -F"=" '{print $2}')
            is_list=$(echo ${new_value} | grep "\[")
            if [[ "$(echo ${new_value} | grep "\[")" == "" ]]; then
                add_vars ${local_var} ${new_value}
            else
                new_list=$(echo ${new_value} | tr -d "\[" | tr -d "\]")
                add_vars ${local_var} ${new_list} "list"
            fi
        fi
    done

    missing_vars

}
function add_vars() {
    var_name=$1
    var_value=$2
    var_type=$3
    log "Adding new ParameterStore value:  ${RED}${var_name} ${YELLOW}=${RED} ${var_value}${YELLOW}" ${YELLOW}

    build_path
    #check if parameter exists already. if yes grab the type of it
    parameter_type=$(aws ssm get-parameter --name=${parameter_path}/${var_name} --query Parameter.Type 2>log.out | tr -d "\"")

    if [[ "${parameter_type}" == "" ]]; then
        type="String"
        if [ "${var_type}" == "list" ]; then
            type="StringList"
        fi
    else
        type=${parameter_type}
    fi

    if [[ ${type} == "StringList" ]]; then
        #get the current value and append the rest
        base_value=$(aws ssm get-parameter --name=${parameter_path}/${var_name} --query Parameter.Value 2>log.out | tr -d "\"" )
        if [[ ! ${base_value} == "" ]]; then
            var_value=${base_value},$2
        else
            var_value=$2
        fi
    fi

    aws ssm put-parameter --name=${parameter_path}/${var_name} --description="${var_name}" --value=${var_value} --type=${type} --overwrite
    if [[ ${type} == "StringList" ]]; then
        sed -i '' -e "/${var_name}/d" ${tfvar_file}
        var_value=$(aws ssm get-parameter --name=${parameter_path}/${var_name} --query Parameter.Value | sed 's/,/","/g' )
        echo ${var_name}="["${var_value}"]" >> ${tfvar_file}
    else
        sed -i '' -e "/${var_name}/d" ${tfvar_file}
        echo ${var_name}="\""${var_value}"\"" >> ${tfvar_file}
    fi

    if [[ "$?" -eq 0 ]]; then
        log "Parameter ${var_name} added" ${YELLOW}
        #exit 0
    else
        log "Failed to add parameter ${var_name}" ${RED}
        exit 1
    fi

}
# This function checks if environments is present in parameter store
# If it is present then this function will return 0
# If it is not present then this function will return 1
function is_environment_available() {
    existing_environments_value=$(aws ssm get-parameters-by-path --path=/ --query 'Parameters[?Name==`environments`].Value' --output text)
    is_available=1 # 1 means not not-successful

    if [ -z ${existing_environments_value} ]; then
        return ${is_available}
    fi

    environments=$(echo ${existing_environments_value} | tr "," "\n")
    environment_to_find=$1

    for environment in ${environments}
    do
        if [ ${environment} = ${environment_to_find} ]; then
          is_available=0 # 0 means success
        fi
    done

    return ${is_available}

}

# Appends newly added environment variable to /environments in parameter store
function append_new_env_to_environments() {
    existing_environments_value=$(aws ssm get-parameters-by-path --path=/ --query 'Parameters[?Name==`environments`].Value' --output text)
    if [ -z ${existing_environments_value} ]; then
        new_value=${1}
    else
        new_value=${existing_environments_value},${1}
    fi
    aws ssm put-parameter --name=/environments --value=${new_value} --type=StringList --overwrite

    log "${1} is present in /${environments}\n" ${YELLOW}
}

function remove_env_from_environments() {
# make sure that entry if first then should be handled
    env_name="$1"
    environment_value=$(aws ssm get-parameters-by-path --path=/ --query 'Parameters[?Name==`environments`].Value' --output text)
#    new_environment_value=$(echo ${environment_value} | sed  "s/$env_name//g" | sed  's/,,/,/g' | sed "s/ ,/ /g" | sed 's/,*$//g' )
    new_environment_value=$(echo ${environment_value} | sed  -e "s/$env_name//g" -e 's/,,/,/g' -e "s/ ,/ /g" -e 's/,*$//g' )
    aws ssm put-parameter --name=/environments --description="environment list available in /$environments" --value=${new_environment_value} --type=StringList --overwrite
}
# This function reads mandatory environment variables and add them to ssm parameter store"
function read_new_env_variables() {

     if [ "$#" -eq 0 ]; then
        read -p "enter env_name, [e.g. fra-slgi-oks]: " env_name
     else
        env_name="$1"
     fi

     region_prefix=$(echo $env_name | cut -d '-' -f 1)
     #aws_region=$(cat *.tf | grep $region_prefix -i | head -1 | cut -d '=' -f 1 | xargs)
     aws_region=$(lookup_region $region_prefix)
     full_env=$(echo $env_name | cut -d '-' -f 2)
     new_product=$(echo $env_name | cut -d '-' -f 3)
     new_customer=${full_env:1:3}
     parameter_path="/$region_prefix/${full_env:0:1}${full_env:1:3}/$new_product"
     new_account_id=$(aws sts get-caller-identity --query "Account" | sed 's/"//g')
     s3_bucket_configuration="--create-bucket-configuration LocationConstraint=$aws_region --acl private"

     change_region "${region_prefix}" "new"

     # check if the bucket for the tfstate exists. otherwise ask for its creation
     export bucket_name="tf-remotestate-${aws_region}-${new_account_id}"
     [ $aws_region == "us-east-1" ] && s3_bucket_configuration="--acl private"
     #Create S3 bucket if doesn't exists already
     aws s3 ls "s3://$bucket_name" 2>/dev/null || \
     aws s3api create-bucket --bucket $bucket_name --region $aws_region \
        $s3_bucket_configuration

     # Blocking public permissions: available in aws-cli/1.16.81
     aws s3api put-public-access-block --bucket ${bucket_name} \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

     aws s3api put-bucket-versioning --bucket ${bucket_name} \
        --versioning-configuration Status=Enabled

     is_environment_available ${env_name} || append_new_env_to_environments ${env_name}

     read -p "enter owner name, [default: devops]: " owner
     if [ "${owner}" == "" ]; then
        owner="devops"
     fi
     read -p "enter VPC CIDR, [e.g. 10.22.200.0/22]: " vpc_cidr
     if [ "${vpc_cidr}" == "" ]; then
        read -p "You have not added a value for the VPC CIDR. Please insert the CIDR: " vpc_cidr
        if [ "${vpc_cidr}" == "" ]; then
            log "We cannot proceed further without the CIDR. Please restart the process once you have the CIDR. For any questions please contact the DevOps Team!" ${RED}
            exit 0
        fi
     fi
     log "Appending ${env_name} to the string list: /$environments ... " ${YELLOW}

     # Add account_id/env/region/account_id/customer/product to parameter store
     aws ssm put-parameter --name=$parameter_path/account_id --description="current AWS account ID" --value=${new_account_id} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/env --description="1 letter env prefix" --value=${full_env:0:1} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/region  --description="current AWS region" --value=${aws_region} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/customer  --description="3 letter customer name" --value=${new_customer} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/product  --description="product name" --value=${new_product} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/owner  --description="owner name" --value=${owner} --type=String --overwrite
     aws ssm put-parameter --name=$parameter_path/vpc_cidr  --description="vpc_cidr block for $parameter_path" --value=${vpc_cidr} --type=String --overwrite

     # create dynamodb table for locking state if doesnt exists
     export dynamo_db_table_name="tf-remotestate-lock-${aws_region}-${new_account_id}"
     aws dynamodb describe-table --table-name ${dynamo_db_table_name}
     if [ "$?" -eq 0 ]; then
        printf '%s\n' "${dynamo_db_table_name} already exists"
     else
        aws dynamodb create-table  \
            --table-name=${dynamo_db_table_name}   \
            --attribute-definitions AttributeName=LockID,AttributeType=S  \
            --key-schema AttributeName=LockID,KeyType=HASH  \
            --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
     fi
}

# Shows all the available environment variables present in /environments
function show_available_environments() {
    existing_environments_value=$(aws ssm get-parameters-by-path --path=/ --query 'Parameters[?Name==`environments`].Value' --output text)
    if [ -z ${existing_environments_value} ]; then
        log "No environment exists. Use ./run_terraform.sh new-env to add one." ${YELLOW}
    else
        printf '%s\n' ${existing_environments_value} | tr "," "\n"
    fi
    printf "\n"
    if [[ "$#" -eq 0 ]]; then
        log "To create a new environment please use ${0} new-env" ${YELLOW}
        exit 0
    fi
}
function set_env() {
    if [ "$#" -eq 0 ]; then
        show_available_environments "pass"
        read -p "set your env variable. [e.g. reg-ecus-prd]:" env_name
    else
        env_name="$1"
    fi
    export region_prefix=$(echo $env_name | cut -d '-' -f 1)
    export env=$(echo $env_name | cut -d '-' -f 2)
    export product=$(echo $env_name | cut -d '-' -f 3)
    export parameter_path="/$region_prefix/${env:0:1}${env:1:3}/$product"

    echo ${env_name} > .current_env.out

    log "checking if all the parameters in place for $parameter_path" ${YELLOW}

 
    existing_parameters=$(aws ssm get-parameters-by-path --path=$parameter_path --query 'Parameters[].Name' --output text| sed 's/\[\]//g')
    did_find_parameters=1

    if [[ -z "$existing_parameters" ]]; then
        log "[ ${env_name} ] is not a valid environment. The available environments are:" ${YELLOW}
        show_available_environments
        return $did_find_parameters
    else
	 [ -f ${tfvar_file} ] && rm -f ${tfvar_file}
         for parameter_value in ${existing_parameters}
         do
            parameter_type=$(aws ssm get-parameter --name=${parameter_value} --query Parameter.Type | tr -d "\"")
            echo $parameter_value
            parameter_name=$(echo $parameter_value | cut -d '/' -f 5)
            if [ "${parameter_type}" == "StringList" ]; then
                list_value=$(aws ssm get-parameter --name=${parameter_value} --query Parameter.Value | sed 's/,/","/g' )
                echo ${parameter_name}="["${list_value}"]" >> ${tfvar_file}
            else
                echo ${parameter_name}=$(aws ssm get-parameter --name=${parameter_value} --query Parameter.Value) >> ${tfvar_file}
            fi
        done
    fi

    pick_values $tfvar_file

    # Check if table exists for existing envs. Otherwise create it.

    aws dynamodb describe-table --table-name ${table_name} 2>/dev/null || \
        aws dynamodb create-table  \
            --table-name=${table_name}   \
            --attribute-definitions AttributeName=LockID,AttributeType=S  \
            --key-schema AttributeName=LockID,KeyType=HASH  \
            --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

}

function show_projects() {
  printf '%s\n' "Function used to show all available projects in upper directory"
  # we are looking for all directories with main.tf inside except of *wrapper* directories
  list_of_projects_dirs=$(find $script_dir/../ -maxdepth 2 -name "main.tf" \! \( -regex '.*wrapper/main.tf' \) -exec dirname {} \;|xargs -I {} basename {})
  log "List of available local projects" ${YELLOW}
  echo $list_of_projects_dirs |tr " " "\n"
  if [[ 0 -eq ${#list_of_projects_dirs} ]]; then
    log "Looks like you have no local projects!" ${YELLOW}
  fi
  log "To create a new project please use ${0} new-project" ${YELLOW}
  return 0
}
function new_project() {
  if [ "$#" -eq 0 ]; then
    read -p "Please, enter a name for your new project, [e.g. superduper]: " project_name
  else
    project_name="$1"
  fi
  mkdir $script_dir/../$project_name || ( printf '%s\n' "${RED} ERROR: Can't create ${project_name} project directory!\nExiting...${NORMAL}"; exit 1)
  cp $script_dir/*.tf $script_dir/../$project_name || ( printf '%s\n' "${RED}ERROR: Can't copy files to ${project_name} project directory!\nExiting...${NORMAL}"; exit 1)

  log "New project created - [ ${project_name} ]" ${YELLOW}

}
function set_current_project() {
  if [ "$#" -eq 0 ]; then
    show_projects
    read -p "Please, enter a name of existing project to set as current, [e.g. superduper]: " project_name
  else
    project_name="$1"
  fi
  echo $project_name > $script_dir/$current_project_filename
  log "Current project - [ $project_name ]" ${YELLOW}
#  echo $project_name
}
function show_current_project() {
  if [ -e $script_dir/$current_project_filename ]; then
    project_name=$(cat $script_dir/$current_project_filename)
    log "Current project - [ $project_name ]" ${YELLOW}
  else
    log "Looks like you don't set current project" ${YELLOW}
    log "To set a current project please use ${0} set-project" ${YELLOW}
  fi
}
function check_project_dir_exist_and_cd() {
    # Function used to check existence of the project directory and cd to it
    project_name=$1
    found=1
    if [ -d $script_dir/../$project_name ]; then
      log "Project $project_name found, changing working dir to $(dirname $script_dir)/$project_name" ${YELLOW}
      cd $script_dir/../$project_name && found=0
    else
      log "ERROR: Project ${project_name} not found!!! Exiting..." ${RED}
      found=1
    fi
    return $found
}
function lookup_region() {
  declare "fra=eu-central-1"
  declare "dub=eu-west-1"
  declare "vir=us-east-1"
  declare "cal=us-west-1"
  declare "ore=us-west-2"
  declare "sin=ap-southeast-1"
  declare "syd=ap-southeast-2"
  declare "mum=ap-south-1"

  local i="$1"
  echo "${!i}"
}
function log () {
    message=$1
    color=$2
    printf '%s\n' "${color}<---------- ${message} ---------->${NORMAL}"
}
function aws_version() {
    command -v aws > /dev/null 2>&1 || ( echo "AWS CLI is not installed "; exit 0 )
    aws_version=$(aws --version | cut -d' ' -f 1 | cut -d'/' -f 2)
    major_version=${aws_version:0:1}
    [ $major_version == 2 ] && export AWS_PAGER=""

}

enable_colours
aws_version


if [[ "$#" -lt 1 ]] || [[ "$#" -gt 5 ]]; then
   usage
   exit 1
fi

# cases for the operations with the projects
case $action in
    "show-projects")
      show_projects
      exit 0
      ;;
    "show-current-project")
      show_current_project
      exit 0
      ;;
    "new-project")
      new_project $2
      exit 0
      ;;
    "set-project")
      set_current_project $2
      exit 0
      ;;
    "account")
      who_am_i
      ;;
    "change-region")
      change_region $2
      ;;
esac

if [ -e ${script_dir}/${current_project_filename} ]; then
  current_project=$(cat ${script_dir}/${current_project_filename})
else
  current_project=$(set_current_project)
fi

check_project_dir_exist_and_cd $current_project || exit 1

if [[ ! $action =~ "env" ]]; then
   if [[ -e ".current_env.out" ]]; then
    environment=$(cat .current_env.out)
    pick_values ${tfvar_file}
   else
    [[ ! $action == "reset" ]] && set_env
  fi
fi

case $action in
    "reset")
      reset_local_env
      exit 0
      ;;
    "change-region")
      change_region $2
      ;;
    "add-vars")
      add_vars $2 $3 $4
      ;;
    "check-vars")
    check_vars
      ;;
    "show-env")
      show_available_environments
      ;;
    "new-env")
      read_new_env_variables $2
      ;;
    "set-env")
      set_env $2
      ;;
    "init")
      terraform_init
      ;;
    "plan")
      terraform_plan $2
      ;;
    "apply")
      terraform_apply $2
      ;;
    "destroy")
      terraform_destroy
      ;;
    "get")
      terraform_get
      ;;
    "tflint")
      terraform_lint
      ;;
    "docs")
      terraform_docs $2
      ;;
    "show")
      terraform_show
      ;;
    "fmt")
      terraform_fmt $2
      ;;
    "output")
      terraform_output
      ;;
    "state")
      terraform_state $2 $3 $4 $5
      ;;
    "import")
      terraform_import $2 $3
      ;;
    "reset")
      reset_local_env
      ;;
    *)
      printf '%s\n\n%s\n\n%s\n' "${RED}" "<---Invalid parameter--->" "${NORMAL}"
      usage
      ;;
esac
