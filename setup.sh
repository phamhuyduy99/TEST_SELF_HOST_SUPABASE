#!/usr/bin/env bash
# Chạy được trên: Git Bash (Windows), Linux, macOS
# Yêu cầu: Docker, Git, openssl (có sẵn trong Git Bash)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$SCRIPT_DIR/supabase-config"

echo "============================================================"
echo "  SUPABASE SELF-HOST SETUP"
echo "  Chay duoc tren: Git Bash / Linux / macOS"
echo "============================================================"
echo

# ============================================================
# KIEM TRA YEU CAU
# ============================================================
if ! command -v docker &>/dev/null; then
    echo "[LOI] Chua cai Docker. Tai tai: https://docs.docker.com/get-docker/"
    exit 1
fi
echo "[OK] Docker san sang: $(docker --version)"

if ! command -v git &>/dev/null; then
    echo "[LOI] Chua cai Git. Tai tai: https://git-scm.com"
    exit 1
fi
echo "[OK] Git san sang."

if ! command -v openssl &>/dev/null; then
    echo "[LOI] Chua co openssl. Tren Windows hay cai Git for Windows day du."
    exit 1
fi
echo "[OK] openssl san sang."

# ============================================================
# BUOC 1: CLONE SUPABASE
# ============================================================
if [ ! -d "$WORKDIR" ]; then
    echo
    echo "[BUOC 1] Clone Supabase tu GitHub (chi lay phan docker)..."
    # --filter=blob:none + --sparse giup chi tai phan can thiet, nhanh hon nhieu
    git clone --depth 1 --filter=blob:none --sparse \
        https://github.com/supabase/supabase "$SCRIPT_DIR/supabase-src"
    cd "$SCRIPT_DIR/supabase-src"
    git sparse-checkout set docker
    cd "$SCRIPT_DIR"

    echo "[BUOC 2] Copy file cau hinh vao supabase-config..."
    cp -r "$SCRIPT_DIR/supabase-src/docker" "$WORKDIR"
    rm -rf "$SCRIPT_DIR/supabase-src"
    echo "[OK] Clone va copy xong."
else
    echo "[INFO] Thu muc supabase-config da ton tai, bo qua buoc clone."
fi

# ============================================================
# BUOC 2: TAO FILE .env
# ============================================================
if [ ! -f "$WORKDIR/.env" ]; then
    cp "$WORKDIR/.env.example" "$WORKDIR/.env"
    echo "[OK] Tao .env tu .env.example"
fi

# ============================================================
# BUOC 3: SINH KHOA BAO MAT
# Dung openssl co san trong Git Bash / Linux / macOS
# ============================================================
echo
echo "[BUOC 3] Sinh khoa bao mat ngau nhien..."

POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n')
SECRET_KEY_BASE=$(openssl rand -base64 48 | tr -d '\n')
VAULT_ENC_KEY=$(openssl rand -hex 16)
PG_META_CRYPTO_KEY=$(openssl rand -base64 24 | tr -d '\n')
LOGFLARE_ACCESS_TOKEN=$(openssl rand -base64 24 | tr -d '\n')
MINIO_ROOT_PASSWORD=$(openssl rand -hex 16)
DASHBOARD_PASSWORD=$(openssl rand -base64 12 | tr -d '\n/+=')

# ============================================================
# BUOC 4: SINH ANON_KEY VA SERVICE_ROLE_KEY (JWT HS256)
# Cach: tao header.payload dang base64url, ky bang HMAC-SHA256
# Khong can Node, Python - chi dung openssl + bash
# ============================================================
echo "[BUOC 4] Sinh JWT (ANON_KEY va SERVICE_ROLE_KEY)..."

# Ham chuyen base64 -> base64url (thay +/ bang -_, bo =)
b64url() {
    echo -n "$1" | tr '+/' '-_' | tr -d '='
}

# Ham tao JWT HS256
# $1 = payload JSON, $2 = secret
make_jwt() {
    local payload="$1"
    local secret="$2"

    local header
    header=$(b64url "$(echo -n '{"alg":"HS256","typ":"JWT"}' | openssl base64 -A)")

    local body
    body=$(b64url "$(echo -n "$payload" | openssl base64 -A)")

    local sig
    sig=$(echo -n "${header}.${body}" \
        | openssl dgst -sha256 -hmac "$secret" -binary \
        | openssl base64 -A \
        | tr '+/' '-_' | tr -d '=')

    echo "${header}.${body}.${sig}"
}

# Thoi gian: iat = now, exp = 10 nam sau
IAT=$(date +%s)
EXP=$((IAT + 315360000))  # 10 nam = 315360000 giay

ANON_KEY=$(make_jwt \
    "{\"role\":\"anon\",\"iss\":\"supabase\",\"iat\":${IAT},\"exp\":${EXP}}" \
    "$JWT_SECRET")

SERVICE_ROLE_KEY=$(make_jwt \
    "{\"role\":\"service_role\",\"iss\":\"supabase\",\"iat\":${IAT},\"exp\":${EXP}}" \
    "$JWT_SECRET")

echo "[OK] Da sinh xong ANON_KEY va SERVICE_ROLE_KEY."

# ============================================================
# BUOC 5: CAP NHAT FILE .env
# ============================================================
echo "[BUOC 5] Cap nhat file .env..."

# Ham sed tuong thich ca GNU (Linux/Git Bash) va BSD (macOS)
sedi() {
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

sedi "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|"   "$WORKDIR/.env"
sedi "s|^JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET}|"                         "$WORKDIR/.env"
sedi "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET_KEY_BASE}|"         "$WORKDIR/.env"
sedi "s|^VAULT_ENC_KEY=.*|VAULT_ENC_KEY=${VAULT_ENC_KEY}|"               "$WORKDIR/.env"
sedi "s|^PG_META_CRYPTO_KEY=.*|PG_META_CRYPTO_KEY=${PG_META_CRYPTO_KEY}|" "$WORKDIR/.env"
sedi "s|^LOGFLARE_ACCESS_TOKEN=.*|LOGFLARE_ACCESS_TOKEN=${LOGFLARE_ACCESS_TOKEN}|" "$WORKDIR/.env"
sedi "s|^MINIO_ROOT_PASSWORD=.*|MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}|" "$WORKDIR/.env"
sedi "s|^DASHBOARD_USERNAME=.*|DASHBOARD_USERNAME=admin|"                 "$WORKDIR/.env"
sedi "s|^DASHBOARD_PASSWORD=.*|DASHBOARD_PASSWORD=${DASHBOARD_PASSWORD}|" "$WORKDIR/.env"
sedi "s|^ANON_KEY=.*|ANON_KEY=${ANON_KEY}|"                               "$WORKDIR/.env"
sedi "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}|"       "$WORKDIR/.env"

echo "[OK] File .env da cap nhat day du."

# ============================================================
# BUOC 6: TAO start.sh VA stop.sh BEN TRONG supabase-config
# ============================================================
echo "[BUOC 6] Tao start.sh va stop.sh..."

cat > "$WORKDIR/start.sh" <<'STARTSH'
#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d
echo "Supabase da khoi dong. Truy cap Studio tai http://localhost:8000"
STARTSH

cat > "$WORKDIR/stop.sh" <<'STOPSH'
#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose down
STOPSH

chmod +x "$WORKDIR/start.sh" "$WORKDIR/stop.sh"
echo "[OK] Da tao start.sh va stop.sh (da cap quyen +x)."

# ============================================================
# BUOC 7: LUU THONG TIN DANG NHAP
# ============================================================
cat > "$SCRIPT_DIR/credentials.txt" <<EOF
============================================================
  THONG TIN DANG NHAP SUPABASE STUDIO
============================================================
  URL Studio       : http://localhost:8000
  Username         : admin
  Password         : ${DASHBOARD_PASSWORD}

  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  JWT_SECRET       : ${JWT_SECRET}
  ANON_KEY         : ${ANON_KEY}
  SERVICE_ROLE_KEY : ${SERVICE_ROLE_KEY}
============================================================
  Giu file nay an toan, khong chia se cho nguoi khac!
============================================================
EOF
echo "[OK] Da luu thong tin vao credentials.txt"

# ============================================================
# BUOC 8: KHOI DONG SUPABASE bang start.sh
# ============================================================
echo
echo "[BUOC 8] Khoi dong Supabase (lan dau se keo image ~2-3GB)..."
bash "$WORKDIR/start.sh"

echo
echo "============================================================"
echo "  SUPABASE DA CHAY THANH CONG!"
echo "  Studio : http://localhost:8000"
echo "  User   : admin"
echo "  Pass   : ${DASHBOARD_PASSWORD}"
echo "  (Xem day du trong file credentials.txt)"
echo "============================================================"
echo "  Khoi dong lai : cd supabase-config && ./start.sh"
echo "  Dung          : cd supabase-config && ./stop.sh"
echo "  Dong goi      : tar -czf supabase-portable.tar.gz supabase-config/"
echo "============================================================"
