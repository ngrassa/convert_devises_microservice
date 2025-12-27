#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="convert_devises_microservice"
GIT_URL="https://github.com/ngrassa/convert_devises_microservice.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/.git" ]; then
  echo ">>> Running from existing repository at $SCRIPT_DIR"
  cd "$SCRIPT_DIR"
elif [ -d "$REPO_NAME/.git" ]; then
  echo ">>> Repository already exists, skipping clone"
  cd "$REPO_NAME"
else
  echo ">>> Cloning repository"
  git clone "$GIT_URL" "$REPO_NAME"
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
PACKAGES=(python3 python3-pip python3-venv docker.io curl ca-certificates)
COMPOSE_VERSION="v2.29.2"
INSTALL_COMPOSE_BINARY=0

echo ">>> Checking for docker compose plugin availability"
if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  PACKAGES+=(docker-compose-plugin)
  echo "docker-compose-plugin found in apt repositories."
else
  echo "docker-compose-plugin not available. A standalone Docker Compose v2 binary will be installed."
  INSTALL_COMPOSE_BINARY=1
fi

echo ">>> Installing packages: ${PACKAGES[*]}"
$SUDO apt-get install -y "${PACKAGES[@]}"

if [ "$INSTALL_COMPOSE_BINARY" -eq 1 ]; then
  echo ">>> Installing Docker Compose v2 binary (${COMPOSE_VERSION})"
  DEST_DIR="/usr/local/lib/docker/cli-plugins"
  $SUDO mkdir -p "$DEST_DIR"
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64) COMPOSE_ARCH="x86_64" ;;
    aarch64|arm64) COMPOSE_ARCH="aarch64" ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
  $SUDO curl -sSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" -o "$DEST_DIR/docker-compose"
  $SUDO chmod +x "$DEST_DIR/docker-compose"
fi

echo ">>> Ensuring Docker service is running"
$SUDO systemctl enable --now docker

if ! groups "$USER" | grep -q "\bdocker\b"; then
  echo ">>> Adding $USER to docker group (you may need to re-login afterwards)"
  $SUDO usermod -aG docker "$USER"
  echo ">>> Apply new group with: newgrp docker"
fi

DOCKER_CMD="docker"
COMPOSE_CMD="$DOCKER_CMD compose"

echo ">>> Verifying Docker access"
if ! $DOCKER_CMD info >/dev/null 2>&1; then
  if [ -n "$SUDO" ] && $SUDO docker info >/dev/null 2>&1; then
    echo ">>> Docker requires elevated privileges in this session; falling back to sudo for Compose commands"
    DOCKER_CMD="$SUDO docker"
    COMPOSE_CMD="$DOCKER_CMD compose"
  else
    echo ">>> Docker daemon is not accessible. Check that the service is running and that your user has permissions."
    exit 1
  fi
fi

if ! $COMPOSE_CMD version >/dev/null 2>&1; then
  echo ">>> Docker Compose v2 is not available. Please check the installation steps above."
  exit 1
fi

echo ">>> Building and starting containers"
cd "$PROJECT_DIR"
# docker-compose.yml must be in the current directory for these commands
$COMPOSE_CMD version
$COMPOSE_CMD up --build -d

echo ">>> Done. Frontend: http://localhost:8000 | Convert API: http://localhost:5001/convert | Rate API: http://localhost:5000/rate"
