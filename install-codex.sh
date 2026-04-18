#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOKEN="${CODEX_TOKEN:-${CODESOME_API_KEY:-${OPENAI_API_KEY:-}}}"
BASE_URL="${CODEX_API_URL:-https://cc.codesome.ai}"
MODEL="${CODEX_MODEL:-gpt-5.4}"
REVIEW_MODEL="${CODEX_REVIEW_MODEL:-gpt-5.4}"
REASONING_EFFORT="${CODEX_REASONING_EFFORT:-xhigh}"
CODEX_DIR="$HOME/.codex"
CONFIG_FILE="$CODEX_DIR/config.toml"

print_step() {
    echo -e "${CYAN}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_shell_config() {
    if [[ "${SHELL:-}" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
}

show_help() {
    cat <<EOF
Codesome Codex installer

Usage:
  CODEX_TOKEN="your_api_key" bash -c "\$(curl -fsSL RAW_URL/install-codex.sh)"

Environment variables:
  CODEX_TOKEN            Required. Codesome API key.
  CODESOME_API_KEY       Alias for CODEX_TOKEN.
  OPENAI_API_KEY         Fallback alias for CODEX_TOKEN.
  CODEX_API_URL          Optional. Default: https://cc.codesome.ai
  CODEX_MODEL            Optional. Default: gpt-5.4
  CODEX_REVIEW_MODEL     Optional. Default: gpt-5.4
  CODEX_REASONING_EFFORT Optional. Default: xhigh
EOF
    exit 0
}

install_nvm() {
    print_step "NVM" "Installing NVM..."
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"

    if command_exists curl; then
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    elif command_exists wget; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    else
        print_error "curl or wget is required to install NVM"
    fi

    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    print_success "NVM installed"
}

ensure_node_and_npm() {
    if command_exists node && command_exists npm; then
        print_success "Node.js detected: $(node --version)"
        print_success "npm detected: $(npm --version)"
        return 0
    fi

    print_info "Node.js/npm not found, installing with NVM..."
    export NVM_DIR="$HOME/.nvm"

    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        install_nvm
    fi

    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    print_success "Node.js installed via NVM: $(node --version)"
}

install_codex() {
    print_step "1/4" "Installing @openai/codex..."
    ensure_node_and_npm
    npm install -g @openai/codex
    print_success "Codex CLI installed"
}

backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp "$file_path" "${file_path}.backup.${timestamp}"
        print_info "Backed up existing file: ${file_path}.backup.${timestamp}"
    fi
}

write_config() {
    print_step "2/4" "Writing Codex config..."
    mkdir -p "$CODEX_DIR"
    backup_file "$CONFIG_FILE"
    cat > "$CONFIG_FILE" <<EOF
model_provider = "codesome"
model = "$MODEL"
review_model = "$REVIEW_MODEL"
model_reasoning_effort = "$REASONING_EFFORT"
preferred_auth_method = "apikey"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.codesome]
name = "codesome"
base_url = "$BASE_URL"
wire_api = "responses"
env_key = "CODESOME_API_KEY"
EOF
    print_success "Config written to $CONFIG_FILE"
}

persist_api_key() {
    print_step "3/4" "Persisting API key to shell config..."
    detect_shell_config
    backup_file "$SHELL_CONFIG"
    export CODESOME_API_KEY="$TOKEN"

    touch "$SHELL_CONFIG"
    if grep -q 'export CODESOME_API_KEY=' "$SHELL_CONFIG" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|export CODESOME_API_KEY=.*|export CODESOME_API_KEY=\"$TOKEN\"|" "$SHELL_CONFIG"
        else
            sed -i "s|export CODESOME_API_KEY=.*|export CODESOME_API_KEY=\"$TOKEN\"|" "$SHELL_CONFIG"
        fi
        print_info "Updated CODESOME_API_KEY in $SHELL_CONFIG"
    else
        {
            echo
            echo "# Codesome Codex API key"
            echo "export CODESOME_API_KEY=\"$TOKEN\""
        } >> "$SHELL_CONFIG"
        print_success "Added CODESOME_API_KEY to $SHELL_CONFIG"
    fi
}

verify_install() {
    print_step "4/4" "Verifying installation..."
    if codex --version >/dev/null 2>&1; then
        print_success "codex --version succeeded"
    else
        print_warning "codex command did not verify in the current shell"
        detect_shell_config
        print_info "Try reloading your shell: source $SHELL_CONFIG"
    fi
}

show_summary() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}         Codesome Codex Setup Complete        ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo
    echo "Config: $CONFIG_FILE"
    echo "Base:   $BASE_URL"
    echo "Model:  $MODEL"
    echo "Env:    CODESOME_API_KEY"
    echo
    echo "Next:"
    echo "  1. Open a new terminal or run: source $SHELL_CONFIG"
    echo "  2. Run: codex"
    echo
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        show_help
    fi

    if [ -z "$TOKEN" ]; then
        print_error "CODEX_TOKEN is required"
    fi

    install_codex
    write_config
    persist_api_key
    verify_install
    show_summary
}

trap 'print_error "Script failed near line $LINENO"' ERR

main "$@"
