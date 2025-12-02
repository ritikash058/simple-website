#!/bin/bash

# Exit on error
set -e

# Configuration
AWS_REGION="ap-south-1"
ECR_REPO_NAME="simple-website"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting deployment to AWS ECR...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install it first.${NC}"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}Failed to get AWS account ID. Check your AWS credentials.${NC}"
    exit 1
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Repository: $ECR_REPO_NAME"

# Build Docker image
echo -e "${GREEN}Building Docker image...${NC}"
docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} .

# Tag the image for ECR
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
echo -e "${GREEN}Tagging image for ECR...${NC}"
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${ECR_REPOSITORY}:${IMAGE_TAG}

# Login to ECR
echo -e "${GREEN}Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Create repository if it doesn't exist
if ! aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} > /dev/null 2>&1; then
    echo -e "${GREEN}Creating ECR repository...${NC}"
    aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}
fi

# Push image to ECR
echo -e "${GREEN}Pushing image to ECR...${NC}"
docker push ${ECR_REPOSITORY}:${IMAGE_TAG}

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}Image URI: ${ECR_REPOSITORY}:${IMAGE_TAG}${NC}"