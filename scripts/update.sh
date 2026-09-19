#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$ROOT_DIR/UPSTREAM.lock"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"

[[ "${EUID}" -eq 0 ]] || { echo "Esegui con sudo/root" >&2; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "Configurazione mancante: $ENV_FILE" >&2; exit 1; }

set -a
source "$ENV_FILE"
set +a

COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")
current="$("${COMPOSE[@]}" exec -T --user www-data web php bin/console suitecrm:version 2>/dev/null | tr -d '\r' | tail -n 1 || true)"

echo "Versione installata: ${current:-sconosciuta}"
echo "Versione GE360 fissata: $SUITECRM_VERSION"

if [[ "$current" == *"$SUITECRM_VERSION"* ]]; then
  echo "Nessun upgrade necessario."
  exit 0
fi

echo "Upgrade applicativo automatico sospeso per sicurezza."
echo "Prima di abilitare il salto di versione GE360 richiede un test della procedura ufficiale SuiteCRM."
echo "Esegui prima: ge360-suitecrm-backup"
exit 3
