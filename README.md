[![Tests](https://github.com/Doessing/server-motd/actions/workflows/test.yml/badge.svg)](https://github.com/Doessing/server-motd/actions/workflows/test.yml)

# SERVER-MOTD

A dynamic SSH login experience with matrix animation, ASCII banner, system stats and login history.

🌐 **Install**: `curl -fsSL https://motd.dossing.net/install | sudo bash`

## Features

- 🟩 **Matrix animation** on every SSH login
- 🔠 **ASCII art banner** with customizable title and colour theme
- 📊 **Live system info**: hostname, OS, uptime, load, RAM, disk, Docker
- 🌐 **Public IP** shown on the machine it's installed on
- 🔐 **Login history**: IP geolocation, PTR/DNS, ISP and ASN logged per login
- 💾 **Backup & restore**: backs up your existing MOTD before replacing it
- 🔄 **Reinstall / Uninstall**: one command, interactive menu

## Install

```bash
curl -fsSL https://motd.dossing.net/install | sudo bash
```

The installer will ask you:

| Prompt | Description |
|--------|-------------|
| **Server title** | Shown as large ASCII art banner |
| **Your name** | Optional welcome message |
| **Color theme** | `blue`, `green`, `purple`, `cyan` or `orange` |
| **Animation duration** | How many seconds the matrix animation runs |
| **Backup** | Whether to back up your existing MOTD before replacing it |

## Reinstall / Update

Run the install command again on a machine where server-motd is already installed:

```bash
curl -fsSL https://motd.dossing.net/install | sudo bash
```

You will be prompted to choose between **Reinstall/Update**, **Uninstall**, or **Cancel**. On reinstall, your previous settings are pre-filled so you only need to change what you want.

## Uninstall

Run the install command and choose **Uninstall**:

```bash
curl -fsSL https://motd.dossing.net/install | sudo bash
```

If a backup was made during install, the original MOTD scripts, `/etc/pam.d/sshd` and `~/.profile` are fully restored. If no backup exists, the default Ubuntu MOTD scripts are re-enabled instead.

## Config

Settings are stored in `/etc/motd-banner.conf`:

```bash
MOTD_TITLE="My Server"
MOTD_NAME="Alice"
MOTD_COLOR="blue"
MOTD_ANIM_SECS=1
```

Edit the file directly, or re-run the installer to update interactively.

## Backup

When installing fresh, you are asked whether to back up your existing MOTD. If you say yes, the following are saved to `/etc/motd-banner.backup/`:

| Backup file | Original |
|---|---|
| `update-motd.d/*` | All executable scripts in `/etc/update-motd.d/` |
| `pam.d.sshd` | `/etc/pam.d/sshd` |
| `profile` | `~/.profile` |

The backup is automatically restored on uninstall and then removed.

## Login history

Every SSH login is logged to `~/.ssh/login_history.log`:

```
2026-03-06 18:48:58 UTC  203.0.113.42
  PTR      : host-203-0-113-42.example.net
  Location : Chicago, Illinois, United States (US)
  ISP      : Some ISP Inc
  AS       : AS1234 Some ISP Inc
```

## Project structure

```
.
├── .github/
│   └── workflows/
│       └── test.yml        # CI: install, reinstall, uninstall, backup/restore
├── install.sh              # Installer (also handles reinstall and uninstall)
├── motd-banner.sh          # /etc/update-motd.d/01-dynamic-banner
├── profile-snippet.sh      # Prepended to ~/.profile
└── README.md               # This file
```

## Files

| File | Destination |
|------|-------------|
| `install.sh` | Installer (also handles reinstall and uninstall) |
| `motd-banner.sh` | `/etc/update-motd.d/01-dynamic-banner` |
| `profile-snippet.sh` | Prepended to `~/.profile` |

## Tested on

- 🐧 Ubuntu 24.04 LTS (arm64, amd64)

## CI/CD

Push to `main` → GitHub Actions runs 4 tests automatically:

| Test | What it checks |
|------|---------------|
| **1. Fresh install** | Script installs, config written, snippet in `.profile`, PAM disabled |
| **2. Reinstall** | Config updated, no duplicate snippets, banner still runs |
| **3. Uninstall** | Script removed, config removed, snippet cleaned from `.profile` |
| **4. Backup + restore** | Backup created on install, restored cleanly on uninstall |

---

**Credits**: Design & development: Anonymous · CI/CD: GitHub Actions
