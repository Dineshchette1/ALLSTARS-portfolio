#!/bin/bash

# Variables
AWS_REGION="us-east-1"
ECR_REPO="<AWS_ACCOUNT_ID>.dkr.ecr.$AWS_REGION.amazonaws.com/allstars-captsone-repo"
IMAGE_TAG="latest"

# Build Docker image
docker build -t allstars-captsone-repo:$IMAGE_TAG .

# Tag Docker image for ECR
docker tag allstars-captsone-repo:$IMAGE_TAG $ECR_REPO:$IMAGE_TAG

# Login to AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO

# Push image to ECR
docker push $ECR_REPO:$IMAGE_TAG

# Deploy with Terraform
cd iac
terraform init
terraform apply -auto-approve
cd ..

echo "Deployment complete."
