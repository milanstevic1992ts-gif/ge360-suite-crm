#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/UPSTREAM.lock"

CONFIG_DIR="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}"
ENV_FILE="$CONFIG_DIR/suitecrm-engine.env"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
PROJECT="ge360-suitecrm"

fail() { echo "[GE360 SuiteCRM] ERRORE: $*" >&2; exit 1; }
info() { echo "[GE360 SuiteCRM] $*"; }

[[ "${EUID}" -eq 0 ]] || fail "esegui con sudo/root"

for cmd in docker openssl curl; do
  command -v "$cmd" >/dev/null 2>&1 || fail "manca il comando: $cmd"
done

docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 non disponibile"
docker info >/dev/null 2>&1 || fail "Docker daemon non raggiungibile"

detect_site_host() {
  local detected=""
  if command -v tailscale >/dev/null 2>&1; then
    detected="$(tailscale ip -4 2>/dev/null | head -n 1 || true)"
  fi
  if [[ -z "$detected" ]]; then
    detected="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  if [[ -z "$detected" ]]; then
    detected="127.0.0.1"
  fi
  printf "%s" "$detected"
}

mkdir -p "$CONFIG_DIR"
chmod 0755 "$CONFIG_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
  info "Genero configurazione locale e credenziali..."
  DB_PASSWORD="$(openssl rand -hex 24)"
  DB_ROOT_PASSWORD="$(openssl rand -hex 24)"
  ADMIN_PASSWORD="$(openssl rand -hex 12)"
  DETECTED_HOST="$(detect_site_host)"
  SITE_URL_DEFAULT="http://$DETECTED_HOST:8791"

  umask 077
  cat > "$ENV_FILE" <<EOF
SUITECRM_VERSION=$SUITECRM_VERSION
SUITECRM_URL=$SUITECRM_URL
SUITECRM_SHA256=$SUITECRM_SHA256
HTTP_PORT=8791
SITE_URL=$SITE_URL_DEFAULT
DB_NAME=suitecrm
DB_USER=suitecrm
DB_PASSWORD=$DB_PASSWORD
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
TZ=Europe/Rome
EOF
  chmod 0600 "$ENV_FILE"
fi

set -a
source "$ENV_FILE"
set +a

COMPOSE=(docker compose -p "$PROJECT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE")

if command -v ss >/dev/null 2>&1 && ss -ltnH 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)$HTTP_PORT$"; then
  if ! "${COMPOSE[@]}" ps --services --status running 2>/dev/null | grep -qx web; then
    fail "la porta $HTTP_PORT è già occupata da un altro servizio"
  fi
fi

info "Costruisco il runtime SuiteCRM $SUITECRM_VERSION..."
"${COMPOSE[@]}" build web

info "Avvio MariaDB..."
"${COMPOSE[@]}" up -d db

SITE_URL="${SITE_URL%/}/"

if "${COMPOSE[@]}" run --rm --no-deps --user www-data web test -f public/legacy/config.php >/dev/null 2>&1; then
  info "SuiteCRM risulta già inizializzato: non reinstallo il database."
else
  info "Eseguo l'installer CLI ufficiale SuiteCRM..."
  "${COMPOSE[@]}" run --rm --no-deps --user www-data web     php bin/console suitecrm:app:install       -u "$ADMIN_USERNAME"       -p "$ADMIN_PASSWORD"       -U "$DB_USER"       -P "$DB_PASSWORD"       -H "db"       -N "$DB_NAME"       -S "$SITE_URL"       -d "no"

  "${COMPOSE[@]}" run --rm --no-deps --user www-data web     sh -lc 'touch .env.local; grep -q "^APP_ENV=" .env.local || printf "\nAPP_ENV=prod\n" >> .env.local'
fi

info "Avvio web, scheduler e Messenger worker..."
"${COMPOSE[@]}" up -d web worker scheduler

info "Attendo la risposta HTTP..."
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${HTTP_PORT:-8791}/" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS "http://127.0.0.1:${HTTP_PORT:-8791}/" >/dev/null 2>&1; then
  "${COMPOSE[@]}" ps
  fail "SuiteCRM non risponde sulla porta ${HTTP_PORT:-8791}; esegui ge360-suitecrm-doctor"
fi

info "Installazione completata."
info "URL locale: http://127.0.0.1:${HTTP_PORT:-8791}"
info "URL configurato: $SITE_URL"
info "Admin: $ADMIN_USERNAME"
info "Password iniziale: $ADMIN_PASSWORD"
info "Credenziali salvate in: $ENV_FILE"
