# Raspberry Pi Docker & Portainer Installer

Easily set up Docker and Portainer on your Raspberry Pi with a single script.

## Features

- Installs Docker and its dependencies.
- Adds your user to the Docker group.
- Installs the latest Docker Compose.
- Deploys Portainer CE for container management.

## Quick Install

Run this one-liner to install everything automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/besoeasy/raspberry-pi-docker-portainer/refs/heads/main/install.sh | sudo bash
```

## Access Portainer

After installation, access Portainer at:  
**`http://<your-pi-ip>:9000`**

Find your Pi’s IP using:

```bash
hostname -I
```

## Requirements

- Raspberry Pi with a Debian-based OS.
- User with `sudo` privileges.
- Internet connection.

## Contributing

Feel free to open issues or submit pull requests to improve this project.
