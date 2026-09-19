#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${GE360_SUITECRM_CONFIG_DIR:-/etc/ge360}/suitecrm-engine.env"
BACKUP_ROOT="${GE360_SUITECRM_BACKUP_DIR:-/var/backups/ge360-suitecrm}"

[[ "${EUID}" -eq 0 ]] || { echo "Esegui con sudo/root" >&2; exit 1; }
[[ -f "$ENV_FILE" ]] || { echo "Configurazione mancante: $ENV_FILE" >&2; exit 1; }

set -a
source "$ENV_FILE"
set +a

COMPOSE=(docker compose -p ge360-suitecrm --env-file "$ENV_FILE" -f "$ROOT_DIR/docker-compose.yml")
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BACKUP_ROOT/$STAMP"

mkdir -p "$DEST"
chmod 0700 "$BACKUP_ROOT" "$DEST"

echo "[GE360 SuiteCRM] Backup database..."
"${COMPOSE[@]}" exec -T db sh -lc   'MYSQL_PWD="$DB_PASSWORD" mariadb-dump --single-transaction --routines --triggers -u"$DB_USER" "$DB_NAME"'   > "$DEST/database.sql"

echo "[GE360 SuiteCRM] Backup file applicativi..."
"${COMPOSE[@]}" exec -T web tar -C /var/www -czf - suitecrm > "$DEST/suitecrm-files.tar.gz"

cp "$ENV_FILE" "$DEST/suitecrm-engine.env"
chmod 0600 "$DEST/suitecrm-engine.env"

"${COMPOSE[@]}" exec -T --user www-data web php bin/console suitecrm:version   > "$DEST/version.txt" 2>/dev/null || true

(
  cd "$DEST"
  sha256sum database.sql suitecrm-files.tar.gz suitecrm-engine.env > SHA256SUMS
)

echo "[GE360 SuiteCRM] Backup completato: $DEST"
