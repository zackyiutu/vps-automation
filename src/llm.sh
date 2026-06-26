#!/usr/bin/env bash
# ============================================================
# llm.sh - LLM Integration for intelligent provisioning
# Supports: OpenAI, OpenRouter, LiteLLM, Ollama, custom
# ============================================================

source "${ABFOOL_ROOT}/src/lib.sh"

llm_cmd() {
    local subcmd="${1:-status}"
    shift 2>/dev/null || true

    case "$subcmd" in
        setup)  llm_setup ;;
        status) llm_status ;;
        ask)    llm_ask "$*" ;;
        *)      echo "Usage: abfool-vps llm [setup|status|ask <prompt>]" ;;
    esac
}

llm_setup() {
    echo -e "\n${W}═══ LLM Configuration ═══${N}\n"
    echo "Supported providers:"
    echo "  1. OpenAI (GPT-4, GPT-3.5)"
    echo "  2. OpenRouter (200+ models)"
    echo "  3. Ollama (local)"
    echo "  4. Custom endpoint"
    echo ""

    read -rp "Provider [1-4]: " choice
    local api_url api_key model

    case "$choice" in
        1) api_url="https://api.openai.com/v1"; read -rsp "OpenAI API Key: " api_key; echo; read -rp "Model [gpt-4]: " model; model="${model:-gpt-4}" ;;
        2) api_url="https://openrouter.ai/api/v1"; read -rsp "OpenRouter Key: " api_key; echo; read -rp "Model [openai/gpt-4]: " model; model="${model:-openai/gpt-4}" ;;
        3) api_url="http://localhost:11434/v1"; api_key="ollama"; read -rp "Model [llama3]: " model; model="${model:-llama3}" ;;
        4) read -rp "API URL: " api_url; read -rsp "API Key: " api_key; echo; read -rp "Model: " model ;;
    esac

    config_set "llm_api_url" "$api_url"
    config_set "llm_api_key" "$api_key"
    config_set "llm_model" "$model"
    config_set "llm_enabled" "true"

    log_ok "LLM configured: ${model} @ ${api_url}"
    llm_status
}

llm_status() {
    local api_url api_key model enabled
    api_url=$(config_get "llm_api_url" "")
    api_key=$(config_get "llm_api_key" "")
    model=$(config_get "llm_model" "")
    enabled=$(config_get "llm_enabled" "false")

    echo -e "\n${W}LLM Status${N}"
    echo "─────────────────────"
    echo -e "  Enabled:  ${enabled}"
    echo -e "  Provider: ${api_url:-not configured}"
    echo -e "  Model:    ${model:-not configured}"
    echo -e "  API Key:  $([ -n "$api_key" ] && echo '***configured***' || echo 'not set')"

    if [[ "$enabled" == "true" && -n "$api_url" ]]; then
        # Test connection
        local test_result
        test_result=$(curl -sf --max-time 10 "${api_url}/models" \
            -H "Authorization: Bearer ${api_key}" 2>/dev/null | head -c 100)
        if [[ -n "$test_result" ]]; then
            echo -e "  Status:   ${G}Connected${N}"
        else
            echo -e "  Status:   ${R}Connection failed${N}"
        fi
    fi
    echo ""
}

llm_ask() {
    local prompt="$1"
    local api_url api_key model
    api_url=$(config_get "llm_api_url" "")
    api_key=$(config_get "llm_api_key" "")
    model=$(config_get "llm_model" "")

    if [[ -z "$api_url" || -z "$api_key" ]]; then
        log_error "LLM not configured. Run 'abfool-vps llm setup'"
        return 1
    fi

    local response
    response=$(curl -sf --max-time 30 "${api_url}/chat/completions" \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${model}\",
            \"messages\": [{\"role\": \"user\", \"content\": \"${prompt}\"}],
            \"max_tokens\": 1000
        }" 2>/dev/null)

    if [[ -n "$response" ]]; then
        echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" 2>/dev/null || echo "$response"
    else
        log_error "LLM request failed"
        return 1
    fi
}

# LLM-powered worker task
llm_worker_task() {
    local task="$1"
    local api_url api_key model
    api_url=$(config_get "llm_api_url" "")
    api_key=$(config_get "llm_api_key" "")
    model=$(config_get "llm_model" "")

    if [[ -z "$api_url" || -z "$api_key" ]]; then
        log_error "LLM not configured"
        return 1
    fi

    local system_prompt="You are a VPS orchestration assistant. Generate bash commands to accomplish the given task. Output ONLY the bash commands, no explanation. The system runs on Linux with bash."

    local response
    response=$(curl -sf --max-time 60 "${api_url}/chat/completions" \
        -H "Authorization: Bearer ${api_key}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${model}\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"${system_prompt}\"},
                {\"role\": \"user\", \"content\": \"${task}\"}
            ],
            \"max_tokens\": 2000
        }" 2>/dev/null)

    local commands
    commands=$(echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" 2>/dev/null)

    if [[ -n "$commands" ]]; then
        echo -e "\n${W}Generated Commands:${N}"
        echo "$commands"
        echo ""
        if confirm "Execute these commands?"; then
            eval "$commands"
        fi
    fi
}
