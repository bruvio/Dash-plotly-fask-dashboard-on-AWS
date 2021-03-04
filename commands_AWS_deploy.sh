#!/bin/bash

IMAGE_NAME="tp_dashboard"
echo "image name" $IMAGE_NAME
REPO_NAME="dashboard"
echo "repository name" $REPO_NAME


SERVICE_NAME="dashboard"
# IMAGE_VERSION="v_"${BUILD_NUMBER}
IMAGE_VERSION=${1:-latest}
# IMAGE_VERSION="latest"
# TASK_FAMILY="dashboard"
CLUSTER="dashboard"
REGION="us-east-1"

profile_name='AWS-cli'
accountid='546123287190'
DNS_name='brunoviola.com'
# iam_role='ecsTaskExecutionRole' #ecsTaskExecutionRole
task_role='dashboard_role' #ecsTaskExecutionRole
task_execution_role='ecsTaskExecutionRole'




docker build -t $IMAGE_NAME:$IMAGE_VERSION .
# exit


# docker run -p 8080:80 tp_dashboard:latest
# docker-compose -f docker-compose_aws_credential.yml up --build -d
# docker container run -it --name dash tp_dashboard:3 bash

# exit


aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $accountid.dkr.ecr.$REGION.amazonaws.com

# create repository on AWS ECR

REPO_URI=$(aws ecr describe-repositories --repository-names "${REPO_NAME}" --query "repositories[0].repositoryUri" --output text 2>/dev/null || \
           aws ecr create-repository --repository-name "${REPO_NAME}"  --query "repository.repositoryUri" --output text) 

echo "repository uri" $REPO_URI

docker tag $IMAGE_NAME $REPO_URI:$IMAGE_VERSION

docker push $REPO_URI:$IMAGE_VERSION
# exit

# 546123287190.dkr.ecr.us-east-1.amazonaws.com/dashboard

# aws ecs register-task-definition --generate-cli-skeleton


aws iam wait role-exists --role-name $task_execution_role 2>/dev/null || \ aws iam --region $REGION create-role --role-name $task_execution_role \
  --assume-role-policy-document file://task-execution-assume-role.json || return 1
 

aws iam --region $REGION attach-role-policy --role-name $task_execution_role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || return 1


# aws iam wait role-exists --role-name $task_role 2>/dev/null || \ 
# aws iam --region $REGION create-role --role-name $task_role \
#   --assume-role-policy-document file://task-role.json || return 1


# aws iam --region $REGION attach-role-policy --role-name $task_role \
#   --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess || return 1



# ACCOUNT_ID=$(aws sts get-caller-identity \
#    --query Account --output text)

# aws iam create-role  \
#   --role-name $task_execution_role \
#   --assume-role-policy-document "$(
#      jq -n . --arg account_id $ACCOUNT_ID '{
#         "Statement": [{
#             "Effect": "Allow",
#             "Principal": { "Service": [ "ecs-tasks.amazonaws.com" ] },
#             "Action": [ "sts:AssumeRole" ]
#           },{
#             "Effect": "Allow",
#             "Principal": { "AWS": [ $account_id ] },
#             "Action": [ "sts:AssumeRole" ]
#           }]}'
#      )"


# aws iam create-role $task_role \
#   --role-name $task_role \
#   --policy-name 'describe-parameters' \
#   --policy-document '{
#             "Statement": [{
#                 "Effect": "Allow",
#                 "Action": [
#                 "s3:Get*",
#                 "s3:List*"
#             ],
#                 "Resource": "*"
#             }]}'


# aws iam --region $REGION attach-role-policy --role-name $iam_role \
#   --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess || return 1

 #to be used only at the very beginning when configuring ecs-cli
# ecs-cli configure profile --access-key AWS_ACCESS_KEY_ID --secret-key AWS_SECRET_ACCESS_KEY --profile-name $profile_name


ecs-cli configure --cluster $CLUSTER --default-launch-type FARGATE --config-name $CLUSTER --region $REGION || return 1

ecs-cli down --force --cluster-config $CLUSTER --ecs-profile $profile_name || return 1


ecs-cli up --force --cluster-config $CLUSTER --ecs-profile $profile_name  || return 1q



VPCid=$(aws ec2 describe-vpcs --vpc-ids --query "Vpcs[0].VpcId" --output text)
echo $VPCid

SGid=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPCid" \
  --region $REGION  --query "SecurityGroups[0].GroupId" --output text)
echo $SGid


SUBNET_IDS=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPCid" --region us-east-1 --query "Subnets[*].SubnetId" --output text )

IFS=$'\t ' read -r -a subnet_ids <<< $SUBNET_IDS
subnet1=${subnet_ids[0]}
subnet2=${subnet_ids[1]}
echo $subnet1
echo $subnet2


aws ec2 authorize-security-group-ingress --group-id $SGid --protocol tcp \
--port 80 --cidr 0.0.0.0/0 --region $REGION || return



## creating automatically docker-compose file using image name to use
export image=$REPO_URI
export REGION=$REGION
rm -f docker-compose.yml temp.yml  
( echo "cat <<EOF >docker-compose.yml";
  cat docker-template.yml;
#   echo "EOF";
) >temp.yml
. temp.yml
# cat docker-compose.yml
# exit

## creating automatically ecs-params with SGid and subnet ids
export task_role
export task_execution_role
export subnet1=$subnet1
export subnet2=$subnet2
export secgroupid=$SGid
rm -f ecs-params.yml temp.yml  
( echo "cat <<EOF >ecs-params.yml";
  cat ecs-params-template.yml;
#   echo "EOF";
) >temp.yml
. temp.yml
# cat ecs-params.yml

ecs-cli compose --project-name $SERVICE_NAME service up --create-log-groups \
  --cluster-config $CLUSTER --ecs-profile $profile_name


ecs-cli compose --project-name $SERVICE_NAME service ps \
  --cluster-config $CLUSTER --ecs-profile $profile_name

aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`]| [0].Value]' --output table



# aws ecs update-service \
# --cluster $CLUSTER \
# --service $SERVICE_NAME \
# --task-definition feedback-bot-dev \
# --region $REGION

# #get hostedzone id

# HostedZoneId=$(aws route53 list-hosted-zones-by-name --dns-name ${DNS_name} --query "HostedZones[*].Id" --output text)

# # IFS=$'/' read -ra aaa <<< $HostedZoneId
# # id=${HostedZoneId[2]}
# # echo $HostedZoneId | sed -e 's///\n/g'
# echo $HostedZoneId
# IFS='/' read d1 d2 id  <<<$HostedZoneId
# echo $id


# HostedZoneId=$(aws route53 list-hosted-zones-by-name | 
# jq --arg name "brunoviola.com" \
# -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id' --output text)

# aws route53 change-resource-record-sets --hosted-zone-id $id --change-batch file://hostedzone_sample.json || return 1


# TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition "$SERVICE_NAME" --region $REGION)


# NEW_TASK_DEFINTIION=$(echo $SERVICE_NAME | jq --arg IMAGE "$IMAGE_VERSION" '.taskDefinition | .containerDefinitions[0].image = $REPO_NAME | del(.taskDefinitionArn) | del(.revision) | del(.status) | del(.requiresAttributes) | del(.compatibilities)')

# echo $NEW_TASK_DEFINTIION
# exit
# aws ecs register-task-definition --region $REGION --cli-input-json "$NEW_TASK_DEFINTIION"

#scale up
# ecs-cli compose --project-name $SERVICE_NAME service scale 2 --cluster-config $SERVICE_NAME --ecs-profile $profile_name

#clean up
# ecs-cli compose --project-name $SERVICE_NAME service down --cluster-config $CLUSTER --ecs-profile $profile_name

# ecs-cli down --force --cluster-config $CLUSTER --ecs-profile $profile_name

#update with new image
# aws ecs update-service --cluster $CLUSTER --service $SERVICE_NAME --force-new-deployment

# exit




# OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition $SERVICE_NAME)
# NEW_CONTAINER_DEFS=$(echo $OLD_TASK_DEF | jq '.taskDefinition.containerDefinitions' | jq '.[0].image="<new_image_name>"')
# aws ecs register-task-definition --family $SERVICE_NAME--container-definitions "'$(echo $NEW_CONTAINER_DEFS)'"




# echo "=====================Create a new task definition for this build==========================="
# sed -e "s;%BUILD_NUMBER%;${BUILD_NUMBER};g" taskdef.json > ${TASK_FAMILY}-${IMAGE_VERSION}.json

# echo "=================Resgistring the task defination==========================================="
# aws ecs register-task-definition  --family ${TASK_FAMILY} --cli-input-json  file://${TASK_FAMILY}-${IMAGE_VERSION}.json --region ${REGION}

# echo "================Update the service with the new task definition and desired count================"
# TASK_REVISION=`aws ecs describe-task-definition --task-definition  ${TASK_FAMILY}  --region ${REGION} | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//'`


# DESIRED_COUNT=`aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE_NAME}  --region ${REGION} | jq .services[].desiredCount`
# if [ ${DESIRED_COUNT} = "0" ]; then
#     DESIRED_COUNT="1"
# fi

# echo "===============Updating the service=============================================================="
# aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY}:${TASK_REVISION} --desired-count ${DESIRED_COUNT} --region ${REGION}
