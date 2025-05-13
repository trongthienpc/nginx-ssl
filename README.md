# Hướng dẫn Cài đặt NGINX với SSL (Let's Encrypt)

## Mục lục

- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Các bước thực hiện](#các-bước-thực-hiện)
- [Cấu hình Crontab](#cấu-hình-crontab)
- [Xử lý sự cố](#xử-lý-sự-cố)

## Yêu cầu hệ thống

- Docker và Docker Compose đã được cài đặt
- Domain đã trỏ về IP server
- Port 80 và 443 đã được mở

## Cấu trúc thư mục

```
nginx-ssl/
├── data/
│   ├── certbot/     # Chứa chứng chỉ SSL
│   ├── varlib/      # Dữ liệu Let's Encrypt
│   └── www/         # Web root cho xác thực domain
├── docker-compose.yml           # File cấu hình Docker chính
├── docker-compose-cert.yml      # File cấu hình cho việc lấy chứng chỉ
├── nginx.conf                   # File cấu hình NGINX
└── renew-ssl.sh                # Script gia hạn SSL
```

## Các bước thực hiện

### 1. Tạo cấu trúc thư mục

```bash
mkdir -p data/{certbot,varlib,www}
```

### 2. Khởi tạo NGINX

```bash
docker compose up -d
```

### 3. Lấy chứng chỉ SSL

Thay đổi domain và email trong file `docker-compose-cert.yml` theo nhu cầu, sau đó chạy:

```bash
docker compose -f docker-compose-cert.yml run --rm certbot
```

### 4. Kiểm tra cài đặt

- Truy cập website qua HTTPS
- Kiểm tra chứng chỉ SSL trong trình duyệt

## Cấu hình Crontab

### 1. Cấp quyền thực thi cho script gia hạn

```bash
chmod +x renew-ssl.sh
```

### 2. Mở crontab editor

```bash
crontab -e
```

### 3. Thêm lệnh tự động gia hạn (chạy vào 3:00 AM mỗi ngày)

```bash
0 3 * * * /path/to/nginx-ssl/renew-ssl.sh >> /path/to/nginx-ssl/renew.log 2>&1
```

## Xử lý sự cố

### Lỗi khi gia hạn SSL

1. Kiểm tra log:

```bash
cat renew.log
```

2. Đảm bảo NGINX đang chạy:

```bash
docker compose ps
```

3. Kiểm tra cấu hình NGINX:

```bash
docker compose exec nginx nginx -t
```

### Lỗi kết nối HTTPS

1. Kiểm tra file cấu hình nginx.conf
2. Đảm bảo các file chứng chỉ tồn tại trong thư mục data/certbot
3. Kiểm tra quyền truy cập các file chứng chỉ

### Lưu ý quan trọng

- Luôn backup thư mục data/certbot trước khi thực hiện các thay đổi lớn
- Theo dõi log gia hạn SSL định kỳ
- Đảm bảo đủ dung lượng ổ đĩa cho việc lưu trữ log và chứng chỉ
