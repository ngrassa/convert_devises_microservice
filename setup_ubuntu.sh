#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="convert_devises_microservices"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/.git" ]; then
  echo ">>> Running from existing repository at $SCRIPT_DIR"
  cd "$SCRIPT_DIR"
elif [ -d "$REPO_NAME/.git" ]; then
  echo ">>> Repository already exists, skipping clone"
  cd "$REPO_NAME"
else
  echo ">>> Cloning repository"
  git clone https://github.com/ngrassa/convert_devises_microservices.git "$REPO_NAME"
  cd "$REPO_NAME"
fi

# Detect sudo availability (skip when already root)
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

PROJECT_DIR="$(pwd)"

echo ">>> Updating package lists"
$SUDO apt-get update -y

# Base packages required in every case
PACKAGES=(python3 python3-pip python3-venv docker.io)
COMPOSE_CMD="docker compose"
USE_PIP_COMPOSE=0

echo ">>> Checking for docker compose package availability"
if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  PACKAGES+=(docker-compose-plugin)
  echo "docker-compose-plugin found in apt repositories."
else
  echo "docker-compose-plugin not available. Trying docker-compose package."
  if apt-cache show docker-compose >/dev/null 2>&1; then
    PACKAGES+=(docker-compose)
    COMPOSE_CMD="docker-compose"
    echo "docker-compose package will be installed."
  else
    echo "Neither docker-compose-plugin nor docker-compose available; falling back to pip installation."
    USE_PIP_COMPOSE=1
    COMPOSE_CMD="$HOME/.local/bin/docker-compose"
  fi
fi

echo ">>> Installing packages: ${PACKAGES[*]}"
$SUDO apt-get install -y "${PACKAGES[@]}"

if [ "$USE_PIP_COMPOSE" -eq 1 ]; then
  echo ">>> Installing docker-compose via pip for current user"
  python3 -m pip install --user --upgrade pip
  python3 -m pip install --user docker-compose
  # Ensure docker-compose is on PATH for the current session
  export PATH="$HOME/.local/bin:$PATH"
fi

echo ">>> Ensuring Docker service is running"
$SUDO systemctl enable --now docker

if ! groups "$USER" | grep -q "\bdocker\b"; then
  echo ">>> Adding $USER to docker group (you may need to re-login afterwards)"
  $SUDO usermod -aG docker "$USER"
  echo ">>> Apply new group with: newgrp docker"
fi

echo ">>> Building and starting containers"
cd "$PROJECT_DIR"
# docker-compose.yml must be in the current directory for these commands
$COMPOSE_CMD version
$COMPOSE_CMD up --build -d

echo ">>> Done. Frontend: http://localhost:8000 | Convert API: http://localhost:5001/convert | Rate API: http://localhost:5000/rate"
