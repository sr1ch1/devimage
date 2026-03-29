#!/usr/bin/env bash
set -e

# --- Detect the URL used to fetch this script (works even with curl | sh) ---
detect_url() {
    # Case 1: Script executed directly (rare)
    case "$0" in
        http*|https*)
            echo "$0"
            return
            ;;
    esac

    # Case 2: curl | sh → extract URL from parent process
    local parent_cmd
    parent_cmd=$(ps -o command= $PPID 2>/dev/null || true)

    # Accept ANY https://... URL
    echo "$parent_cmd" | grep -oE 'https://[^ ]+' || true
}

SCRIPT_URL=$(detect_url)

if [ -z "$SCRIPT_URL" ]; then
    echo "ERROR: Could not detect script URL."
    exit 1
fi

echo "Detected script URL:"
echo "  $SCRIPT_URL"
echo

# --- Extract GitHub user + repo from GitHub Pages URL ---
# Format: https://<user>.github.io/<repo>/boot.sh

if echo "$SCRIPT_URL" | grep -q 'github.io'; then
    GITHUB_USER=$(echo "$SCRIPT_URL" | sed -n 's#https://\([^\.]*\)\.github\.io/.*#\1#p')
    GITHUB_REPO=$(echo "$SCRIPT_URL" | sed -n 's#https://[^/]*/\([^/]*\)/.*#\1#p')
else
    echo "ERROR: Unsupported script URL format."
    exit 1
fi

if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_REPO" ]; then
    echo "ERROR: Could not extract GitHub user or repo from URL."
    exit 1
fi

DOTFILES_REPO="${GITHUB_USER}/dotfiles"

echo "Using GitHub user:   $GITHUB_USER"
echo "Using devimage repo: $GITHUB_REPO"
echo "Using dotfiles repo: $DOTFILES_REPO"
echo

# --- Build image directly from GitHub (no git needed) ---
echo "Building devimage from GitHub..."
podman build \
  -t devimage \
  --build-arg DOTFILES_REPO="${DOTFILES_REPO}" \
  "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

# --- Run container ---
echo "Starting dev container..."
podman run -it --name dev -e DOTFILES_REPO="${DOTFILES_REPO}" devimage
