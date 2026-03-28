FROM ubuntu:24.04

# Allow passing a GitHub repo in the form "user/repo"
ARG DOTFILES_REPO
ENV DOTFILES_REPO="${DOTFILES_REPO}"

# Basic tools for Neovim + building runtimes via mise
RUN apt-get update && apt-get install -y \
    curl git unzip build-essential cmake \
    ripgrep fd-find python3 python3-pip tmux \
    libssl-dev zlib1g-dev libreadline-dev libffi-dev \
    keepassxc \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Neovim (latest stable)
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz \
    && tar xzf nvim-linux64.tar.gz \
    && mv nvim-linux64 /opt/nvim \
    && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && rm nvim-linux64.tar.gz

# Python support
RUN pip3 install pynvim

# Install mise
RUN curl -fsSL https://mise.run | sh

# Add mise to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create entrypoint.sh inline
RUN cat << 'EOF' > /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

# DOTFILES_REPO must be provided as "user/repo"
if [ -z "$DOTFILES_REPO" ]; then
    echo "ERROR: DOTFILES_REPO was not provided."
    echo "Please pass it as:"
    echo "  podman run -e DOTFILES_REPO=user/repo devimage"
    exit 1
fi

# Convert "user/repo" → full GitHub URL
REPO_URL="https://github.com/${DOTFILES_REPO}"

echo "Using dotfiles repo: $REPO_URL"

# 1. initialize chezmoi if not done already
if [ ! -d "/root/.local/share/chezmoi" ]; then
    echo "Initializing chezmoi from ${REPO_URL}..."
    chezmoi init "${REPO_URL}"
fi

# 2. apply configuration including run_once scripts
echo "Applying chezmoi configuration..."
chezmoi apply --verbose

# If inside tmux already, just run nvim
if [ -n "$TMUX" ]; then
    exec nvim "$@"
fi

# If a tmux session exists, attach to it
if tmux has-session -t dev 2>/dev/null; then
    exec tmux attach -t dev
fi

# Otherwise create a new session running nvim
exec tmux new -s dev "nvim"
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
