#!/usr/bin/env bash
set -euo pipefail

# fetch users devimage repository
GITHUB_USER="${GITHUB_USER:-$(whoami)}"

echo "Found user: $GITHUB_USER"
cd ~/projects
# clone repo if it does not exist
if [ ! -d "devimage" ]; then
  if ! git clone "https://github.com/$GITHUB_USER/devimage.git"; then
    echo "ERROR: Failed to clone https://github.com/$GITHUB_USER/devimage.git" >&2
    echo "Please verify the GITHUB_USER is correct and the repository is public." >&2
    exit 1
  fi
fi
cd devimage || {
  echo "Failed to cd into devimage directory"
  exit 1
}

# ---------------------------------------------------------
# restore user config
# ---------------------------------------------------------

if [[ ! -f "bootstrap.kdbx" ]]; then
  echo "WARNING: bootstrap.kdbx not found. No personal configuration will be restored." >&2
else
  # source helper (runs in current shell and sets $PW)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  . "${SCRIPT_DIR}/get_password.sh"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "Password input failed (rc=$rc)" >&2
    exit 1
  fi

  . "${SCRIPT_DIR}/restore.sh" "$PW"
fi
echo "$PWD"

# ---------------------------------------------------------
# install and activate mise
# ---------------------------------------------------------
curl -fsSL https://mise.run | sh
eval "$(mise activate bash)"
if ! grep -q 'mise activate bash' ~/.bashrc 2>/dev/null; then
  echo 'eval "$(mise activate bash)"' >>~/.bashrc
fi
mise install

# install language and package managers serially (not stable otherwise)
mise use -g go@latest
mise use -g node@latest
mise use -g deno@latest
mise use -g python@latest
mise use -g lua@5.1
mise use -g rust@latest
mise use -g ruby@latest
mise use -g java@latest
mise use -g groovy@latest
mise use -g julia@latest
mise use -g dotnet@latest
mise use -g php@8.4

# Install productivity tools in one fast, parallel burst
mise use -g \
  aqua:nushell/nushell@latest \
  fzf@latest \
  ripgrep@latest \
  fd@latest \
  jq@latest \
  yq@latest \
  rtk@latest \
  lazygit@latest \
  zoxide@latest \
  zellij@latest \
  tree-sitter@latest \
  ast-grep@latest \
  typst@latest \
  bat@latest \
  starship@latest \
  eza@latest \
  nvim@latest \
  opencode@latest \
  claude@latest

if ! grep -q 'starship init bash' ~/.bashrc 2>/dev/null; then
  echo 'eval "$(starship init bash)"' >>~/.bashrc
fi

# install hermes-agent
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# Handle the complex 'niche' installs last
echo "Installing complex tools..."
mise use -g github:tectonic-typesetting/tectonic
mise use -g npm:@mermaid-js/mermaid-cli

if ! grep -q 'zoxide init bash' ~/.bashrc 2>/dev/null; then
  echo 'eval "$(zoxide init bash)"' >>~/.bashrc
fi
eval "$(mise activate bash)"

npm install -g neovim@latest
mise use -g gem:neovim
mise exec python@latest -- pip install pynvim

# nushell specific integrations
mkdir -p ~/.config/mise ~/.config/nushell
mise activate nu >~/.config/mise/activate.nu
starship init nu >~/.config/nushell/starship.nu

# ---------------------------------------------------------
# Install lazyvim
# ---------------------------------------------------------
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# add modifications
cp -af nvim/. ~/.config/nvim/

# install plugins before the first start
nvim --headless "+Lazy! sync" +qa

#curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME/.local/bin --filename=composer
