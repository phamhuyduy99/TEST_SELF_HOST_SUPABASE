@echo off
chcp 65001 >nul
cd /d "%~dp0supabase-config"
echo [INFO] Dung Supabase...
docker compose down
echo [OK] Da dung tat ca container.
pause
