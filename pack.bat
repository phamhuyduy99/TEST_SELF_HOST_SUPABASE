@echo off
chcp 65001 >nul
echo [INFO] Dong goi Supabase portable...

:: Dùng PowerShell để tạo file zip
powershell -Command "Compress-Archive -Path '%~dp0supabase-config' -DestinationPath '%~dp0supabase-portable.zip' -Force"

echo [OK] Da tao file: supabase-portable.zip
echo.
echo Cach dung tren may khac:
echo   1. Copy file supabase-portable.zip sang may dich
echo   2. Giai nen: chuot phai -> Extract All
echo   3. Vao thu muc supabase-config
echo   4. Chay: docker compose up -d
echo   5. Truy cap: http://localhost:8000
pause
