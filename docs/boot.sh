#!/usr/bin/env bash
set -e

# --- Detect the URL used to fetch this script (works even with curl | sh) ---
detect_url() {
    case "$0" in
        http*|https*)
            echo "$0"
            return
            ;;
    esac

    # curl | sh → extract URL from parent process
    local parent_cmd
    parent_cmd=$(ps -o command= $PPID 2>/dev/null || true)

    # Look for GitHub Pages or raw URLs
    echo "$parent_cmd" | grep -oE 'https://[^ ]+' || true
}

SCRIPT_URL=$(detect_url)

if [ -z "$SCRIPT_URL" ]; then
    echo "ERROR: Could not detect script URL."
    echo "Please run via:"
    echo "  curl -fsSL https://sr1ch1.github.io/devimage/boot.sh | sh"
    exit 1
fi

echo "Detected script URL:"
echo "  $SCRIPT_URL"
echo

# --- Extract GitHub username ---
if echo "$SCRIPT_URL" | grep -q 'raw.githubusercontent.com'; then
    # https://raw.githubusercontent.com/<user>/<repo>/...
    GITHUB_USER=$(echo "$SCRIPT_URL" | sed -n 's#.*raw.githubusercontent.com/\([^/]*\)/.*#\1#p')
elif echo "$SCRIPT_URL" | grep -q 'github.io'; then
    # https://<user>.github.io/<repo>/boot.sh
    GITHUB_USER=$(echo "$SCRIPT_URL" | sed -n 's#https://\([^\.]*\)\.github\.io/.*#\1#p')
else
    GITHUB_USER=""
fi

if [ -z "$GITHUB_USER" ]; then
    echo "ERROR: Could not extract GitHub user from URL."
    exit 1
fi

DOTFILES_REPO="${GITHUB_USER}/dotfiles"

echo "Using GitHub user:   $GITHUB_USER"
echo "Using dotfiles repo: $DOTFILES_REPO"
echo

echo "Building devimage from GitHub..."
podman build \
  -t devimage \
  --build-arg DOTFILES_REPO="${DOTFILES_REPO}" \
  "https://github.com/${GITHUB_USER}/devimage.git"

echo "Starting dev container..."
podman run -it --name dev -e DOTFILES_REPO="${DOTFILES_REPO}" devimage
