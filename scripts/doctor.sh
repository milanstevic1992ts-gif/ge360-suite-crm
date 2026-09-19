#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"
errors=0

ok() { echo "OK      $*"; }
warn() { echo "WARNING $*"; }
bad() { echo "ERROR   $*"; errors=$((errors+1)); }

command -v docker >/dev/null 2>&1 && ok "Docker disponibile" || bad "Docker non trovato"
docker compose version >/dev/null 2>&1 && ok "Docker Compose v2 disponibile" || bad "Docker Compose v2 non disponibile"

if [[ -f "$ENV_FILE" ]]; then
  ok "Configurazione presente: $ENV_FILE"
  set -a
  source "$ENV_FILE"
  set +a
else
  bad "Configurazione mancante: $ENV_FILE"
fi

if [[ -f "$ENV_FILE" ]] && command -v docker >/dev/null 2>&1; then
  COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")

  for svc in db web worker scheduler; do
    if "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -qx "$svc"; then
      ok "container $svc attivo"
    else
      bad "container $svc non attivo"
    fi
  done

  if "${COMPOSE[@]}" exec -T db mariadb-admin ping -h 127.0.0.1 -u"$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
    ok "MariaDB raggiungibile"
  else
    bad "MariaDB non raggiungibile"
  fi

  if curl -fsS "http://127.0.0.1:${HTTP_PORT:-8791}/" >/dev/null 2>&1; then
    ok "SuiteCRM risponde via HTTP"
  else
    bad "SuiteCRM non risponde via HTTP"
  fi

  version="$("${COMPOSE[@]}" exec -T --user www-data web php bin/console suitecrm:version 2>/dev/null | tr -d '\r' | tail -n 1)"
  [[ -n "$version" ]] && ok "versione installata: $version" || warn "versione SuiteCRM non rilevata"

  if "${COMPOSE[@]}" exec -T worker sh -lc 'ps aux | grep "[m]essenger:consume" >/dev/null' 2>/dev/null; then
    ok "Messenger worker in esecuzione"
  else
    bad "Messenger worker non rilevato"
  fi
fi

avail="$(df -Pk / 2>/dev/null | awk 'NR==2 {print $4}')"
if [[ -n "$avail" && "$avail" -lt 2097152 ]]; then
  warn "meno di 2 GiB liberi sul filesystem root"
else
  ok "spazio disco di base disponibile"
fi

exit "$errors"
