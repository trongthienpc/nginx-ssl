# Nginx SSL Proxy Configuration

Cấu hình Nginx Proxy với SSL cho hệ thống quản lý hàng đợi bệnh viện.

## Tính năng

- Proxy ngược cho ứng dụng Next.js và API
- Hỗ trợ SSL/TLS với Let's Encrypt
- Tối ưu hiệu suất với proxy buffer và gzip compression
- Cấu hình bảo mật với các header HTTP security
- Tự động chuyển hướng HTTP sang HTTPS

## Yêu cầu

- Docker và Docker Compose
- Domain đã được cấu hình DNS trỏ về server
- Chứng chỉ SSL từ Let's Encrypt

## Cấu trúc thư mục

```
.
├── docker-compose.yml    # Cấu hình Docker Compose
├── nginx.conf           # Cấu hình Nginx
├── renew-ssl.sh         # Script gia hạn chứng chỉ SSL
└── certificate/         # Thư mục chứa chứng chỉ SSL
```

## Cài đặt

1. Clone repository:

```bash
git clone <repository-url>
cd nginx-ssl
```

2. Đặt chứng chỉ SSL vào thư mục `certificate/`:

- `fullchain.pem`
- `privkey.pem`
- `chain.pem`

3. Khởi động container:

```bash
docker compose up -d
```

## Cấu hình

### SSL/TLS

- Sử dụng TLS 1.2 và 1.3
- Tối ưu cipher suites
- OCSP Stapling được bật
- Strict Transport Security (HSTS)

### Proxy Buffer

- Client body buffer: 10K
- Client header buffer: 1K
- Client max body size: 8M
- Proxy buffer size: 128K

### Gzip Compression

- Nén các loại file phổ biến (text, CSS, JS, JSON)
- Mức độ nén: 6
- Kích thước buffer: 16 8k

### Security Headers

- HSTS
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection

## Gia hạn chứng chỉ SSL

Chạy script `renew-ssl.sh` để gia hạn chứng chỉ SSL:

```bash
./renew-ssl.sh
```

## Kiểm tra trạng thái

Kiểm tra container đang chạy:

```bash
docker compose ps
```

Xem logs của Nginx:

```bash
docker compose logs nginx
```

## Bảo trì

1. Khởi động lại Nginx:

```bash
docker compose restart nginx
```

2. Reload cấu hình Nginx:

```bash
docker compose exec nginx nginx -s reload
```

## Lưu ý bảo mật

- Luôn giữ các container và image được cập nhật
- Kiểm tra định kỳ các log để phát hiện vấn đề
- Đảm bảo quyền truy cập thư mục chứng chỉ SSL được cấu hình đúng
- Thường xuyên cập nhật các security headers theo khuyến nghị mới nhất
