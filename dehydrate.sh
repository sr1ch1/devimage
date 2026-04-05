#!/bin/bash

# Configuration
ARCHIVE_NAME="home.tar.gz"
RESTORE_TEMP="./home"

echo "---------"
echo "Password: $PW"
echo "---------"

# fetch user config from database
printf '%s\n' "$PW" |
  keepassxc-cli attachment-export bootstrap.kdbx "user" "home.tar.gz" "home.tar.gz"

unset PW

# Check if the archive exists
if [[ ! -f "$ARCHIVE_NAME" ]]; then
  echo "Error: Archive $ARCHIVE_NAME not found."
  exit 1
fi

# Create a temporary directory for extraction
echo "Creating temporary directory..."
mkdir -p "$RESTORE_TEMP"

# Extract the archive
echo "Extracting $ARCHIVE_NAME..."
# --strip-components=1 removes the top-level "home" directory created during archiving
tar -xzf "$ARCHIVE_NAME" -C "$RESTORE_TEMP" --strip-components=1

# Check if extraction was successful
if [[ $? -eq 0 ]]; then
  echo "Restoring files to $HOME..."

  # Copy all files and folders from the temp dir to the user's actual home
  # -a preserves permissions, -v shows what is being restored
  cp -av "$RESTORE_TEMP/." "$HOME/"

  echo "Restore completed successfully."
else
  echo "Error: Extraction failed."
  exit 1
fi

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$RESTORE_TEMP"
rm home.tar.gz

echo "Done!"
