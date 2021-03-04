#!/bin/bash

IMAGE_NAME="tp_dashboard"
echo ""
echo "image name" $IMAGE_NAME
REPO_NAME="dashboard"
echo ""
echo "repository name" $REPO_NAME


SERVICE_NAME="dashboard"
# IMAGE_VERSION="v_"${BUILD_NUMBER}
IMAGE_VERSION=${1:-latest}
# IMAGE_VERSION="latest"
# TASK_FAMILY="dashboard"
CLUSTER="dashboard_S3"
REGION="us-east-1"

profile_name='AWS-cli'
accountid=$(aws sts get-caller-identity --query Account --output text)
DNS_name='brunoviola.com'


task_role='dashboardRole' #ecsTaskExecutionRole
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

echo ""
echo "repository uri" $REPO_URI

docker tag $IMAGE_NAME $REPO_URI:$IMAGE_VERSION

docker push $REPO_URI:$IMAGE_VERSION
# exit

# 546123287190.dkr.ecr.us-east-1.amazonaws.com/dashboard

# aws ecs register-task-definition --generate-cli-skeleton

echo ""
echo "creating task execution role"
aws iam wait role-exists --role-name $task_execution_role 2>/dev/null || \ aws iam --region $REGION create-role --role-name $task_execution_role \
  --assume-role-policy-document file://task-execution-assume-role.json || return 1
 
echo ""
echo "adding AmazonECSTaskExecutionRole Policy"
aws iam --region $REGION attach-role-policy --role-name $task_execution_role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 

echo ""
echo "creating task role"
aws iam wait role-exists --role-name $task_role 2>/dev/null || \ 
aws iam --region $REGION create-role --role-name $task_role \
  --assume-role-policy-document file://task-role.json 

echo ""
echo "adding AmazonS3ReadOnlyAccess Policy"
aws iam --region $REGION attach-role-policy --role-name $task_role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess 


TASK_DEF=$(aws ecs describe-task-definition --task-definition $SERVICE_NAME)
 #to be used only at the very beginning when configuring ecs-cli
# ecs-cli configure profile --access-key AWS_ACCESS_KEY_ID --secret-key AWS_SECRET_ACCESS_KEY --profile-name $profile_name

echo ""
echo "configuring cluster"
ecs-cli configure --cluster $CLUSTER --default-launch-type FARGATE --config-name $CLUSTER --region $REGION 

ecs-cli down --force --cluster-config $CLUSTER --ecs-profile $profile_name 


ecs-cli up --force --cluster-config $CLUSTER --ecs-profile $profile_name --verbose 








echo "getting resource ids "
VPCid=$(aws ec2 describe-vpcs --vpc-ids --query "Vpcs[0].VpcId" --output text)
echo ""
echo $VPCid

SGid=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPCid" \
  --region $REGION  --query "SecurityGroups[0].GroupId" --output text)
echo ""
echo $SGid


SUBNET_IDS=$(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$VPCid" --region us-east-1 --query "Subnets[*].SubnetId" --output text )

IFS=$'\t ' read -r -a subnet_ids <<< $SUBNET_IDS
subnet1=${subnet_ids[0]}
subnet2=${subnet_ids[1]}
echo ""
echo $subnet1
echo $subnet2

echo ""
echo "\nadding ingress rules to security groups"
aws ec2 authorize-security-group-ingress --group-id $SGid --protocol tcp \
--port 80 --cidr 0.0.0.0/0 --region $REGION || return


echo ""
echo "\ngenerating docker compose file to be used"

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
echo ""
echo "generating ecs params file"
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

#####
# ecs-cli configure --region us-east-1 --cluster $CLUSTER_NAME

# create ecs cluster of ec2 instances
# ecs-cli up --keypair $KEY_PAIR --capability-iam --size $CLUSTER_SIZE --security-group $SSH_SECURITY_GROUP --vpc $VPC_ID --subnets $SUBNET_ID --image-id $AMI_ID --instance-type $INSTANCE_TYPE --verbose

# create task definition for a docker container
ecs-cli compose --file docker-compose.yml --project-name $CLUSTER --verbose create

# create elb & add a dns CNAME for the elb dns
aws elb create-load-balancer --load-balancer-name $CLUSTER --listeners Protocol="TCP,LoadBalancerPort=8080,InstanceProtocol=TCP,InstancePort=80" --subnets $subnet1 $subnet2 --security-groups $SGid --scheme internal

# create service with above created task definition & elb
aws ecs create-service --service-name $CLUSTER --cluster $CLUSTER_NAME --task-definition $TASK_DEF --load-balancers "loadBalancerName=$CLUSTER,containerName=demo-service,containerPort=80" --desired-count 1 --deployment-configuration "maximumPercent=200,minimumHealthyPercent=50" --role $task_execution_role



#####





ecs-cli compose --project-name $SERVICE_NAME service up --create-log-groups \
  --cluster-config $CLUSTER --ecs-profile $profile_name


ecs-cli compose --project-name $SERVICE_NAME service ps \
  --cluster-config $CLUSTER --ecs-profile $profile_name

aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`]| [0].Value]' --output table

exit

# aws ecs update-service \
# --cluster $CLUSTER \
# --service $SERVICE_NAME \
# --task-definition feedback-bot-dev \
# --region $REGION

