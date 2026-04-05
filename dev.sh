#!/usr/bin/env bash

set -e

CONTAINER_NAME="dev"
IMAGE_NAME="dev"

# --- Detect Container Engine ---
if command -v podman &> /dev/null; then
    DOCKER_BIN="podman"
elif command -v docker &> /dev/null; then
    DOCKER_BIN="docker"
else
    echo "Error: Neither podman nor docker found in PATH."
    exit 1
fi

# --- check input ---
if [ -z "$1" ]; then
    echo "Usage: $0 <GITHUB_USER>"
    exit 1
fi

GITHUB_USER="$1"
HOST_DIR="$HOME/projects"
CONTAINER_DIR="/home/$GITHUB_USER/projects"

# check if container exists in a portable way
if $DOCKER_BIN ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then

    # check if container runs
    if ! $DOCKER_BIN ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        # Läuft nicht → starten
        $DOCKER_BIN start "$CONTAINER_NAME"
    fi

    # logon to the container
    $DOCKER_BIN exec -it \
        -u "$GITHUB_USER" \
        -w "$CONTAINER_DIR" \
        "$CONTAINER_NAME" bash
    exit 0
else
    echo "Using engine: $DOCKER_BIN"
    echo "Building image: '$IMAGE_NAME'..."

    $DOCKER_BIN build \
        --build-arg GITHUB_USER="$GITHUB_USER" \
        -t "$IMAGE_NAME" .

    $DOCKER_BIN run -it \
        --hostname "$CONTAINER_NAME" \
        --name "$CONTAINER_NAME" \
        --volume "$HOST_DIR:$CONTAINER_DIR" \
        "$IMAGE_NAME"
    exit 0
fi
