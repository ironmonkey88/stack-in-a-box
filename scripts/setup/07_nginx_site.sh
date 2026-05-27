#!/usr/bin/env bash
# 07_nginx_site.sh — install nginx, deploy first-boot portal, drop site config.
#
# Idempotent: re-running re-deploys the canonical site config, leaving
# already-installed nginx alone. The first-boot portal copy is
# idempotently re-deployed (overwriting only if the in-repo source has
# changed).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly NGINX_DOCROOT="/var/www/stack-in-a-box"
readonly NGINX_SITE_NAME="stack-in-a-box"
readonly NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$NGINX_SITE_NAME"
readonly NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE_NAME"
readonly REPO_NGINX_CONF="$PROJECT_ROOT/nginx/stack-in-a-box.conf"
readonly REPO_PORTAL_HTML="$PROJECT_ROOT/portal/index.html"

main() {
    log_step "07 — nginx site"
    require_root_or_sudo

    # ---------- install nginx ----------
    if command -v nginx >/dev/null 2>&1; then
        log_ok "nginx already installed: $(nginx -v 2>&1)"
    else
        log_info "installing nginx..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx
        log_ok "nginx installed"
    fi

    # ---------- docroot ----------
    if [[ ! -d "$NGINX_DOCROOT" ]]; then
        log_info "creating $NGINX_DOCROOT..."
        sudo mkdir -p "$NGINX_DOCROOT"
    fi
    # nginx www-data owns the docroot
    sudo chown -R www-data:www-data "$NGINX_DOCROOT"
    sudo chmod 755 "$NGINX_DOCROOT"

    # ---------- first-boot portal ----------
    if [[ ! -f "$REPO_PORTAL_HTML" ]]; then
        die "$REPO_PORTAL_HTML missing — was the repo cloned correctly?"
    fi
    log_info "deploying first-boot portal..."
    sudo cp "$REPO_PORTAL_HTML" "$NGINX_DOCROOT/index.html"
    sudo chown www-data:www-data "$NGINX_DOCROOT/index.html"
    log_ok "portal/index.html deployed to $NGINX_DOCROOT/index.html"

    # ---------- site config ----------
    if [[ ! -f "$REPO_NGINX_CONF" ]]; then
        die "$REPO_NGINX_CONF missing — was the repo cloned correctly?"
    fi
    log_info "deploying nginx site config..."
    sudo cp "$REPO_NGINX_CONF" "$NGINX_SITE_AVAILABLE"

    # Symlink into sites-enabled (idempotent — -f forces if already present)
    sudo ln -sf "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"
    log_ok "site enabled: $NGINX_SITE_ENABLED"

    # Disable the default site — its /var/www/html docroot is a footgun.
    # Somerville Session 12 deployed to the wrong docroot for an hour
    # before figuring out the default site was shadowing intent.
    if [[ -L /etc/nginx/sites-enabled/default ]]; then
        log_info "disabling default site (was shadowing our docroot)..."
        sudo rm -f /etc/nginx/sites-enabled/default
        log_ok "default site disabled"
    else
        log_ok "default site already disabled"
    fi

    # ---------- syntax check ----------
    log_info "running nginx -t..."
    if ! sudo nginx -t 2>&1 | tee /tmp/nginx-t.log; then
        log_error "nginx config syntax check failed (see above)"
        die "fix nginx config and rerun"
    fi
    rm -f /tmp/nginx-t.log

    # ---------- enable at boot (idempotent — safe to always run) ----------
    sudo systemctl enable nginx >/dev/null 2>&1 || true

    # ---------- reload or start ----------
    if systemctl is-active nginx >/dev/null 2>&1; then
        log_info "reloading nginx..."
        sudo systemctl reload nginx
    else
        log_info "starting nginx..."
        sudo systemctl start nginx
    fi

    verify_gate
}

verify_gate() {
    log_step "07 — verify gate"
    local failures=0

    if systemctl is-active nginx >/dev/null 2>&1; then
        log_ok "nginx: active"
    else
        log_error "nginx: not active"
        failures=$((failures + 1))
    fi

    if systemctl is-enabled nginx >/dev/null 2>&1; then
        log_ok "nginx: enabled"
    else
        log_warn "nginx not enabled at boot (use 'sudo systemctl enable nginx')"
    fi

    # Default site should NOT be enabled
    if [[ -L /etc/nginx/sites-enabled/default ]]; then
        log_error "default site is enabled — will shadow our docroot"
        failures=$((failures + 1))
    else
        log_ok "default site disabled"
    fi

    # Curl localhost /
    local http_code
    http_code="$(curl -sI -o /dev/null -w '%{http_code}' http://localhost/ || echo 000)"
    if [[ "$http_code" == "200" ]]; then
        log_ok "GET / → 200"
    else
        log_error "GET / → $http_code (expected 200)"
        failures=$((failures + 1))
    fi

    # Body contains the project name (proves OUR portal is serving, not nginx default)
    if curl -s http://localhost/ | grep -qi "stack-in-a-box\|first-boot\|smoke test pending"; then
        log_ok "portal body matches first-boot template"
    else
        log_error "portal body looks like default nginx welcome, not our portal"
        failures=$((failures + 1))
    fi

    # /docs should 404 cleanly (dbt docs don't exist yet) — proves the
    # alias location matches; if we got 502 here, the alias is wrong.
    local docs_code
    docs_code="$(curl -sI -o /dev/null -w '%{http_code}' http://localhost/docs/ || echo 000)"
    if [[ "$docs_code" == "404" ]] || [[ "$docs_code" == "200" ]]; then
        log_ok "GET /docs/ → $docs_code (expected 404 or 200 pre-pipeline)"
    elif [[ "$docs_code" == "403" ]]; then
        log_warn "GET /docs/ → 403 — probably /home/ubuntu mode issue; check 755"
    else
        log_error "GET /docs/ → $docs_code (expected 404 or 200)"
        failures=$((failures + 1))
    fi

    if [[ $failures -eq 0 ]]; then
        log_ok "07 — passed"
        return 0
    else
        log_error "07 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
