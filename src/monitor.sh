#!/usr/bin/env bash
# ============================================================
# monitor.sh - Health monitoring & auto-heal daemon
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"
source "${ABFOOL_ROOT}/src/db.sh"

MONITOR_PID="${ABFOOL_STATE_DIR}/monitor.pid"
MONITOR_INTERVAL="${MONITOR_INTERVAL:-300}"

monitor_cmd() {
    local subcmd="${1:-status}"
    case "$subcmd" in
        start)  monitor_start ;;
        stop)   monitor_stop ;;
        scan)   worker_health_check ;;
        heal)   worker_auto_heal ;;
        status) monitor_status ;;
        *)      echo "Usage: abfool-vps monitor [start|stop|scan|heal|status]" ;;
    esac
}

monitor_start() {
    if [[ -f "$MONITOR_PID" ]]; then
        local pid
        pid=$(cat "$MONITOR_PID")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Monitor already running (PID: ${pid})"
            return 0
        fi
    fi

    log_info "Starting monitor daemon (interval: ${MONITOR_INTERVAL}s)..."

    (
        while true; do
            worker_health_check >> "${ABFOOL_LOG_DIR}/monitor.log" 2>&1
            worker_auto_heal >> "${ABFOOL_LOG_DIR}/monitor.log" 2>&1
            sleep "$MONITOR_INTERVAL"
        done
    ) &

    echo $! > "$MONITOR_PID"
    log_ok "Monitor started (PID: $(cat "$MONITOR_PID"))"
}

monitor_stop() {
    if [[ -f "$MONITOR_PID" ]]; then
        local pid
        pid=$(cat "$MONITOR_PID")
        kill "$pid" 2>/dev/null && rm -f "$MONITOR_PID"
        log_ok "Monitor stopped"
    fi
}

monitor_status() {
    echo -e "\n${W}Monitor Status${N}"
    echo "─────────────────────"
    if [[ -f "$MONITOR_PID" ]]; then
        local pid
        pid=$(cat "$MONITOR_PID")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  ${G}●${N} Running (PID: ${pid})"
        else
            echo -e "  ${R}●${N} Not running (stale PID)"
        fi
    else
        echo -e "  ${D}●${N} Not running"
    fi
    echo ""
}
