# TROUBLESHOOTING — Supabase Self-Host

Ghi lại các vấn đề gặp phải trong quá trình setup và cách đã fix.

---

## Vấn đề 1 — `auth`, `storage`, `pooler` crash ngay khi khởi động

**Triệu chứng:**
```
supabase-auth | FATAL: parse "postgres://supabase_auth_admin:WWn+9VYL6zd33lCe+...@db:5432/postgres":
invalid port ":WWn+9VYL6zd33lCe+" after host
```

**Nguyên nhân:**  
`POSTGRES_PASSWORD` được sinh bằng `openssl rand -base64` chứa các ký tự đặc biệt (`+`, `/`, `=`).  
Khi các service ghép password vào connection URL dạng `postgres://user:PASSWORD@host:port/db`, Go và Elixir parser bị nhầm — đọc phần sau dấu `/` trong password như là hostname/port.

**Fix:**  
Sinh lại tất cả secrets dùng `openssl rand -hex` (hoặc PowerShell `RNGCryptoServiceProvider` hex) — chỉ có ký tự `[0-9a-f]`, không có ký tự đặc biệt.

```powershell
# Sinh password an toàn cho URL (Windows PowerShell)
$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$b = New-Object byte[] 24
$rng.GetBytes($b)
[System.BitConverter]::ToString($b).Replace('-','').ToLower()
```

**Các biến bị ảnh hưởng:** `POSTGRES_PASSWORD`, `JWT_SECRET`, `SECRET_KEY_BASE`, `PG_META_CRYPTO_KEY`

---

## Vấn đề 2 — `analytics` (Logflare) lỗi `invalid_password` sau khi đổi password

**Triệu chứng:**
```
FATAL 28P01 (invalid_password) password authentication failed for user "supabase_admin"
```

**Nguyên nhân:**  
`docker compose down -v` chỉ xóa **Docker named volumes** (`db-config`, `deno-cache`).  
Thư mục `./volumes/db/data` là **bind mount** trực tiếp trên disk — không bị xóa.  
PostgreSQL đã được init với password cũ, khi đổi `POSTGRES_PASSWORD` trong `.env` mà không xóa data, DB vẫn dùng password cũ.

**Fix:**  
Dừng container và xóa thư mục data để DB init lại từ đầu:

```cmd
docker compose down
rmdir /s /q volumes\db\data
docker compose up -d
```

> ⚠️ **Lưu ý:** Lệnh này xóa toàn bộ dữ liệu database. Chỉ làm khi setup lần đầu hoặc chấp nhận mất data.

---

## Vấn đề 3 — DB init lần đầu mất quá lâu, các service phụ thuộc báo `unhealthy`

**Triệu chứng:**
```
dependency failed to start: container supabase-db is unhealthy
```

**Nguyên nhân:**  
Lần đầu init DB, PostgreSQL phải chạy toàn bộ migration scripts (tạo schema, roles, extensions...) mất 2–3 phút. Trong khi đó các service khác (`analytics`, `auth`...) chờ DB healthy nhưng timeout trước.

**Fix:**  
Chờ DB healthy hoàn toàn rồi chạy lại `up -d` — Docker Compose sẽ chỉ khởi động các service còn thiếu, không restart DB:

```bash
# Chờ DB healthy (kiểm tra bằng lệnh này)
docker compose ps db

# Khi DB hiện "healthy", chạy lại
docker compose up -d
```

---

## Vấn đề 4 — `pooler` (Supavisor) crash với lỗi `carriage return`

**Triệu chứng:**
```
** (SyntaxError) invalid syntax found on nofile:30:4:
    error: unexpected token: carriage return (column 4, code point U+000D)
```

**Nguyên nhân:**  
File `volumes/pooler/pooler.exs` có line endings kiểu Windows (`CRLF` = `\r\n`).  
Elixir runtime chỉ chấp nhận Unix line endings (`LF` = `\n`).  
File bị CRLF do được tạo/chỉnh sửa trên Windows.

**Fix:**  
Convert line endings sang LF bằng PowerShell (không dùng `Set-Content` vì nó tự thêm BOM):

```powershell
$content = (Get-Content 'volumes\pooler\pooler.exs' -Raw).Replace("`r`n", "`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Resolve-Path 'volumes\pooler\pooler.exs'), $content, $utf8NoBom)
```

---

## Vấn đề 5 — `pooler` crash với lỗi BOM (`U+FEFF`)

**Triệu chứng:**
```
** (SyntaxError) invalid syntax found on nofile:1:1:
    error: unexpected token: "﻿" (column 1, code point U+FEFF)
```

**Nguyên nhân:**  
Sau khi fix vấn đề 4, dùng `Set-Content -Encoding UTF8` của PowerShell lại thêm **BOM** (Byte Order Mark `\uFEFF`) vào đầu file.  
Elixir không chấp nhận BOM trong source file.

**Fix:**  
Dùng `System.IO.File::WriteAllText` với `UTF8Encoding($false)` — tham số `$false` = không BOM:

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

> 💡 **Bài học:** Trên Windows, khi cần ghi file text cho Linux container, luôn dùng UTF-8 không BOM + LF line endings.

---

## Kết quả cuối cùng

Tất cả 13 service đều `healthy`:

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

**Truy cập Studio:** http://localhost:8000  
**Thông tin đăng nhập:** xem file `credentials.txt`
