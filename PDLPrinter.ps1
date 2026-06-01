#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$PrinterIP   = "",
    [string]$PrinterName = "",
    [string]$DriverName  = "Generic / Text Only"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  PDL Printer Installer  v1.0.0"       -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($PrinterIP))   { $PrinterIP   = (Read-Host "Inserisci IP Stampante (es. della tua HP)").Trim() }
if ([string]::IsNullOrWhiteSpace($PrinterName)) { $PrinterName = (Read-Host "Inserisci Nome Stampante (es. HP_UFFICIO)").Trim() }

$PortName = "IP_$PrinterIP"

try {
    # 1. Controllo e creazione della Porta TCP/IP
    Write-Host "  Verifica porta standard TCP/IP ($PortName)..." -ForegroundColor Gray
    if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
        Write-Host "  OK: La porta $PortName esiste gia." -ForegroundColor Green
    } else {
        Write-Host "  Creazione porta TCP/IP in corso..." -ForegroundColor Yellow
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
        Write-Host "  OK: Porta creata con successo." -ForegroundColor Green
    }

    # 2. Controllo e installazione automatica del driver se mancante
    Write-Host "  Verifica presenza driver ($DriverName)..." -ForegroundColor Gray
    if (-not (Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue)) {
        Write-Host "  Driver non trovato. Installazione di '$DriverName' in corso..." -ForegroundColor Yellow
        Add-PrinterDriver -Name $DriverName
        Write-Host "  OK: Driver installato e registrato nel sistema." -ForegroundColor Green
    } else {
        Write-Host "  OK: Il driver e gia disponibile nel sistema." -ForegroundColor Green
    }

    # 3. Controllo e creazione della Stampante
    Write-Host "  Verifica stampante ($PrinterName)..." -ForegroundColor Gray
    if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
        Write-Host "  ATTENZIONE: Una stampante con nome $PrinterName esiste gia." -ForegroundColor Yellow
    } else {
        Write-Host "  Installazione stampante $PrinterName su porta $PortName..." -ForegroundColor Yellow
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
        Write-Host "  OK: Stampante installata correttamente!" -ForegroundColor Green
    }

} catch {
    Write-Host "  ERRORE durante la configurazione: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Operazione completata." -ForegroundColor White
Write-Host ""