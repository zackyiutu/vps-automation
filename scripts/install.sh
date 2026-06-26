#!/usr/bin/env bash
# ============================================================
# install.sh - One-click installer for abfool VPS Orchestration
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "
╔══════════════════════════════════════════════════════════╗
║        abfool VPS Orchestration - Installer             ║
║        https://abfool.web.id                            ║
╚══════════════════════════════════════════════════════════╝
"

# Detect environment
IS_TERMUX=false
[[ -d "/data/data/com.termux" ]] && IS_TERMUX=true
echo "✓ Detected: $([ "$IS_TERMUX" = true ] && echo "Termux (Android)" || echo "$(uname -s) ($(uname -m))")"

# Install dependencies
echo ""
echo "Installing dependencies..."

install_pkg() {
    local cmd="$1" pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        echo "  ✓ ${cmd}"
        return 0
    fi
    echo "  ⟳ Installing ${pkg}..."
    if [ "$IS_TERMUX" = true ]; then
        pkg install -y "$pkg" 2>/dev/null && echo "  ✓ ${cmd}" || echo "  ⚠ ${cmd} (optional, skipped)"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg" 2>/dev/null && echo "  ✓ ${cmd}" || echo "  ⚠ ${cmd} (optional, skipped)"
    fi
}

install_pkg bash bash
install_pkg curl curl
install_pkg git git
install_pkg ssh openssh-client
install_pkg python3 python3
install_pkg sqlite3 sqlite3
install_pkg node nodejs

# Termux extras
if [ "$IS_TERMUX" = true ]; then
    pkg install -y termux-api 2>/dev/null || true
    [ ! -d "$HOME/storage" ] && termux-setup-storage 2>/dev/null || true
fi

# Make executable
echo ""
echo "Setting up..."
chmod +x "${SCRIPT_DIR}/abfool-vps"

# Create symlink
mkdir -p "${HOME}/.local/bin"
cat > "${HOME}/.local/bin/abfool-vps" << EOF
#!/usr/bin/env bash
exec bash "${SCRIPT_DIR}/abfool-vps" "\$@"
EOF
chmod +x "${HOME}/.local/bin/abfool-vps"

# PATH
if ! echo "$PATH" | grep -q "${HOME}/.local/bin"; then
    SHELL_RC="${HOME}/.bashrc"
    [ -f "${HOME}/.zshrc" ] && SHELL_RC="${HOME}/.zshrc"
    echo '' >> "$SHELL_RC"
    echo '# abfool VPS Orchestration' >> "$SHELL_RC"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "  ✓ Added to PATH (run: source ${SHELL_RC})"
fi

# SSH key
if [ ! -f "${HOME}/.ssh/abfool_key" ]; then
    mkdir -p "${HOME}/.ssh"
    ssh-keygen -t ed25519 -f "${HOME}/.ssh/abfool_key" -N "" -C "abfool-vps" 2>/dev/null
    echo "  ✓ SSH key generated"
fi

# Init dirs
mkdir -p "${SCRIPT_DIR}/data" "${SCRIPT_DIR}/logs" "${SCRIPT_DIR}/.state"

# Init database
sqlite3 "${SCRIPT_DIR}/data/vault.db" << 'SQL' 2>/dev/null
CREATE TABLE IF NOT EXISTS instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL, name TEXT NOT NULL,
    ip TEXT, port INTEGER DEFAULT 22,
    username TEXT, password TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, name)
);
CREATE TABLE IF NOT EXISTS credentials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL UNIQUE,
    token TEXT, api_secret TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
echo "  ✓ Database initialized"

echo "
╔══════════════════════════════════════════════════════════╗
║        Installation Complete!                            ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  Run:  abfool-vps setup                                  ║
║  Help: abfool-vps help                                   ║
║  Web:  https://abfool.web.id                             ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
"
