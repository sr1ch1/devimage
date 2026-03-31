# get password from user
read -s -p "Password: " PW < /dev/tty

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
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
mise install
mise reshim


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
python3 -m pip install --user pynvim

# install ast grep
npm install -g @ast-grep/cli


bash

