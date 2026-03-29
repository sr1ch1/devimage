#!/usr/bin/env bash
set -e

# --- Required: GitHub user must be provided ---
if [ -z "$GITHUB_USER" ]; then
  echo "ERROR: GITHUB_USER is not set."
  echo
  echo "Use:"
  echo "  GITHUB_USER=<user> bash -c \"\$(curl -fsSL https://<user>.github.io/devimage/boot.sh)\""
  exit 1
fi

GITHUB_REPO="${GITHUB_REPO:-devimage}"
DOTFILES_REPO="${DOTFILES_REPO:-${GITHUB_USER}/dotfiles}"

echo "Using GitHub user:   $GITHUB_USER"
echo "Using devimage repo: $GITHUB_REPO"
echo "Using dotfiles repo: $DOTFILES_REPO"
echo

# Build image directly from GitHub
podman build \
  -t devimage \
  --build-arg DOTFILES_REPO="${DOTFILES_REPO}" \
  "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

# Run container
podman run -it --name dev -e DOTFILES_REPO="${DOTFILES_REPO}" devimage
