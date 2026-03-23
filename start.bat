@echo off
chcp 65001 >nul
cd /d "%~dp0supabase-config"
echo [INFO] Khoi dong Supabase...
docker compose up -d
echo.
echo [OK] Truy cap Studio: http://localhost:8000
pause
