#!/bin/bash

echo "Testing Xray connection..."

# Проверка порта
echo "1. Checking if port 443 is listening..."
netstat -tulpn | grep ":443"

# Проверка логов
echo -e "\n2. Recent Xray logs:"
docker compose logs --tail=20 xray

# Проверка TLS
echo -e "\n3. Testing TLS connection..."
openssl s_client -connect localhost:443 -servername github.com

# Проверка DNS
echo -e "\n4. DNS resolution for xraykvads.online:"
dig xraykvads.online +short

# Проверка маршрутизации
echo -e "\n5. Network routing:"
traceroute xraykvads.online 