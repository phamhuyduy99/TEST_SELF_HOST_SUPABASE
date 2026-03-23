# HƯỚNG DẪN SỬ DỤNG SUPABASE SELF-HOST

Sau khi hệ thống đã chạy, đây là toàn bộ hướng dẫn: xem giao diện, kết nối từ ứng dụng, gọi API.

---

## 1. THÔNG TIN KẾT NỐI CỦA BỘ NÀY

```
Studio URL   : http://localhost:8000
API URL      : http://localhost:8000
PostgreSQL   : localhost:5432  (qua Supavisor session mode)
Pooler TX    : localhost:6543  (qua Supavisor transaction mode)

ANON_KEY     : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo

SERVICE_ROLE_KEY : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NzQzMTI3MDMsImV4cCI6MjA4OTY3MjcwM30.fkgpC_9j1hOBrw8KJu7trypWcSIm3ofuNqud-ynBn5U
```

> Nếu chạy trên server khác, thay `localhost` bằng IP hoặc domain của server đó.

---

## 2. STUDIO — GIAO DIỆN QUẢN TRỊ

Truy cập: **http://localhost:8000**

Đăng nhập:
- Username: `admin`
- Password: `0hDXhzuTsVjDzHMH`

### Các tính năng chính trong Studio:

**Table Editor** — Xem, thêm, sửa, xóa dữ liệu trực tiếp như một spreadsheet.

**SQL Editor** — Chạy câu lệnh SQL tùy ý. Ví dụ:
```sql
CREATE TABLE products (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text NOT NULL,
  price numeric,
  created_at timestamptz DEFAULT now()
);
```

**Authentication** — Quản lý user, xem danh sách tài khoản đã đăng ký, cấu hình providers (Google, GitHub...).

**Storage** — Upload/download file, tạo bucket, quản lý quyền truy cập file.

**Edge Functions** — Deploy và quản lý serverless functions.

**Logs** — Xem log realtime của tất cả service.

**Settings → API** — Lấy `anon key`, `service role key`, URL API.

---

## 3. CÁC ENDPOINT API

Tất cả đều đi qua Kong API Gateway tại port `8000`.

| Endpoint | Mô tả |
|----------|-------|
| `http://localhost:8000/rest/v1/` | REST API (PostgREST) |
| `http://localhost:8000/auth/v1/` | Authentication API |
| `http://localhost:8000/storage/v1/` | Storage API |
| `http://localhost:8000/realtime/v1/` | Realtime WebSocket |
| `http://localhost:8000/functions/v1/` | Edge Functions |

---

## 4. KẾT NỐI TỪ ỨNG DỤNG — SUPABASE CLIENT

### 4.1 JavaScript / TypeScript

Cài thư viện:
```bash
npm install @supabase/supabase-js
```

Khởi tạo client:
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo'
)
```

Ví dụ query:
```typescript
// Lấy dữ liệu
const { data, error } = await supabase
  .from('products')
  .select('*')

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
```

### 4.2 Python

Cài thư viện:
```bash
pip install supabase
```

Khởi tạo client:
```python
from supabase import create_client

supabase = create_client(
    'http://localhost:8000',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo'
)

# Lấy dữ liệu
response = supabase.table('products').select('*').execute()
print(response.data)

# Thêm dữ liệu
response = supabase.table('products').insert({'name': 'Sản phẩm A', 'price': 99000}).execute()
```

### 4.3 Dart / Flutter

Cài thư viện (pubspec.yaml):
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

Khởi tạo:
```dart
await Supabase.initialize(
  url: 'http://localhost:8000',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);

final supabase = Supabase.instance.client;

// Query
final data = await supabase.from('products').select();
```

---

## 5. GỌI API TRỰC TIẾP BẰNG HTTP (không dùng SDK)

Dùng được với bất kỳ ngôn ngữ nào có HTTP client (curl, Postman, Axios...).

### Header bắt buộc:
```
apikey: <ANON_KEY hoặc SERVICE_ROLE_KEY>
Authorization: Bearer <ANON_KEY hoặc SERVICE_ROLE_KEY>
Content-Type: application/json
```

### Ví dụ với curl:

**Lấy dữ liệu từ bảng `products`:**
```bash
curl http://localhost:8000/rest/v1/products \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc0MzEyNzAzLCJleHAiOjIwODk2NzI3MDN9.yPs_SqolffT1kGbM27BwL6SiXBCTF1EB6qs0krBDhdo"
```

**Thêm dữ liệu:**
```bash
curl -X POST http://localhost:8000/rest/v1/products \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"name": "Sản phẩm A", "price": 99000}'
```

**Đăng ký user:**
```bash
curl -X POST http://localhost:8000/auth/v1/signup \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

**Đăng nhập:**
```bash
curl -X POST http://localhost:8000/auth/v1/token?grant_type=password \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password123"}'
```

---

## 6. KẾT NỐI POSTGRESQL TRỰC TIẾP

Dùng khi cần chạy migration, dùng ORM (Prisma, SQLAlchemy, GORM...), hoặc tool như DBeaver, TablePlus.

### Connection string:

**Session mode** (dùng cho migration, long-running queries):
```
postgresql://postgres:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:5432/postgres
```

**Transaction mode** (dùng cho app, connection pooling):
```
postgresql://postgres.your-tenant-id:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:6543/postgres
```

> `your-tenant-id` = giá trị `POOLER_TENANT_ID` trong `.env` (mặc định là `your-tenant-id`)

### Kết nối bằng psql:
```bash
psql postgresql://postgres:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:5432/postgres
```

### Kết nối bằng Prisma (Node.js):
```env
# .env
DATABASE_URL="postgresql://postgres:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:5432/postgres"
DIRECT_URL="postgresql://postgres:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:5432/postgres"
```

### Kết nối bằng SQLAlchemy (Python):
```python
DATABASE_URL = "postgresql://postgres:53b00a7e903714a9d13de093fbcaa4bc3c3efe79d7610b06@localhost:5432/postgres"
```

---

## 7. PHÂN BIỆT ANON KEY vs SERVICE ROLE KEY

| | ANON KEY | SERVICE ROLE KEY |
|---|---|---|
| Dùng ở đâu | Client (browser, mobile app) | Server (backend, scripts) |
| Quyền hạn | Bị giới hạn bởi Row Level Security (RLS) | Bypass toàn bộ RLS, quyền admin |
| Có thể public không | Được (nhúng vào frontend) | **KHÔNG** — chỉ dùng server-side |
| Ví dụ dùng | Đăng nhập, đọc data public | Tạo user, xóa data, admin tasks |

---

## 8. ROW LEVEL SECURITY (RLS) — BẢO MẬT DỮ LIỆU

Mặc định khi tạo bảng mới, **RLS bị tắt** — mọi người đều đọc/ghi được.  
Cần bật RLS và tạo policy để kiểm soát quyền truy cập.

**Bật RLS cho bảng:**
```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
```

**Tạo policy cho phép user đọc data của chính họ:**
```sql
CREATE POLICY "Users can read own data"
ON products FOR SELECT
USING (auth.uid() = user_id);
```

**Cho phép tất cả đọc (public read):**
```sql
CREATE POLICY "Public read"
ON products FOR SELECT
USING (true);
```

---

## 9. REALTIME — LẮNG NGHE THAY ĐỔI DỮ LIỆU

Supabase Realtime cho phép subscribe vào thay đổi của bảng theo thời gian thực qua WebSocket.

```typescript
// Subscribe vào bảng products
const channel = supabase
  .channel('products-changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'products' },
    (payload) => {
      console.log('Có thay đổi:', payload)
    }
  )
  .subscribe()

// Hủy subscribe
supabase.removeChannel(channel)
```

---

## 10. STORAGE — LƯU TRỮ FILE

**Tạo bucket trong Studio:** Storage → New bucket → đặt tên → chọn public/private.

**Upload file bằng SDK:**
```typescript
const { data, error } = await supabase.storage
  .from('avatars')
  .upload('user123/avatar.png', file)

// Lấy public URL
const { data } = supabase.storage
  .from('avatars')
  .getPublicUrl('user123/avatar.png')

console.log(data.publicUrl)
// http://localhost:8000/storage/v1/object/public/avatars/user123/avatar.png
```

---

## 11. CHẠY TRÊN SERVER KHÁC (không phải localhost)

Khi deploy lên server thật (VPS, cloud...), cần đổi các URL trong `.env`:

```env
SUPABASE_PUBLIC_URL=http://<IP_SERVER>:8000
API_EXTERNAL_URL=http://<IP_SERVER>:8000
SITE_URL=http://<IP_SERVER>:3000
```

Sau đó restart:
```bash
docker compose down && docker compose up -d
```

Ứng dụng kết nối dùng:
```typescript
const supabase = createClient(
  'http://<IP_SERVER>:8000',
  '<ANON_KEY>'
)
```

---

## 12. LỆNH QUẢN LÝ THƯỜNG DÙNG

```bash
# Khởi động
docker compose up -d

# Dừng (giữ data)
docker compose down

# Xem trạng thái
docker compose ps

# Xem log realtime
docker compose logs -f

# Xem log một service cụ thể
docker compose logs -f auth
docker compose logs -f db
docker compose logs -f kong

# Restart một service
docker compose restart auth

# Vào trong container DB chạy SQL
docker compose exec db psql -U postgres
```

---

## 13. SƠ ĐỒ LUỒNG REQUEST

```
Ứng dụng / Browser
        │
        │  HTTP :8000
        ▼
  Kong API Gateway  ──── xác thực apikey / JWT
        │
        ├──── /rest/v1/     ──► PostgREST  ──► PostgreSQL
        ├──── /auth/v1/     ──► GoTrue (Auth)
        ├──── /storage/v1/  ──► Storage API ──► ./volumes/storage/
        ├──── /realtime/v1/ ──► Realtime (WebSocket)
        └──── /functions/v1/──► Edge Runtime (Deno)
```

Tất cả request đều đi qua **Kong** ở port `8000`. Kong kiểm tra `apikey` header, nếu hợp lệ thì forward đến service tương ứng.
