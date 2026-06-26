#!/usr/bin/env bash
# ============================================================
# lib.sh - Core library functions
# ============================================================

export ABFOOL_DB="${ABFOOL_ROOT}/data/vault.db"
export ABFOOL_CONFIG="${ABFOOL_ROOT}/config/abfool.yaml"
export ABFOOL_LOG_DIR="${ABFOOL_ROOT}/logs"
export ABFOOL_STATE_DIR="${ABFOOL_ROOT}/.state"
export SSH_KEY_PATH="${HOME}/.ssh/abfool_key"

# Colors
if [[ -t 1 ]]; then
    R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' W='\033[1;37m' D='\033[2m' N='\033[0m'
else
    R='' G='' Y='' B='' C='' W='' D='' N=''
fi

# Logging
log_info()  { echo -e "${G}[INFO]${N} $*" >&2; echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [INFO] $*" >> "${ABFOOL_LOG_DIR}/system.log" 2>/dev/null; }
log_warn()  { echo -e "${Y}[WARN]${N} $*" >&2; echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [WARN] $*" >> "${ABFOOL_LOG_DIR}/system.log" 2>/dev/null; }
log_error() { echo -e "${R}[ERROR]${N} $*" >&2; echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [ERROR] $*" >> "${ABFOOL_LOG_DIR}/system.log" 2>/dev/null; }
log_ok()    { echo -e "${G}[OK]${N} $*" >&2; }
log_cmd()   { echo -e "${C}→${N} $*" >&2; }

# Init directories
init_dirs() {
    mkdir -p "${ABFOOL_LOG_DIR}" "${ABFOOL_STATE_DIR}" "${ABFOOL_ROOT}/data"
    [[ -f "$ABFOOL_DB" ]] || touch "$ABFOOL_DB"
}

# Safe exec with timeout
run_cmd() {
    local cmd="$1" timeout="${2:-30}"
    timeout "$timeout" bash -c "$cmd" 2>/dev/null
}

# Check command exists
has_cmd() { command -v "$1" &>/dev/null; }

# Install if missing
ensure_cmd() {
    local cmd="$1" pkg="${2:-$1}"
    if ! has_cmd "$cmd"; then
        log_info "Installing ${pkg}..."
        if has_cmd apt-get; then
            sudo apt-get install -y "$pkg" 2>/dev/null || pip3 install "$pkg" 2>/dev/null
        elif has_cmd pkg; then
            pkg install -y "$pkg" 2>/dev/null
        elif has_cmd brew; then
            brew install "$pkg" 2>/dev/null
        fi
    fi
}

# SSH key management
generate_ssh_key() {
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        mkdir -p "$(dirname "$SSH_KEY_PATH")"
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "abfool-vps@$(hostname)" 2>/dev/null
        chmod 600 "$SSH_KEY_PATH"
        log_ok "SSH key generated: ${SSH_KEY_PATH}"
    fi
}

get_ssh_pubkey() {
    [[ -f "${SSH_KEY_PATH}.pub" ]] || generate_ssh_key
    cat "${SSH_KEY_PATH}.pub"
}

# Network helpers
get_public_ip() {
    curl -sf --max-time 5 "https://api.ipify.org" 2>/dev/null || \
    curl -sf --max-time 5 "https://ifconfig.me" 2>/dev/null || echo "unknown"
}

check_internet() {
    curl -sf --max-time 3 "https://1.1.1.1" &>/dev/null
}

# Confirmation
confirm() {
    local prompt="${1:-Continue?}"
    read -rp "$(echo -e "${Y}${prompt} [y/N]:${N} ")" ans
    [[ "${ans,,}" == "y" ]]
}

# Config helpers
config_get() {
    local key="$1" default="${2:-}"
    [[ -f "$ABFOOL_CONFIG" ]] && grep -E "^${key}:" "$ABFOOL_CONFIG" 2>/dev/null | head -1 | sed 's/^[^:]*: *//' || echo "$default"
}

config_set() {
    local key="$1" value="$2"
    mkdir -p "$(dirname "$ABFOOL_CONFIG")"
    if [[ -f "$ABFOOL_CONFIG" ]] && grep -q "^${key}:" "$ABFOOL_CONFIG"; then
        sed -i "s|^${key}:.*|${key}: ${value}|" "$ABFOOL_CONFIG"
    else
        echo "${key}: ${value}" >> "$ABFOOL_CONFIG"
    fi
}

# Platform detection
IS_TERMUX=$([[ -d "/data/data/com.termux" ]] && echo true || echo false)
PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

init_dirs
