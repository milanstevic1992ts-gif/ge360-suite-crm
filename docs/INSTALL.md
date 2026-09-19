# Installazione GE360 SuiteCRM Engine

## Requisiti

- Debian/Ubuntu
- Docker Engine
- Docker Compose v2
- accesso Internet al primo build per scaricare immagini e release ufficiale SuiteCRM

## Installazione

```bash
sudo apt install ./ge360-suitecrm-engine_0.1.0_all.deb
sudo ge360-suitecrm-install
```

Porta predefinita:

```
http://localhost:8791
```

L'installer genera automaticamente:

- password MariaDB;
- password root MariaDB;
- password admin SuiteCRM.

Le credenziali vengono salvate con permessi restrittivi in:

```
/etc/ge360/suitecrm-engine.env
```

## Verifica

```bash
ge360-suitecrm-status
ge360-suitecrm-doctor
```

## Backup

```bash
sudo ge360-suitecrm-backup
```

Percorso predefinito:

```
/var/backups/ge360-suitecrm/
```

## Restore

```bash
sudo ge360-suitecrm-restore /var/backups/ge360-suitecrm/AAAAmmgg-HHMMSS
```

## Disinstallazione

Conserva dati e configurazione:

```bash
sudo ge360-suitecrm-uninstall
```

Elimina anche volumi e configurazione:

```bash
sudo ge360-suitecrm-uninstall --purge
```

## Note

Il runtime punta il DocumentRoot Apache alla directory `public/`, come raccomandato da SuiteCRM.

Scheduler e Messenger worker vengono eseguiti in container separati con lo stesso utente del web server.
