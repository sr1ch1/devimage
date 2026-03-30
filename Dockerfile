# ---------------------------------------------------------
# Ubuntu Development Environment
# ---------------------------------------------------------
FROM ubuntu:24.04

ARG GITHUB_USER
ENV GITHUB_USER="${GITHUB_USER}"


# basic dev tools and the latest version of keepassxc
RUN apt-get update && \
    apt-get install -y \
        software-properties-common \
        curl git unzip build-essential cmake \
        ripgrep fd-find python3 python3-pip tmux \
        libssl-dev zlib1g-dev libreadline-dev libffi-dev && \
    add-apt-repository -y ppa:phoerious/keepassxc && \
    apt-get update && \
    apt-get install -y keepassxc && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Neovim (latest stable)
RUN curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz \
    && tar xzf nvim-linux-x86_64.tar.gz \
    && mv nvim-linux-x86_64 /opt/nvim \
    && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && rm nvim-linux-x86_64.tar.gz

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# ---------------------------------------------------------
# Create a non-root user for development
# ---------------------------------------------------------
ARG GITHUB_USER
ENV GITHUB_USER="${GITHUB_USER}"

RUN test -n "$GITHUB_USER" || (echo "GITHUB_USER is empty!" && exit 1) \
    && useradd -m -s /bin/bash "$GITHUB_USER" \
    && echo "$GITHUB_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $GITHUB_USER
ENV HOME=/home/$GITHUB_USER
WORKDIR $HOME

# Install mise
ENV PATH="/home/${GITHUB_USER}/.local/bin:${PATH}"
RUN curl -fsSL https://mise.run | sh \
    && echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc

# Add mise to PATH
ENV PATH="/root/.local/bin:${PATH}"

# ---------------------------------------------------------
# Create entrypoint.sh inline
# ---------------------------------------------------------
USER root
RUN cat << 'EOF_ENTRYPOINT' > /usr/local/bin/entrypoint.sh
#!/usr/bin/env bash

mkdir -p ~/.ssh

cat << 'EOF_SSHCONFIG' > ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_github
EOF_SSHCONFIG

curl -fsSL \
  "https://raw.githubusercontent.com/${GITHUB_USER}/devimage/main/bootstrap.kdbx" \
  -o bootstrap.kdbx

read -s -p "Password: " PW < /dev/tty
printf '%s\n' "$PW" | keepassxc-cli show -q -a Notes -s bootstrap.kdbx "ssh/id_github" > ~/.ssh/id_github.pub

printf '%s\n' "$PW" \
  | keepassxc-cli attachment-export bootstrap.kdbx "ssh/id_github" id_github ~/.ssh/id_github

chmod 600 ~/.ssh/id_github.pub
chmod 600 ~/.ssh/id_github

git_email="$(
  printf '%s\n' "$PW" \
    | keepassxc-cli show -q -a UserName -s bootstrap.kdbx "git/email"
)"

git_name="$(
  printf '%s\n' "$PW" \
    | keepassxc-cli show -q -a UserName -s bootstrap.kdbx "git/name"
)"

mkdir -p ~/.local/share/keepass
mv bootstrap.kdbx ~/.local/share/keepass

git config --global user.email "$git_email"
git config --global user.name "$git_name"
git config --global --add safe.directory '*'
ssh-keyscan github.com >> ~/.ssh/known_hosts

REPO_URL="git@github.com:${GITHUB_USER}/dotfiles.git"
echo "Using dotfiles repo: $REPO_URL"

# initialize chezmoi if not done already
if [ ! -d "~/.local/share/chezmoi" ]; then
    echo "Initializing chezmoi from ${REPO_URL}..."
    chezmoi init "${REPO_URL}"
fi

# apply configuration including run_once scripts
echo "Applying chezmoi configuration..."
chezmoi apply

bash
EOF_ENTRYPOINT

RUN chmod +x /usr/local/bin/entrypoint.sh

USER $GITHUB_USER
WORKDIR /home/$GITHUB_USER/workspace

# Default command
CMD [ "/usr/local/bin/entrypoint.sh" ]
