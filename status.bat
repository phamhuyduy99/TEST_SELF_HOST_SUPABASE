@echo off
chcp 65001 >nul
cd /d "%~dp0supabase-config"
echo [INFO] Trang thai cac container Supabase:
echo.
docker compose ps
echo.
pause
