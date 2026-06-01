#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$SourcePC    = "",
    [string]$Username    = "",
    [string]$Destination = "",
    [string]$TicketID    = "",
    [switch]$Quick
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm"
$mode       = if ($Quick) { "QUICK" } else { "FULL" }

$FOLDERS_FULL = @(
    "Desktop",
    "Documents",
    "Favorites",
    "Pictures",
    "AppData\Roaming\Microsoft\Office",
    "AppData\Roaming\Microsoft\Sticky Notes",
    "AppData\Roaming\Mozilla\Firefox\Profiles",
    "AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
)

$FOLDERS_QUICK = @(
    "Desktop",
    "Documents"
)

function Write-Status {
    param([string]$Msg, [string]$Color = "Gray")
    Write-Host "  $Msg" -ForegroundColor $Color
}

function Read-NonEmpty {
    param([string]$Prompt)
    do { $val = (Read-Host $Prompt).Trim() } while ([string]::IsNullOrWhiteSpace($val))
    return $val
}

function Get-FolderSizeMB {
    param([string]$Path)
    try {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        return [Math]::Round($size / 1MB, 1)
    } catch { return 0 }
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  PDL Backup  v1.1.0" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

if ([string]::IsNullOrWhiteSpace($SourcePC))    { $SourcePC    = Read-NonEmpty "PC sorgente (hostname)" }
if ([string]::IsNullOrWhiteSpace($Username))    { $Username    = Read-NonEmpty "Account utente (es. m.rossi)" }
if ([string]::IsNullOrWhiteSpace($Destination)) { $Destination = Read-NonEmpty "Destinazione backup (percorso o UNC)" }
if ([string]::IsNullOrWhiteSpace($TicketID)) {
    $t = (Read-Host "Ticket SysAid (Invio per saltare)").Trim()
    $TicketID = if ($t) { $t } else { "notiket" }
}

$ticketPart = if ($TicketID -ne "notiket") { "_T$TicketID" } else { "" }
$backupRoot = Join-Path $Destination "${Username}_${timestamp}${ticketPart}"

Write-Status "Verifica $SourcePC ..." "Gray"

if (-not (Test-Connection -ComputerName $SourcePC -Count 2 -Quiet)) {
    Write-Status "ERRORE: $SourcePC non risponde al ping." "Red"
    exit 1
}

$sourceProfile = "\\$SourcePC\C$\Users\$Username"
if (-not (Test-Path $sourceProfile)) {
    Write-Status "ERRORE: profilo non trovato: $sourceProfile" "Red"
    Write-Status "Verifica: PC acceso? Share C`$ attiva? Username corretto?" "Yellow"
    exit 1
}

Write-Status "OK - $SourcePC raggiungibile." "Green"

try {
    if (-not (Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    }
} catch {
    Write-Status "ERRORE: impossibile creare destinazione: $backupRoot" "Red"
    exit 1
}

Write-Host ""
Write-Host "  GDPR: Desktop e Documenti non contengono dati paziente?" -ForegroundColor Yellow
$ok = Read-Host "  Confermi (s/N)"
if ($ok -notmatch '^[sS]$') {
    Write-Status "Backup annullato." "Yellow"
    exit 0
}

$folders = if ($Quick) { $FOLDERS_QUICK } else { $FOLDERS_FULL }

Write-Host ""
Write-Host "  Modalita  : $mode"              -ForegroundColor White
Write-Host "  Sorgente  : $sourceProfile"     -ForegroundColor White
Write-Host "  Dest.     : $backupRoot"        -ForegroundColor White
Write-Host "  Cartelle  : $($folders.Count)"  -ForegroundColor White
Write-Host ""

$logFile = Join-Path $backupRoot "_backup.log"
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalMB = 0
$sw      = [System.Diagnostics.Stopwatch]::StartNew()

"PDL Backup - $timestamp`nPC: $SourcePC`nUtente: $Username`nModalita: $mode`nTicket: $TicketID`nDest: $backupRoot`nTecnico: $env:COMPUTERNAME" |
    Out-File $logFile -Encoding UTF8

foreach ($folder in $folders) {
    $src    = Join-Path $sourceProfile $folder
    $dst    = Join-Path $backupRoot $folder
    $sizeMB = Get-FolderSizeMB -Path $src

    if (-not (Test-Path $src)) {
        Write-Status "SKIP  $folder (non trovata)" "DarkGray"
        $results.Add([PSCustomObject]@{ Cartella=$folder; Esito="SKIP"; MB=$sizeMB })
        continue
    }

    Write-Status "COPY  $folder ($sizeMB MB) ..." "White"

    $roboArgs = @(
        "`"$src`"", "`"$dst`"",
        "/E", "/Z", "/R:2", "/W:5", "/NP", "/NDL",
        "/LOG+:`"$logFile`""
    )

    $proc  = Start-Process robocopy -ArgumentList $roboArgs -Wait -PassThru -NoNewWindow
    $isOk  = $proc.ExitCode -lt 8
    $esito = if ($isOk) { "OK" } else { "ERR($($proc.ExitCode))" }
    $color = if ($isOk) { "Green" } else { "Red" }

    Write-Status "$esito  $folder" $color
    $results.Add([PSCustomObject]@{ Cartella=$folder; Esito=$esito; MB=$sizeMB })
    if ($isOk) { $totalMB += $sizeMB }
}

$sw.Stop()
$elapsed = [Math]::Round($sw.Elapsed.TotalSeconds)
$errors  = @($results | Where-Object { $_.Esito -like "ERR*" })
$skips   = @($results | Where-Object { $_.Esito -eq "SKIP" })

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  RIEPILOGO" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$results | ForEach-Object {
    $c = if ($_.Esito -eq "OK") { "Green" } elseif ($_.Esito -eq "SKIP") { "DarkGray" } else { "Red" }
    Write-Host ("  {0,-10} {1,-45} {2,6} MB" -f $_.Esito, $_.Cartella, $_.MB) -ForegroundColor $c
}

Write-Host ""
Write-Host "  Copiati : $totalMB MB in ${elapsed}s" -ForegroundColor White
Write-Host "  Errori  : $($errors.Count)   Skip: $($skips.Count)" -ForegroundColor White
Write-Host ""
Write-Host "  Backup  : $backupRoot" -ForegroundColor Green
Write-Host "  Log     : $logFile"    -ForegroundColor Green
Write-Host ""

if ($errors.Count -gt 0) {
    Write-Host "  ATTENZIONE: errori presenti - controlla il log." -ForegroundColor Yellow
} else {
    Write-Host "  Backup completato senza errori." -ForegroundColor Green
}
Write-Host ""
