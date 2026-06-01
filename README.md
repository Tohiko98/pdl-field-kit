# pdl-backup

> Backup rapido del profilo utente da un PC ospedaliero verso qualsiasi destinazione — share, PC tecnico, percorso UNC.

[![PSScriptAnalyzer](https://github.com/Tohiko98/pdl-backup/actions/workflows/lint.yml/badge.svg)](https://github.com/Tohiko98/pdl-backup/actions/workflows/lint.yml)
![PowerShell 5.1](https://img.shields.io/badge/PowerShell-5.1-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Cosa fa

Un solo script. Fa una cosa sola: copia le cartelle essenziali del profilo utente da un PC remoto verso una destinazione a scelta, con log allegabile al ticket SysAid.

Funziona in qualsiasi scenario:
- Pre-migrazione (prima di sostituire il PC)
- PC con problemi hardware imminenti
- Backup al volo in reparto

> Testato su Windows 10, PowerShell 5.1, dominio AD — ULSS Treviso (Ca' Foncello)

---

## Requisiti

- PowerShell 5.1
- Privilegi **Administrator**
- Share `C$` attiva sul PC remoto (default in dominio AD)

---

## Utilizzo

### Modalita interattiva (nessun parametro — ti chiede tutto)

```powershell
.\Invoke-PDLBackup.ps1
```

### Con parametri

```powershell
# Backup completo su share ospedaliera
.\Invoke-PDLBackup.ps1 -SourcePC HOSP-CHIR-PC04 -Username m.rossi -Destination "\\SERVER\Backup\PDL" -TicketID 10542

# Backup rapido — solo Desktop + Documenti
.\Invoke-PDLBackup.ps1 -SourcePC HOSP-CHIR-PC04 -Username m.rossi -Destination "C:\PDL_Backup" -Quick

# Verso il PC del tecnico via rete
.\Invoke-PDLBackup.ps1 -SourcePC HOSP-CHIR-PC04 -Username m.rossi -Destination "\\HOSP-TECH-PC01\C$\Backup"
```

---

## Parametri

| Parametro | Tipo | Default | Descrizione |
|---|---|---|---|
| `-SourcePC` | String | _(interattivo)_ | Hostname PC sorgente |
| `-Username` | String | _(interattivo)_ | Account AD utente |
| `-Destination` | String | _(interattivo)_ | Percorso destinazione (locale o UNC) |
| `-TicketID` | String | _(opzionale)_ | Numero ticket SysAid |
| `-Quick` | Switch | — | Solo Desktop + Documenti |

---

## Cosa viene copiato

**Modalita FULL:**
- Desktop, Documents, Favorites, Pictures
- AppData\Roaming\Office, Sticky Notes, Firefox, Start Menu

**Modalita QUICK (`-Quick`):**
- Desktop, Documents

Per aggiungere cartelle Dedalus o altri applicativi: modifica `$FOLDERS_FULL` nella sezione CONFIGURAZIONE dello script.

---

## Output

Il backup viene salvato in una cartella nominata automaticamente:

```
<Destination>\m.rossi_2026-05-15_09-30_T10542\
├── Desktop\
├── Documents\
├── ...
└── _backup.log     <- da allegare al ticket SysAid
```

---

## GDPR

Lo script chiede conferma esplicita prima di procedere.
Verifica che Desktop e Documenti non contengano dati paziente prima di copiare.
Elimina il backup dopo la migrazione se contiene informazioni sensibili.

---

## Note tecniche

- Usa `robocopy /Z` (modalita riavviabile) — il trasferimento riprende se la rete cade
- Compatibile con reti WiFi lente e instabili tipiche di reparti e case di comunita
- Non modifica la Execution Policy di sistema — lanciare con `-ExecutionPolicy Bypass`

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Invoke-PDLBackup.ps1"
```

---

## Changelog

### v1.1.0
- Fix: variabili `$timestamp`, `$ticketPart`, `$backupRoot` spostate a inizio script (compatibilita `Set-StrictMode`)
- Fix: `$errors` e `$skips` forzati ad array con `@()` per `.Count` su collezioni vuote
- Rinominata variabile `$args` in `$roboArgs` (conflitto con variabile riservata PowerShell)

### v1.0.0
- Release iniziale

---

## Autore

**Antonio Barengo** — [github.com/Tohiko98](https://github.com/Tohiko98) · [LinkedIn](https://linkedin.com/in/antonio-barengo-b148a1303)

Licenza: [MIT](LICENSE)
