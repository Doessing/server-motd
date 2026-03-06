# server-motd

A dynamic SSH MOTD with matrix animation and login history logging.

**Features:**
- Matrix-style animation on login
- ASCII banner with customizable title and color theme
- Live system info: hostname, OS, uptime, load, RAM, disk, Docker
- Private IP
- Login history with IP geolocation, PTR/DNS, ISP and ASN

## Install

```bash
curl -fsSL https://motd.dossing.net/install | sudo bash
```

The installer will ask you:
- **Server title** – shown as large ASCII art banner
- **Your name** – optional welcome message
- **Color theme** – blue, green, purple, cyan or orange
- **Animation duration** – how many seconds the matrix animation runs
- **Backup** – whether to back up your existing MOTD before replacing it

## Reinstall / Update

Run the install command again on a machine where server-motd is already installed:

```bash
curl -fsSL https://motd.dossing.net/install | sudo bash
```

You will be prompted to choose between **Reinstall/Update**, **Uninstall**, or **Cancel**. On reinstall, your previous settings are pre-filled so you only need to change what you want.

## Uninstall

Run the install command again and choose **Uninstall**:

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

## Files

| File | Destination |
|------|-------------|
| `install.sh` | Installer (also handles reinstall and uninstall) |
| `motd-banner.sh` | `/etc/update-motd.d/01-dynamic-banner` |
| `profile-snippet.sh` | Prepended to `~/.profile` |

## Tested on

- Ubuntu 24.04 LTS (arm64, amd64)
