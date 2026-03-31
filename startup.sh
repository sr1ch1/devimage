#!/usr/bin/env bash

# get password from user
read -s -p "Password: " PW < /dev/tty

if [[ -z "$PWD" ]]; then
    echo "no password entered - aborting"
    exit 1
fi

GITHUB_USER=$(whoami)
git clone https://github.com/$GITHUB_USER/devimage.git
cd devimage

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
# Aktivate mise and install user dev tools
# ---------------------------------------------------------
curl -fsSL https://mise.run | sh
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
eval "$(mise activate bash)"
mise install
mise reshim

mise use -g go@latest
mise use -g node@latest
mise use -g deno@latest
mise use -g python@latest
mise use -g lua@5.1
mise use -g rust@latest
mise use -g ruby@latest
mise use -g java@latest
mise use -g julia@latest
mise use -g fzf@latest
mise use -g ripgrep@latest
mise use -g fd@latest
mise use -g dotnet@latest
eval "$(mise activate bash)"

# install composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=$HOME/.local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# ---------------------------------------------------------
# Install lazyvim prerequisites
# ---------------------------------------------------------

# install lazygit
~/.local/share/mise/installs/go/latest/bin/go install github.com/jesseduffield/lazygit@latest
mv ~/go/bin/* ~/.local/bin/
mv ~/go/pkg ~/.local
rm -rf go

# install tree-sitter cli
curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.7/tree-sitter-cli-linux-x64.zip -o tree-sitter-cli-linux-x64.zip
unzip tree-sitter-cli-linux-x64.zip
chmod +x tree-sitter
mv ./tree-sitter ~/.local/bin/
rm tree-sitter-cli-linux-x64.zip

# install tectonic
curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net |sh
mv tectonic ~/.local/bin/

# install mermaid
npm install -g @mermaid-js/mermaid-cli

# install neovim integration for node, ruby and python
npm install -g neovim
gem install neovim
python3 -m venv ~/.venvs/nvim
~/.venvs/nvim/bin/pip install pynvim

# install ast grep
npm install -g @ast-grep/cli

# install lazyvim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# add modifications
cp -af nvim/. ~/.config/nvim/

tail -f /dev/null
