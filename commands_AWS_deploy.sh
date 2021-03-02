#!/bin/bash

IMAGE_NAME="tp_dashboard"
echo "image name" $IMAGE_NAME
REPO_NAME="dashboard"
echo "repository name" $REPO_NAME


SERVICE_NAME="dashboard"
# IMAGE_VERSION="v_"${BUILD_NUMBER}
IMAGE_VERSION="latest"
TASK_FAMILY="mytask"
CLUSTER="dashboard"
REGION="us-east-1"

profile_name='AWS-cli'

# docker build -t $IMAGE_NAME .



aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 546123287190.dkr.ecr.us-east-1.amazonaws.com

# # create repository on AWS ECR
# # aws ecr get-authorization-token
# # aws ecr create-repository \
#     # --repository-name $REPO_NAME


REPO_URI=$(aws ecr describe-repositories --repository-names "${REPO_NAME}" --query "repositories[0].repositoryUri" --output text 2>/dev/null || \
           aws ecr create-repository --repository-name "${REPO_NAME}"  --query "repository.repositoryUri" --output text)

echo "repository uri" $REPO_URI

docker tag tp_dashboard $REPO_URI

docker push $REPO_URI:latest

aws iam wait role-exists --role-name ecsTaskExecutionRole

aws iam --region $REGION create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://task-execution-assume-role.json


aws iam --region $REGION attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

 
# ecs-cli configure profile --access-key AWS_ACCESS_KEY_ID --secret-key AWS_SECRET_ACCESS_KEY --profile-name $profile_name


ecs-cli configure --cluster $CLUSTER --default-launch-type FARGATE --config-name $CLUSTER --region $REGION

ecs-cli down --force --cluster-config $CLUSTER --ecs-profile $profile_name


ecs-cli up --force --cluster-config $CLUSTER --ecs-profile $profile_name

# VPC created: vpc-013ec393688c8d82a
# Subnet created: subnet-0b41e8b69171835e0
# Subnet created: subnet-040f61342b33be4a5
# aws ec2 describe-vpc 
VPCid=$(aws ec2 describe-vpcs --vpc-ids --query "Vpcs[0].VpcId" --output text)
# VpcIdq

echo $VPCid

SGid=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPCid" \
  --region $REGION  --query "SecurityGroups[0].GroupId" --output text)

echo $SGid


SBnet=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=vpc-02ccd4753c63214e8" --region us-east-1 --query "Subnets[*].SubnetId" --output text )
# 

echo $SBnet
# exit
aws ec2 authorize-security-group-ingress --group-id $SGid --protocol tcp \
--port 80 --cidr 0.0.0.0/0 --region $REGION


ecs-cli compose --project-name $SERVICE_NAME service up --create-log-groups \
  --cluster-config $CLUSTER --ecs-profile $profile_name



# exit


ecs-cli compose --project-name $SERVICE_NAME service ps \
  --cluster-config $CLUSTER --ecs-profile $profile_name



ecs-cli compose --project-name $SERVICE_NAME service down --cluster-config $CLUSTER \
  --ecs-profile $profile_name

exit




# OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition <task_family_name>)
# NEW_CONTAINER_DEFS=$(echo $OLD_TASK_DEF | jq '.taskDefinition.containerDefinitions' | jq '.[0].image="<new_image_name>"')
# aws ecs register-task-definition --family <task_family_name> --container-definitions "'$(echo $NEW_CONTAINER_DEFS)'"




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
