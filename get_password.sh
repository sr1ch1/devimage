#!/bin/bash

while true; do
  # Read password - input comes from /dev/tty to not interfere with stdout
  read -s -p "Password: " PW </dev/tty
  # Echo a newline to stderr so the prompt looks clean
  echo >&2

  if [[ -z "$PW" ]]; then
    echo "No password entered – aborting" >&2
    exit 1
  fi

  # Test password
  if printf '%s\n' "$PW" | keepassxc-cli ls bootstrap.kdbx dir >/dev/null 2>&1; then
    echo "Password OK" >&2
    # Print the password to stdout so it can be captured in a variable
    printf '%s' "$PW"
    break
  else
    echo "Wrong password – try again" >&2
  fi
done
