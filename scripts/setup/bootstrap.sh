#!/usr/bin/env bash
# bootstrap.sh — orchestrate scripts 01–10 in order, with checkpointing.
#
# Usage:
#   ./bootstrap.sh                          # run all scripts in order
#   ./bootstrap.sh --from 06                # resume from step 06
#   ./bootstrap.sh --only 09                # run only step 09 (e.g. retry smoke test)
#   ./bootstrap.sh --dry-run                # print the plan, do nothing
#
# Checkpointing:
#   Each successful script writes a marker to scratch/checkpoints/.
#   Re-running bootstrap.sh skips checkpointed steps unless --force is set.
#
# Special exit codes from individual scripts:
#   100 = reboot required; user reconnects and reruns bootstrap.sh.
#
# After step 06 (Tailscale), bootstrap.sh STOPS and waits for the user
# to close the AWS SG and verify Tailnet SSH. Resume with `--from 07`.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- single-instance guard ----------
# Prevent two bootstrap.sh runs in parallel (e.g. two SSH sessions where
# the user forgot they'd already started). Concurrent installs hit apt
# locks, race on /etc/environment writes, and generally corrupt state.
readonly BOOTSTRAP_LOCK="/tmp/stack-in-a-box-bootstrap.lock"
exec {LOCK_FD}>"$BOOTSTRAP_LOCK"
if ! flock -n "$LOCK_FD"; then
    echo "[error] another bootstrap.sh is running (lock: $BOOTSTRAP_LOCK)" >&2
    echo "[error] if you are sure no other run is active, remove the lock file and retry." >&2
    exit 1
fi

# ---------- fail fast on missing sudo (don't hang waiting for password) ----------
if [[ $EUID -ne 0 ]]; then
    if ! sudo -n true 2>/dev/null; then
        echo "[error] this script needs passwordless sudo, but 'sudo -n true' failed." >&2
        echo "[error] on standard Ubuntu Cloud AMIs the 'ubuntu' user has NOPASSWD sudo via" >&2
        echo "[error] /etc/sudoers.d/90-cloud-init-users. if you're on a custom AMI, verify." >&2
        exit 1
    fi
fi

readonly CHECKPOINT_DIR="$PROJECT_ROOT/scratch/checkpoints"
readonly STEPS=(
    "00:00_preflight.sh"
    "01:01_ec2_bootstrap.sh"
    "02:02_install_docker.sh"
    "03:03_install_oxygen.sh"
    "05:05_clone_and_config.sh"   # Note: 05 before 04, so requirements.txt exists.
    "04:04_python_venv.sh"
    "06:06_tailscale_join.sh"
    "07:07_nginx_site.sh"
    "08:08_systemd_units.sh"
    "09:09_first_run.sh"
    "10:10_verify.sh"
)

main() {
    local from=""
    local only=""
    local dry_run=0
    local force=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from)   from="$2"; shift 2 ;;
            --only)   only="$2"; shift 2 ;;
            --dry-run) dry_run=1; shift ;;
            --force)  force=1; shift ;;
            --help|-h)
                cat <<'EOF'
Usage: ./bootstrap.sh [--from NN] [--only NN] [--dry-run] [--force]
  --from NN    resume from step NN (e.g. 07 to skip preflight + earlier)
  --only NN    run only step NN (no checkpoint logic)
  --dry-run    print plan, do nothing
  --force      re-run steps even if checkpointed as done
EOF
                exit 0
                ;;
            *) die "unknown arg: $1 (use --help)" ;;
        esac
    done

    # ---------- normalize step IDs (accept "9" as well as "09") ----------
    # Validate before invoking printf so we don't leak a raw bash error.
    if [[ -n "$from" ]]; then
        if [[ ! "$from" =~ ^[0-9]+$ ]]; then
            die "invalid --from: $from (must be a number, e.g. 07)"
        fi
        from="$(printf '%02d' "$((10#$from))")"
    fi
    if [[ -n "$only" ]]; then
        if [[ ! "$only" =~ ^[0-9]+$ ]]; then
            die "invalid --only: $only (must be a number, e.g. 09)"
        fi
        only="$(printf '%02d' "$((10#$only))")"
    fi

    mkdir -p "$CHECKPOINT_DIR"

    # ---------- determine which steps to run ----------
    # IMPORTANT: STEPS is in execution order, not numeric order (step 05
    # runs BEFORE step 04 because 05 clones the repo containing the
    # requirements.txt that step 04 installs from). The --from filter
    # must respect execution order, not numeric ordering, or resume
    # operations will silently skip prerequisites.
    local steps_to_run=()
    local step num path seen_from=0
    for step in "${STEPS[@]}"; do
        num="${step%%:*}"
        path="${step#*:}"
        if [[ -n "$only" ]]; then
            if [[ "$num" == "$only" ]]; then
                steps_to_run+=("$step")
            fi
        elif [[ -n "$from" ]]; then
            # Position-based filter: once we hit the named step in the
            # execution-order STEPS array, include it and everything after.
            if [[ "$num" == "$from" ]]; then
                seen_from=1
            fi
            if [[ $seen_from -eq 1 ]]; then
                steps_to_run+=("$step")
            fi
        else
            steps_to_run+=("$step")
        fi
    done

    # If --from was given but never matched, fail loud.
    if [[ -n "$from" ]] && [[ $seen_from -eq 0 ]]; then
        die "--from $from did not match any step; valid: 00 01 02 03 04 05 06 07 08 09 10"
    fi

    if [[ ${#steps_to_run[@]} -eq 0 ]]; then
        die "no steps match the given filters"
    fi

    # ---------- print plan ----------
    log_step "bootstrap plan"
    log_info "(note: 05 runs before 04 — clone deposits requirements.txt that 04 reads)"
    for step in "${steps_to_run[@]}"; do
        num="${step%%:*}"
        path="${step#*:}"
        if is_checkpointed "$num" && [[ $force -eq 0 ]] && [[ -z "$only" ]]; then
            log_info "  [skip-done] $num  $path"
        else
            log_info "  [will-run]  $num  $path"
        fi
    done

    if [[ $dry_run -eq 1 ]]; then
        log_info "(dry-run; exiting)"
        exit 0
    fi

    if ! confirm "Proceed?"; then
        log_info "aborted by user"
        exit 0
    fi

    # ---------- execute ----------
    for step in "${steps_to_run[@]}"; do
        num="${step%%:*}"
        path="$SCRIPT_DIR/${step#*:}"
        if is_checkpointed "$num" && [[ $force -eq 0 ]] && [[ -z "$only" ]]; then
            log_info "==> skipping $num (already checkpointed; --force to re-run)"
            continue
        fi

        log_step "running step $num"

        # Tailscale step prints lockdown instructions and exits 0 — we
        # honour the user's manual checkpoint by stopping here.
        local rc=0
        bash "$path" || rc=$?

        if [[ $rc -eq 0 ]]; then
            mark_checkpointed "$num"
            log_ok "step $num complete"

            if [[ "$num" == "06" ]]; then
                cat >&2 <<EOF
${CLR_YELLOW}========================================================================${CLR_RESET}
${CLR_YELLOW}PAUSED at step 06 (Tailscale)${CLR_RESET}
${CLR_YELLOW}========================================================================${CLR_RESET}

bootstrap.sh stops here. Complete the manual AWS SG lockdown above,
verify Tailnet SSH from your laptop, then resume:

    ./bootstrap.sh --from 07

${CLR_YELLOW}========================================================================${CLR_RESET}
EOF
                exit 0
            fi
        elif [[ $rc -eq 100 ]]; then
            log_warn "step $num requested a reboot; rerun bootstrap.sh after SSH comes back"
            exit 100
        else
            log_error "step $num failed with exit $rc"
            log_error "fix the issue, then either:"
            log_error "  ./bootstrap.sh --only $num     # retry this step alone"
            log_error "  ./bootstrap.sh --from $num     # retry from here"
            exit "$rc"
        fi
    done

    log_step "bootstrap complete"
    log_ok "all requested steps finished"
}

is_checkpointed() {
    [[ -f "$CHECKPOINT_DIR/step_$1.done" ]]
}

mark_checkpointed() {
    touch "$CHECKPOINT_DIR/step_$1.done"
}

main "$@"
