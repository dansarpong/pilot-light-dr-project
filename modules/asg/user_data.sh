#!/bin/bash

# Update and install base packages
apt-get update
apt-get install -y \
    curl \
    wget \
    unzip \
    awscli \
    cloud-init

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent


# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
rm amazon-cloudwatch-agent.deb