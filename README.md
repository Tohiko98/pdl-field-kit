# PDL Field Kit (Automation & System Diagnostics)

Un framework modulare in PowerShell 5.1 progettato per ottimizzare i tempi di intervento on-field dei tecnici di supporto IT (PDL / Workstation Management) in contesti infrastrutturali complessi.

## 🚀 I Moduli del Kit

Il repository include tre strumenti core indipendenti per azzerare i tempi di downtime nei reparti:

### 1. 🔍 Diagnostica Postazione (`Test-PDL.ps1` / `Avvia-Diagnostica.bat`)
* Raccolta istantanea dei parametri di rete critici (IP, Subnet, Gateway, DNS, DHCP).
* Check di raggiungibilità dei Domain Controller e instradamento di rete.
* Esportazione del report per gli allegati di ticketing.

### 2. 💾 Gestione Backup Profilo (`Invoke-PDLBackup.ps1` / `Avvia-Backup.bat`)
* **Modalità Quick/Full**: Migrazione mirata dei dati utente (Desktop, Documenti, AppData, Sticky Notes, Browser).
* **Resilienza**: Integrazione nativa con *Robocopy /z* per gestire reti instabili o WiFi di reparto senza corruzione dei dati.
* **Compliance GDPR**: Richiesta di conferma esplicita per la tutela dei dati sensibili/paziente.

### 3. 🖨️ Automazione Stampanti (`PDLPrinter.ps1`)
* Creazione dinamica di porte Standard TCP/IP e censimento immediato delle code di stampa tramite interfaccia CIM.
* **Driver Management**: Logica di installazione del driver specifico di reparto con sistema di fallback automatico sul driver generico di Windows per garantire l'operatività di stampa in ogni scenario.

## 🛠️ Requisiti & Utilizzo

* **OS**: Windows 10 / Windows 11
* **Shell**: PowerShell 5.1+ (Eseguito con privilegi di Amministratore)

I file `.bat` inclusi permettono il lancio rapido con bypass automatico della Execution Policy:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\PDLPrinter.ps1"
