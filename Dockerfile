FROM debian:12

# Allow passing a GitHub repo in the form "user/repo"
ARG DOTFILES_REPO
ENV DOTFILES_REPO="${DOTFILES_REPO}"

# Basic tools for Neovim + building runtimes via mise
RUN apt-get update && apt-get install -y \
    curl git unzip build-essential cmake \
    ripgrep fd-find python3 python3-pip tmux \
    libssl-dev zlib1g-dev libreadline-dev libffi-dev \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Neovim (latest stable)
RUN set -eux; \
    url=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
      | grep browser_download_url \
      | grep 'nvim-linux-x86_64.tar.gz' \
      | sed -E 's/.*"([^"]+)".*/\1/'); \
    echo "Downloading: $url"; \
    curl -fL -o nvim.tar.gz "$url"; \
    tar xzf nvim.tar.gz; \
    mv nvim-linux-* /opt/nvim; \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim; \
    rm nvim.tar.gz

# Python support
RUN pip3 install --break-system-packages pynvim
RUN apt-get update && apt-get install -y python3-venv
RUN python3 -m venv /opt/py \
    && /opt/py/bin/pip install pykeepass

# Install mise
RUN curl -fsSL https://mise.run | sh

# Add mise to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create entrypoint.sh inline
RUN cat << 'EOF_ENTRYPOINT' > /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

GITHUB_USER="${DOTFILES_REPO%%/*}"

curl -fsSL \
  "https://github.com/${GITHUB_USER}/devimage/raw/refs/heads/main/bootstrap.kdbx" \
  -o /tmp/bootstrap.kdbx

# --- ask for password ---
echo -n "KeePass password: "
read -s KPPASS
echo

python3 <<EOF_EXTRACT
from pykeepass import PyKeePass
import sys

password = sys.stdin.read().strip()
kp = PyKeePass('/tmp/bootstrap.kdbx', password=password)

entry = kp.find_entries(path='ssh/id_github', first=True)
attachment = entry.attachments[0]

with open('/tmp/id_github', 'wb') as f:
    f.write(attachment.data)
EOF_EXTRACT


PUBKEY=$(python3 <<EOF_EXTRACT
from pykeepass import PyKeePass
import sys

password = sys.stdin.read().strip()
kp = PyKeePass('/tmp/bootstrap.kdbx', password=password)

entry = kp.find_entries(path='ssh/id_github', first=True)
print(entry.notes)
EOF_EXTRACT
)

# --- write SSH files ---
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "$PUBKEY" > ~/.ssh/id_github.pub
mv /tmp/id_github ~/.ssh/id_github
chmod 600 ~/.ssh/id_github ~/.ssh/id_github.pub

# --- write SSH config ---
cat > ~/.ssh/config << 'EOF_SSHCONFIG'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes
EOF_SSHCONFIG

chmod 600 ~/.ssh/config

# --- start ssh-agent ---
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_github

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
EOF_ENTRYPOINT

RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
