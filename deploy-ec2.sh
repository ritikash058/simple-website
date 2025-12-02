#!/bin/bash

# Exit on error
set -e

# Configuration
AWS_REGION="ap-south-1"
ECR_REPO_NAME="simple-website"
IMAGE_TAG="latest"
CONTAINER_NAME="simple-website"
PORT=80

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting deployment on EC2...${NC}"

# Get AWS account ID from instance metadata
AWS_ACCOUNT_ID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '(?<="accountId" : ")[^"]*')
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}Failed to get AWS account ID from metadata.${NC}"
    exit 1
fi

ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
IMAGE_URI="${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "Using image: $IMAGE_URI"

# Login to ECR
echo -e "${GREEN}Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Stop and remove existing container if running
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo -e "${GREEN}Stopping existing container...${NC}"
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi

# Remove old image to save space
echo -e "${GREEN}Cleaning up old images...${NC}"
docker system prune -f

# Pull latest image
echo -e "${GREEN}Pulling latest image from ECR...${NC}"
docker pull ${IMAGE_URI}

# Run new container
echo -e "${GREEN}Starting new container...${NC}"
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:80 \
    --restart unless-stopped \
    ${IMAGE_URI}

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${GREEN}Container is running on port ${PORT}${NC}"
echo -e "${GREEN}Check your website at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)${NC}"