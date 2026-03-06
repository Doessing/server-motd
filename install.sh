#!/bin/bash
# server-motd installer
# https://github.com/Doessing/server-motd

set -e

REPO_RAW="https://raw.githubusercontent.com/Doessing/server-motd/main"
CONF_FILE="/etc/motd-banner.conf"
MOTD_SCRIPT="/etc/update-motd.d/01-dynamic-banner"
PROFILE_MARKER="# ── Login sequence"

# ── Colors for installer UI ───────────────────────────────────────────────────
R=$'\033[0m'; B=$'\033[1m'; CY=$'\033[38;5;45m'; GR=$'\033[38;5;240m'; RD=$'\033[38;5;196m'

header() { printf "\n${CY}${B}▶ %s${R}\n" "$1"; }
ok()     { printf "  ${CY}✓${R} %s\n" "$1"; }
info()   { printf "  ${GR}%s${R}\n" "$1"; }
err()    { printf "  ${RD}✗ %s${R}\n" "$1" >&2; }

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    err "Run with sudo: sudo bash install.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo '')}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
[ -z "$REAL_HOME" ] && REAL_HOME="$HOME"

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

# ── Interactive prompts ───────────────────────────────────────────────────────
header "Configuration"

read -rp "  Server title (shown as ASCII banner) [My Server]: " MOTD_TITLE
MOTD_TITLE="${MOTD_TITLE:-My Server}"

read -rp "  Your name for welcome message (leave blank to skip): " MOTD_NAME

echo ""
printf "  Color theme:\n"
printf "    ${CY}1${R}) Blue (default)\n"
printf "    ${CY}2${R}) Green\n"
printf "    ${CY}3${R}) Purple\n"
printf "    ${CY}4${R}) Cyan\n"
printf "    ${CY}5${R}) Orange\n"
read -rp "  Choose [1-5]: " COLOR_CHOICE
case "$COLOR_CHOICE" in
    2) MOTD_COLOR="green"  ;;
    3) MOTD_COLOR="purple" ;;
    4) MOTD_COLOR="cyan"   ;;
    5) MOTD_COLOR="orange" ;;
    *) MOTD_COLOR="blue"   ;;
esac

read -rp "  Animation duration in seconds [1]: " MOTD_ANIM_SECS
MOTD_ANIM_SECS="${MOTD_ANIM_SECS:-1}"
if ! [[ "$MOTD_ANIM_SECS" =~ ^[0-9]+$ ]]; then MOTD_ANIM_SECS=1; fi

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
# Edit and re-run: sudo bash <(curl -fsSL https://raw.githubusercontent.com/Doessing/server-motd/main/install.sh)
MOTD_TITLE="${MOTD_TITLE}"
MOTD_NAME="${MOTD_NAME}"
MOTD_COLOR="${MOTD_COLOR}"
MOTD_ANIM_SECS=${MOTD_ANIM_SECS}
CONF
ok "Written to $CONF_FILE"

# ── Disable default Ubuntu MOTD scripts ───────────────────────────────────────
header "Disabling default Ubuntu MOTD scripts"
for f in /etc/update-motd.d/00-header \
          /etc/update-motd.d/60-unminimize \
          /etc/update-motd.d/85-fwupd \
          /etc/update-motd.d/91-contract-ua-esm-status \
          /etc/update-motd.d/92-unattended-upgrades; do
    [ -f "$f" ] && chmod -x "$f" && info "disabled: $(basename $f)"
done

# ── Disable PAM MOTD ──────────────────────────────────────────────────────────
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
PROFILE_FILE="$REAL_HOME/.profile"

# Remove any previous install
if grep -q "$PROFILE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
    sed -i "/# ── Login sequence/,/# ── end server-motd/d" "$PROFILE_FILE"
    info "Removed previous installation from $PROFILE_FILE"
fi

# Ensure ~/.ssh exists for log file
mkdir -p "$REAL_HOME/.ssh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.ssh"

# Prepend snippet after first line of .profile
SNIPPET=$(curl -fsSL "${REPO_RAW}/profile-snippet.sh")
# Strip shebang from snippet before inserting
SNIPPET=$(echo "$SNIPPET" | tail -n +2)

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
printf "  ${GR}Config:        $CONF_FILE${R}\n\n"
