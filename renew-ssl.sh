#!/bin/bash

# Thử gia hạn chứng chỉ
docker compose run --rm certbot renew

# Nếu gia hạn thành công, reload NGINX để áp dụng chứng chỉ mới
if [ $? -eq 0 ]; then
    docker compose -f ../docker-compose.yml exec nginx nginx -s reload
fi