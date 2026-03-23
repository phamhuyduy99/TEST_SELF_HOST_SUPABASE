# SUPABASE SELF-HOST PORTABLE
Bộ script tự động cài đặt và chạy Supabase self-host trên mọi hệ điều hành có Docker.

---

## YÊU CẦU (trên mọi máy)
- Docker Desktop (Windows/macOS) hoặc Docker Engine (Linux)
- Git (chỉ cần khi chạy setup lần đầu)

---

## CÁCH DÙNG TRÊN WINDOWS (CMD hoặc nhấp đúp)

### Lần đầu tiên (setup):
```
Nhấp đúp vào: setup.bat
```
Script sẽ tự động:
1. Clone Supabase từ GitHub
2. Sinh tất cả khóa bảo mật ngẫu nhiên
3. Cấu hình file .env
4. Khởi động toàn bộ hệ thống

### Sau khi setup xong:
1. Mở trình duyệt vào: **http://localhost:8000**
2. Đăng nhập bằng thông tin trong file `credentials.txt`
3. Vào **Settings → API**, copy **Anon Key** và **Service Role Key**
4. Nhấp đúp vào `update-keys.bat`, dán 2 key vào
5. Xong! Supabase đã sẵn sàng dùng.

### Các lần sau:
| Tác vụ | File |
|--------|------|
| Khởi động | `start.bat` |
| Dừng | `stop.bat` |
| Xem trạng thái | `status.bat` |
| Đóng gói mang đi | `pack.bat` |

---

## CÁCH DÙNG TRÊN LINUX / MACOS / GIT BASH

```bash
# Cấp quyền thực thi (chỉ cần 1 lần)
chmod +x setup.sh update-keys.sh

# Chạy setup
./setup.sh

# Sau khi lấy key từ Studio
./update-keys.sh
```

Khởi động/dừng thủ công:
```bash
cd supabase-config
docker compose up -d    # khởi động
docker compose down     # dừng
docker compose ps       # xem trạng thái
```

---

## MANG SANG MÁY KHÁC

### Trên Windows:
```
Nhấp đúp vào: pack.bat
```
Sẽ tạo file `supabase-portable.zip`. Copy file này sang máy đích.

Trên máy đích:
1. Giải nén file zip
2. Vào thư mục `supabase-config`
3. Chạy: `docker compose up -d`
4. Truy cập: http://localhost:8000

### Trên Linux/macOS:
```bash
tar -czf supabase-portable.tar.gz supabase-config/
# Giải nén trên máy đích:
tar -xzf supabase-portable.tar.gz
cd supabase-config && docker compose up -d
```

---

## CÁC PORT MẶC ĐỊNH
| Service | Port |
|---------|------|
| Studio (giao diện) | 8000 |
| PostgreSQL | 5432 |
| Kong API Gateway | 8000 |

Nếu port 8000 bị chiếm, sửa trong `supabase-config/docker-compose.yml`:
```yaml
services:
  kong:
    ports:
      - "9000:8000"   # đổi 9000 thành port muốn dùng
```

---

## XỬ LÝ SỰ CỐ
```bash
# Xem log của một service cụ thể
docker compose logs db
docker compose logs auth
docker compose logs kong

# Xem log tất cả
docker compose logs -f

# Khởi động lại một service
docker compose restart auth
```

---

## CẤU TRÚC THƯ MỤC
```
SUPABASE/
├── setup.bat          ← Chạy lần đầu (Windows CMD)
├── setup.sh           ← Chạy lần đầu (Linux/macOS/Git Bash)
├── start.bat          ← Khởi động (Windows)
├── stop.bat           ← Dừng (Windows)
├── status.bat         ← Xem trạng thái (Windows)
├── update-keys.bat    ← Cập nhật API keys (Windows)
├── update-keys.sh     ← Cập nhật API keys (Linux/macOS)
├── pack.bat           ← Đóng gói mang đi (Windows)
├── credentials.txt    ← Thông tin đăng nhập (tự sinh sau setup)
├── README.md          ← File này
└── supabase-config/   ← Thư mục cấu hình (tự tạo sau setup)
    ├── docker-compose.yml
    ├── .env
    └── volumes/
```
