#!/usr/bin/env bash
set -e

# Try to detect the URL used to fetch this script
detect_url() {
    # If the script was run directly (not via curl | sh)
    case "$0" in
        http*|https*)
            echo "$0"
            return
            ;;
    esac

    # If run via curl | sh, extract URL from parent process
    local parent_cmd
    parent_cmd=$(ps -o command= $PPID 2>/dev/null || true)

    # Look for a GitHub raw URL in the parent command
    echo "$parent_cmd" | grep -oE 'https://raw.githubusercontent.com[^ ]+' || true
}

SCRIPT_URL=$(detect_url)

if [ -z "$SCRIPT_URL" ]; then
    echo "ERROR: Could not detect script URL."
    echo "Please run via:"
    echo "  curl -fsSL https://raw.githubusercontent.com/<user>/<repo>/main/boot.sh | sh"
    exit 1
fi

echo "Detected script URL:"
echo "  $SCRIPT_URL"
echo

# Extract GitHub username
GITHUB_USER=$(echo "$SCRIPT_URL" | sed -n 's#.*raw.githubusercontent.com/\([^/]*\)/.*#\1#p')

if [ -z "$GITHUB_USER" ]; then
    echo "ERROR: Could not extract GitHub user from URL."
    exit 1
fi

DOTFILES_REPO="${GITHUB_USER}/dotfiles"

echo "Using GitHub user:   $GITHUB_USER"
echo "Using dotfiles repo: $DOTFILES_REPO"
echo

# Build image directly from GitHub
echo "Building devimage from GitHub..."
podman build \
  -t devimage \
  --build-arg DOTFILES_REPO="${DOTFILES_REPO}" \
  "https://github.com/${GITHUB_USER}/devimage.git"

echo "Starting dev container..."
podman run -it --name dev -e DOTFILES_REPO="${DOTFILES_REPO}" devimage
