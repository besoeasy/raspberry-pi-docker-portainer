#!/bin/bash

# Exit script on error
set -e

echo "Starting system update and Docker environment setup..."
echo "-----------------------------------------------------"

# Update system packages
echo "1. Updating system packages..."
sudo apt update && sudo apt upgrade -y
echo "System packages updated successfully."

# Install prerequisites including jq for JSON parsing
echo "2. Installing prerequisites (curl, jq)..."
sudo apt install -y curl jq
echo "Prerequisites installed successfully."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "3. Docker not found. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    echo "Docker installed successfully. Version: $(docker --version)."
else
    echo "3. Docker is already installed. Version: $(docker --version)."
fi

# Add current user to Docker group to avoid sudo
echo "4. Adding user '$(whoami)' to the Docker group..."
sudo usermod -aG docker $(whoami)
echo "User '$(whoami)' added to Docker group. Note: A reboot or re-login is required for this change to take effect."

# Install Docker Compose (standalone)
echo "5. Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
fi
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$ARCH" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "Docker Compose installed successfully. Version: $(docker-compose --version)."

# Deploy/Update Portainer
echo "6. Setting up Portainer (Docker management GUI)..."
if sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
    echo "Checking for Portainer updates..."
    LATEST_PORTAINER_VERSION=$(curl -s https://hub.docker.com/v2/repositories/portainer/portainer-ce/tags?page_size=1 | jq -r '.results[0].name')
    CURRENT_PORTAINER_VERSION=$(sudo docker inspect portainer &>/dev/null && sudo docker inspect portainer | jq -r '.[0].Config.Image' | cut -d ':' -f 2 || echo "unknown")

    if [ "$LATEST_PORTAINER_VERSION" != "$CURRENT_PORTAINER_VERSION" ]; then
        echo "Updating Portainer from v$CURRENT_PORTAINER_VERSION to v$LATEST_PORTAINER_VERSION..."
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
        echo "Portainer updated to v$LATEST_PORTAINER_VERSION successfully."
    else
        echo "Portainer is already up to date (v$CURRENT_PORTAINER_VERSION)."
    fi
else
    echo "Installing Portainer for the first time..."
    sudo docker volume create portainer_data
    sudo docker run -d \
      --name=portainer \
      --restart=always \
      -p 8000:8000 -p 9000:9000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data \
      portainer/portainer-ce:latest
    echo "Portainer installed successfully. Access it at: http://$(hostname -I | awk '{print $1}'):9000"
fi

# Final instructions
echo "-----------------------------------------------------"
echo "Setup completed successfully!"
echo "To access Portainer, visit: http://$(hostname -I | awk '{print $1}'):9000"
echo "Please reboot your system or log out and back in for Docker group changes to take effect."
