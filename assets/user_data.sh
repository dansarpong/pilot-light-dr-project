#!/bin/bash

# Update and install base packages
sudo DEBIAN_FRONTEND=noninteractive apt update -y && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
    curl \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    mysql-client \
    libmysqlclient-dev \
    default-libmysqlclient-dev \
    git

# Clone the application
cd /home/ubuntu
git clone https://github.com/dansarpong/flask-uploads-app.git
cd flask-uploads-app

# Install dependencies
sudo pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/flask-uploads.service > /dev/null << 'EOF'
[Unit]
Description=Flask Uploads Application
After=network.target

[Service]
User=root
WorkingDirectory=/home/ubuntu/flask-uploads-app
ExecStart=/usr/local/bin/flask run --host=0.0.0.0 --port=80
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
sudo systemctl daemon-reload
sudo systemctl enable flask-uploads
sudo systemctl start flask-uploads

# Cleanup
sudo DEBIAN_FRONTEND=noninteractive apt clean -y
sudo rm -rf /var/lib/apt/lists/*
