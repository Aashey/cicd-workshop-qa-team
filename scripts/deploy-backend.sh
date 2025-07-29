#!/bin/bash
set -e	

# Debug (remove after testing)
echo "AWS_REGION=$AWS_REGION"
echo "ECR_REGISTRY=$ECR_REGISTRY"
echo "ECR_REPOSITORY=$ECR_REPOSITORY"
echo "EC2_INSTANCE_ID=$EC2_INSTANCE_ID"

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Use branch name from GitHub Actions
branch_name="${GITHUB_REF#refs/heads/}"

cd backend

echo "Building Docker image..."
docker build -t "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest" .

echo "Pushing Docker image..."
docker push "$ECR_REGISTRY/$ECR_REPOSITORY:$branch_name-latest"

echo "Triggering EC2 deploy script via SSM..."
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "[{\"Key\":\"InstanceIds\",\"Values\":[\"$EC2_INSTANCE_ID\"]}]" \
  --parameters "{\"commands\":[\"sudo su - root -c '/root/deployment/deployment_script_team1-aashish.sh'\"]}" \
  --region "$AWS_REGION"
