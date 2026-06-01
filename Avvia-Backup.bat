@echo off
:: Verifica i permessi di Amministratore (richiesti esplicitamente dallo script di backup)
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :menu
) else (
    goto :elevate
)

:elevate
:: Richiede i privilegi UAC e rilancia il file batch
powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
exit /b

:menu
cd /d "%~dp0"
cls
echo ===================================================
echo               PDL FIELD KIT - MENU BACKUP          
echo ===================================================
echo.
echo  [1] Avvia BACKUP COMPLETO (Desktop, Documenti, AppData...)
echo  [2] Avvia BACKUP RAPIDO   (Solo Desktop e Documenti)
echo  [3] Esci
echo.
echo ===================================================
set /p scelta=" Scegli un'opzione (1-3): "

if "%scelta%"=="1" goto :full
if "%scelta%"=="2" goto :quick
if "%scelta%"=="3" exit
goto :menu

:full
echo.
echo  Avvio del Backup Completo in corso...
powershell.exe -ExecutionPolicy Bypass -NoExit -File "Invoke-PDLBackup.ps1"
exit

:quick
echo.
echo  Avvio del Backup Rapido (-Quick) in corso...
powershell.exe -ExecutionPolicy Bypass -NoExit -File "Invoke-PDLBackup.ps1" -Quick
exit