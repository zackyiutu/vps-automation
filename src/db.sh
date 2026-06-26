#!/usr/bin/env bash
# ============================================================
# db.sh - Credential & Instance Database (SQLite)
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"

DB_FILE="${ABFOOL_ROOT}/data/vault.db"

db_init() {
    sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL,
    name TEXT NOT NULL,
    ip TEXT,
    port INTEGER DEFAULT 22,
    username TEXT,
    password TEXT,
    ssh_key TEXT,
    status TEXT DEFAULT 'active',
    specs TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, name)
);

CREATE TABLE IF NOT EXISTS credentials (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL UNIQUE,
    api_key TEXT,
    api_secret TEXT,
    token TEXT,
    extra TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT,
    component TEXT,
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL
}

db_save_instance() {
    local provider="$1" name="$2" ip="$3" port="${4:-22}" user="${5:-root}" pass="${6:-}"
    db_init
    sqlite3 "$DB_FILE" << SQL
INSERT OR REPLACE INTO instances (provider, name, ip, port, username, password, status, updated_at)
VALUES ('${provider}', '${name}', '${ip}', ${port}, '${user}', '${pass}', 'active', CURRENT_TIMESTAMP);
SQL
    log_ok "Saved: ${provider}/${name} → ${ip}:${port}"
}

db_get_instance() {
    local provider="$1" name="$2"
    db_init
    sqlite3 -separator ' ' "$DB_FILE" << SQL
SELECT ip, port, username, password FROM instances
WHERE provider='${provider}' AND name='${name}' AND status='active'
LIMIT 1;
SQL
}

db_list_instances() {
    local provider="${1:-}"
    db_init
    if [[ -n "$provider" ]]; then
        sqlite3 -header -column "$DB_FILE" << SQL
SELECT provider, name, ip, port, username, status, created_at FROM instances
WHERE provider='${provider}' AND status='active' ORDER BY created_at DESC;
SQL
    else
        sqlite3 -header -column "$DB_FILE" << SQL
SELECT provider, name, ip, port, username, status, created_at FROM instances
WHERE status='active' ORDER BY created_at DESC;
SQL
    fi
}

db_delete_instance() {
    local provider="$1" name="$2"
    db_init
    sqlite3 "$DB_FILE" << SQL
UPDATE instances SET status='destroyed', updated_at=CURRENT_TIMESTAMP
WHERE provider='${provider}' AND name='${name}';
SQL
}

# ── Credential Vault ───────────────────────────────────────
vault_manage() {
    local subcmd="${1:-list}"
    db_init

    case "$subcmd" in
        add)
            local provider="${2:-}"
            [[ -z "$provider" ]] && { echo "Usage: abfool-vps vault add <provider>"; return 1; }

            local token key secret
            read -rsp "API Token/Key: " token; echo
            read -rp "API Secret (optional): " secret

            sqlite3 "$DB_FILE" << SQL
INSERT OR REPLACE INTO credentials (provider, token, api_secret, created_at)
VALUES ('${provider}', '${token}', '${secret}', CURRENT_TIMESTAMP);
SQL
            log_ok "Credentials saved for ${provider}"
            ;;
        list)
            sqlite3 -header -column "$DB_FILE" << SQL
SELECT provider, substr(token,1,10)||'...' as token_preview, created_at FROM credentials ORDER BY provider;
SQL
            ;;
        remove)
            local provider="${2:-}"
            sqlite3 "$DB_FILE" "DELETE FROM credentials WHERE provider='${provider}';"
            log_ok "Credentials removed for ${provider}"
            ;;
        *) echo "Usage: abfool-vps vault [add|list|remove] [provider]" ;;
    esac
}
