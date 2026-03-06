#!/bin/bash
# /etc/update-motd.d/01-dynamic-banner
# Dynamic MOTD - https://github.com/Doessing/server-motd
#
# Config written by install.sh to /etc/motd-banner.conf
# Variables: MOTD_TITLE, MOTD_NAME, MOTD_COLOR

# ── Load config ───────────────────────────────────────────────────────────────
MOTD_TITLE="My Server"
MOTD_NAME=""
MOTD_COLOR="blue"
[ -f /etc/motd-banner.conf ] && . /etc/motd-banner.conf

# ── Color theme ───────────────────────────────────────────────────────────────
RESET=$'\033[0m'
BOLD=$'\033[1m'
GR=$'\033[38;5;240m'
WH=$'\033[38;5;255m'

case "$MOTD_COLOR" in
    green)  C1=$'\033[38;5;22m';  C2=$'\033[38;5;28m';  C3=$'\033[38;5;34m';  C4=$'\033[38;5;40m'  ;;
    purple) C1=$'\033[38;5;54m';  C2=$'\033[38;5;55m';  C3=$'\033[38;5;92m';  C4=$'\033[38;5;99m'  ;;
    cyan)   C1=$'\033[38;5;23m';  C2=$'\033[38;5;30m';  C3=$'\033[38;5;37m';  C4=$'\033[38;5;44m'  ;;
    orange) C1=$'\033[38;5;130m'; C2=$'\033[38;5;136m'; C3=$'\033[38;5;172m'; C4=$'\033[38;5;208m' ;;
    blue|*) C1=$'\033[38;5;19m';  C2=$'\033[38;5;21m';  C3=$'\033[38;5;33m';  C4=$'\033[38;5;45m'  ;;
esac

# ── ASCII Banner ──────────────────────────────────────────────────────────────
echo ""
if command -v toilet &>/dev/null; then
    toilet -f mono12 -F metal --width 72 "$MOTD_TITLE" 2>/dev/null | sed 's/^/  /'
else
    printf "  ${C3}${BOLD}%s${RESET}\n" "$MOTD_TITLE"
fi

# ── Separator ─────────────────────────────────────────────────────────────────
COLS=$(TERM=${TERM:-xterm} tput cols 2>/dev/null || echo 80)
[[ "$COLS" =~ ^[0-9]+$ ]] || COLS=80
PUB_IP=$(curl -s --max-time 2 https://api.ipify.org 2>/dev/null || echo "n/a")
SEP_LEN=$(( COLS > 74 ? 74 : COLS - 4 ))
printf "  ${GR}"; printf '─%.0s' $(seq 1 $SEP_LEN); printf "${RESET}\n"

# ── Dynamic system info ───────────────────────────────────────────────────────
HOSTNAME_F=$(hostname -f 2>/dev/null || hostname)
OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -o)
KERNEL=$(uname -r)
ARCH=$(uname -m)
UPTIME_STR=$(uptime -p 2>/dev/null | sed 's/^up //' || echo "n/a")
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
USERS=$(who | wc -l)
CPU_COUNT=$(nproc 2>/dev/null || echo "?")

PRIV_IP=$(ip -4 addr show scope global 2>/dev/null \
    | grep inet | grep -v '172\.' | awk '{print $2}' | cut -d/ -f1 | head -1)
[ -z "$PRIV_IP" ] && PRIV_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_PCT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2*100}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

if command -v docker &>/dev/null; then
    DR=$(docker ps -q 2>/dev/null | wc -l)
    DT=$(docker ps -aq 2>/dev/null | wc -l)
    DOCKER_STR="${WH}${DR}${RESET}${GR} running / ${RESET}${WH}${DT}${RESET}${GR} total${RESET}"
else
    DOCKER_STR="${GR}not installed${RESET}"
fi

# ── Progress bar ──────────────────────────────────────────────────────────────
progress_bar() {
    local pct=$1 width=20
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local COLOR
    if   [ "$pct" -lt 60 ]; then COLOR=$'\033[38;5;34m'
    elif [ "$pct" -lt 80 ]; then COLOR=$'\033[38;5;220m'
    else                         COLOR=$'\033[38;5;196m'
    fi
    local bar="${COLOR}"
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    bar="${bar}${GR}"
    for i in $(seq 1 $empty);  do bar="${bar}░"; done
    printf "%s" "${bar}${RESET}"
}

MEM_BAR=$(progress_bar "$MEM_PCT")
DISK_BAR=$(progress_bar "$DISK_PCT")

lbl() { printf "  ${C3}%-16s${RESET} ${GR}│${RESET} %s\n" "$1" "$2"; }

echo ""
[ -n "$MOTD_NAME" ] && printf "  ${C4}${BOLD}Welcome, %s${RESET}\n\n" "$MOTD_NAME"
lbl "Hostname"   "${WH}${BOLD}${HOSTNAME_F}${RESET}"
lbl "OS"         "${WH}${OS}${RESET}  ${GR}${KERNEL} (${ARCH})${RESET}"
lbl "Uptime"     "${WH}${UPTIME_STR}${RESET}"
lbl "Load"       "${WH}${LOAD}${RESET}  ${GR}(${CPU_COUNT} vCPU)${RESET}"
lbl "Sessions"   "${WH}${USERS}${RESET}${GR} active${RESET}"
echo ""
lbl "Private IP" "${WH}${PRIV_IP}${RESET}"
echo ""
lbl "RAM"        "${MEM_BAR}  ${WH}${MEM_USED} / ${MEM_TOTAL}${RESET}  ${GR}(${MEM_PCT}%)${RESET}"
lbl "Disk (/)"   "${DISK_BAR}  ${WH}${DISK_USED} / ${DISK_TOTAL}${RESET}  ${GR}(${DISK_PCT}%)${RESET}"
echo ""
lbl "Docker"     "${DOCKER_STR}"
echo ""

printf "  ${GR}"; printf '─%.0s' $(seq 1 $SEP_LEN); printf "${RESET}\n"
printf "  ${GR}%s${RESET}\n\n" "$(date '+%A %d %B %Y  %H:%M %Z')"
