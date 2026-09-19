#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"
SOURCE="${1:-}"

[[ "${EUID}" -eq 0 ]] || { echo "Esegui con sudo/root" >&2; exit 1; }
[[ -n "$SOURCE" ]] || { echo "Uso: ge360-suitecrm-restore /percorso/backup" >&2; exit 2; }
[[ -f "$SOURCE/database.sql" && -f "$SOURCE/suitecrm-files.tar.gz" ]] || {
  echo "Backup non valido: mancano database.sql o suitecrm-files.tar.gz" >&2
  exit 1
}
[[ -f "$ENV_FILE" ]] || { echo "Configurazione attuale mancante: $ENV_FILE" >&2; exit 1; }

if [[ -f "$SOURCE/SHA256SUMS" ]]; then
  (cd "$SOURCE" && sha256sum -c SHA256SUMS --ignore-missing)
fi

set -a
source "$ENV_FILE"
set +a

COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")

echo "[GE360 SuiteCRM] Fermo web e processi in background..."
"${COMPOSE[@]}" stop worker scheduler web || true
"${COMPOSE[@]}" up -d db

echo "[GE360 SuiteCRM] Ripristino database..."
"${COMPOSE[@]}" exec -T db sh -lc   'MYSQL_PWD="$DB_PASSWORD" mariadb -u"$DB_USER" "$DB_NAME"'   < "$SOURCE/database.sql"

echo "[GE360 SuiteCRM] Ripristino file..."
"${COMPOSE[@]}" run --rm --no-deps --user root web sh -lc   'rm -rf /var/www/suitecrm/* /var/www/suitecrm/.[!.]* /var/www/suitecrm/..?* 2>/dev/null || true; tar -C /var/www -xzf -; chown -R www-data:www-data /var/www/suitecrm'   < "$SOURCE/suitecrm-files.tar.gz"

"${COMPOSE[@]}" up -d web worker scheduler
echo "[GE360 SuiteCRM] Ripristino completato."
