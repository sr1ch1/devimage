#!/usr/bin/env bash

# fetch users devmage repository
GITHUB_USER=$(whoami)
git clone https://github.com/$GITHUB_USER/devimage.git
cd devimage

# ---------------------------------------------------------
# dehydrate user config
# ---------------------------------------------------------
. ./dehydrate.sh GITHUB_USER

# ---------------------------------------------------------
# install and activate mise
# ---------------------------------------------------------
curl -fsSL https://mise.run | sh
echo 'eval "$(mise activate bash)"' >>~/.bashrc
eval "$(mise activate bash)"
mise install

mise use -g neovim@0.11.5

# install language and package managers serially (not stable otherwise)
mise use -g go@latest
mise use -g node@latest
mise use -g deno@latest
mise use -g python@latest
mise use -g lua@5.1
mise use -g rust@latest
mise use -g ruby@latest
mise use -g java@latest
mise use -g julia@latest
mise use -g dotnet@latest
mise use -g php@8.4

# Install productivity tools in one fast, parallel burst
mise use -g \
  fzf@latest \
  ripgrep@latest \
  fd@latest \
  lazygit@latest \
  zoxide@latest \
  zellij@latest \
  tree-sitter@latest \
  ast-grep@latest \
  typst@latest

# Handle the complex 'niche' installs last
echo "Installing complex tools..."
mise use -g github:tectonic-typesetting/tectonic
mise use -g npm:@mermaid-js/mermaid-cli

echo 'eval "$(zoxide init bash)"' >>~/.bashrc
eval "$(mise activate bash)"

npm install -g neovim
mise use -g gem:neovim
mise exec python@latest -- pip install pynvim

curl -sS https://getcomposer.org/installer | php -- --install-dir=$HOME/.local/bin --filename=composer
mise reshim

# ---------------------------------------------------------
# Install lazyvim
# ---------------------------------------------------------
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# add modifications
cp -af nvim/. ~/.config/nvim/

# install plugins before the first start
nvim --headless "+Lazy! sync" +MasonToolsInstallSync +qa

tail -f /dev/null
