#!/usr/bin/env bash
# Dong goi supabase-config thanh file tar.gz de mang sang may khac
# Tuong duong pack.bat nhung dung cho Git Bash / Linux / macOS
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SCRIPT_DIR/supabase-config" ]; then
    echo "[LOI] Chua co thu muc supabase-config. Hay chay setup.sh truoc."
    exit 1
fi

OUTPUT="$SCRIPT_DIR/supabase-portable.tar.gz"
echo "[INFO] Dang dong goi supabase-config..."
tar -czf "$OUTPUT" -C "$SCRIPT_DIR" supabase-config/

echo "[OK] Da tao file: supabase-portable.tar.gz"
echo
echo "Cach dung tren may dich (chi can Docker):"
echo "  tar -xzf supabase-portable.tar.gz"
echo "  cd supabase-config"
echo "  docker compose up -d"
echo "  Truy cap: http://localhost:8000"
