# Architettura

## Principio

GE360 SuiteCRM Engine non è un nuovo CRM e non è un fork pesante.

Il wrapper gestisce il ciclo di vita del pacchetto ufficiale SuiteCRM:

```
                 GE360 Core
                     |
                 API / eventi
                     |
                     v
             SuiteCRM 8 ufficiale
              /       |       \
          Apache   Scheduler   Worker
            |                    |
            +------ MariaDB ------+
```

## Persistenza

- `ge360_suitecrm_db`: database MariaDB
- `ge360_suitecrm_app`: installazione SuiteCRM, configurazioni, upload e personalizzazioni

## Sicurezza

- nessun secret nel repository;
- password generate localmente;
- configurazione `/etc/ge360/suitecrm-engine.env` con permessi 0600;
- pacchetto upstream verificato tramite SHA-256;
- versione upstream bloccata in `UPSTREAM.lock`.

## Integrazione futura

Prospex non deve scrivere direttamente in SuiteCRM.

Flusso previsto:

```
Prospex -> GE360 Core -> deduplica/mapping -> SuiteCRM
```

GE360 manterrà un identificatore stabile `ge360_id` e gli identificatori esterni dei vari motori.
