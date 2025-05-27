#!/bin/bash

echo "Testing Xray connection..."

# Проверка порта
echo "1. Checking if port 443 is listening..."
docker compose exec xray netstat -tulpn | grep ":443"

# Проверка логов
echo -e "\n2. Recent Xray logs:"
docker compose logs --tail=20 xray

# Проверка TLS
echo -e "\n3. Testing TLS connection..."
docker compose exec xray curl -v --connect-to github.com:443:localhost:443 https://github.com

# Проверка DNS
echo -e "\n4. DNS resolution for xraykvads.online:"
dig xraykvads.online +short

# Проверка маршрутизации
echo -e "\n5. Network routing:"
traceroute xraykvads.online

# Проверка Reality
echo -e "\n6. Testing Reality connection..."
docker compose exec xray curl -v --connect-to github.com:443:localhost:443 \
  -H "Host: github.com" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
  -H "Accept-Language: en-US,en;q=0.9" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -H "Upgrade-Insecure-Requests: 1" \
  -H "Sec-Fetch-Dest: document" \
  -H "Sec-Fetch-Mode: navigate" \
  -H "Sec-Fetch-Site: none" \
  -H "Sec-Fetch-User: ?1" \
  https://github.com 