# SUPABASE SELF-HOST PORTABLE

Bộ cấu hình Docker để chạy Supabase self-host trên **mọi hệ điều hành có Docker** — Windows, Linux, macOS.  
Không cần cài thêm gì ngoài Docker. Clone repo về, tạo file `.env`, chạy một lệnh là xong.

---

## MỤC LỤC

1. [Ý tưởng tổng thể](#1-ý-tưởng-tổng-thể)
2. [Yêu cầu](#2-yêu-cầu)
3. [Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
4. [Cài đặt lần đầu](#4-cài-đặt-lần-đầu)
5. [Tạo file .env](#5-tạo-file-env)
6. [Khởi động hệ thống](#6-khởi-động-hệ-thống)
7. [Truy cập Studio](#7-truy-cập-studio)
8. [Kết nối từ ứng dụng](#8-kết-nối-từ-ứng-dụng)
9. [Gọi API trực tiếp](#9-gọi-api-trực-tiếp)
10. [Kết nối PostgreSQL trực tiếp](#10-kết-nối-postgresql-trực-tiếp)
11. [Mang sang máy khác](#11-mang-sang-máy-khác)
12. [Lệnh quản lý thường dùng](#12-lệnh-quản-lý-thường-dùng)
13. [Xử lý sự cố](#13-xử-lý-sự-cố)
14. [Sơ đồ kiến trúc](#14-sơ-đồ-kiến-trúc)

---

## 1. Ý tưởng tổng thể

Supabase gồm nhiều service độc lập (PostgreSQL, Auth, REST API, Realtime, Storage...), mỗi service có Docker image riêng. Thay vì build một image tổng hợp (không thực tế), ta dùng **Docker Compose** để quản lý toàn bộ — đây là cách chuẩn cho multi-container.

Bộ này đóng gói sẵn toàn bộ file cấu hình. Ai clone về chỉ cần:
1. Tạo file `.env` với secrets của riêng mình
2. Chạy `docker compose up -d`

Không cần Git, không cần openssl trên máy đích — **chỉ cần Docker**.

---

## 2. Yêu cầu

| Thứ cần có | Ghi chú |
|-----------|---------|
| Docker Engine ≥ 20.10 | Windows/macOS dùng Docker Desktop, Linux dùng Docker Engine |
| Docker Compose v2 | Đi kèm Docker Desktop, hoặc cài riêng trên Linux |
| Git | Chỉ cần khi clone repo lần đầu |
| RAM tối thiểu | 4GB (khuyến nghị 8GB) |
| Disk trống | ~5GB (images + data) |

> Trên Windows nên dùng **Git Bash** để chạy các lệnh bash. Mở Git Bash bằng chuột phải → Run as administrator.

---

## 3. Cấu trúc thư mục

```
SUPABASE/
├── README.md                  ← File này
├── ENV_SETUP_GUIDE.md         ← Hướng dẫn chi tiết tạo file .env
├── TROUBLESHOOTING.md         ← Các lỗi đã gặp và cách fix
├── USAGE_GUIDE.md             ← Hướng dẫn sử dụng API, SDK
├── .gitignore
│
├── setup.bat                  ← Setup tự động (Windows CMD)
├── setup.sh                   ← Setup tự động (Linux/macOS/Git Bash)
├── start.bat / start.sh       ← Khởi động
├── stop.bat / stop.sh         ← Dừng
├── status.bat                 ← Xem trạng thái (Windows)
├── update-keys.bat            ← Cập nhật API keys (Windows)
├── update-keys.sh             ← Cập nhật API keys (Linux/macOS)
├── pack.bat / pack.sh         ← Đóng gói mang đi
│
└── supabase-config/           ← Thư mục cấu hình Docker
    ├── docker-compose.yml     ← File chính định nghĩa tất cả service
    ├── .env.example           ← File mẫu .env (không có secrets thật)
    ├── .env                   ← File secrets thật (KHÔNG commit lên git)
    └── volumes/
        ├── api/               ← Cấu hình Kong API Gateway
        ├── db/                ← SQL init scripts + data PostgreSQL
        ├── functions/         ← Edge Functions
        ├── logs/              ← Cấu hình Vector log collector
        ├── pooler/            ← Cấu hình Supavisor
        ├── proxy/             ← Cấu hình Caddy/Nginx (tùy chọn)
        ├── snippets/          ← SQL snippets của Studio
        └── storage/           ← File upload của Storage API
```

---

## 4. Cài đặt lần đầu

### Bước 1 — Clone repo

```bash
git clone https://github.com/phamhuyduy99/TEST_SELF_HOST_SUPABASE.git
cd TEST_SELF_HOST_SUPABASE/supabase-config
```

### Bước 2 — Tạo file .env

```bash
cp .env.example .env
```

Sau đó điền secrets vào file `.env`. Xem hướng dẫn chi tiết ở [Phần 5](#5-tạo-file-env) hoặc file `ENV_SETUP_GUIDE.md`.

### Bước 3 — Khởi động

```bash
docker compose up -d
```

Lần đầu sẽ kéo các Docker image (~3GB). Chờ khoảng 2–3 phút.

### Bước 4 — Kiểm tra

```bash
docker compose ps
```

Tất cả service hiện `healthy` là thành công. Truy cập Studio tại **http://localhost:8000**.

> ⚠️ **Lưu ý lần đầu:** DB init mất 2–3 phút. Nếu thấy lỗi `unhealthy`, chờ DB healthy rồi chạy lại `docker compose up -d`.

---

## 5. Tạo file .env

> Xem hướng dẫn đầy đủ trong file `ENV_SETUP_GUIDE.md`.

### Sinh secrets — Linux / macOS / Git Bash

```bash
openssl rand -hex 24   # dùng cho POSTGRES_PASSWORD, PG_META_CRYPTO_KEY...
openssl rand -hex 32   # dùng cho JWT_SECRET
openssl rand -hex 48   # dùng cho SECRET_KEY_BASE
openssl rand -hex 16   # dùng cho VAULT_ENC_KEY (đúng 32 ký tự)
```

### Sinh secrets — Windows PowerShell

```powershell
$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$b = New-Object byte[] 24; $rng.GetBytes($b)
[System.BitConverter]::ToString($b).Replace('-','').ToLower()
```

### Sinh ANON_KEY và SERVICE_ROLE_KEY — Windows PowerShell

```powershell
$secret = "<JWT_SECRET_CUA_BAN>"
$now = [int](New-TimeSpan -Start (Get-Date '1970-01-01') -End (Get-Date)).TotalSeconds
$exp = $now + 315360000

function Make-JWT($role) {
    $header  = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('{"alg":"HS256","typ":"JWT"}')).TrimEnd('=').Replace('+','-').Replace('/','_')
    $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("{`"role`":`"$role`",`"iss`":`"supabase`",`"iat`":$now,`"exp`":$exp}")).TrimEnd('=').Replace('+','-').Replace('/','_')
    $data    = "$header.$payload"
    $hmac    = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($secret)
    $sig     = [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($data))).TrimEnd('=').Replace('+','-').Replace('/','_')
    return "$data.$sig"
}

Write-Host "ANON_KEY=$(Make-JWT 'anon')"
Write-Host "SERVICE_ROLE_KEY=$(Make-JWT 'service_role')"
```

### Sinh ANON_KEY và SERVICE_ROLE_KEY — Git Bash / Linux / macOS

```bash
npm install -g jwt-cli

jwt sign --secret <JWT_SECRET> \
  --iat $(date +%s) \
  --exp $(($(date +%s) + 315360000)) \
  '{"role":"anon","iss":"supabase"}'

jwt sign --secret <JWT_SECRET> \
  --iat $(date +%s) \
  --exp $(($(date +%s) + 315360000)) \
  '{"role":"service_role","iss":"supabase"}'
```

### Checklist các biến bắt buộc phải đổi

```
[ ] POSTGRES_PASSWORD          → openssl rand -hex 24
[ ] JWT_SECRET                 → openssl rand -hex 32
[ ] ANON_KEY                   → JWT ký bằng JWT_SECRET (role: anon)
[ ] SERVICE_ROLE_KEY           → JWT ký bằng JWT_SECRET (role: service_role)
[ ] DASHBOARD_USERNAME         → tự đặt (ví dụ: admin)
[ ] DASHBOARD_PASSWORD         → openssl rand -hex 12
[ ] SECRET_KEY_BASE            → openssl rand -hex 48
[ ] VAULT_ENC_KEY              → openssl rand -hex 16  (đúng 32 ký tự)
[ ] PG_META_CRYPTO_KEY         → openssl rand -hex 24
[ ] LOGFLARE_PUBLIC_ACCESS_TOKEN  → openssl rand -hex 24
[ ] LOGFLARE_PRIVATE_ACCESS_TOKEN → openssl rand -hex 24
[ ] S3_PROTOCOL_ACCESS_KEY_ID     → openssl rand -hex 16
[ ] S3_PROTOCOL_ACCESS_KEY_SECRET → openssl rand -hex 32
[ ] SUPABASE_PUBLIC_URL        → đổi nếu deploy server thật
[ ] API_EXTERNAL_URL           → đổi nếu deploy server thật
[ ] SITE_URL                   → URL frontend app của bạn
[ ] POOLER_TENANT_ID           → đặt tên tùy ý, ví dụ: my-project
```

> ⚠️ **Quan trọng:** Chỉ dùng `hex`, không dùng `base64`. Ký tự `+`, `/`, `=` trong base64 phá vỡ connection string `postgres://user:PASSWORD@host:port/db` gây crash toàn bộ service.

---

## 6. Khởi động hệ thống

### Windows (CMD hoặc nhấp đúp)

```
start.bat
```

### Linux / macOS / Git Bash

```bash
cd supabase-config
docker compose up -d
```

### Dừng hệ thống

```bash
# Windows
stop.bat

# Linux/macOS/Git Bash
docker compose down        # dừng, giữ nguyên data
docker compose down -v     # dừng và xóa named volumes (KHÔNG xóa data trong volumes/db/data)
```

### Xem trạng thái

```bash
docker compose ps
```

Kết quả mong đợi — tất cả 13 service:

| Service | Trạng thái |
|---------|-----------|
| supabase-db | ✅ healthy |
| supabase-auth | ✅ healthy |
| supabase-rest | ✅ running |
| supabase-realtime | ✅ healthy |
| supabase-storage | ✅ healthy |
| supabase-analytics | ✅ healthy |
| supabase-studio | ✅ healthy |
| supabase-kong | ✅ healthy |
| supabase-meta | ✅ healthy |
| supabase-pooler | ✅ healthy |
| supabase-edge-functions | ✅ running |
| supabase-imgproxy | ✅ healthy |
| supabase-vector | ✅ healthy |

---

## 7. Truy cập Studio

Truy cập: **http://localhost:8000**

Đăng nhập bằng `DASHBOARD_USERNAME` và `DASHBOARD_PASSWORD` đã đặt trong `.env`.

### Các tính năng chính:

**Table Editor** — Xem, thêm, sửa, xóa dữ liệu như spreadsheet.

**SQL Editor** — Chạy SQL tùy ý:
```sql
CREATE TABLE products (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  price numeric,
  created_at timestamptz DEFAULT now()
);
```

**Authentication** — Quản lý user, cấu hình OAuth providers (Google, GitHub...).

**Storage** — Upload/download file, tạo bucket, quản lý quyền.

**Edge Functions** — Deploy serverless functions (Deno/TypeScript).

**Logs** — Xem log realtime của tất cả service.

**Settings → API** — Lấy `anon key`, `service role key`, URL API.

---

## 8. Kết nối từ ứng dụng

Tất cả request đi qua Kong API Gateway tại port `8000`.

| Endpoint | Mô tả |
|----------|-------|
| `http://localhost:8000/rest/v1/` | REST API (PostgREST) |
| `http://localhost:8000/auth/v1/` | Authentication |
| `http://localhost:8000/storage/v1/` | File Storage |
| `http://localhost:8000/realtime/v1/` | Realtime WebSocket |
| `http://localhost:8000/functions/v1/` | Edge Functions |

### JavaScript / TypeScript

```bash
npm install @supabase/supabase-js
```

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  '<ANON_KEY>'   // lấy từ .env hoặc Studio → Settings → API
)

// Query dữ liệu
const { data, error } = await supabase.from('products').select('*')

// Thêm dữ liệu
const { data, error } = await supabase
  .from('products')
  .insert({ name: 'Sản phẩm A', price: 99000 })

// Đăng ký user
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123'
})

// Đăng nhập
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})

// Realtime — lắng nghe thay đổi
supabase
  .channel('products-changes')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'products' }, (payload) => {
    console.log('Thay đổi:', payload)
  })
  .subscribe()

// Storage — upload file
const { data, error } = await supabase.storage
  .from('avatars')
  .upload('user123/avatar.png', file)
```

### Python

```bash
pip install supabase
```

```python
from supabase import create_client

supabase = create_client('http://localhost:8000', '<ANON_KEY>')

# Query
response = supabase.table('products').select('*').execute()
print(response.data)

# Insert
response = supabase.table('products').insert({'name': 'Sản phẩm A', 'price': 99000}).execute()
```

### Dart / Flutter

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
```

```dart
await Supabase.initialize(
  url: 'http://localhost:8000',
  anonKey: '<ANON_KEY>',
);

final supabase = Supabase.instance.client;
final data = await supabase.from('products').select();
```

### Phân biệt ANON KEY vs SERVICE ROLE KEY

| | ANON KEY | SERVICE ROLE KEY |
|---|---|---|
| Dùng ở đâu | Client — browser, mobile | Server — backend, scripts |
| Quyền | Bị giới hạn bởi RLS | Bypass toàn bộ RLS |
| Có thể public | Được | **KHÔNG — tuyệt đối không để lộ** |

---

## 9. Gọi API trực tiếp

Dùng với bất kỳ ngôn ngữ nào có HTTP client (curl, Postman, Axios...).

Header bắt buộc với mọi request:
```
apikey: <ANON_KEY hoặc SERVICE_ROLE_KEY>
Authorization: Bearer <ANON_KEY hoặc SERVICE_ROLE_KEY>
Content-Type: application/json
```

```bash
# Lấy dữ liệu
curl http://localhost:8000/rest/v1/products \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>"

# Thêm dữ liệu
curl -X POST http://localhost:8000/rest/v1/products \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"name": "Sản phẩm A", "price": 99000}'

# Đăng ký user
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'

# Đăng nhập
curl -X POST "http://localhost:8000/auth/v1/token?grant_type=password" \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

---

## 10. Kết nối PostgreSQL trực tiếp

Dùng khi cần chạy migration, dùng ORM (Prisma, SQLAlchemy, GORM...), hoặc tool như DBeaver, TablePlus.

**Session mode** — dùng cho migration, long-running queries (port 5432):
```
postgresql://postgres:<POSTGRES_PASSWORD>@localhost:5432/postgres
```

**Transaction mode** — dùng cho app, connection pooling (port 6543):
```
postgresql://postgres.<POOLER_TENANT_ID>:<POSTGRES_PASSWORD>@localhost:6543/postgres
```

```bash
# psql
psql postgresql://postgres:<POSTGRES_PASSWORD>@localhost:5432/postgres

# Prisma (.env)
DATABASE_URL="postgresql://postgres:<POSTGRES_PASSWORD>@localhost:5432/postgres"

# SQLAlchemy (Python)
DATABASE_URL = "postgresql://postgres:<POSTGRES_PASSWORD>@localhost:5432/postgres"
```

### Row Level Security (RLS)

Mặc định bảng mới **không có RLS** — mọi người đều đọc/ghi được. Cần bật cho môi trường production:

```sql
-- Bật RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policy: user chỉ đọc data của chính mình
CREATE POLICY "Users read own data"
ON products FOR SELECT
USING (auth.uid() = user_id);

-- Policy: cho phép tất cả đọc (public)
CREATE POLICY "Public read"
ON products FOR SELECT
USING (true);
```

---

## 11. Mang sang máy khác

### Đóng gói

```bash
# Windows
pack.bat

# Linux/macOS/Git Bash
tar -czf supabase-portable.tar.gz supabase-config/
```

### Chạy trên máy đích

Máy đích chỉ cần có Docker, không cần gì khác.

```bash
# Giải nén
tar -xzf supabase-portable.tar.gz

# Chạy
cd supabase-config
docker compose up -d
```

### Deploy lên server thật (VPS/cloud)

Đổi các URL trong `.env` trước khi chạy:

```env
SUPABASE_PUBLIC_URL=http://<IP_SERVER>:8000
API_EXTERNAL_URL=http://<IP_SERVER>:8000
SITE_URL=http://<IP_SERVER>:3000
```

Kết nối từ app:
```typescript
const supabase = createClient('http://<IP_SERVER>:8000', '<ANON_KEY>')
```

### Đổi port nếu bị xung đột

Sửa trong `supabase-config/docker-compose.yml`:
```yaml
services:
  kong:
    ports:
      - "9000:8000"   # đổi 9000 thành port muốn dùng
```

Hoặc đổi trong `.env`:
```env
KONG_HTTP_PORT=9000
```

---

## 12. Lệnh quản lý thường dùng

```bash
# Khởi động
docker compose up -d

# Dừng (giữ data)
docker compose down

# Xem trạng thái tất cả service
docker compose ps

# Xem log realtime
docker compose logs -f

# Xem log một service cụ thể
docker compose logs -f auth
docker compose logs -f db
docker compose logs -f kong
docker compose logs -f analytics

# Restart một service
docker compose restart auth
docker compose restart pooler

# Vào container DB chạy SQL trực tiếp
docker compose exec db psql -U postgres
```

---

## 13. Xử lý sự cố

### Lỗi thường gặp

**`auth`/`storage`/`pooler` crash — lỗi `invalid port` hoặc `invalid URL`**
```
FATAL: parse "postgres://user:PASSWORD@db:5432/postgres": invalid port ":PASSWORD" after host
```
Nguyên nhân: password chứa ký tự đặc biệt (`+`, `/`, `=`).  
Fix: sinh lại tất cả secrets dùng `openssl rand -hex` thay vì `base64`.

---

**`analytics` lỗi `invalid_password` sau khi đổi password**
```
FATAL 28P01 (invalid_password) password authentication failed for user "supabase_admin"
```
Nguyên nhân: `./volumes/db/data` là bind mount trên disk, không bị xóa khi `docker compose down -v`. DB vẫn dùng password cũ.  
Fix:
```bash
docker compose down
rmdir /s /q volumes\db\data   # Windows
# hoặc: rm -rf volumes/db/data  # Linux/macOS
docker compose up -d
```
> ⚠️ Lệnh này xóa toàn bộ data. Chỉ làm khi setup lần đầu.

---

**Các service báo `unhealthy` ngay sau khi khởi động**
```
dependency failed to start: container supabase-db is unhealthy
```
Nguyên nhân: DB init lần đầu mất 2–3 phút, các service khác timeout trước.  
Fix: chờ DB healthy rồi chạy lại:
```bash
docker compose ps db        # chờ hiện "healthy"
docker compose up -d        # khởi động các service còn lại
```

---

**`pooler` crash — lỗi `carriage return` hoặc BOM**
```
error: unexpected token: carriage return (column 4, code point U+000D)
error: unexpected token: "﻿" (column 1, code point U+FEFF)
```
Nguyên nhân: file `volumes/pooler/pooler.exs` có line endings Windows (CRLF) hoặc BOM.  
Fix (PowerShell):
```powershell
$content = (Get-Content 'volumes\pooler\pooler.exs' -Raw).Replace("`r`n", "`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path 'volumes\pooler\pooler.exs'), $content, $utf8NoBom)
docker compose restart supavisor
```

---

**Các lỗi khác**

| Vấn đề | Cách khắc phục |
|--------|---------------|
| `docker: command not found` | Chưa cài Docker Desktop / Docker Engine |
| Port đã bị dùng | Đổi `KONG_HTTP_PORT` trong `.env` |
| Linux cần sudo để chạy docker | `sudo usermod -aG docker $USER` rồi logout/login |

> Xem chi tiết tất cả lỗi đã gặp trong file `TROUBLESHOOTING.md`.

---

## 14. Sơ đồ kiến trúc

```
Ứng dụng / Browser
        │
        │  HTTP :8000  (hoặc HTTPS :8443)
        ▼
┌─────────────────────────────────┐
│     Kong API Gateway            │  ← xác thực apikey / JWT
│     (supabase-kong)             │
└──────────────┬──────────────────┘
               │
       ┌───────┼────────────────────────┐
       │       │                        │
       ▼       ▼                        ▼
  /rest/v1  /auth/v1              /storage/v1
  PostgREST  GoTrue               Storage API
       │       │                        │
       └───────┴────────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Supavisor (Pooler)  │  ← connection pooling
    │  port 5432 / 6543    │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │   PostgreSQL (DB)    │  ← ./volumes/db/data/
    └──────────────────────┘

Các service khác:
  /realtime/v1  → Realtime (WebSocket)
  /functions/v1 → Edge Runtime (Deno)
  Studio        → supabase-studio :3000 (qua Kong)
  Logs          → Vector → Logflare (analytics)
```

---

## Tài liệu liên quan

| File | Nội dung |
|------|---------|
| `ENV_SETUP_GUIDE.md` | Giải thích chi tiết từng biến trong `.env`, cách sinh giá trị |
| `USAGE_GUIDE.md` | Hướng dẫn đầy đủ kết nối SDK, gọi API, RLS, Realtime, Storage |
| `TROUBLESHOOTING.md` | Tất cả lỗi đã gặp trong quá trình setup và cách fix |
| `supabase-config/.env.example` | File mẫu `.env` với giá trị placeholder |
