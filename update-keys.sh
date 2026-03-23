#!/usr/bin/env bash
# Dung khi muon thay the key bang key tu Studio thu cong
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="$SCRIPT_DIR/supabase-config"

echo "Lay key tai: Studio -> Settings -> API"
echo
read -rp "Dan ANON KEY: " ANON_KEY
read -rp "Dan SERVICE ROLE KEY: " SERVICE_KEY

sedi() {
    if sed --version 2>/dev/null | grep -q GNU; then sed -i "$@"; else sed -i '' "$@"; fi
}

sedi "s|^ANON_KEY=.*|ANON_KEY=${ANON_KEY}|" "$WORKDIR/.env"
sedi "s|^SERVICE_ROLE_KEY=.*|SERVICE_ROLE_KEY=${SERVICE_KEY}|" "$WORKDIR/.env"

echo "[OK] Da cap nhat. Khoi dong lai..."
cd "$WORKDIR"
docker compose down && docker compose up -d
echo "[OK] Supabase da chay voi key moi!"
