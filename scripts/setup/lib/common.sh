#!/usr/bin/env bash
# lib/common.sh — shared helpers for stack-in-a-box setup scripts.
#
# Source this from each script:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   # shellcheck source=lib/common.sh
#   source "$SCRIPT_DIR/lib/common.sh"
#
# Provides:
#   - log_info / log_warn / log_error / log_ok / log_step  — coloured stderr output
#   - die <msg>                                            — log_error + exit 1
#   - require_cmd <cmd>                                    — assert a binary is on PATH
#   - require_root_or_sudo                                 — assert sudo is usable
#   - read_secret <prompt> <var_name> [<prefix_check>]     — read without echo, validate prefix
#   - file_contains_line <file> <line>                     — idempotent append helper
#   - append_line_if_missing <file> <line> [<sudo>]        — actually append it
#   - retry <n> <delay_sec> -- <cmd...>                    — retry with backoff
#   - confirm <prompt>                                     — y/N gate
#
# Conventions:
#   - All scripts use `set -euo pipefail` at the top.
#   - All scripts are idempotent: re-running is a no-op or refresh, never destructive.
#   - All scripts end with a verify_gate function that returns 0/1.

# Colours (auto-disable if not a tty)
if [[ -t 2 ]]; then
    readonly CLR_RED=$'\033[0;31m'
    readonly CLR_GREEN=$'\033[0;32m'
    readonly CLR_YELLOW=$'\033[0;33m'
    readonly CLR_BLUE=$'\033[0;34m'
    readonly CLR_RESET=$'\033[0m'
else
    readonly CLR_RED=''
    readonly CLR_GREEN=''
    readonly CLR_YELLOW=''
    readonly CLR_BLUE=''
    readonly CLR_RESET=''
fi

log_info()  { echo "${CLR_BLUE}[info]${CLR_RESET} $*" >&2; }
log_warn()  { echo "${CLR_YELLOW}[warn]${CLR_RESET} $*" >&2; }
log_error() { echo "${CLR_RED}[error]${CLR_RESET} $*" >&2; }
log_ok()    { echo "${CLR_GREEN}[ ok ]${CLR_RESET} $*" >&2; }
log_step()  { echo "" >&2; echo "${CLR_BLUE}==>${CLR_RESET} $*" >&2; }

die() {
    log_error "$*"
    exit 1
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "required command not found on PATH: $cmd"
    fi
}

require_root_or_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        log_info "this script needs sudo; you may be prompted for your password"
        sudo -v || die "sudo authentication failed"
    fi
}

# require_not_root — refuse to proceed when running as root.
# Use this in scripts that write to $HOME (oxy installer, dbt profile,
# venv creation). On EC2 the ubuntu user has NOPASSWD sudo, so the
# intended path is `bash bootstrap.sh` (running as ubuntu), with sudo
# escalation per-command. `sudo bash bootstrap.sh` would put $HOME=/root
# and silently misconfigure the install.
require_not_root() {
    if [[ $EUID -eq 0 ]]; then
        die "do not run as root — \$HOME would resolve to /root, breaking the install. run as the 'ubuntu' user; sudo is invoked internally where needed."
    fi
}

# read_secret <prompt> <out_var_name> [<required_prefix>] [<env_var_override>]
# Reads a line without echoing it. If <required_prefix> is given, rejects values
# that don't start with it (returns 1 after MAX_TRIES, default 3).
#
# If <env_var_override> is given AND that env var is set to a non-empty value
# matching the prefix, use it without prompting (supports non-interactive installs).
# Without an env-var override, fails immediately when stdin is not a TTY.
read_secret() {
    local prompt="$1"
    local var_name="$2"
    local prefix="${3:-}"
    local env_override="${4:-}"
    local max_tries="${MAX_TRIES:-3}"
    local value=""
    local tries=0

    # ---------- env-var override path (supports non-interactive installs) ----------
    if [[ -n "$env_override" ]]; then
        local env_value="${!env_override:-}"
        if [[ -n "$env_value" ]]; then
            # Same validation as interactive path: whitespace = bad.
            if [[ "$env_value" =~ [[:space:]] ]]; then
                log_error "$env_override contains whitespace; check for clipboard mishaps in your env setup"
                return 1
            fi
            if [[ -n "$prefix" ]] && [[ "$env_value" != "$prefix"* ]]; then
                log_error "$env_override does not match required prefix '$prefix'"
                return 1
            fi
            log_info "$env_override env var present; using it (no prompt)"
            printf -v "$var_name" '%s' "$env_value"
            return 0
        fi
    fi

    # ---------- interactive path ----------
    if [[ ! -t 0 ]]; then
        log_error "no TTY for prompt: $prompt"
        if [[ -n "$env_override" ]]; then
            log_error "for non-interactive installs, set $env_override before running"
        fi
        return 1
    fi

    while [[ $tries -lt $max_tries ]]; do
        tries=$((tries + 1))
        printf "%s" "$prompt" >&2
        IFS= read -rs value
        echo "" >&2
        if [[ -z "$value" ]]; then
            log_warn "empty input; try again ($tries/$max_tries)"
            continue
        fi
        # Reject values with embedded whitespace — usually a clipboard
        # mishap. If the user actually needs whitespace in a secret, they
        # can pass it via env-var override.
        if [[ "$value" =~ [[:space:]] ]]; then
            log_warn "value contains whitespace (clipboard mishap?); try again ($tries/$max_tries)"
            continue
        fi
        if [[ -n "$prefix" ]] && [[ "$value" != "$prefix"* ]]; then
            log_warn "value must start with '$prefix' ($tries/$max_tries)"
            continue
        fi
        printf -v "$var_name" '%s' "$value"
        return 0
    done

    log_error "too many invalid attempts"
    return 1
}

# file_contains_line <file> <line>  — returns 0 if exact line is present.
file_contains_line() {
    local file="$1"
    local line="$2"
    [[ -f "$file" ]] || return 1
    grep -Fxq -- "$line" "$file"
}

# append_line_if_missing <file> <line> [sudo]
# Appends a line to a file if not already present. Pass any third arg to use sudo.
append_line_if_missing() {
    local file="$1"
    local line="$2"
    local use_sudo="${3:-}"
    if file_contains_line "$file" "$line"; then
        return 0
    fi
    if [[ -n "$use_sudo" ]]; then
        echo "$line" | sudo tee -a "$file" >/dev/null
    else
        echo "$line" >> "$file"
    fi
}

# retry <max_attempts> <delay_sec> -- <cmd> [args...]
retry() {
    local max="$1"
    local delay="$2"
    shift 2
    [[ "$1" == "--" ]] && shift
    local attempt=1
    while [[ $attempt -le $max ]]; do
        if "$@"; then
            return 0
        fi
        if [[ $attempt -lt $max ]]; then
            log_warn "attempt $attempt/$max failed; retrying in ${delay}s..."
            sleep "$delay"
        fi
        attempt=$((attempt + 1))
    done
    log_error "all $max attempts failed: $*"
    return 1
}

confirm() {
    local prompt="$1"
    local reply
    printf "%s [y/N]: " "$prompt" >&2
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Project root resolution — every script can rely on $PROJECT_ROOT.
#
# Resolution order:
#   1. $PROJECT_ROOT env var (explicit override)
#   2. Walk up from $BASH_SOURCE looking for a .git or a marker file
#      (the repo root — robust to where the user cloned)
#   3. Fall back to /home/ubuntu/stack-in-a-box (legacy default)
#
# Important: do not `readonly` PROJECT_ROOT here — scripts may need to
# adjust it before sourcing common.sh in unusual layouts (CI, tests).
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    _lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # _lib_dir is .../scripts/setup/lib. Repo root is two levels up.
    _candidate="$(cd "$_lib_dir/../../.." && pwd)"
    if [[ -d "$_candidate/.git" ]] || [[ -f "$_candidate/.stack-in-a-box-root" ]]; then
        PROJECT_ROOT="$_candidate"
    else
        # Last resort — the documented default path.
        PROJECT_ROOT="/home/ubuntu/stack-in-a-box"
    fi
    unset _lib_dir _candidate
fi
export PROJECT_ROOT
