#!/usr/bin/env bash

set -e

CONTAINER_NAME="dev"
IMAGE_NAME="dev"

# --- check input ---
if [ -z "$1" ]; then
    echo "Usage: $0 <GITHUB_USER>"
    exit 1
fi

GITHUB_USER="$1"

# --- Check if container exists ---
if podman container exists "$CONTAINER_NAME"; then

    # --- Check if container runs ---
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        podman exec -it "$CONTAINER_NAME" bash
        exit 0
    else
        podman start "$CONTAINER_NAME"
        podman exec -it "$CONTAINER_NAME" bash
        exit 0
    fi
else
    echo "Building image: '$IMAGE_NAME'..."

    podman build \
        --build-arg GITHUB_USER="$GITHUB_USER" \
        -t "$IMAGE_NAME" .

    podman run -it \
        --hostname "$CONTAINER_NAME" \
        --name "$CONTAINER_NAME" \
        "$IMAGE_NAME"
    exit 0
fi
