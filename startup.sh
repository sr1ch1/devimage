#!/usr/bin/env bash

# fetch users devmage repository
GITHUB_USER=$(whoami)
git clone https://github.com/$GITHUB_USER/devimage.git
cd devimage

# ---------------------------------------------------------
# get password from user
# ---------------------------------------------------------
while true; do
    # get password from user
    read -s -p "Password: " PW < /dev/tty
    echo

    if [[ -z "$PW" ]]; then
        echo "No password entered – aborting"
        exit 1
    fi

    # Test password (with 'ls')
    if printf '%s\n' "$PW" | keepassxc-cli ls bootstrap.kdbx dir >/dev/null 2>&1; then
        echo "Password OK"
        break
    else
        echo "Wrong password – try again"
    fi
done

# ---------------------------------------------------------
# Extract folders from keepass db
# ---------------------------------------------------------
  DIRS=$(printf '%s\n' "$PW" \
    | keepassxc-cli ls bootstrap.kdbx dir)

while IFS= read -r item; do

  path="${item/#\~/$HOME}"
  printf '%s\n' "$path"
  mkdir -p -- "$path"

  printf '%s\n' "$PW" \
    | keepassxc-cli attachment-export bootstrap.kdbx "dir/$item" data.tar.gz data.tar.gz
  tar -xzf data.tar.gz -C $path
  rm data.tar.gz
done <<< "$DIRS"

# add github to known hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts

# ---------------------------------------------------------
# install and activate mise
# ---------------------------------------------------------
curl -fsSL https://mise.run | sh
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
eval "$(mise activate bash)"
mise install

mise use -g neovim@0.11.5

# install language and package managers
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

# install productivity tools
mise use -g fzf@latest
mise use -g ripgrep@latest
mise use -g fd@latest
mise use -g lazygit@latest
mise use -g tree-sitter@latest
mise use -g ast-grep@latest
mise use -g github:tectonic-typesetting/tectonic
mise use -g npm:@mermaid-js/mermaid-cli

eval "$(mise activate bash)"
mise use -g npm:neovim
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

tail -f /dev/null
