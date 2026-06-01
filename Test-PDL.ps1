#Requires -Version 5.1
<#
.SYNOPSIS
    Diagnostica rapida postazione di lavoro ospedaliera.

.DESCRIPTION
    Lancia sul PC del reparto senza parametri.
    Mostra in 10 secondi: rete, servizi critici, disco, RAM, utente loggato.

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File ".\Test-PDL.ps1"

.NOTES
    Autore  : Antonio Barengo
    Repo    : https://github.com/Tohiko98/pdl-field-notes
    Versione: 1.1.2
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# ---------------------------------------------------------------------------
# CONFIGURAZIONE -- adatta al tuo ambiente
# ---------------------------------------------------------------------------

# Servizi da controllare
$SERVICES = @(
    @{ Nome = "Print Spooler";    ID = "Spooler"    },
    @{ Nome = "RPC";              ID = "RpcSs"      },
    @{ Nome = "Windows Update";   ID = "wuauserv"   },
    @{ Nome = "DNS Client";       ID = "Dnscache"   },
    @{ Nome = "Workstation";      ID = "LanmanWorkstation" }
)

# Soglie disco
$DISK_WARN_GB  = 10
$DISK_ERROR_GB = 5

# ---------------------------------------------------------------------------
# FUNZIONI
# ---------------------------------------------------------------------------

function Write-Header { 
    param([string]$Title)
    Write-Host "" -NoNewline
    Write-Host "`n  $Title" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * ($Title.Length))) -ForegroundColor DarkGray 
}

function Write-Row { 
    param([string]$Label, [string]$Value, [string]$Color = "White") 
    Write-Host ("  {0,-22} {1}" -f $Label, $Value) -ForegroundColor $Color 
}

# ---------------------------------------------------------------------------
# HEADER
# ---------------------------------------------------------------------------

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n  ======================================`n    PDL Diagnostica  v1.1.2`n    $timestamp`n  ======================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# SEZIONE 1 -- IDENTITA PC
# ---------------------------------------------------------------------------

Write-Header "POSTAZIONE"

$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeStr = "{0}g {1}h {2}m" -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes

Write-Row "Hostname"    $env:COMPUTERNAME
Write-Row "Dominio"     "$($cs.Domain)"
Write-Row "OS"          "$($os.Caption) -- Build $($os.BuildNumber)"
Write-Row "Uptime"      $uptimeStr $(if ($uptime.TotalDays -gt 30) { "Yellow" } else { "White" })

# ---------------------------------------------------------------------------
# SEZIONE 2 -- ULTIMO UTENTE LOGGATO
# ---------------------------------------------------------------------------

Write-Header "UTENTE"

if ($null -ne $cs.UserName) { 
    Write-Row "Utente attivo" "$($cs.UserName)" "Green" 
} else { 
    Write-Row "Utente attivo" "Nessun login attivo" "Yellow" 
}

$lastProfile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { !$_.Special } | Sort-Object LastUseTime -Descending | Select-Object -First 1
if ($null -ne $lastProfile) {
    $lastUser = Split-Path $lastProfile.LocalPath -Leaf
    Write-Row "Ultimo profilo" "$lastUser"
}

# ---------------------------------------------------------------------------
# SEZIONE 3 -- RETE E CONNETTIVITÀ
# ---------------------------------------------------------------------------

Write-Header "RETE"

$adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
$currentGw = "10.3.10.1"
$currentDns = "10.3.1.2"

foreach ($adapter in $adapters) {
    $netAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.DeviceID -eq $adapter.Index }
    $ip   = ($adapter.IPAddress) -join ", "
    $gw   = ($adapter.DefaultIPGateway) -join ", "
    $dhcp = if ($adapter.DHCPEnabled) { "DHCP" } else { "Statico" }
    
    if ($adapter.DefaultIPGateway) { $currentGw = $adapter.DefaultIPGateway[0] }
    if ($adapter.DNSServerSearchOrder) { $currentDns = $adapter.DNSServerSearchOrder[0] }

    Write-Row "Scheda"      "$($netAdapter.NetConnectionID) ($dhcp)"
    Write-Row "IP"          "$ip" $(if ($ip) { "White" } else { "Red" })
    Write-Row "Gateway"     $(if ($gw) { $gw } else { "Non configurato" }) $(if ($gw) { "White" } else { "Red" })
    Write-Host ""
}

$PING_TARGETS = @(
    @{ Nome = "Gateway Locale"; Host = $currentGw },
    @{ Nome = "DNS Aziendale";  Host = $currentDns }
)

Write-Host "  Connettivita:" -ForegroundColor DarkGray
Set-StrictMode -Off
foreach ($target in $PING_TARGETS) {
    $ping = Test-Connection -ComputerName $target.Host -Count 1 -ErrorAction SilentlyContinue
    if ($ping) {
        $latency = "$($ping.ResponseTime) ms"
        $color = "Green"
    } else {
        $latency = "TIMEOUT"
        $color = "Red"
    }
    Write-Host ("  {0,-22} {1}" -f $target.Nome, $latency) -ForegroundColor $color
}

$dnsOk = $null; try { $dnsOk = [System.Net.Dns]::GetHostEntry("www.google.com") } catch {}
$dnsColor = if ($null -ne $dnsOk) { "Green" } else { "Red" }
$dnsText = if ($null -ne $dnsOk) { "OK" } else { "FALLITA" }
Write-Row "Risoluzione DNS" $dnsText $dnsColor
Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# SEZIONE 4 -- DISCO E RAM
# ---------------------------------------------------------------------------

Write-Header "DISCO E RAM"

$disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
if ($disk) {
    $freeGB = [Math]::Round($disk.FreeSpace / 1GB, 1)
    $totalGB = [Math]::Round($disk.Size / 1GB, 1)
    $usedPct = [Math]::Round((1 - $disk.FreeSpace / $disk.Size) * 100, 0)
    $diskColor = if ($freeGB -le $DISK_ERROR_GB) { "Red" } elseif ($freeGB -le $DISK_WARN_GB) { "Yellow" } else { "Green" }
    Write-Row "Disco C:" "$freeGB GB liberi / $totalGB GB totali ($usedPct% usato)" $diskColor
}

$totalRAM = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$freeRAM  = [Math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
$usedRAM  = [Math]::Round($totalRAM - $freeRAM, 1)
$ramColor = if ($freeRAM -lt 0.5) { "Red" } elseif ($freeRAM -lt 1) { "Yellow" } else { "White" }
Write-Row "RAM" "$usedRAM GB usati / $totalRAM GB totali ($freeRAM GB liberi)" $ramColor

# ---------------------------------------------------------------------------
# SEZIONE 5 -- SERVIZI
# ---------------------------------------------------------------------------

Write-Header "SERVIZI"

foreach ($svc in $SERVICES) {
    $s = Get-Service -Name $svc.ID -ErrorAction SilentlyContinue
    if ($null -ne $s) {
        $stato = $s.Status.ToString()
        $color = if ($stato -eq "Running") { "Green" } else { "Red" }
    } else {
        $stato = "Non trovato"
        $color = "Red"
    }
    Write-Row "$($svc.Nome)" "$stato" $color
}

# ---------------------------------------------------------------------------
# FOOTER
# ---------------------------------------------------------------------------

Write-Host "`n  ======================================`n  Fine diagnostica -- $(Get-Date -Format 'HH:mm:ss')`n  ======================================" -ForegroundColor DarkGray