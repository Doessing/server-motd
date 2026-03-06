# ~/.profile: executed by the command interpreter for login shells.

# ── Login sekvens: animation → MOTD (kun ved interaktiv SSH) ─────────────────
if [ -n "$SSH_TTY" ] && [ -t 1 ]; then
    B2=$'\033[38;5;19m'
    B4=$'\033[38;5;21m'
    B6=$'\033[38;5;33m'
    B8=$'\033[38;5;45m'
    RESET=$'\033[0m'
    COLS=$(tput cols 2>/dev/null || echo 80)
    ROWS=$(tput lines 2>/dev/null || echo 24)
    # Brug hele skærmen til animationen
    ANIM_ROWS=$(( ROWS > 20 ? 20 : ROWS - 4 ))

    # Hint om login-historik (vises kort før animationen starter)
    GR=$'\033[38;5;240m'
    printf "\n  ${GR}Login historik:  cat ~/.ssh/login_history.log${RESET}\n\n"
    sleep 1.5

    # Matrix-animation i ~1 sek (14 frames * 0.07s = ~1.0s)
    printf '\033[2J\033[H'
    for frame in $(seq 1 14); do
        printf '\033[H'
        for row in $(seq 1 $ANIM_ROWS); do
            line=""
            for col in $(seq 1 $(( COLS / 3 ))); do
                case $(( RANDOM % 4 )) in
                    0) line="${line}${B4}▓${RESET} " ;;
                    1) line="${line}${B6}▒${RESET} " ;;
                    2) line="${line}${B8}░${RESET} " ;;
                    3) line="${line}${B2}█${RESET} " ;;
                esac
            done
            printf "%s\n" "$line"
        done
        sleep 0.07
    done

    # Log login-IP med DNS/geo lookup
    LOGIN_IP=$(echo "$SSH_CLIENT" | awk '{print $1}')
    LOGIN_TIME=$(date '+%Y-%m-%d %H:%M:%S %Z')

    GEO=$(curl -s --max-time 3 \
        "http://ip-api.com/json/${LOGIN_IP}?fields=status,country,countryCode,regionName,city,isp,org,as,reverse,proxy,hosting" \
        2>/dev/null)

    if echo "$GEO" | grep -q '"status":"success"'; then
        GEO_CITY=$(echo    "$GEO" | grep -oP '"city":"\K[^"]+')
        GEO_REGION=$(echo  "$GEO" | grep -oP '"regionName":"\K[^"]+')
        GEO_COUNTRY=$(echo "$GEO" | grep -oP '"country":"\K[^"]+')
        GEO_CC=$(echo      "$GEO" | grep -oP '"countryCode":"\K[^"]+')
        GEO_ISP=$(echo     "$GEO" | grep -oP '"isp":"\K[^"]+')
        GEO_ORG=$(echo     "$GEO" | grep -oP '"org":"\K[^"]+')
        GEO_AS=$(echo      "$GEO" | grep -oP '"as":"\K[^"]+')
        GEO_PTR=$(echo     "$GEO" | grep -oP '"reverse":"\K[^"]+')
        GEO_PROXY=$(echo   "$GEO" | grep -oP '"proxy":\K(true|false)')
        GEO_HOST=$(echo    "$GEO" | grep -oP '"hosting":\K(true|false)')

        # Byg lokation-streng
        LOCATION="${GEO_CITY}, ${GEO_REGION}, ${GEO_COUNTRY} (${GEO_CC})"
        # Flags/advarsler
        FLAGS=""
        [ "$GEO_PROXY" = "true" ]   && FLAGS="${FLAGS} [PROXY]"
        [ "$GEO_HOST"  = "true" ]   && FLAGS="${FLAGS} [DATACENTER]"

        LOG_ENTRY="${LOGIN_TIME}  ${LOGIN_IP}"$'\n'
        LOG_ENTRY+="  PTR      : ${GEO_PTR:-n/a}"$'\n'
        LOG_ENTRY+="  Location : ${LOCATION}"$'\n'
        LOG_ENTRY+="  ISP      : ${GEO_ISP}"$'\n'
        [ "$GEO_ORG" != "$GEO_ISP" ] && LOG_ENTRY+="  Org      : ${GEO_ORG}"$'\n'
        LOG_ENTRY+="  AS       : ${GEO_AS}"$'\n'
        [ -n "$FLAGS" ] && LOG_ENTRY+="  Flags    :${FLAGS}"$'\n'
    else
        # Fallback: bare PTR via dig
        PTR=$(dig +short -x "$LOGIN_IP" 2>/dev/null | head -1)
        LOG_ENTRY="${LOGIN_TIME}  ${LOGIN_IP}"$'\n'
        LOG_ENTRY+="  PTR      : ${PTR:-n/a}"$'\n'
        LOG_ENTRY+="  Geo      : lookup fejlede"$'\n'
    fi

    printf "%s\n" "$LOG_ENTRY" >> /home/ubuntu/.ssh/login_history.log

    # Ryd skærmen og vis MOTD
    printf '\033[2J\033[H'
    run-parts /etc/update-motd.d/ 2>/dev/null
fi
# ─────────────────────────────────────────────────────────────────────────────

# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
