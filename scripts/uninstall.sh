#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"
PURGE="${1:-}"

[[ "${EUID}" -eq 0 ]] || { echo "Esegui con sudo/root" >&2; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "Configurazione non trovata: $ENV_FILE" >&2; exit 1; }

COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")

if [[ "$PURGE" == "--purge" ]]; then
  "${COMPOSE[@]}" down -v --remove-orphans
  rm -f "$ENV_FILE"
  echo "GE360 SuiteCRM rimosso completamente, inclusi dati e configurazione."
else
  "${COMPOSE[@]}" down --remove-orphans
  echo "GE360 SuiteCRM fermato e rimosso. Volumi e configurazione sono stati conservati."
  echo "Per eliminare anche i dati: ge360-suitecrm-uninstall --purge"
fi
