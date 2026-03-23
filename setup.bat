@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

echo ============================================================
echo   SUPABASE SELF-HOST SETUP - Windows CMD / PowerShell
echo   Chay duoc tren moi Windows co Docker Desktop
echo ============================================================
echo.

:: ============================================================
:: KIEM TRA YEU CAU
:: ============================================================
docker --version >nul 2>&1
if errorlevel 1 (
    echo [LOI] Docker chua duoc cai hoac chua chay.
    echo       Tai Docker Desktop: https://www.docker.com/products/docker-desktop
    pause & exit /b 1
)
echo [OK] Docker san sang.

git --version >nul 2>&1
if errorlevel 1 (
    echo [LOI] Git chua duoc cai.
    echo       Tai Git: https://git-scm.com/download/win
    pause & exit /b 1
)
echo [OK] Git san sang.

:: ============================================================
:: BUOC 1: CLONE SUPABASE
:: ============================================================
set "WORKDIR=%~dp0supabase-config"

if exist "%WORKDIR%" (
    echo [INFO] supabase-config da ton tai, bo qua buoc clone.
    goto :generate_keys
)

echo.
echo [BUOC 1] Clone Supabase tu GitHub...
git clone --depth 1 --filter=blob:none --sparse https://github.com/supabase/supabase "%~dp0supabase-src"
if errorlevel 1 (
    echo [LOI] Clone that bai. Kiem tra ket noi mang.
    pause & exit /b 1
)

cd /d "%~dp0supabase-src"
git sparse-checkout set docker
cd /d "%~dp0"

echo [BUOC 2] Copy file cau hinh...
mkdir "%WORKDIR%"
xcopy /E /I /Y "%~dp0supabase-src\docker\*" "%WORKDIR%\" >nul
rmdir /S /Q "%~dp0supabase-src"
echo [OK] Clone va copy xong.

:generate_keys
:: ============================================================
:: BUOC 2: TAO FILE .env
:: ============================================================
if not exist "%WORKDIR%\.env" (
    copy "%WORKDIR%\.env.example" "%WORKDIR%\.env" >nul
    echo [OK] Tao .env tu .env.example
)

:: ============================================================
:: BUOC 3 + 4: SINH KHOA VA JWT BANG POWERSHELL
:: PowerShell co san tren moi Windows 7+, khong can cai them gi
:: ============================================================
echo.
echo [BUOC 3] Sinh khoa bao mat va JWT...

:: Dung PowerShell de sinh tat ca khoa va JWT HS256 trong 1 lenh
:: Ket qua ghi ra file tam de CMD doc vao
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "Add-Type -AssemblyName System;" ^
    "" ^
    "function New-RandomBase64([int]$bytes) {" ^
    "    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create();" ^
    "    $buf = New-Object byte[] $bytes;" ^
    "    $rng.GetBytes($buf);" ^
    "    return [Convert]::ToBase64String($buf)" ^
    "}" ^
    "" ^
    "function New-RandomHex([int]$bytes) {" ^
    "    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create();" ^
    "    $buf = New-Object byte[] $bytes;" ^
    "    $rng.GetBytes($buf);" ^
    "    return ($buf | ForEach-Object { $_.ToString('x2') }) -join ''" ^
    "}" ^
    "" ^
    "function ConvertTo-Base64Url([string]$s) {" ^
    "    return $s.Replace('+','-').Replace('/','_').TrimEnd('=')" ^
    "}" ^
    "" ^
    "function New-JWT([string]$payload, [string]$secret) {" ^
    "    $header = ConvertTo-Base64Url([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('{\"alg\":\"HS256\",\"typ\":\"JWT\"}')));" ^
    "    $body   = ConvertTo-Base64Url([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload)));" ^
    "    $hmac   = New-Object System.Security.Cryptography.HMACSHA256;" ^
    "    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($secret);" ^
    "    $sig = ConvertTo-Base64Url([Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes(\"$header.$body\"))));" ^
    "    return \"$header.$body.$sig\"" ^
    "}" ^
    "" ^
    "$pg_pass   = New-RandomBase64 32;" ^
    "$jwt_sec   = New-RandomBase64 32;" ^
    "$skb       = New-RandomBase64 48;" ^
    "$vault     = New-RandomHex 16;" ^
    "$pg_meta   = New-RandomBase64 24;" ^
    "$logflare  = New-RandomBase64 24;" ^
    "$minio     = New-RandomHex 16;" ^
    "$dash_pass = (New-RandomBase64 12) -replace '[/+=]','';" ^
    "" ^
    "$iat = [int][double]::Parse((Get-Date -UFormat '%%s'));" ^
    "$exp = $iat + 315360000;" ^
    "" ^
    "$anon_key = New-JWT \"{`\"role`\":`\"anon`\",`\"iss`\":`\"supabase`\",`\"iat`\":$iat,`\"exp`\":$exp}\" $jwt_sec;" ^
    "$svc_key  = New-JWT \"{`\"role`\":`\"service_role`\",`\"iss`\":`\"supabase`\",`\"iat`\":$iat,`\"exp`\":$exp}\" $jwt_sec;" ^
    "" ^
    "@(" ^
    "    \"POSTGRES_PASSWORD=$pg_pass\"," ^
    "    \"JWT_SECRET=$jwt_sec\"," ^
    "    \"SECRET_KEY_BASE=$skb\"," ^
    "    \"VAULT_ENC_KEY=$vault\"," ^
    "    \"PG_META_CRYPTO_KEY=$pg_meta\"," ^
    "    \"LOGFLARE_ACCESS_TOKEN=$logflare\"," ^
    "    \"MINIO_ROOT_PASSWORD=$minio\"," ^
    "    \"DASHBOARD_PASSWORD=$dash_pass\"," ^
    "    \"ANON_KEY=$anon_key\"," ^
    "    \"SERVICE_ROLE_KEY=$svc_key\"" ^
    ") | Set-Content '%~dp0_keys_tmp.txt' -Encoding UTF8"

if errorlevel 1 (
    echo [LOI] Sinh khoa that bai.
    pause & exit /b 1
)

:: Doc tung bien tu file tam
for /f "tokens=1,* delims==" %%A in (%~dp0_keys_tmp.txt) do (
    set "%%A=%%B"
)
del "%~dp0_keys_tmp.txt" >nul 2>&1

echo [OK] Da sinh xong tat ca khoa va JWT.
echo.
echo   POSTGRES_PASSWORD = !POSTGRES_PASSWORD!
echo   JWT_SECRET        = !JWT_SECRET!
echo   VAULT_ENC_KEY     = !VAULT_ENC_KEY!
echo   DASHBOARD_PASSWORD= !DASHBOARD_PASSWORD!
echo.

:: ============================================================
:: BUOC 5: CAP NHAT FILE .env BANG POWERSHELL
:: ============================================================
echo [BUOC 5] Cap nhat file .env...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$e = Get-Content '%WORKDIR%\.env' -Raw -Encoding UTF8;" ^
    "$e = $e -replace '(?m)^POSTGRES_PASSWORD=.*',   'POSTGRES_PASSWORD=!POSTGRES_PASSWORD!';" ^
    "$e = $e -replace '(?m)^JWT_SECRET=.*',           'JWT_SECRET=!JWT_SECRET!';" ^
    "$e = $e -replace '(?m)^SECRET_KEY_BASE=.*',      'SECRET_KEY_BASE=!SECRET_KEY_BASE!';" ^
    "$e = $e -replace '(?m)^VAULT_ENC_KEY=.*',        'VAULT_ENC_KEY=!VAULT_ENC_KEY!';" ^
    "$e = $e -replace '(?m)^PG_META_CRYPTO_KEY=.*',   'PG_META_CRYPTO_KEY=!PG_META_CRYPTO_KEY!';" ^
    "$e = $e -replace '(?m)^LOGFLARE_ACCESS_TOKEN=.*','LOGFLARE_ACCESS_TOKEN=!LOGFLARE_ACCESS_TOKEN!';" ^
    "$e = $e -replace '(?m)^MINIO_ROOT_PASSWORD=.*',  'MINIO_ROOT_PASSWORD=!MINIO_ROOT_PASSWORD!';" ^
    "$e = $e -replace '(?m)^DASHBOARD_USERNAME=.*',   'DASHBOARD_USERNAME=admin';" ^
    "$e = $e -replace '(?m)^DASHBOARD_PASSWORD=.*',   'DASHBOARD_PASSWORD=!DASHBOARD_PASSWORD!';" ^
    "$e = $e -replace '(?m)^ANON_KEY=.*',             'ANON_KEY=!ANON_KEY!';" ^
    "$e = $e -replace '(?m)^SERVICE_ROLE_KEY=.*',     'SERVICE_ROLE_KEY=!SERVICE_ROLE_KEY!';" ^
    "Set-Content '%WORKDIR%\.env' $e -Encoding UTF8 -NoNewline"

if errorlevel 1 (
    echo [LOI] Cap nhat .env that bai.
    pause & exit /b 1
)
echo [OK] File .env da cap nhat day du.

:: ============================================================
:: BUOC 6: TAO start.bat VA stop.bat BEN TRONG supabase-config
:: ============================================================
echo [BUOC 6] Tao start.bat va stop.bat...

(
    echo @echo off
    echo cd /d "%%~dp0"
    echo docker compose up -d
    echo echo Supabase da khoi dong. Truy cap Studio tai http://localhost:8000
    echo pause
) > "%WORKDIR%\start.bat"

(
    echo @echo off
    echo cd /d "%%~dp0"
    echo docker compose down
    echo pause
) > "%WORKDIR%\stop.bat"

echo [OK] Da tao start.bat va stop.bat.

:: ============================================================
:: BUOC 7: LUU THONG TIN DANG NHAP
:: ============================================================
(
    echo ============================================================
    echo   THONG TIN DANG NHAP SUPABASE STUDIO
    echo ============================================================
    echo   URL Studio       : http://localhost:8000
    echo   Username         : admin
    echo   Password         : !DASHBOARD_PASSWORD!
    echo.
    echo   POSTGRES_PASSWORD: !POSTGRES_PASSWORD!
    echo   JWT_SECRET       : !JWT_SECRET!
    echo   ANON_KEY         : !ANON_KEY!
    echo   SERVICE_ROLE_KEY : !SERVICE_ROLE_KEY!
    echo ============================================================
    echo   Giu file nay an toan, khong chia se cho nguoi khac!
    echo ============================================================
) > "%~dp0credentials.txt"
echo [OK] Da luu thong tin vao credentials.txt

:: ============================================================
:: BUOC 8: KHOI DONG SUPABASE bang start.bat
:: ============================================================
echo.
echo [BUOC 8] Khoi dong Supabase (lan dau keo image ~2-3GB)...
call "%WORKDIR%\start.bat"

if errorlevel 1 (
    echo [LOI] Khoi dong that bai. Chay lenh sau de xem loi:
    echo       docker compose logs
    pause & exit /b 1
)

echo.
echo ============================================================
echo   SUPABASE DA CHAY THANH CONG!
echo   Studio : http://localhost:8000
echo   User   : admin
echo   Pass   : !DASHBOARD_PASSWORD!
echo   (Xem day du trong file credentials.txt)
echo ============================================================
echo   Khoi dong lai : nhap doi vao start.bat trong supabase-config
echo   Dung          : nhap doi vao stop.bat trong supabase-config
echo   Dong goi      : chay pack.bat
echo ============================================================
pause
