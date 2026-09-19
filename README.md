# GE360 SuiteCRM Engine

Wrapper self-hosted per usare **SuiteCRM 8** come CRM operativo di GE360 senza riscriverlo.

## Obiettivo

GE360 SuiteCRM Engine installa e gestisce il pacchetto ufficiale SuiteCRM in un ambiente isolato e ripetibile.

Ruoli previsti:

- **Prospex** -> scoperta e scoring dei lead
- **GE360 Core** -> orchestrazione, deduplica e mapping
- **SuiteCRM** -> aziende, contatti, opportunità, pipeline, campagne, email, workflow e report
- **Mautic** -> opzionale in futuro, solo se servirà marketing automation più avanzato

## Upstream

- Progetto: SuiteCRM 8
- Repository ufficiale: https://github.com/SuiteCRM/SuiteCRM-Core
- Versione iniziale: **8.10.2**
- Tag: `v8.10.2`
- Commit: `6c7ce002a8f9b594eb80021d273af0aee72af54a`
- Licenza upstream: **AGPL-3.0**
- Pacchetto produzione: `SuiteCRM-8.10.2.zip`

Il codice SuiteCRM non viene copiato o rebrandizzato in questa repository. Il wrapper scarica il pacchetto ufficiale fissato in `UPSTREAM.lock` e verifica il checksum prima di usarlo.

## Stack GE360

```
GE360 Core
    |
    v
GE360 SuiteCRM Engine
    |
    +-- SuiteCRM 8.10.2
    +-- Apache 2.4 / PHP 8.3
    +-- MariaDB 11.4
    +-- Scheduler SuiteCRM
    +-- Symfony Messenger worker
```

Porta predefinita:

```
http://localhost:8791
```

## Installazione

Dopo aver installato il pacchetto Debian:

```bash
sudo ge360-suitecrm-install
```

Comandi:

```bash
ge360-suitecrm-status
ge360-suitecrm-doctor
sudo ge360-suitecrm-backup
sudo ge360-suitecrm-update
sudo ge360-suitecrm-uninstall
```

Configurazione persistente:

```
/etc/ge360/suitecrm-engine.env
```

Dati persistenti: volumi Docker dedicati a GE360 SuiteCRM.

## Principio

Prima facciamo funzionare SuiteCRM quasi originale e lo proviamo nel lavoro reale.

Solo se diventa indispensabile valuteremo personalizzazioni più profonde.

## Roadmap

### Fase 1 — Standalone
- [x] upstream ufficiale identificato
- [x] release stabile fissata
- [x] licenza verificata
- [x] stack runtime GE360
- [x] installer
- [x] status / doctor
- [x] backup / restore
- [x] packaging Debian
- [ ] test installazione reale Debian
- [x] GitHub Actions verde

### Fase 2 — Uso reale
- [ ] aziende
- [ ] contatti
- [ ] opportunità
- [ ] pipeline
- [ ] email
- [ ] campagne
- [ ] workflow
- [ ] report

### Fase 3 — GE360
- [ ] adapter API
- [ ] ge360_id
- [ ] import da Prospex
- [ ] deduplica
- [ ] sync controllato
- [ ] webhook/eventi

## Licenze

Il wrapper GE360 è separato da SuiteCRM. SuiteCRM è software AGPL-3.0. Vedere `THIRD_PARTY_NOTICES.md`.
