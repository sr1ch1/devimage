#!/bin/bash

DB="bootstrap.kdbx"
ENTRY="user"
ATTACHMENT_NAME="home.tar.gz"
SOURCE_FILE="home.tar.gz"

if [[ -n "$1" ]]; then
  USERNAME="$1"
  echo "Using provided username: $USERNAME"
else
  USERNAME=$(whoami)
  echo "No username provided. Using user: $USERNAME"
fi

# fetch password
PW=$(./get_password.sh)

# Check if the script was aborted (exit code 1)
if [[ $? -ne 0 ]]; then
  echo "Password entry failed."
  exit 1
fi

# Configuration
FILELIST="filelist.txt"
DEST_DIR="home"
ARCHIVE_NAME="home.tar.gz"

# Get the current working directory absolute path
CURRENT_PWD=$(pwd)

# Check if the file list exists
if [[ ! -f "$FILELIST" ]]; then
  echo "Error: $FILELIST not found."
  exit 1
fi

# Create destination directory
mkdir -p "$DEST_DIR"

echo "Starting copy process with cp (stripping home prefix)..."

# Read file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  # Check if the path starts with ~
  if [[ "$line" == "~"* ]]; then
    # Remove the "~/" prefix to get the relative path from $HOME
    # Example: "~/docs/file.txt" becomes "docs/file.txt"
    relative_path="${line#\~/}"

    # Change directory to $HOME to make --parents relative to it
    if [[ -e "$HOME/$relative_path" ]]; then
      echo "Copying: $line"

      # Execute copy from within $HOME to strip the /home/user prefix
      (cd "$HOME" && cp -a --parents "$relative_path" "$CURRENT_PWD/$DEST_DIR/")
    else
      echo "Warning: Path does not exist: $HOME/$relative_path"
    fi
  else
    echo "Skipping (no ~ at start): $line"
  fi
done <"$FILELIST"

# Archive the results
if [ -d "$DEST_DIR" ]; then
  echo "Creating archive $ARCHIVE_NAME..."
  tar -czf "$ARCHIVE_NAME" "$DEST_DIR"
  echo "Finished!"
else
  echo "Nothing found to archive."
fi

ENTRY_EXISTS=$(printf '%s\n' "$PW" | keepassxc-cli ls "$DB" | grep -x "$ENTRY")

# create entry if needed ans set username
if [[ -z "$ENTRY_EXISTS" ]]; then
  echo "Entry '$ENTRY' not found. Creating it..."
  printf '%s\n' "$PW" | keepassxc-cli add "$DB" "$ENTRY" --username "$USERNAME"
else
  echo "Entry '$ENTRY' exists. Updating username..."
  printf '%s\n' "$PW" | keepassxc-cli edit "$DB" "$ENTRY" --username "$USERNAME"
  if [[ $? -eq 0 ]]; then
    echo "Username updated to: $USERNAME"
  fi
fi

# update attachment
if [[ -f "$SOURCE_FILE" ]]; then
    # 1. Try to remove the existing attachment first. 
    # We pipe the password and ignore errors (in case it doesn't exist yet).
    printf '%s\n' "$PW" | keepassxc-cli attachment-rm "$DB" "$ENTRY" "$ATTACHMENT_NAME" &> /dev/null

    # 2. Perform the import
    if printf '%s\n' "$PW" | keepassxc-cli attachment-import "$DB" "$ENTRY" "$ATTACHMENT_NAME" "$SOURCE_FILE"; then
        echo "Success: Attachment '$ATTACHMENT_NAME' updated in entry '$ENTRY'."
    else
        echo "Error: Failed to update attachment."
        exit 1
    fi
else
    echo "Error: Source file '$SOURCE_FILE' not found."
    exit 1
fi

# clean up
rm -rf home
rm home.tar.gz
