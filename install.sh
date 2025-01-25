#!/bin/bash

# Exit script on error
set -e

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install prerequisites
echo "Installing prerequisites..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
else
    echo "Docker is already installed."
fi

# Add the current user to the Docker group
echo "Adding user $(whoami) to the docker group..."
sudo usermod -aG docker $(whoami)

# Install Docker Compose (standalone)
echo "Installing Docker Compose (standalone)..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Check if Portainer is installed
if sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
    echo "Portainer is already installed. Checking for updates..."
    
    # Get the latest Portainer version
    LATEST_PORTAINER_VERSION=$(curl -s https://hub.docker.com/v2/repositories/portainer/portainer-ce/tags?page_size=1 | jq -r '.results[0].name')
    
    # Get the currently installed Portainer version
    CURRENT_PORTAINER_VERSION=$(sudo docker inspect portainer | jq -r '.[0].Config.Image' | cut -d ':' -f 2)

    if [ "$LATEST_PORTAINER_VERSION" != "$CURRENT_PORTAINER_VERSION" ]; then
        echo "A new version of Portainer is available. Updating to version $LATEST_PORTAINER_VERSION..."
        sudo docker stop portainer
        sudo docker rm portainer
        sudo docker pull portainer/portainer-ce:$LATEST_PORTAINER_VERSION
        sudo docker run -d \
          --name=portainer \
          --restart=always \
          -p 8000:8000 -p 9000:9000 \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -v portainer_data:/data \
          portainer/portainer-ce:$LATEST_PORTAINER_VERSION
        echo "Portainer has been updated to version $LATEST_PORTAINER_VERSION."
    else
        echo "Portainer is already up to date (version $CURRENT_PORTAINER_VERSION)."
    fi
else
    echo "Portainer is not installed. Installing the latest version..."
    sudo docker volume create portainer_data
    sudo docker run -d \
      --name=portainer \
      --restart=always \
      -p 8000:8000 -p 9000:9000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
    echo "Portainer has been successfully installed!"
fi

# Final message
echo "Docker and Portainer setup is complete!"
echo "You can access Portainer at: http://<your-pi-ip>:9000"
echo "Please reboot your system to apply changes."
