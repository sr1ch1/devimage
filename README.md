# devimage

A reproducible, self-provisioning container-based development environment. `backup.sh` encrypts your personal configuration and credentials into an encrypted database, then the Docker container decrypts and installs everything on start — languages, tools, dotfiles, secrets, editor. Minutes from zero to fully configured workspace.

## Design

The container is treated as **ephemeral**. Nothing of value lives inside it permanently:

- **Projects** are bind-mounted from the host (`~/projects`).
- **Personal configuration and secrets** (SSH keys, `.gitconfig`, mise config, shell config, etc.) are encrypted with a master password into `bootstrap.kdbx` via `backup.sh`. On container start, `restore.sh` decrypts and places them at their designated locations.

Every container start self-provisions the full toolchain from scratch. Tear it down, rebuild — you get a fresh, up-to-date environment every time.

### Why This Approach

**Always current, not frozen.** Tools and languages are installed at their latest versions on every provision. This is intentional — the goal is a modern development environment, not a reproducible artifact from a specific point in time. Cron jobs (nightly `apt dist-upgrade` and `mise upgrade`) keep a long-running container from falling behind.

**Secrets travel, agents don't.** The KeePass-encrypted `bootstrap.kdbx` is the transport mechanism for personal configuration and credentials. SSH agent forwarding requires infrastructure that isn't available everywhere. KeePass only requires a password and the CLI — it works on any machine with Docker and `keepassxc-cli`.

**Container as scratch space.** The container has no persistent state worth preserving. Projects live on the host. Personal config lives in the encrypted database. The container is rebuilt or discarded freely. This eliminates configuration drift — every start is a clean slate.

**One command, full workspace.** `./dev.sh` builds, provisions, and drops you into a ready-to-use environment. No manual setup steps, no dotfile management, no remembering what to install. The entire setup is declarative in the scripts and Dockerfile.

## Quick Start

### Prerequisites

- Docker or Podman
- KeePassXC CLI (`keepassxc-cli`)
- A `bootstrap.kdbx` file with your encrypted configuration (see [Encrypting Your Configuration](#encrypting-your-configuration))

### Build & Run

```bash
./dev.sh <github-username>
```

On first run, this:

1. Builds the Docker image (Ubuntu 24.04)
2. Starts the container with `~/projects` bind-mounted
3. Prompts for your KeePass master password
4. Decrypts and places your personal configuration from `bootstrap.kdbx`
5. Installs all languages and tools via `mise`
6. Sets up Neovim with LazyVim and your custom config

To re-attach to a running container:

```bash
./dev.sh <github-username>
```

## What's Inside

### System

| Component   | Details                                       |
| ----------- | --------------------------------------------- |
| Base        | Ubuntu 24.04                                  |
| Locale      | de_DE.UTF-8                                   |
| Timezone    | Europe/Berlin                                 |
| Shells      | Bash, Fish, Nushell                           |
| Multiplexer | Zellij                                        |
| Prompt      | Starship                                      |
| Secrets     | Encrypted KeePass database (`bootstrap.kdbx`) |
| Scheduler   | Cron (nightly updates)                        |

### Languages

Go, Node.js, Deno, Python, Lua 5.1, Rust, Ruby, Java, Groovy, Julia, .NET, PHP 8.4

Installed and managed by [mise](https://mise.jdx.dev/).

### Tools

fzf, ripgrep, fd, jq, yq, lazygit, zoxide, bat, eza, tree-sitter, ast-grep, typst, tectonic, mermaid-cli, httpie, imagemagick, ghostscript, opencode, claude

### Editor

Neovim 0.11.7 with [LazyVim](https://www.lazyvim.org/) — custom configs in `nvim/` are layered on top of a fresh LazyVim starter install.

## Project Structure

```
.
├── Dockerfile              # Image definition
├── dev.sh                  # Host-side launcher (build/run/attach)
├── bootstrap.kdbx          # Encrypted database holding personal config & secrets
├── filelist.txt            # Which files to transport into the container
├── nvim/                   # Custom Neovim config overlays
│   └── lua/
│       ├── config/         # options.lua
│       └── plugins/        # themes, treesitter, extras, noice
├── utils/
│   ├── entrypoint.sh       # Container entrypoint (cron + provision)
│   ├── provision.sh        # Self-provisioning: tools, nvim, dotfiles
│   ├── backup.sh            # Encrypt personal config & secrets into bootstrap.kdbx
│   ├── restore.sh           # Decrypt and place config at designated locations
│   ├── get_password.sh     # KeePass password prompt + validation
│   └── prj                 # Zellij project session manager (fzf)
└── jobs/
    ├── sys-update.sh       # Cron: nightly apt dist-upgrade
    └── mise-auto-update.sh # Cron: nightly mise self-update + upgrade
```

## Encrypting Your Configuration

The primary mechanism for transporting personal configuration, credentials, and secrets into the container is the `backup` / `restore` pair.

- **`backup.sh`** — run on your host machine. Encrypts the files listed in `filelist.txt` into `bootstrap.kdbx` behind a master password. This is how you initially create the database, and you re-run it whenever your config changes and the database needs updating.
- **`restore.sh`** — runs automatically inside the container during provisioning. Prompts for the master password, extracts the archive, and places each file at its designated location (as defined by `filelist.txt`).

### Creating or Updating the Encrypted Database

Run on your host machine from the project root:

```bash
bash utils/backup.sh [username]
```

This reads `filelist.txt`, collects each file from `$HOME`, packages them into an archive, and stores it as an encrypted attachment in `bootstrap.kdbx`.

Files encrypted by default:

```
~/.gitconfig
~/.ssh
~/.config/zellij
~/.config/mise/config.toml
~/.config/starship.toml
~/.config/nushell/config.nu
```

Edit `filelist.txt` to control what gets transported into the container.

### How It Works in the Container

During provisioning, `restore.sh` decrypts the archive from `bootstrap.kdbx` and copies the files into `$HOME`.

## Cron Jobs

Two nightly jobs keep the environment up to date:

| Job                | Time  | User | Action                                      |
| ------------------ | ----- | ---- | ------------------------------------------- |
| `sys-update`       | 03:00 | root | `apt-get update && apt-get dist-upgrade -y` |
| `mise-auto-update` | 03:30 | user | `mise self-update && mise upgrade --yes`    |

Logs are written to `/var/log/sys-update.log` and `/var/log/mise-update.log` (capped at 50 KB).

## Custom Neovim Config

The `nvim/` directory contains partial configurations overlayed onto LazyVim:

- **Catppuccin** theme with transparent background and integrations for cmp, gitsigns, telescope, neotree, noice, which-key, and more
- **OSC52 clipboard** for terminal copy/paste over SSH
- **Extra tree-sitter parsers**: css, latex, scss, svelte, typst, vue
- **Perl provider disabled** (fewer warnings)

Add or modify files in `nvim/lua/plugins/` to extend the setup.

## Project Switcher (`prj`)

The `prj` command manages Zellij sessions per project under `~/projects/`:

```bash
prj              # fzf picker to select a project
prj myproject    # attach to or create session "myproject"
```

Running `prj` from inside a project directory auto-detects the session name.

## Portability

The only artifacts needed to rebuild your entire environment on a new machine:

1. This repository (Dockerfile + scripts + nvim configs)
2. Your `bootstrap.kdbx` encrypted database
3. The KeePass master password

No dotfiles scattered across the filesystem. No list of `apt install` commands to remember. Your secrets travel encrypted. One command gets you back to work.
