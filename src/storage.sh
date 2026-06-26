#!/usr/bin/env bash
# ============================================================
# storage.sh - Cloud storage management (Rclone + GDrive)
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"

GDRIVE_MOUNT="${HOME}/gdrive"

storage_cmd() {
    local subcmd="${1:-status}"
    case "$subcmd" in
        setup)   storage_setup ;;
        mount)   storage_mount "${2:-$GDRIVE_MOUNT}" ;;
        unmount) storage_unmount ;;
        status)  storage_status ;;
        sync)    storage_sync "$@" ;;
        *)       echo "Usage: abfool-vps storage [setup|mount|unmount|status|sync]" ;;
    esac
}

storage_setup() {
    ensure_cmd rclone
    log_info "Run 'rclone config' to configure Google Drive"
    rclone config
}

storage_mount() {
    local mount_point="${1:-$GDRIVE_MOUNT}"
    ensure_cmd rclone
    mkdir -p "$mount_point"

    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_ok "Already mounted at ${mount_point}"
        return 0
    fi

    log_info "Mounting Google Drive at ${mount_point}..."
    rclone mount "gdrive:" "$mount_point" \
        --vfs-cache-mode writes \
        --vfs-cache-max-age 1h \
        --buffer-size 64MB \
        --dir-cache-time 72h \
        --daemon 2>/dev/null

    sleep 2
    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_ok "Mounted: ${mount_point}"
        df -h "$mount_point"
    else
        log_error "Mount failed"
    fi
}

storage_unmount() {
    if mountpoint -q "$GDRIVE_MOUNT" 2>/dev/null; then
        fusermount -u "$GDRIVE_MOUNT" 2>/dev/null || umount "$GDRIVE_MOUNT" 2>/dev/null
        log_ok "Unmounted"
    fi
}

storage_status() {
    echo -e "\n${W}Storage Status${N}"
    echo "─────────────────────"
    if has_cmd rclone; then
        echo -e "  ${G}●${N} Rclone installed"
    else
        echo -e "  ${R}●${N} Rclone not installed"
    fi

    if mountpoint -q "$GDRIVE_MOUNT" 2>/dev/null; then
        echo -e "  ${G}●${N} Google Drive mounted"
        df -h "$GDRIVE_MOUNT" | tail -1 | awk '{printf "    Used: %s / %s (%s)\n", $3, $2, $5}'
    else
        echo -e "  ${D}●${N} Google Drive not mounted"
    fi
    echo ""
}

storage_sync() {
    local dir="${2:-}" src="${3:-}" dst="${4:-}"
    case "$dir" in
        up)   rclone sync "$src" "gdrive:${dst}" --progress ;;
        down) rclone sync "gdrive:${src}" "$dst" --progress ;;
        *)    echo "Usage: abfool-vps storage sync up|down <src> <dst>" ;;
    esac
}
