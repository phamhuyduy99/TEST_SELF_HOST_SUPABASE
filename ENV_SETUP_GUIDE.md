# HƯỚNG DẪN TẠO FILE .ENV

File `.env` chứa toàn bộ secrets và cấu hình của Supabase. File này **không được commit lên git**.  
Hướng dẫn này giải thích từng biến, cách sinh giá trị, và những gì cần thay đổi bắt buộc.

---

## BƯỚC 1 — Copy file mẫu

```bash
cd supabase-config
cp .env.example .env
```

---

## BƯỚC 2 — Sinh các giá trị ngẫu nhiên

> ⚠️ **Quan trọng:** Chỉ dùng `hex` (không dùng `base64`) để tránh lỗi URL parsing.  
> Lý do: các ký tự `+`, `/`, `=` trong base64 phá vỡ connection string `postgres://user:PASSWORD@host:port/db`.

### Trên Linux / macOS / Git Bash:
```bash
# Sinh hex ngẫu nhiên
openssl rand -hex 24   # 48 ký tự
openssl rand -hex 32   # 64 ký tự
openssl rand -hex 48   # 96 ký tự
```

### Trên Windows (PowerShell):
```powershell
$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

# 48 ký tự hex
$b = New-Object byte[] 24; $rng.GetBytes($b)
[System.BitConverter]::ToString($b).Replace('-','').ToLower()

# 64 ký tự hex
$b = New-Object byte[] 32; $rng.GetBytes($b)
[System.BitConverter]::ToString($b).Replace('-','').ToLower()

# 96 ký tự hex
$b = New-Object byte[] 48; $rng.GetBytes($b)
[System.BitConverter]::ToString($b).Replace('-','').ToLower()
```

---

## BƯỚC 3 — Sinh ANON_KEY và SERVICE_ROLE_KEY

Hai key này là **JWT được ký bằng JWT_SECRET**. Phải sinh sau khi đã có `JWT_SECRET`.

### Trên Linux / macOS / Git Bash:
```bash
# Cài jwt-cli nếu chưa có
npm install -g jwt-cli

# Sinh ANON_KEY (role: anon)
jwt sign --secret <JWT_SECRET> --iat $(date +%s) --exp $(($(date +%s) + 315360000)) '{"role":"anon","iss":"supabase"}'

# Sinh SERVICE_ROLE_KEY (role: service_role)
jwt sign --secret <JWT_SECRET> --iat $(date +%s) --exp $(($(date +%s) + 315360000)) '{"role":"service_role","iss":"supabase"}'
```

### Trên Windows (PowerShell):
```powershell
$secret = "<JWT_SECRET_CUA_BAN>"
$now = [int](New-TimeSpan -Start (Get-Date '1970-01-01') -End (Get-Date)).TotalSeconds
$exp = $now + 315360000  # hết hạn sau ~10 năm

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

---

## BƯỚC 4 — Điền vào file .env

Dưới đây là giải thích chi tiết từng biến.

---

## CHI TIẾT TỪNG BIẾN

### PHẦN 1 — SECRETS (bắt buộc phải đổi)

---

#### `POSTGRES_PASSWORD`
- **Dùng cho:** Mật khẩu user `postgres` trong PostgreSQL
- **Yêu cầu:** Chỉ dùng ký tự `[a-z0-9]` (hex), không dùng ký tự đặc biệt
- **Sinh:** `openssl rand -hex 24`
- **Ví dụ:** `53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06`

---

#### `JWT_SECRET`
- **Dùng cho:** Khóa bí mật để ký và xác thực tất cả JWT token trong hệ thống (Auth, PostgREST, Realtime, Storage)
- **Yêu cầu:** Tối thiểu 32 ký tự, chỉ dùng hex
- **Sinh:** `openssl rand -hex 32`
- **Ví dụ:** `cfec62c2b97a3870da67030f4493daf82346d122be090ed3f1f16cdae55a098d`
- **⚠️ Lưu ý:** Sau khi đổi `JWT_SECRET`, phải sinh lại `ANON_KEY` và `SERVICE_ROLE_KEY`

---

#### `ANON_KEY`
- **Dùng cho:** JWT token cho role `anon` — dùng ở client/frontend
- **Yêu cầu:** Phải là JWT HS256 được ký bằng `JWT_SECRET`, payload có `"role":"anon"`
- **Sinh:** Xem Bước 3 ở trên
- **Ví dụ:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo`

---

#### `SERVICE_ROLE_KEY`
- **Dùng cho:** JWT token cho role `service_role` — dùng ở server/backend, bypass RLS
- **Yêu cầu:** Phải là JWT HS256 được ký bằng `JWT_SECRET`, payload có `"role":"service_role"`
- **Sinh:** Xem Bước 3 ở trên
- **⚠️ Không bao giờ để lộ ra client/frontend**

---

#### `DASHBOARD_USERNAME`
- **Dùng cho:** Tên đăng nhập vào Supabase Studio (http://localhost:8000)
- **Yêu cầu:** Tự đặt, ví dụ `admin`

---

#### `DASHBOARD_PASSWORD`
- **Dùng cho:** Mật khẩu đăng nhập Studio
- **Yêu cầu:** Đặt mật khẩu mạnh, chỉ dùng chữ và số
- **Sinh:** `openssl rand -hex 12`

---

#### `SECRET_KEY_BASE`
- **Dùng cho:** Realtime và Supavisor dùng để mã hóa session nội bộ
- **Yêu cầu:** Tối thiểu 64 ký tự hex
- **Sinh:** `openssl rand -hex 48`
- **Ví dụ:** `7bc26414c29d15a625e2a2f304249284adfdb74312e52baf2daa79b913870bcd7bbe30ebad86d079e7b5044d9e239c29`

---

#### `VAULT_ENC_KEY`
- **Dùng cho:** Supavisor (connection pooler) dùng để mã hóa dữ liệu vault
- **Yêu cầu:** Đúng 32 ký tự hex (16 bytes)
- **Sinh:** `openssl rand -hex 16`
- **Ví dụ:** `3943dd0f98acb030ea9e9e7888d02c47`

---

#### `PG_META_CRYPTO_KEY`
- **Dùng cho:** Studio dùng để mã hóa thông tin kết nối database
- **Yêu cầu:** Tối thiểu 32 ký tự hex
- **Sinh:** `openssl rand -hex 24`
- **Ví dụ:** `1e690444f1c40e160f0fe0265b48200d731770d5a7df147c`

---

#### `LOGFLARE_PUBLIC_ACCESS_TOKEN`
- **Dùng cho:** Token để đọc logs từ Logflare (analytics)
- **Sinh:** `openssl rand -hex 24`

---

#### `LOGFLARE_PRIVATE_ACCESS_TOKEN`
- **Dùng cho:** Token để ghi logs vào Logflare
- **Sinh:** `openssl rand -hex 24`

---

#### `S3_PROTOCOL_ACCESS_KEY_ID`
- **Dùng cho:** Access key ID cho S3 protocol endpoint của Storage
- **Sinh:** `openssl rand -hex 16`

---

#### `S3_PROTOCOL_ACCESS_KEY_SECRET`
- **Dùng cho:** Secret key cho S3 protocol endpoint
- **Sinh:** `openssl rand -hex 32`

---

#### `MINIO_ROOT_PASSWORD`
- **Dùng cho:** Mật khẩu admin MinIO (chỉ dùng khi bật S3 backend)
- **Sinh:** `openssl rand -hex 16`

---

### PHẦN 2 — URLs (đổi khi deploy lên server thật)

---

#### `SUPABASE_PUBLIC_URL`
- **Mặc định:** `http://localhost:8000`
- **Khi deploy:** Đổi thành `http://<IP_SERVER>:8000` hoặc `https://supabase.yourdomain.com`
- **Dùng cho:** URL public để truy cập API và Studio

---

#### `API_EXTERNAL_URL`
- **Mặc định:** `http://localhost:8000`
- **Khi deploy:** Đổi giống `SUPABASE_PUBLIC_URL`
- **Dùng cho:** Auth service dùng để tạo callback URL cho OAuth, email verification link

---

#### `SITE_URL`
- **Mặc định:** `http://localhost:3000`
- **Khi deploy:** Đổi thành URL của frontend app của anh
- **Dùng cho:** Auth redirect sau khi đăng nhập/đăng ký thành công

---

### PHẦN 3 — Database (thường giữ nguyên)

| Biến | Mặc định | Giải thích |
|------|----------|-----------|
| `POSTGRES_HOST` | `db` | Tên container DB trong Docker network, không đổi |
| `POSTGRES_DB` | `postgres` | Tên database mặc định |
| `POSTGRES_PORT` | `5432` | Port PostgreSQL bên trong container |
| `POOLER_PROXY_PORT_TRANSACTION` | `6543` | Port transaction mode pooling expose ra ngoài |
| `POOLER_DEFAULT_POOL_SIZE` | `20` | Số connection tối đa mỗi pool |
| `POOLER_MAX_CLIENT_CONN` | `100` | Số client connection tối đa |
| `POOLER_TENANT_ID` | `your-tenant-id` | ID định danh tenant trong Supavisor, đặt tùy ý |
| `POOLER_DB_POOL_SIZE` | `5` | Pool size nội bộ của Supavisor |

---

### PHẦN 4 — Ports (đổi nếu bị xung đột)

| Biến | Mặc định | Giải thích |
|------|----------|-----------|
| `KONG_HTTP_PORT` | `8000` | Port HTTP của API Gateway (Studio + API) |
| `KONG_HTTPS_PORT` | `8443` | Port HTTPS của API Gateway |

Nếu port `8000` đã bị dùng, đổi `KONG_HTTP_PORT=9000` và truy cập Studio qua `http://localhost:9000`.

---

### PHẦN 5 — Auth (tùy chỉnh theo nhu cầu)

| Biến | Mặc định | Giải thích |
|------|----------|-----------|
| `JWT_EXPIRY` | `3600` | Thời gian hết hạn JWT tính bằng giây (3600 = 1 giờ) |
| `DISABLE_SIGNUP` | `false` | `true` = tắt tự đăng ký, chỉ admin mới tạo user được |
| `ENABLE_EMAIL_SIGNUP` | `true` | Cho phép đăng ký bằng email |
| `ENABLE_EMAIL_AUTOCONFIRM` | `false` | `true` = không cần xác nhận email (tiện cho dev) |
| `ENABLE_ANONYMOUS_USERS` | `false` | Cho phép user ẩn danh |
| `ADDITIONAL_REDIRECT_URLS` | _(trống)_ | Danh sách URL được phép redirect sau auth, cách nhau bằng dấu phẩy |

---

### PHẦN 6 — SMTP Email (cấu hình nếu cần gửi email)

Mặc định dùng mailhog giả lập, không gửi email thật. Để gửi email thật:

| Biến | Giải thích |
|------|-----------|
| `SMTP_HOST` | Host SMTP, ví dụ `smtp.gmail.com` |
| `SMTP_PORT` | Port SMTP, ví dụ `587` |
| `SMTP_USER` | Email/username đăng nhập SMTP |
| `SMTP_PASS` | Mật khẩu SMTP |
| `SMTP_ADMIN_EMAIL` | Email hiển thị là người gửi |
| `SMTP_SENDER_NAME` | Tên hiển thị người gửi |

---

## TỔNG HỢP — Checklist trước khi chạy

```
[ ] POSTGRES_PASSWORD     → sinh hex 48 ký tự
[ ] JWT_SECRET            → sinh hex 64 ký tự
[ ] ANON_KEY              → sinh JWT từ JWT_SECRET (role: anon)
[ ] SERVICE_ROLE_KEY      → sinh JWT từ JWT_SECRET (role: service_role)
[ ] DASHBOARD_USERNAME    → tự đặt
[ ] DASHBOARD_PASSWORD    → tự đặt, chỉ chữ và số
[ ] SECRET_KEY_BASE       → sinh hex 96 ký tự
[ ] VAULT_ENC_KEY         → sinh hex 32 ký tự (đúng 32)
[ ] PG_META_CRYPTO_KEY    → sinh hex 48 ký tự
[ ] LOGFLARE_PUBLIC_ACCESS_TOKEN  → sinh hex 24 ký tự
[ ] LOGFLARE_PRIVATE_ACCESS_TOKEN → sinh hex 24 ký tự
[ ] S3_PROTOCOL_ACCESS_KEY_ID     → sinh hex 16 ký tự
[ ] S3_PROTOCOL_ACCESS_KEY_SECRET → sinh hex 32 ký tự
[ ] SUPABASE_PUBLIC_URL   → đổi nếu deploy lên server thật
[ ] API_EXTERNAL_URL      → đổi nếu deploy lên server thật
[ ] SITE_URL              → đổi thành URL frontend app của anh
[ ] POOLER_TENANT_ID      → đặt tên tùy ý, ví dụ: my-project
```

---

## LƯU Ý QUAN TRỌNG

1. **Không commit file `.env` lên git** — file này đã có trong `.gitignore`
2. **Backup file `.env`** ở nơi an toàn — mất file này là mất khả năng kết nối lại DB
3. **Không đổi secrets sau khi đã có data** — đổi `POSTGRES_PASSWORD` hay `JWT_SECRET` sau khi DB đã có dữ liệu sẽ làm hỏng toàn bộ hệ thống (phải reset DB)
4. **`SERVICE_ROLE_KEY` tuyệt đối không để lộ ra client** — key này bypass toàn bộ Row Level Security
