#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"

[[ "${EUID}" -eq 0 ]] || { echo "Esegui con sudo/root: sudo ge360-suitecrm-status" >&2; exit 1; }

[[ -f "$ENV_FILE" ]] || { echo "Configurazione non trovata: $ENV_FILE" >&2; exit 1; }

set -a
source "$ENV_FILE"
set +a

COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")

"${COMPOSE[@]}" ps

echo
echo "Versione:"
"${COMPOSE[@]}" exec -T --user www-data web php bin/console suitecrm:version 2>/dev/null || echo "non disponibile"

echo
echo "HTTP:"
if curl -fsS "http://127.0.0.1:${HTTP_PORT:-8791}/" >/dev/null 2>&1; then
  echo "OK - http://127.0.0.1:${HTTP_PORT:-8791}"
else
  echo "ERROR - nessuna risposta HTTP"
  exit 1
fi
