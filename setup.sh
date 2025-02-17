#!/bin/bash

set -e  # Exit immediately if a command fails
set -u  # Treat unset variables as errors
set -o pipefail  # Exit if any command in a pipeline fails

echo "🚀 Starting system setup and package installation..."

# ---------------------
# 1️⃣ Update and Upgrade System Packages
# ---------------------
echo "📦 Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean

# ---------------------
# 2️⃣ Install GitHub CLI if not installed
# ---------------------
if ! command -v gh &>/dev/null; then
    echo "🛠 Installing GitHub CLI..."
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y
else
    echo "✅ GitHub CLI is already installed."
fi

# ---------------------
# 3️⃣ Install Docker and Docker Compose if not installed
# ---------------------
if ! command -v docker &>/dev/null; then
    echo "🐳 Installing Docker and Docker Compose..."

    # Remove conflicting packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || true
    done

    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker and related packages
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "✅ Docker is already installed."
fi

# ---------------------
# 4️⃣ Add Current User to Docker Group
# ---------------------
if ! groups $USER | grep -q docker; then
    echo "🔑 Adding current user to the Docker group..."
    sudo usermod -aG docker ${USER} && newgrp docker
    echo "🔄 Restarting Docker service..."
    sudo systemctl restart docker
else
    echo "✅ User is already in the Docker group."
fi

# ---------------------
# 5️⃣ Install Bash & jq if not installed
# ---------------------
echo "🔍 Checking for Bash and jq installation..."
sudo apt-get install -y bash jq

# ---------------------
# 6️⃣ Install Rclone if not installed
# ---------------------
if ! command -v rclone &>/dev/null; then
    echo "☁️ Installing Rclone..."
    curl https://rclone.org/install.sh | sudo bash
else
    echo "✅ Rclone is already installed."
fi

# ---------------------
# 7️⃣ Install Infisical CLI if not installed
# ---------------------
if ! command -v infisical &>/dev/null; then
    echo "🔑 Installing Infisical CLI..."
    curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
    sudo apt-get update && sudo apt-get install -y infisical
else
    echo "✅ Infisical CLI is already installed."
fi

echo "🎉 System setup and package installation complete!"
