#!/bin/bash
# server-motd installer
# https://github.com/Doessing/server-motd

set -e

REPO_RAW="https://raw.githubusercontent.com/Doessing/server-motd/main"
CONF_FILE="/etc/motd-banner.conf"
MOTD_SCRIPT="/etc/update-motd.d/01-dynamic-banner"
BACKUP_DIR="/etc/motd-banner.backup"
PROFILE_MARKER="# ── Login sequence"

# ── Colors for installer UI ───────────────────────────────────────────────────
R=$'\033[0m'; B=$'\033[1m'; CY=$'\033[38;5;45m'; GR=$'\033[38;5;240m'; RD=$'\033[38;5;196m'

header() { printf "\n${CY}${B}▶ %s${R}\n" "$1"; }
ok()     { printf "  ${CY}✓${R} %s\n" "$1"; }
info()   { printf "  ${GR}%s${R}\n" "$1"; }
err()    { printf "  ${RD}✗ %s${R}\n" "$1" >&2; }
ask()    { printf "  ${CY}?${R} %s" "$1"; }

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    err "Run with sudo: curl -fsSL https://motd.dossing.net/install | sudo bash"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo '')}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
[ -z "$REAL_HOME" ] && REAL_HOME="$HOME"
PROFILE_FILE="$REAL_HOME/.profile"

# ── Welcome ───────────────────────────────────────────────────────────────────
clear
printf "\n${CY}${B}"
printf "  ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗      ███╗   ███╗ ██████╗ ████████╗██████╗ \n"
printf "  ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗     ████╗ ████║██╔═══██╗╚══██╔══╝██╔══██╗\n"
printf "  ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝     ██╔████╔██║██║   ██║   ██║   ██║  ██║\n"
printf "  ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗     ██║╚██╔╝██║██║   ██║   ██║   ██║  ██║\n"
printf "  ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║     ██║ ╚═╝ ██║╚██████╔╝   ██║   ██████╔╝\n"
printf "  ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝     ╚═╝     ╚═╝ ╚═════╝    ╚═╝   ╚═════╝ \n"
printf "${R}\n"
printf "  ${GR}Dynamic MOTD with matrix animation + login history${R}\n"
printf "  ${GR}https://github.com/Doessing/server-motd${R}\n\n"

# ── Detect existing installation ──────────────────────────────────────────────
ALREADY_INSTALLED=false
if [ -f "$MOTD_SCRIPT" ] || grep -q "$PROFILE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
    ALREADY_INSTALLED=true
fi

if $ALREADY_INSTALLED; then
    printf "  ${CY}${B}server-motd is already installed on this machine.${R}\n\n"
    printf "  ${CY}1${R}) Reinstall / Update\n"
    printf "  ${CY}2${R}) Uninstall\n"
    printf "  ${CY}3${R}) Cancel\n\n"
    read -rp "  Choose [1-3]: " MODE_CHOICE </dev/tty
    case "$MODE_CHOICE" in
        1) MODE="install" ;;
        2) MODE="uninstall" ;;
        *) printf "\n  Cancelled.\n\n"; exit 0 ;;
    esac
else
    MODE="install"
fi

# ══════════════════════════════════════════════════════════════════════════════
# UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════
if [ "$MODE" = "uninstall" ]; then
    header "Uninstalling server-motd"

    # Remove MOTD banner script
    if [ -f "$MOTD_SCRIPT" ]; then
        rm -f "$MOTD_SCRIPT"
        ok "Removed $MOTD_SCRIPT"
    fi

    # Remove config
    if [ -f "$CONF_FILE" ]; then
        rm -f "$CONF_FILE"
        ok "Removed $CONF_FILE"
    fi

    # Remove profile snippet
    if grep -q "$PROFILE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        sed -i "/# ── Login sequence/,/# ── end server-motd/d" "$PROFILE_FILE"
        ok "Removed login snippet from $PROFILE_FILE"
    fi

    # Restore backup if available
    if [ -d "$BACKUP_DIR" ]; then
        header "Restoring backup from $BACKUP_DIR"

        # Restore MOTD scripts (re-enable them)
        if [ -d "$BACKUP_DIR/update-motd.d" ]; then
            for f in "$BACKUP_DIR/update-motd.d"/*; do
                fname=$(basename "$f")
                dest="/etc/update-motd.d/$fname"
                cp "$f" "$dest"
                chmod +x "$dest"
                ok "Restored $dest"
            done
        fi

        # Restore PAM sshd if backed up
        if [ -f "$BACKUP_DIR/pam.d.sshd" ]; then
            cp "$BACKUP_DIR/pam.d.sshd" /etc/pam.d/sshd
            ok "Restored /etc/pam.d/sshd"
        fi

        # Restore .profile if backed up
        if [ -f "$BACKUP_DIR/profile" ]; then
            cp "$BACKUP_DIR/profile" "$PROFILE_FILE"
            chown "$REAL_USER:$REAL_USER" "$PROFILE_FILE"
            ok "Restored $PROFILE_FILE"
        fi

        rm -rf "$BACKUP_DIR"
        ok "Removed backup directory"
    else
        info "No backup found — original MOTD scripts were not restored"
        # Re-enable default Ubuntu MOTD scripts if they exist
        for f in /etc/update-motd.d/00-header \
                  /etc/update-motd.d/60-unminimize \
                  /etc/update-motd.d/85-fwupd \
                  /etc/update-motd.d/91-contract-ua-esm-status \
                  /etc/update-motd.d/92-unattended-upgrades; do
            [ -f "$f" ] && chmod +x "$f" && info "re-enabled: $(basename $f)"
        done

        # Re-enable PAM MOTD
        if [ -f /etc/pam.d/sshd ]; then
            sed -i 's/^#\(session.*pam_motd\.so.*\)/\1/' /etc/pam.d/sshd
            ok "PAM MOTD re-enabled"
        fi
    fi

    printf "\n${CY}${B}  Uninstall complete!${R}\n"
    printf "  ${GR}Log out and back in for changes to take effect.${R}\n\n"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# INSTALL / REINSTALL
# ══════════════════════════════════════════════════════════════════════════════

# ── Backup prompt (only on fresh install) ─────────────────────────────────────
if ! $ALREADY_INSTALLED; then
    ask "Backup existing MOTD scripts before installing? [Y/n]: "
    read -r DO_BACKUP </dev/tty
    DO_BACKUP="${DO_BACKUP:-Y}"
else
    DO_BACKUP="N"  # Reinstall: backup already exists (or was never wanted)
fi

# ── Configuration prompts ─────────────────────────────────────────────────────
header "Configuration"

# Pre-fill from existing config on reinstall
if [ -f "$CONF_FILE" ]; then
    . "$CONF_FILE"
    PREV_TITLE="${MOTD_TITLE:-My Server}"
    PREV_NAME="${MOTD_NAME:-}"
    PREV_ANIM="${MOTD_ANIM_SECS:-1}"
else
    PREV_TITLE="My Server"; PREV_NAME=""; PREV_ANIM="1"
fi

read -rp "  Server title (shown as ASCII banner) [${PREV_TITLE}]: " MOTD_TITLE </dev/tty
MOTD_TITLE="${MOTD_TITLE:-$PREV_TITLE}"

read -rp "  Your name for welcome message (leave blank to skip) [${PREV_NAME}]: " MOTD_NAME </dev/tty
MOTD_NAME="${MOTD_NAME:-$PREV_NAME}"

echo ""
printf "  Color theme:\n"
printf "    ${CY}1${R}) Blue (default)\n"
printf "    ${CY}2${R}) Green\n"
printf "    ${CY}3${R}) Purple\n"
printf "    ${CY}4${R}) Cyan\n"
printf "    ${CY}5${R}) Orange\n"
read -rp "  Choose [1-5]: " COLOR_CHOICE </dev/tty
case "$COLOR_CHOICE" in
    2) MOTD_COLOR="green"  ;;
    3) MOTD_COLOR="purple" ;;
    4) MOTD_COLOR="cyan"   ;;
    5) MOTD_COLOR="orange" ;;
    *) MOTD_COLOR="blue"   ;;
esac

read -rp "  Animation duration in seconds [${PREV_ANIM}]: " MOTD_ANIM_SECS </dev/tty
MOTD_ANIM_SECS="${MOTD_ANIM_SECS:-$PREV_ANIM}"
if ! [[ "$MOTD_ANIM_SECS" =~ ^[0-9]+$ ]]; then MOTD_ANIM_SECS=1; fi

# ── Backup existing MOTD ──────────────────────────────────────────────────────
if [[ "$DO_BACKUP" =~ ^[Yy] ]]; then
    header "Backing up existing MOTD"
    mkdir -p "$BACKUP_DIR/update-motd.d"

    # Backup any executable MOTD scripts
    BACKED_UP=0
    for f in /etc/update-motd.d/*; do
        [ -f "$f" ] && [ -x "$f" ] && cp "$f" "$BACKUP_DIR/update-motd.d/" && BACKED_UP=$((BACKED_UP+1))
    done
    [ "$BACKED_UP" -gt 0 ] && ok "Backed up $BACKED_UP MOTD script(s) to $BACKUP_DIR/update-motd.d/"

    # Backup PAM sshd
    [ -f /etc/pam.d/sshd ] && cp /etc/pam.d/sshd "$BACKUP_DIR/pam.d.sshd" && ok "Backed up /etc/pam.d/sshd"

    # Backup .profile
    [ -f "$PROFILE_FILE" ] && cp "$PROFILE_FILE" "$BACKUP_DIR/profile" && ok "Backed up $PROFILE_FILE"
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
header "Installing dependencies"
if command -v apt-get &>/dev/null; then
    apt-get install -y -qq toilet toilet-fonts dnsutils curl 2>/dev/null && ok "toilet, dnsutils, curl"
elif command -v yum &>/dev/null; then
    yum install -y -q toilet bind-utils curl 2>/dev/null && ok "toilet, bind-utils, curl"
else
    info "Could not install packages automatically - ensure toilet, dig, curl are available"
fi

# ── Write config ──────────────────────────────────────────────────────────────
header "Writing config"
cat > "$CONF_FILE" << CONF
# /etc/motd-banner.conf - server-motd configuration
# Edit and re-run: curl -fsSL https://motd.dossing.net/install | sudo bash
MOTD_TITLE="${MOTD_TITLE}"
MOTD_NAME="${MOTD_NAME}"
MOTD_COLOR="${MOTD_COLOR}"
MOTD_ANIM_SECS=${MOTD_ANIM_SECS}
CONF
ok "Written to $CONF_FILE"

# ── Disable and clear existing MOTD ──────────────────────────────────────────
header "Clearing existing MOTD"

# Truncate /etc/motd if it exists
if [ -f /etc/motd ]; then
    truncate -s 0 /etc/motd
    ok "Cleared /etc/motd"
fi

# Disable default Ubuntu MOTD scripts
for f in /etc/update-motd.d/00-header \
          /etc/update-motd.d/60-unminimize \
          /etc/update-motd.d/85-fwupd \
          /etc/update-motd.d/91-contract-ua-esm-status \
          /etc/update-motd.d/92-unattended-upgrades; do
    [ -f "$f" ] && chmod -x "$f" && info "disabled: $(basename $f)"
done

# Disable PAM MOTD
if [ -f /etc/pam.d/sshd ]; then
    sed -i 's/^session.*pam_motd\.so.*/#&/' /etc/pam.d/sshd
    ok "PAM MOTD disabled"
fi

# ── Install MOTD banner script ────────────────────────────────────────────────
header "Installing MOTD banner"
curl -fsSL "${REPO_RAW}/motd-banner.sh" -o "$MOTD_SCRIPT"
chmod +x "$MOTD_SCRIPT"
ok "Installed to $MOTD_SCRIPT"

# ── Install profile snippet ───────────────────────────────────────────────────
header "Installing login animation + history logger"

# Remove any previous install
if grep -q "$PROFILE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
    sed -i "/# ── Login sequence/,/# ── end server-motd/d" "$PROFILE_FILE"
    info "Removed previous snippet from $PROFILE_FILE"
fi

# Ensure ~/.ssh exists for log file
mkdir -p "$REAL_HOME/.ssh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.ssh"

# Fetch and insert snippet
SNIPPET=$(curl -fsSL "${REPO_RAW}/profile-snippet.sh")
SNIPPET=$(echo "$SNIPPET" | tail -n +2)  # strip shebang

if [ -f "$PROFILE_FILE" ]; then
    FIRST_LINE=$(head -1 "$PROFILE_FILE")
    REST=$(tail -n +2 "$PROFILE_FILE")
    printf "%s\n\n%s\n\n%s\n" "$FIRST_LINE" "$SNIPPET" "$REST" > "$PROFILE_FILE"
else
    printf "#!/bin/bash\n\n%s\n" "$SNIPPET" > "$PROFILE_FILE"
fi
chown "$REAL_USER:$REAL_USER" "$PROFILE_FILE"
ok "Snippet added to $PROFILE_FILE"

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n${CY}${B}  Installation complete!${R}\n"
printf "  ${GR}Log out and back in to see your new MOTD.${R}\n"
printf "  ${GR}Login history: cat ~/.ssh/login_history.log${R}\n"
printf "  ${GR}Config:        $CONF_FILE${R}\n"
if [[ "$DO_BACKUP" =~ ^[Yy] ]]; then
    printf "  ${GR}Backup:        $BACKUP_DIR${R}\n"
fi
printf "\n"
