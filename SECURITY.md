# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (`main`) | Yes |
| Older releases | No |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
**privately** rather than opening a public issue.

**How to report:**

Open a [GitHub Security Advisory](https://github.com/Doessing/server-motd/security/advisories/new)
in this repository. This keeps the details confidential until a fix is ready.

Please include:

- A clear description of the vulnerability
- Steps to reproduce (proof-of-concept script or command sequence)
- The potential impact and affected versions

**Response timeline:**

| Stage | Target |
|-------|--------|
| Initial acknowledgement | Within 72 hours |
| Assessment / triage | Within 7 days |
| Fix or mitigation | As soon as practical |
| Public disclosure | After fix is released |

If you cannot use GitHub Security Advisories, open a regular issue with
only a high-level description (no exploit details) and request private contact.

## Scope

This project is a **bash-based SSH MOTD installer** for Debian/Ubuntu systems.
Areas most relevant to security reports:

- Privilege escalation during install/uninstall (`install.sh` runs with `sudo`)
- Unsafe shell practices (command injection, unsafe `eval`, unquoted variables)
- Hardcoded credentials or secrets in any file
- Insecure file permissions set by the installer
- Supply-chain issues in the GitHub Actions workflows

## Out of Scope

- Vulnerabilities in third-party OS packages installed as dependencies
  (`toilet`, `dnsutils`, etc.) — report those upstream
- GitHub Actions runner OS vulnerabilities
- Social engineering
