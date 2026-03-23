#!/usr/bin/env bash
cd "$(dirname "$0")"
docker compose up -d
echo "Supabase da khoi dong. Truy cap Studio tai http://localhost:8000"
