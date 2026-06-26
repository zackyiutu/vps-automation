#!/usr/bin/env bash
# ============================================================
# workers.sh - Background worker system
# Auto-provisioning, health monitoring, self-healing
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"
source "${ABFOOL_ROOT}/src/db.sh"

WORKER_PID_FILE="${ABFOOL_STATE_DIR}/worker.pid"

worker_list() {
    echo -e "\n${W}Active Workers${N}"
    echo "─────────────────────"

    if [[ -f "$WORKER_PID_FILE" ]]; then
        local pid
        pid=$(cat "$WORKER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  ${G}●${N} Main Worker (PID: ${pid})"
        else
            echo -e "  ${R}●${N} Worker not running (stale PID)"
        fi
    else
        echo -e "  ${D}No workers running${N}"
    fi

    # List worker scripts
    echo ""
    echo -e "${W}Worker Scripts:${N}"
    echo "  health-check   - Check all instance health"
    echo "  auto-heal      - Restart unhealthy instances"
    echo "  capacity-watch - Watch for free capacity"
    echo "  sync-storage   - Sync cloud storage"
    echo "  cleanup        - Clean old logs & temp files"
}

worker_run() {
    local task="$1"
    shift

    case "$task" in
        health-check)  worker_health_check ;;
        auto-heal)     worker_auto_heal ;;
        capacity-watch) worker_capacity_watch ;;
        sync-storage)  worker_sync_storage ;;
        cleanup)       worker_cleanup ;;
        *)             llm_worker_task "$task" ;;
    esac
}

worker_health_check() {
    log_info "Running health check on all instances..."
    db_init

    local instances
    instances=$(sqlite3 -separator '|' "$ABFOOL_DB" "SELECT provider, name, ip, port FROM instances WHERE status='active';")

    local total=0 healthy=0 unhealthy=0

    while IFS='|' read -r provider name ip port; do
        [[ -z "$provider" ]] && continue
        ((total++))

        if [[ "$ip" == "github" || "$ip" == "pending" ]]; then
            ((healthy++))
            continue
        fi

        if ping -c 1 -W 3 "$ip" &>/dev/null; then
            ((healthy++))
            echo -e "  ${G}●${N} ${provider}/${name} (${ip}) - healthy"
        else
            ((unhealthy++))
            echo -e "  ${R}●${N} ${provider}/${name} (${ip}) - unreachable"
        fi
    done <<< "$instances"

    echo ""
    echo -e "  Total: ${total} | ${G}Healthy: ${healthy}${N} | ${R}Unhealthy: ${unhealthy}${N}"
}

worker_auto_heal() {
    log_info "Running auto-heal..."
    worker_health_check

    # Heal Fly.io instances
    if has_cmd flyctl; then
        local apps
        apps=$(flyctl apps list --json 2>/dev/null | python3 -c "
import json,sys
for app in json.load(sys.stdin):
    if app.get('Status') != 'deployed':
        print(app['Name'])
" 2>/dev/null)

        for app in $apps; do
            log_warn "Restarting Fly.io app: ${app}"
            flyctl apps restart "$app" 2>/dev/null
        done
    fi

    log_ok "Auto-heal complete"
}

worker_capacity_watch() {
    log_info "Starting capacity watcher (checking every 5 min)..."
    local max_attempts=288  # 24 hours
    local attempt=0

    while (( attempt < max_attempts )); do
        ((attempt++))
        log_info "Capacity check ${attempt}/${max_attempts}"

        # Try to create instances on providers with capacity
        if has_cmd flyctl && flyctl auth whoami &>/dev/null; then
            local count
            count=$(flyctl apps list 2>/dev/null | grep -c "deployed" || echo 0)
            if (( count < 3 )); then
                flyio_create "abfool-auto-${attempt}"
            fi
        fi

        sleep 300
    done
}

worker_sync_storage() {
    log_info "Syncing cloud storage..."
    if has_cmd rclone; then
        rclone sync "${ABFOOL_ROOT}/data" "gdrive:abfool-backup/" --progress 2>&1 | tail -5
        log_ok "Storage synced"
    else
        log_warn "Rclone not installed"
    fi
}

worker_cleanup() {
    log_info "Cleaning up..."
    # Clean old logs
    find "${ABFOOL_LOG_DIR}" -name "*.log" -mtime +7 -delete 2>/dev/null
    # Clean temp files
    rm -rf "${ABFOOL_STATE_DIR}"/tmp-* 2>/dev/null
    # Vacuum database
    sqlite3 "$DB_FILE" "VACUUM;" 2>/dev/null
    log_ok "Cleanup complete"
}
