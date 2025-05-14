# Hướng dẫn Chuyển từ Nginx Docker sang Nginx Host

## 1. Cài đặt Nginx trên Windows

1. Tải Nginx cho Windows từ trang chính thức: https://nginx.org/en/download.html
2. Giải nén vào thư mục (ví dụ: `C:\nginx`)
3. Thêm đường dẫn Nginx vào biến môi trường PATH

## 2. Chuẩn bị thư mục và file cấu hình

1. Tạo cấu trúc thư mục cho SSL:

```bash
C:\nginx\ssl\live\layso.phuongchau.com\
```

2. Copy các file chứng chỉ SSL từ thư mục `certificate` vào thư mục trên:

- fullchain.pem
- privkey.pem
- chain.pem

3. Copy file `nginx.conf` hiện tại vào `C:\nginx\conf\nginx.conf` với các điều chỉnh sau:

- Thay đổi đường dẫn SSL:

```nginx
ssl_certificate C:/nginx/ssl/live/layso.phuongchau.com/fullchain.pem;
ssl_certificate_key C:/nginx/ssl/live/layso.phuongchau.com/privkey.pem;
ssl_trusted_certificate C:/nginx/ssl/live/layso.phuongchau.com/chain.pem;
```

- Điều chỉnh proxy_pass để trỏ đến container:

```nginx
proxy_pass http://localhost:3000/;  # cho Next.js frontend
proxy_pass http://localhost:4000;    # cho API backend
```

## 3. Cập nhật Docker Compose

1. Xóa service nginx trong `docker-compose.yml`
2. Expose ports cho các service còn lại:

```yaml
services:
  ui-web:
    ports:
      - "3000:3000"
  app:
    ports:
      - "4000:4000"
```

## 4. Khởi động dịch vụ

1. Dừng và xóa container Nginx:

```bash
docker compose down
```

2. Khởi động Nginx trên Windows:

```bash
cd C:\nginx
start nginx
```

3. Khởi động lại các container:

```bash
docker compose up -d
```

## 5. Quản lý Nginx

- Kiểm tra cấu hình:

```bash
nginx -t
```

- Reload cấu hình:

```bash
nginx -s reload
```

- Dừng Nginx:

```bash
nginx -s stop
```

## 6. Xử lý sự cố

1. Kiểm tra logs:

- Error logs: `C:\nginx\logs\error.log`
- Access logs: `C:\nginx\logs\access.log`

2. Đảm bảo ports 80 và 443 không bị sử dụng bởi ứng dụng khác
3. Kiểm tra kết nối đến các container thông qua localhost
4. Xác nhận quyền truy cập vào các file chứng chỉ SSL

## Lưu ý

- Đảm bảo Nginx được chạy với quyền Administrator
- Cập nhật Windows Firewall để cho phép kết nối qua ports 80 và 443
- Backup các file cấu hình và chứng chỉ SSL trước khi thực hiện chuyển đổi
