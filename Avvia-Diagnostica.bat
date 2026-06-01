@echo off
:: Verifica i permessi di Amministratore
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run
) else (
    goto :elevate
)

:elevate
:: Rilancia il file .bat richiedendo i privilegi UAC
powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
exit /b

:run
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoExit -File "Test-PDL.ps1"