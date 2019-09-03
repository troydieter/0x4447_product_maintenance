#!/usr/bin/env sh
set -e
# set -x

# Note: This "bash" script was deliberately written to be backwards compatable with POSIX
#       shell (sh) as a result some things (like incrementing variables, using single `[`
#       vice `[[`, or not using named pipes for while read loops) may look a bit wonky

UNIX_USER="ec2-user"
SHUTDOWN_TIME_IN_MINUTES=30
CHECK_FREQ_IN_SECONDS=15

invoke_main(){
    check_if_already_running

    allow_usershutdown

    check_prereqs

    while true; do
        PENDING_SHUTDOWN=$(pgrep -f 'systemd-shutdownd' || true)

        if check_ssh_sessions; then
            check_and_start_shutdown
        else
            remove_shutdown
        fi

        sleep "$CHECK_FREQ_IN_SECONDS"
    done
}

write_log(){
    LOGGING="$1"
    MESSAGE="$2"
    TIMESTAMP="[$(date)]"

    echo "$TIMESTAMP - $LOGGING - $MESSAGE"

    if [ "$LOGGING" = "ERROR" ]; then
        exit 1;
    fi
}

check_if_already_running(){
    PID="$$"
    PIDS="$(pgrep -f "$0")"
    OTHER_PID="$(echo "$PIDS" | grep -v "$PID" | grep -v "$PPID" || true)"

    if test -n "$OTHER_PID"; then
        write_log "INFO" "This script is already running under $OTHER_PID"
        exit
    fi
}

check_prereqs(){
    write_log "INFO" "Checking prereqs."

    if ! command -v pgrep > /dev/null; then
        write_log "INFO" "Refreshing Package list and installing pgrep since it is needed on this system."

        yum check-update 1> /dev/null  ||
            write_log "ERROR" "Unable to refresh package lists."

        yum install -y procps-ng 1> /dev/null ||
            write_log "ERROR" "Unable to install procps-ng."
    fi
}

allow_usershutdown(){
    write_log "INFO" "Ensuring ${UNIX_USER} has permissions to invoke a shutdown."

    if ! grep -P "${UNIX_USER}.*shutdown" /etc/sudoers > /dev/null; then
        write_log "INFO" "Adding ${UNIX_USER} to /etc/sudoers"

        echo "$UNIX_USER    ALL=(ALL) NOPASSWD: /usr/sbin/poweroff, /usr/sbin/reboot, /usr/sbin/shutdown" >> /etc/sudoers || {
            write_log "WARN" "${USER} is unable to write to /etc/sudoers on behalf of ${UNIX_USER}."
            write_log "INFO" "Assuming that this user already has permissions to initiate a shutdown."
        }
    fi
}

check_ssh_sessions(){
    write_log "INFO" "Checking current SSH sessions."

    export SESSION_TIMES_FILE=/tmp/session_times

    if ! test -f "$SESSION_TIMES_FILE"; then
        write_log "INFO" "Creating ${SESSION_TIMES_FILE}"

        touch "$SESSION_TIMES_FILE"

        write_log "INFO" "Ensuring that ${UNIX_USER} has perms to write to ${SESSION_TIMES_FILE}"

        chmod 660 "${SESSION_TIMES_FILE}"
        chown "${UNIX_USER}:${UNIX_USER}" "${SESSION_TIMES_FILE}"
    fi

    w | awk '/pts/ {print $5}' > "${SESSION_TIMES_FILE}"

    INACTIVE_SESSIONS=0

    while read -r SESSION; do
        # check to see if session is idle for longer than 60s
        if echo "$SESSION" | grep -P '\d+\:\d+' > /dev/null; then
            INACTIVE_SESSIONS=$((INACTIVE_SESSIONS+1))
        fi
    done < "$SESSION_TIMES_FILE"

    SESSION_COUNT="$(wc -l "${SESSION_TIMES_FILE}" | awk '{print $1}')"

    write_log "INFO" "Inactive sessions: $INACTIVE_SESSIONS"
    write_log "INFO" "Total sessions: $SESSION_COUNT"

    if [ "$INACTIVE_SESSIONS" = "$SESSION_COUNT" ]; then
        write_log "INFO" "All sessions are inactive."
        return 0
    elif [ "$SESSION_COUNT" = "0" ]; then
        write_log "INFO" "There are no sessions."
        return 0
    fi

    write_log "INFO" "Determined that there is no action to take, will check again in ${CHECK_FREQ_IN_SECONDS} seconds."

    return 1
}

check_and_start_shutdown(){
    write_log "INFO" "Determined that a shutdown is needed."

    if test -z "$PENDING_SHUTDOWN"; then
        write_log "INFO" "Starting shutdown since there is not one scheduled."
        sudo shutdown "+${SHUTDOWN_TIME_IN_MINUTES}"

        PENDING_SHUTDOWN=$(pgrep -f 'systemd-shutdownd' || true)
    else
        write_log "INFO" "Determined that there is already a shutdown scheduled (PID: ${PENDING_SHUTDOWN})."
    fi
}

remove_shutdown(){
    if test -n "$PENDING_SHUTDOWN"; then
        write_log "INFO" "Removing pending shutdown (PID: ${PENDING_SHUTDOWN})."
        sudo shutdown -c
    fi
}

clean_exit(){
    echo # this is so ^C is not messign with my OCD
    write_log "INFO" "SIGINT detected. Exiting gracefully."

    remove_shutdown
}

trap clean_exit INT

invoke_main
