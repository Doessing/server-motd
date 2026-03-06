#!/bin/bash
# ~/.profile snippet - added by server-motd installer
# https://github.com/Doessing/server-motd
#
# Config written by install.sh to /etc/motd-banner.conf
# Variables: MOTD_COLOR, MOTD_ANIM_SECS

# ── Load config ───────────────────────────────────────────────────────────────
MOTD_COLOR="blue"
MOTD_ANIM_SECS=1
# shellcheck source=/dev/null
[ -f /etc/motd-banner.conf ] && . /etc/motd-banner.conf

# ── Login sequence: hint → animation → MOTD (interactive SSH only) ────────────
if [ -n "$SSH_TTY" ] && [ -t 1 ]; then

    # Color theme
    RESET=$'\033[0m'
    GR=$'\033[38;5;240m'
    # shellcheck disable=SC2034  # C2/C3/C4 are used inside string expansions below
    case "$MOTD_COLOR" in
        green)  C2=$'\033[38;5;22m'; C3=$'\033[38;5;34m'; C4=$'\033[38;5;40m'  ;;
        purple) C2=$'\033[38;5;54m'; C3=$'\033[38;5;92m'; C4=$'\033[38;5;99m'  ;;
        cyan)   C2=$'\033[38;5;23m'; C3=$'\033[38;5;37m'; C4=$'\033[38;5;44m'  ;;
        orange) C2=$'\033[38;5;130m'; C3=$'\033[38;5;172m'; C4=$'\033[38;5;208m' ;;
        blue|*) C2=$'\033[38;5;19m'; C3=$'\033[38;5;33m'; C4=$'\033[38;5;45m'  ;;
    esac

    # Hint about login history log
    printf "\n  ${GR}Login history:  cat ~/.ssh/login_history.log${RESET}\n\n"
    sleep 1.5

    # Matrix animation
    COLS=$(TERM=${TERM:-xterm} tput cols 2>/dev/null || echo 80)
    ROWS=$(TERM=${TERM:-xterm} tput lines 2>/dev/null || echo 24)
    [[ "$COLS" =~ ^[0-9]+$ ]] || COLS=80
    [[ "$ROWS" =~ ^[0-9]+$ ]] || ROWS=24
    ANIM_ROWS=$(( ROWS > 20 ? 20 : ROWS - 4 ))
    FRAMES=$(( MOTD_ANIM_SECS * 14 ))  # ~14 frames per second at 0.07s delay
    [ "$FRAMES" -lt 1 ] && FRAMES=1

    printf '\033[2J\033[H'
    # shellcheck disable=SC2034  # frame/row/col are counter-only loop variables
    for frame in $(seq 1 $FRAMES); do
        printf '\033[H'
        # shellcheck disable=SC2034
        for row in $(seq 1 $ANIM_ROWS); do
            line=""
            # shellcheck disable=SC2034
            for col in $(seq 1 $(( COLS / 3 ))); do
                case $(( RANDOM % 4 )) in
                    0) line="${line}${C4}▓${RESET} " ;;
                    1) line="${line}${C3}▒${RESET} " ;;
                    2) line="${line}${C3}░${RESET} " ;;
                    3) line="${line}${C2}█${RESET} " ;;
                esac
            done
            printf "%s\n" "$line"
        done
        sleep 0.07
    done

    # Log login IP with geo lookup
    LOGIN_IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
    LOGIN_TIME=$(date '+%Y-%m-%d %H:%M:%S %Z')
    LOG_FILE="$HOME/.ssh/login_history.log"

    GEO=$(curl -s --max-time 3 \
        "http://ip-api.com/json/${LOGIN_IP}?fields=status,country,countryCode,regionName,city,isp,org,as,reverse,proxy,hosting" \
        2>/dev/null)

    if echo "$GEO" | grep -q '"status":"success"'; then
        GEO_PTR=$(echo     "$GEO" | grep -oP '"reverse":"\K[^"]+')
        GEO_CITY=$(echo    "$GEO" | grep -oP '"city":"\K[^"]+')
        GEO_REGION=$(echo  "$GEO" | grep -oP '"regionName":"\K[^"]+')
        GEO_COUNTRY=$(echo "$GEO" | grep -oP '"country":"\K[^"]+')
        GEO_CC=$(echo      "$GEO" | grep -oP '"countryCode":"\K[^"]+')
        GEO_ISP=$(echo     "$GEO" | grep -oP '"isp":"\K[^"]+')
        GEO_ORG=$(echo     "$GEO" | grep -oP '"org":"\K[^"]+')
        GEO_AS=$(echo      "$GEO" | grep -oP '"as":"\K[^"]+')
        GEO_PROXY=$(echo   "$GEO" | grep -oP '"proxy":\K(true|false)')
        GEO_HOST=$(echo    "$GEO" | grep -oP '"hosting":\K(true|false)')
        FLAGS=""
        [ "$GEO_PROXY" = "true" ] && FLAGS="${FLAGS} [PROXY]"
        [ "$GEO_HOST"  = "true" ] && FLAGS="${FLAGS} [DATACENTER]"
        LOG_ENTRY="${LOGIN_TIME}  ${LOGIN_IP}"$'\n'
        LOG_ENTRY+="  PTR      : ${GEO_PTR:-n/a}"$'\n'
        LOG_ENTRY+="  Location : ${GEO_CITY}, ${GEO_REGION}, ${GEO_COUNTRY} (${GEO_CC})"$'\n'
        LOG_ENTRY+="  ISP      : ${GEO_ISP}"$'\n'
        [ "$GEO_ORG" != "$GEO_ISP" ] && LOG_ENTRY+="  Org      : ${GEO_ORG}"$'\n'
        LOG_ENTRY+="  AS       : ${GEO_AS}"$'\n'
        [ -n "$FLAGS" ] && LOG_ENTRY+="  Flags    :${FLAGS}"$'\n'
    else
        PTR=$(dig +short -x "$LOGIN_IP" 2>/dev/null | head -1)
        LOG_ENTRY="${LOGIN_TIME}  ${LOGIN_IP}"$'\n'
        LOG_ENTRY+="  PTR      : ${PTR:-n/a}"$'\n'
        LOG_ENTRY+="  Geo      : lookup failed"$'\n'
    fi
    printf "%s\n" "$LOG_ENTRY" >> "$LOG_FILE"

    # Clear screen and show MOTD
    printf '\033[2J\033[H'
    run-parts /etc/update-motd.d/ 2>/dev/null
fi
# ── end server-motd ───────────────────────────────────────────────────────────
