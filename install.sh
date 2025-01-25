#!/bin/bash

# Exit script on error
set -e

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing prerequisites..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

echo "Adding user $(whoami) to the docker group..."
sudo usermod -aG docker $(whoami)

echo "Installing Docker Compose (standalone)..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Pulling Portainer image..."
sudo docker volume create portainer_data
sudo docker run -d \
  --name=portainer \
  --restart=always \
  -p 8000:8000 -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "Docker and Portainer have been successfully installed!"
echo "You can access Portainer at: http://<your-pi-ip>:9000"
echo "Please reboot your system to apply changes."
