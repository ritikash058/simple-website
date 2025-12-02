#!/bin/bash

# One-time setup script for EC2 instance
echo "Setting up EC2 instance for Docker deployments..."

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y \
    docker.io \
    awscli \
    curl

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu to docker group
sudo usermod -aG docker ubuntu

# Configure AWS CLI (if not already configured)
if [ ! -f ~/.aws/credentials ]; then
    echo "AWS CLI not configured. Please configure it with:"
    echo "aws configure"
    echo "Or attach an IAM role with ECR permissions to this EC2 instance"
fi

# Create deployment directory
mkdir -p ~/deployments
cd ~/deployments

# Make scripts executable
chmod +x deploy-ec2.sh

echo "Setup complete! Please logout and login again for group changes to take effect."
echo "Then run: ./deploy-ec2.sh"