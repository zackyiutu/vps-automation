#!/usr/bin/env bash
# ============================================================
# tunnel.sh - Network tunnel management
# Cloudflare, Tailscale, SSH, localhost.run
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"

tunnel_cmd() {
    local subcmd="${1:-status}"
    shift 2>/dev/null || true
    case "$subcmd" in
        quick)      tunnel_quick "$@" ;;
        named)      tunnel_named "$@" ;;
        ssh)        tunnel_ssh "$@" ;;
        tailscale)  tunnel_tailscale "$@" ;;
        lhr)        tunnel_localhost_run "$@" ;;
        stop)       tunnel_stop_all ;;
        status)     tunnel_status ;;
        *)          echo "Usage: abfool-vps tunnel [quick|named|ssh|tailscale|lhr|stop|status]" ;;
    esac
}

tunnel_quick() {
    local port="${1:-8080}"
    ensure_cmd cloudflared
    log_info "Starting Cloudflare quick tunnel on port ${port}..."
    cloudflared tunnel --url "http://localhost:${port}" 2>&1 &
    echo $! > "${ABFOOL_STATE_DIR}/cf_tunnel.pid"
    sleep 5
    log_ok "Tunnel started"
}

tunnel_named() {
    local name="${1:-abfool-tunnel}" host="${2:-}" svc="${3:-http://localhost:8080}"
    ensure_cmd cloudflared
    cloudflared tunnel create "$name" 2>/dev/null
    cloudflared tunnel route dns "$name" "$host" 2>/dev/null
    cloudflared tunnel run "$name" &
    echo $! > "${ABFOOL_STATE_DIR}/cf_tunnel.pid"
    log_ok "Named tunnel: ${name}"
}

tunnel_ssh() {
    local port="${1:-22}"
    ensure_cmd cloudflared
    cloudflared tunnel --url "tcp://localhost:${port}" 2>&1 &
    echo $! > "${ABFOOL_STATE_DIR}/cf_ssh.pid"
    log_ok "SSH tunnel started"
}

tunnel_tailscale() {
    if ! has_cmd tailscale; then
        log_info "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh 2>&1 | tail -3
    fi
    sudo tailscale up 2>/dev/null || tailscale up 2>/dev/null
    local ip
    ip=$(tailscale ip -4 2>/dev/null)
    log_ok "Tailscale active: ${ip}"
}

tunnel_localhost_run() {
    local port="${1:-8080}"
    log_info "Starting localhost.run tunnel on port ${port}..."
    ssh -R 80:localhost:${port} nokey@localhost.run 2>&1 &
    echo $! > "${ABFOOL_STATE_DIR}/lhr_tunnel.pid"
    log_ok "localhost.run tunnel started (no install needed)"
}

tunnel_stop_all() {
    for pidfile in "${ABFOOL_STATE_DIR}"/*_tunnel.pid "${ABFOOL_STATE_DIR}"/*_ssh.pid; do
        [[ -f "$pidfile" ]] || continue
        local pid
        pid=$(cat "$pidfile")
        kill "$pid" 2>/dev/null && rm -f "$pidfile"
    done
    log_ok "All tunnels stopped"
}

tunnel_status() {
    echo -e "\n${W}Tunnel Status${N}"
    echo "─────────────────────"
    for pidfile in "${ABFOOL_STATE_DIR}"/*_tunnel.pid "${ABFOOL_STATE_DIR}"/*_ssh.pid; do
        [[ -f "$pidfile" ]] || continue
        local pid name
        pid=$(cat "$pidfile")
        name=$(basename "$pidfile" .pid)
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  ${G}●${N} ${name} (PID: ${pid})"
        else
            echo -e "  ${R}●${N} ${name} (stale)"
        fi
    done
    echo ""
}
