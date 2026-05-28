#!/usr/bin/env bash
# 05_clone_and_config.sh — clone the template repo, capture API key,
# write /etc/environment correctly (a notoriously easy step to get wrong
# under non-interactive SSH — see comments below for the why).
#
# Idempotent: re-cloning is skipped if the working tree exists.
# Re-running the env-var write is safe (append_line_if_missing).
#
# Order matters within this script:
#   1. Clone the repo into $PROJECT_ROOT
#   2. Read Anthropic API key (validated against sk-ant- prefix)
#   3. Write env vars to /etc/environment (NOT ~/.bashrc, NOT ~/.profile;
#      see "Why /etc/environment" comment below)
#   4. Fix PATH in /etc/environment to include ~/.local/bin and venv
#   5. Copy config.example.yml → config.yml and substitute tokens
#   6. Copy dbt/profiles.example.yml → ~/.dbt/profiles.yml

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Default repo URL — override with TEMPLATE_REPO_URL env var if you've forked.
# NOTE: if the repo is renamed in a future plan, update this URL.
readonly DEFAULT_REPO_URL="https://github.com/ironmonkey88/stack-in-a-box.git"
readonly REPO_URL="${TEMPLATE_REPO_URL:-$DEFAULT_REPO_URL}"

# Default config substitutions — these become the project's identity on this host.
readonly PROJECT_NAME="${PROJECT_NAME:-stack-in-a-box}"
readonly DUCKDB_PATH="$PROJECT_ROOT/data/stack.duckdb"

main() {
    log_step "05 — clone template + configure"
    require_not_root
    require_root_or_sudo

    # ---------- clone ----------
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        log_ok "repo already present at $PROJECT_ROOT"
        log_info "(re-clone disabled; rm -rf the dir and rerun if you need a fresh clone)"
    else
        # This block handles the case where bootstrap.sh was fetched via curl
        # (e.g., `curl -fsSL .../bootstrap.sh | bash`) rather than git clone.
        # The README + CLAUDE.md document the clone-first flow, but the one-liner
        # fetch is a reasonable future invocation and ripping out this defensive
        # code is premature minimization.
        log_info "cloning $REPO_URL into $PROJECT_ROOT..."
        # The directory was created in 01; git clone won't clone into a
        # non-empty dir, so we use the "clone into temp + move" pattern.
        local tmp_clone
        tmp_clone="$(mktemp -d)"
        if ! git clone --depth 1 "$REPO_URL" "$tmp_clone/repo"; then
            rm -rf "$tmp_clone"
            die "git clone failed — check REPO_URL ($REPO_URL) and network"
        fi
        # Move git tree + contents into PROJECT_ROOT, preserving the
        # data/scratch/logs dirs that script 01 made.
        # We fail loud if the move can't complete — a silent failure
        # here breaks every subsequent script with a confusing error.
        shopt -s dotglob
        if ! mv "$tmp_clone/repo/"* "$PROJECT_ROOT/"; then
            shopt -u dotglob
            rm -rf "$tmp_clone"
            die "failed to move repo contents into $PROJECT_ROOT — is the dir non-empty with conflicting files?"
        fi
        shopt -u dotglob
        rm -rf "$tmp_clone"

        # Sanity check — .git should now be at PROJECT_ROOT.
        if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
            die "clone reported success but .git not at $PROJECT_ROOT — investigate"
        fi
        log_ok "repo cloned"
    fi

    cd "$PROJECT_ROOT"

    # ---------- Anthropic API key ----------
    local existing_key="" new_key=""
    if grep -q '^ANTHROPIC_API_KEY=' /etc/environment 2>/dev/null; then
        existing_key="$(sudo grep '^ANTHROPIC_API_KEY=' /etc/environment | cut -d= -f2-)"
    fi

    if [[ -n "$existing_key" ]] && [[ "$existing_key" =~ ^sk-ant- ]]; then
        log_ok "ANTHROPIC_API_KEY already configured in /etc/environment"
        log_info "(starts with $(echo "$existing_key" | head -c 14)...)"
        if ! confirm "Replace with a new key?"; then
            log_info "keeping existing key"
        else
            read_secret "Paste Anthropic API key (sk-ant-...): " new_key "sk-ant-" "ANTHROPIC_API_KEY" || die "key entry failed"
            write_env_var ANTHROPIC_API_KEY "$new_key"
        fi
    else
        log_info "ANTHROPIC_API_KEY not yet set; prompting..."
        read_secret "Paste Anthropic API key (sk-ant-...): " new_key "sk-ant-" "ANTHROPIC_API_KEY" || die "key entry failed"
        write_env_var ANTHROPIC_API_KEY "$new_key"
    fi

    # ---------- OXY_DATABASE_URL ----------
    # This is the Postgres connection string for the docker-managed db
    # that `oxy start --local` brings up. The port is the container's
    # exposed port; the credentials are Oxygen's defaults (the container
    # is on localhost only, so this is fine).
    write_env_var OXY_DATABASE_URL "postgresql://postgres:postgres@localhost:15432/oxy"

    # ---------- PATH fix ----------
    # /etc/environment ships with a single PATH= line. We need
    # ~/.local/bin (for oxy) and the venv bin (for dlt/dbt) on PATH for
    # non-interactive SSH (`ssh ec2 'cmd'`).
    #
    # Why /etc/environment and not ~/.bashrc:
    #   - sshd reads /etc/environment via PAM (pam_env.so) at session
    #     setup; works for both login and non-login shells.
    #   - ~/.bashrc early-returns for non-interactive shells (won't run
    #     under `ssh ec2 'cmd'`).
    #   - ~/.profile is login-shell only.
    #   - Format: literal KEY=VALUE, no `export`, no shell expansion.
    log_info "ensuring ~/.local/bin and venv on /etc/environment PATH..."
    local local_bin="/home/ubuntu/.local/bin"
    local venv_bin="$PROJECT_ROOT/.venv/bin"

    # Read current PATH from /etc/environment
    local current_path
    current_path="$(sudo grep -E '^PATH=' /etc/environment 2>/dev/null | sed -E 's/^PATH="?([^"]*)"?$/\1/' || true)"

    if [[ -z "$current_path" ]]; then
        # No PATH line at all — write a sensible default
        log_warn "no PATH= in /etc/environment; writing default"
        echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$local_bin:$venv_bin\"" | sudo tee -a /etc/environment >/dev/null
    else
        # Append local_bin + venv_bin if not already present
        local new_path="$current_path"
        if [[ ":$current_path:" != *":$local_bin:"* ]]; then
            new_path="$new_path:$local_bin"
        fi
        if [[ ":$current_path:" != *":$venv_bin:"* ]]; then
            new_path="$new_path:$venv_bin"
        fi
        if [[ "$new_path" != "$current_path" ]]; then
            sudo sed -i "s|^PATH=.*$|PATH=\"$new_path\"|" /etc/environment
            log_ok "PATH updated: added $local_bin, $venv_bin"
        else
            log_ok "PATH already contains local_bin + venv_bin"
        fi
    fi

    # ---------- config.yml ----------
    if [[ ! -f "$PROJECT_ROOT/config.example.yml" ]]; then
        die "$PROJECT_ROOT/config.example.yml missing — was the repo cloned correctly?"
    fi
    if [[ -f "$PROJECT_ROOT/config.yml" ]]; then
        log_ok "config.yml already exists; leaving in place"
    else
        log_info "creating config.yml from template..."
        sed \
            -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
            -e "s|{{DUCKDB_PATH}}|$DUCKDB_PATH|g" \
            "$PROJECT_ROOT/config.example.yml" > "$PROJECT_ROOT/config.yml"
        log_ok "config.yml written"
    fi

    # ---------- dbt profiles ----------
    mkdir -p "$HOME/.dbt"
    if [[ -f "$HOME/.dbt/profiles.yml" ]]; then
        log_ok "$HOME/.dbt/profiles.yml already exists; leaving in place"
    elif [[ ! -f "$PROJECT_ROOT/dbt/profiles.example.yml" ]]; then
        log_warn "$PROJECT_ROOT/dbt/profiles.example.yml not found; skipping profile setup"
    else
        log_info "creating ~/.dbt/profiles.yml from template..."
        sed \
            -e "s|{{DUCKDB_PATH}}|$DUCKDB_PATH|g" \
            -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
            "$PROJECT_ROOT/dbt/profiles.example.yml" > "$HOME/.dbt/profiles.yml"
        chmod 600 "$HOME/.dbt/profiles.yml"
        log_ok "$HOME/.dbt/profiles.yml written"
    fi

    verify_gate
}

# write_env_var KEY VALUE — append-or-replace a KEY=VALUE line in /etc/environment.
write_env_var() {
    local key="$1"
    local value="$2"

    # Use a temp file + sudo install pattern rather than `sudo sed -i "s|...|...|"`
    # to avoid passing the secret value as a sed argv argument (briefly
    # visible to `ps auxww`). On single-user EC2 this is near-zero risk,
    # but the cost of fixing is one extra file write — worth it.
    local tmp
    tmp="$(mktemp)"
    chmod 600 "$tmp"

    if sudo grep -q "^${key}=" /etc/environment 2>/dev/null; then
        # Filter out the existing line, then append the new one. The
        # secret value is on stdin via heredoc, not in argv.
        # shellcheck disable=SC2024  # $tmp is a user-owned mktemp file, so the
        # redirect doesn't need root; sudo is only on the read, in case a future
        # hardening tightens /etc/environment from 644 to 640.
        sudo grep -v "^${key}=" /etc/environment > "$tmp"
        printf '%s=%s\n' "$key" "$value" >> "$tmp"
        sudo install -m 0644 -o root -g root "$tmp" /etc/environment
        log_ok "$key updated in /etc/environment"
    else
        # Append path — value goes on stdin to tee, not in argv.
        printf '%s=%s\n' "$key" "$value" | sudo tee -a /etc/environment >/dev/null
        log_ok "$key written to /etc/environment"
    fi

    rm -f "$tmp"
}

verify_gate() {
    log_step "05 — verify gate"
    local failures=0

    # /etc/environment has the expected entries
    if sudo grep -q '^ANTHROPIC_API_KEY=sk-ant-' /etc/environment; then
        log_ok "/etc/environment has ANTHROPIC_API_KEY"
    else
        log_error "/etc/environment missing ANTHROPIC_API_KEY"
        failures=$((failures + 1))
    fi

    if sudo grep -q '^OXY_DATABASE_URL=' /etc/environment; then
        log_ok "/etc/environment has OXY_DATABASE_URL"
    else
        log_error "/etc/environment missing OXY_DATABASE_URL"
        failures=$((failures + 1))
    fi

    if sudo grep -E '^PATH=' /etc/environment | grep -q '.local/bin'; then
        log_ok "/etc/environment PATH contains ~/.local/bin"
    else
        log_error "/etc/environment PATH missing ~/.local/bin"
        failures=$((failures + 1))
    fi

    # config.yml has no unsubstituted tokens
    if [[ -f "$PROJECT_ROOT/config.yml" ]]; then
        if grep -q '{{' "$PROJECT_ROOT/config.yml"; then
            log_error "config.yml has unsubstituted {{tokens}}"
            grep '{{' "$PROJECT_ROOT/config.yml" >&2
            failures=$((failures + 1))
        else
            log_ok "config.yml fully substituted"
        fi
    fi

    # Repo present
    if [[ -d "$PROJECT_ROOT/.git" ]]; then
        log_ok "git repo present at $PROJECT_ROOT"
    else
        log_error "git repo missing at $PROJECT_ROOT"
        failures=$((failures + 1))
    fi

    # IMPORTANT: We do NOT here verify the env vars are visible in a new
    # SSH session — that requires actually exiting and reconnecting. The
    # bootstrap.sh wrapper prints instructions for the user to verify
    # manually before script 06.

    if [[ $failures -eq 0 ]]; then
        log_ok "05 — passed"
        log_warn ""
        log_warn "IMPORTANT: env vars in /etc/environment load at SSH session START."
        log_warn "To verify in this shell, run: source /etc/environment && echo \$ANTHROPIC_API_KEY"
        log_warn "Or reconnect via SSH and they will be present automatically."
        return 0
    else
        log_error "05 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
