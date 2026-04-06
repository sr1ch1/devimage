#!/usr/bin/env bash
set -euo pipefail

is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

while true; do
  # interaktiv vom TTY lesen
  if ! read -s -p "Password: " PW </dev/tty; then
    echo >&2 "Failed to read password (no TTY?)"
    if is_sourced; then
      return 1
    else
      exit 1
    fi
  fi
  echo >&2

  if [[ -z "${PW}" ]]; then
    echo "No password entered – aborting" >&2
    if is_sourced; then return 1; else exit 1; fi
  fi

  # Test password (keepassxc-cli)
  if printf '%s\n' "${PW}" | keepassxc-cli ls bootstrap.kdbx dir >/dev/null 2>&1; then
    echo "Password OK" >&2
    if is_sourced; then
      export PW
      return 0
    else
      printf '%s' "${PW}"
      exit 0
    fi
  else
    echo "Wrong password – try again" >&2
  fi
done

