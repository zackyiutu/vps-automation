#!/usr/bin/env bash
# ============================================================
# providers.sh - Multi-provider VPS management
# 15+ free providers, no CC required
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"

declare -A PROVIDERS=(
    [flyio]="Fly.io|3× VM, 256MB RAM|https://fly.io"
    [gitpod]="Gitpod|4 cores, 8GB RAM|https://gitpod.io"
    [codespaces]="GitHub Codespaces|2 cores, 8GB RAM|https://github.com/features/codespaces"
    [huggingface]="HuggingFace Spaces|2 vCPU, 16GB RAM|https://huggingface.co"
    [railway]="Railway|512MB RAM, 1GB disk|https://railway.app"
    [render]="Render|512MB RAM|https://render.com"
    [koyeb]="Koyeb|2× nano, 512MB|https://koyeb.com"
    [deno]="Deno Deploy|Serverless|https://deno.com/deploy"
    [vercel]="Vercel|Serverless, 100GB BW|https://vercel.com"
    [netlify]="Netlify|100GB BW, serverless|https://netlify.com"
    [ibm]="IBM Cloud|Lite tier, 256MB|https://cloud.ibm.com"
    [northflank]="Northflank|2GB RAM, 2 vCPU|https://northflank.com"
    [cyclic]="Cyclic|Serverless, 512MB|https://cyclic.sh"
    [cfworkers]="Cloudflare Workers|10ms CPU, 128MB|https://workers.cloudflare.com"
    [cfpages]="Cloudflare Pages|Unlimited BW|https://pages.cloudflare.com"
)

# ── Provider List ──────────────────────────────────────────
provider_list_all() {
    echo -e "\n${W}Supported Providers${N}"
    echo "─────────────────────────────────────────────────────────"
    printf "${D}%-15s %-25s %s${N}\n" "Provider" "Specs" "URL"
    echo "─────────────────────────────────────────────────────────"
    for key in "${!PROVIDERS[@]}"; do
        IFS='|' read -r name specs url <<< "${PROVIDERS[$key]}"
        printf "%-15s %-25s %s\n" "$key" "$specs" "$url"
    done
    echo ""
}

# ── Fly.io Provider ────────────────────────────────────────
flyio_install() {
    if has_cmd flyctl || has_cmd fly; then return 0; fi
    log_info "Installing Flyctl..."
    curl -L https://fly.io/install.sh | sh 2>&1 | tail -3
    export PATH="${HOME}/.fly/bin:$PATH"
}

flyio_auth() {
    flyio_install
    if flyctl auth whoami &>/dev/null; then
        log_ok "Fly.io: authenticated"
        return 0
    fi
    log_info "Fly.io login required"
    local token
    token=$(config_get "flyio_token" "")
    if [[ -n "$token" ]]; then
        flyctl auth token "$token" 2>/dev/null
    else
        echo -e "${C}Options:${N}"
        echo "  1. Browser login"
        echo "  2. Token login (for headless/Termux)"
        read -rp "Choice [1/2]: " choice
        if [[ "$choice" == "2" ]]; then
            read -rsp "Fly.io token: " token; echo
            flyctl auth token "$token" 2>/dev/null
            config_set "flyio_token" "$token"
        else
            flyctl auth login
        fi
    fi
}

flyio_create() {
    local name="${1:-abfool-$(date +%s)}"
    local region="${2:-sin}"
    flyio_auth

    log_info "Creating Fly.io app: ${name} (${region})..."

    local work_dir="${ABFOOL_STATE_DIR}/flyio-${name}"
    mkdir -p "$work_dir"

    # Generate Dockerfile for full Ubuntu VM
    cat > "${work_dir}/Dockerfile" << 'DOCKER'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssh-server sudo curl wget git vim nano htop \
    python3 python3-pip nodejs npm \
    net-tools iputils-ping dnsutils tmux screen zsh \
    build-essential cmake && rm -rf /var/lib/apt/lists/*
RUN mkdir /run/sshd && ssh-keygen -A && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN useradd -m -s /bin/bash vps && echo 'vps:vps123' | chpasswd && \
    adduser vps sudo && echo 'vps ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EXPOSE 22 80 443 8080
CMD ["/usr/sbin/sshd", "-D"]
DOCKER

    cat > "${work_dir}/fly.toml" << EOF
app = "${name}"
primary_region = "${region}"
[[services]]
  internal_port = 22
  protocol = "tcp"
  [[services.ports]]
    port = 22
    handlers = ["tcp"]
[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"
EOF

    cd "$work_dir"
    flyctl launch --name "$name" --region "$region" --no-deploy --copy-config 2>&1 | tail -3

    local ssh_pubkey
    ssh_pubkey=$(get_ssh_pubkey | tr '\n' ' ')
    flyctl secrets set "SSH_PUBKEY=${ssh_pubkey}" --app "$name" 2>/dev/null

    log_info "Deploying (2-3 minutes)..."
    flyctl deploy --app "$name" --remote-only 2>&1 | tail -5

    local ip
    ip=$(flyctl ips list --app "$name" 2>/dev/null | grep -v VERSION | awk '{print $2}' | head -1)

    # Store in vault
    db_save_instance "flyio" "$name" "$ip" "22" "vps" "vps123"

    echo -e "\n${G}═══ Instance Ready ═══${N}"
    echo -e "  ${W}Provider:${N}  Fly.io"
    echo -e "  ${W}Name:${N}     ${name}"
    echo -e "  ${W}IP:${N}       ${ip}"
    echo -e "  ${W}SSH:${N}      ssh vps@${ip}"
    echo -e "  ${W}Password:${N} vps123"
    echo -e "  ${W}URL:${N}      https://${name}.fly.dev"
    echo ""

    cd "$ABFOOL_ROOT"
}

# ── Codespaces Provider ────────────────────────────────────
cs_auth() {
    if ! has_cmd gh; then
        ensure_cmd gh
    fi
    if ! gh auth status &>/dev/null; then
        log_info "GitHub login required..."
        gh auth login 2>/dev/null || return 1
    fi
}

cs_create() {
    local machine="${1:-basicLinux32gb}" name="${2:-abfool-$(date +%s)}"
    cs_auth

    log_info "Creating Codespace: ${name}..."
    gh codespace create --machine "$machine" --display-name "$name" --idle-timeout 0m 2>&1 | tail -3

    local ssh_cmd="gh codespace ssh -c ${name}"
    db_save_instance "codespaces" "$name" "github" "22" "codespace" ""

    echo -e "\n${G}═══ Instance Ready ═══${N}"
    echo -e "  ${W}Provider:${N}  GitHub Codespaces"
    echo -e "  ${W}Name:${N}     ${name}"
    echo -e "  ${W}SSH:${N}      ${ssh_cmd}"
    echo -e "  ${W}Web:${N}      https://github.com/codespaces/${name}"
    echo ""
}

# ── Railway Provider ───────────────────────────────────────
railway_auth() {
    if ! has_cmd railway; then
        log_info "Installing Railway CLI..."
        npm install -g @railway/cli 2>/dev/null || curl -fsSL https://railway.app/install.sh | sh
    fi
    if ! railway whoami &>/dev/null; then
        railway login 2>/dev/null || return 1
    fi
}

railway_create() {
    local name="${1:-abfool-$(date +%s)}"
    railway_auth

    log_info "Creating Railway project: ${name}..."
    railway init --name "$name" 2>&1 | tail -3
    railway up 2>&1 | tail -5

    local url
    url=$(railway domain 2>/dev/null || echo "https://${name}.up.railway.app")

    db_save_instance "railway" "$name" "$url" "443" "railway" ""

    echo -e "\n${G}═══ Instance Ready ═══${N}"
    echo -e "  ${W}Provider:${N}  Railway"
    echo -e "  ${W}Name:${N}     ${name}"
    echo -e "  ${W}URL:${N}      ${url}"
    echo ""
}

# ── Koyeb Provider ─────────────────────────────────────────
koyeb_auth() {
    if ! has_cmd koyeb; then
        log_info "Installing Koyeb CLI..."
        curl -fsSL https://cli.koyeb.com/install.sh | sh 2>/dev/null
    fi
}

koyeb_create() {
    local name="${1:-abfool-$(date +%s)}"
    koyeb_auth
    log_info "Creating Koyeb app: ${name}..."
    koyeb apps create "$name" 2>&1 | tail -3
    db_save_instance "koyeb" "$name" "pending" "443" "koyeb" ""
    echo -e "${G}Koyeb app created: ${name}${N}"
}

# ── Generic Provider Actions ───────────────────────────────
provider_create() {
    local provider="${1:-}" name="${2:-}"
    if [[ -z "$provider" ]]; then
        echo "Usage: abfool-vps create <provider> [name]"
        echo "Available: flyio, codespaces, railway, koyeb, gitpod, huggingface, render, deno, vercel, netlify, ibm, northflank, cyclic"
        return 1
    fi

    case "$provider" in
        flyio)        flyio_create "$name" ;;
        codespaces|cs) cs_create "" "$name" ;;
        railway)      railway_create "$name" ;;
        koyeb)        koyeb_create "$name" ;;
        render)       log_info "Render: use web dashboard at https://render.com" ;;
        deno)         log_info "Deno Deploy: use web dashboard at https://deno.com/deploy" ;;
        vercel)       log_info "Vercel: use 'vercel' CLI or web dashboard" ;;
        netlify)      log_info "Netlify: use 'netlify' CLI or web dashboard" ;;
        ibm)          log_info "IBM Cloud: use 'ibmcloud' CLI" ;;
        *)            log_error "Unknown provider: $provider"; provider_list_all ;;
    esac
}

provider_list() {
    local provider="${1:-all}"
    if [[ "$provider" == "all" ]]; then
        echo -e "\n${W}Active Instances${N}"
        echo "─────────────────────────────────────────────────"
        db_list_instances
    else
        db_list_instances "$provider"
    fi
}

provider_ssh() {
    local provider="$1" name="$2"
    local ip port user pass
    read -r ip port user pass < <(db_get_instance "$provider" "$name")

    if [[ -z "$ip" ]]; then
        log_error "Instance not found: ${provider}/${name}"
        return 1
    fi

    log_info "Connecting to ${user}@${ip}:${port}..."
    if [[ -n "$pass" ]]; then
        echo -e "${D}Password: ${pass}${N}"
    fi
    ssh -i "$SSH_KEY_PATH" -p "$port" -o StrictHostKeyChecking=accept-new "${user}@${ip}"
}

provider_destroy() {
    local provider="$1" name="$2"
    confirm "Destroy ${provider}/${name}?" || return 0

    case "$provider" in
        flyio) flyctl apps destroy "$name" --force 2>/dev/null ;;
        codespaces) gh codespace delete "$name" --force 2>/dev/null ;;
        *) log_warn "Manual destroy required for ${provider}" ;;
    esac

    db_delete_instance "$provider" "$name"
    log_ok "Instance destroyed: ${provider}/${name}"
}

provider_config() {
    local subcmd="${1:-}" provider="${2:-}"
    case "$subcmd" in
        setup)
            case "$provider" in
                flyio) flyio_auth ;;
                codespaces) cs_auth ;;
                railway) railway_auth ;;
                koyeb) koyeb_auth ;;
                *) log_error "Unknown provider: $provider" ;;
            esac
            ;;
        *) echo "Usage: abfool-vps provider setup <name>" ;;
    esac
}

# ── Setup Wizard ───────────────────────────────────────────
run_setup_wizard() {
    echo -e "\n${W}═══ abfool VPS Orchestration Setup ═══${N}\n"

    generate_ssh_key

    echo -e "${C}Select providers to configure:${N}\n"
    local options=("Fly.io" "GitHub Codespaces" "Railway" "Koyeb" "Google Drive" "LLM API" "Notifications")
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}"
    done
    echo ""

    read -rp "Enter choices (e.g., 1,2,5): " choices

    IFS=',' read -ra selected <<< "$choices"
    for choice in "${selected[@]}"; do
        choice=$(echo "$choice" | tr -d ' ')
        case "$choice" in
            1) flyio_auth ;;
            2) cs_auth ;;
            3) railway_auth ;;
            4) koyeb_auth ;;
            5) log_info "Google Drive: run 'abfool-vps storage setup'" ;;
            6) log_info "LLM: run 'abfool-vps llm setup'" ;;
            7) log_info "Notifications: add telegram_bot_token etc. to config" ;;
        esac
    done

    echo -e "\n${G}Setup complete! Run 'abfool-vps create <provider>' to get started.${N}"
}
