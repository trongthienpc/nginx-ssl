# Hướng dẫn triển khai Nginx trên Ubuntu host cho ứng dụng Phương Châu

## Giới thiệu

Tài liệu này hướng dẫn cách triển khai Nginx trực tiếp trên máy host Ubuntu để phục vụ ứng dụng Phương Châu, thay vì chạy Nginx trong Docker.

## Yêu cầu hệ thống

- Máy chủ Ubuntu (20.04 hoặc mới hơn)
- Quyền sudo
- Các file chứng chỉ SSL đã có sẵn:
  - fullchain.pem
  - privkey.pem
  - chain.pem
- Các dịch vụ backend và frontend đang chạy (có thể trong Docker hoặc trực tiếp trên host)

## Các bước triển khai

### 1. Cài đặt Nginx

```bash
sudo apt update
sudo apt install nginx
```

### 2. Tạo thư mục chứa chứng chỉ SSL

```bash
sudo mkdir -p /etc/nginx/ssl/live/layso.phuongchau.com
```

### 3. Sao chép các file chứng chỉ SSL

```bash
sudo cp /đường/dẫn/đến/fullchain.pem /etc/nginx/ssl/live/layso.phuongchau.com/
sudo cp /đường/dẫn/đến/privkey.pem /etc/nginx/ssl/live/layso.phuongchau.com/
sudo cp /đường/dẫn/đến/chain.pem /etc/nginx/ssl/live/layso.phuongchau.com/
```

### 4. Cấu hình quyền truy cập cho file chứng chỉ

```bash
sudo chmod -R 755 /etc/nginx/ssl/
sudo chmod -R 644 /etc/nginx/ssl/live/layso.phuongchau.com/*.pem
sudo chown -R www-data:www-data /etc/nginx/ssl/live/layso.phuongchau.com/
```

### 5. Tạo cấu hình site cho ứng dụng

```bash
sudo nano /etc/nginx/sites-available/layso.phuongchau.com
```

Sao chép nội dung sau vào file (thay đổi các địa chỉ IP và cổng tương ứng với hệ thống của bạn):

```nginx
server {
    listen 80;
    server_name layso.phuongchau.com;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name layso.phuongchau.com;

    ssl_certificate /etc/nginx/ssl/live/layso.phuongchau.com/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/layso.phuongchau.com/privkey.pem;
    ssl_trusted_certificate /etc/nginx/ssl/live/layso.phuongchau.com/chain.pem;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Proxy đến Frontend (Next.js)
    location / {
        # Thay IP:PORT với địa chỉ thực của frontend
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Proxy Buffer Settings
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;
    }

    # Proxy đến Backend API
    location /api/ {
        # Thay IP:PORT với địa chỉ thực của backend
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Proxy Buffer Settings
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
        proxy_temp_file_write_size 256k;
    }

    # Cấu hình WebSocket cho Socket.IO
    location /socket.io/ {
        # Thay IP:PORT với địa chỉ thực của backend
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 6. Kích hoạt cấu hình site

```bash
sudo ln -s /etc/nginx/sites-available/layso.phuongchau.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default # Xóa site mặc định (tùy chọn)
```

### 7. Tùy chỉnh file cấu hình Nginx chính (tùy chọn)

Nếu bạn muốn tùy chỉnh file cấu hình Nginx chính:

```bash
sudo nano /etc/nginx/nginx.conf
```

Đây là một cấu hình mẫu bạn có thể tham khảo:

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Buffer Size
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;

    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Logging Settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Bao gồm các file cấu hình site
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### 8. Kiểm tra cấu hình và khởi động lại Nginx

```bash
sudo nginx -t # Kiểm tra cấu hình
sudo systemctl restart nginx # Khởi động lại Nginx
```

### 9. Cấu hình tường lửa (nếu có)

```bash
sudo ufw allow 'Nginx Full' # Cho phép truy cập cổng HTTP (80) và HTTPS (443)
```

## Cấu hình cho các dịch vụ Docker (nếu sử dụng)

Nếu frontend và backend vẫn chạy trong Docker, đảm bảo chúng đã được cấu hình đúng:

### Truy cập từ host đến container Docker

Nếu các dịch vụ đang chạy trong Docker, chỉnh sửa các dòng proxy_pass trong cấu hình Nginx để trỏ đến các container:

```nginx
# Ví dụ nếu frontend chạy trong Docker với port mapping 3000:3000
proxy_pass http://localhost:3000/;

# Ví dụ nếu backend chạy trong Docker với port mapping 4000:4000
proxy_pass http://localhost:4000;
```

Nếu sử dụng Docker network, bạn có thể cần thay đổi địa chỉ thành tên container hoặc service trong mạng:

```nginx
# Sử dụng tên container hoặc service (chỉ hoạt động nếu Nginx trên cùng mạng Docker)
proxy_pass http://hospital-queue-management-system-ui-web-1:3000/;
proxy_pass http://hospital-queue-management-system-app-1:4000;
```

## Cấu hình biến môi trường cho Frontend

Đảm bảo biến môi trường NEXT_PUBLIC_SOCKET_URL được đặt chính xác trong cấu hình Frontend:

```
NEXT_PUBLIC_SOCKET_URL=https://layso.phuongchau.com
```

## Xử lý sự cố

### Kiểm tra log của Nginx

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Kiểm tra trạng thái Nginx

```bash
sudo systemctl status nginx
```

### Kiểm tra kết nối mạng

```bash
sudo netstat -tulpn | grep nginx
```

### Kiểm tra quyền truy cập SSL

```bash
sudo ls -la /etc/nginx/ssl/live/layso.phuongchau.com/
```

## Cập nhật chứng chỉ SSL

Nếu bạn cần cập nhật chứng chỉ SSL trong tương lai:

```bash
sudo cp /đường/dẫn/đến/chứng-chỉ-mới/*.pem /etc/nginx/ssl/live/layso.phuongchau.com/
sudo systemctl reload nginx
```

## Kết luận

Sau khi hoàn thành các bước trên, ứng dụng của bạn sẽ chạy với Nginx trên máy host Ubuntu thay vì trong Docker. Cấu hình này bao gồm đầy đủ hỗ trợ cho API và WebSocket (Socket.IO).
