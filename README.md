# server-motd

A dynamic SSH MOTD with matrix animation and login history logging.

**Features:**
- Matrix-style animation on login
- ASCII banner with customizable title and color theme
- Live system info: hostname, OS, uptime, load, RAM, disk, Docker
- Public + private IP
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

## Config

Settings are stored in `/etc/motd-banner.conf`:

```bash
MOTD_TITLE="My Server"
MOTD_NAME="Alice"
MOTD_COLOR="blue"
MOTD_ANIM_SECS=1
```

Edit and re-run the installer to apply changes, or edit the file directly.

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
| `install.sh` | Installer |
| `motd-banner.sh` | `/etc/update-motd.d/01-dynamic-banner` |
| `profile-snippet.sh` | Prepended to `~/.profile` |

## Tested on

- Ubuntu 24.04 LTS (arm64, amd64)
