@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

echo ============================================================
echo   CAP NHAT API KEYS THU CONG
echo   (Dung khi muon thay the key bang key tu Studio)
echo ============================================================
echo.
echo Lay key tai: Studio -^> Settings -^> API
echo.

set /p "ANON_KEY=Dan ANON KEY: "
set /p "SERVICE_KEY=Dan SERVICE ROLE KEY: "

set "WORKDIR=%~dp0supabase-config"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$e = Get-Content '%WORKDIR%\.env' -Raw -Encoding UTF8;" ^
    "$e = $e -replace '(?m)^ANON_KEY=.*',        'ANON_KEY=!ANON_KEY!';" ^
    "$e = $e -replace '(?m)^SERVICE_ROLE_KEY=.*','SERVICE_ROLE_KEY=!SERVICE_KEY!';" ^
    "Set-Content '%WORKDIR%\.env' $e -Encoding UTF8 -NoNewline"

echo.
echo [OK] Da cap nhat key. Khoi dong lai...
cd /d "%WORKDIR%"
docker compose down
docker compose up -d
echo [OK] Supabase da chay voi key moi!
pause
