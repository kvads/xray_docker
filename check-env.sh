#!/bin/bash

# Функция для проверки переменной
check_var() {
    if [ -z "${!1}" ]; then
        echo "Error: $1 is not set in .env file"
        exit 1
    fi
}

# Проверяем наличие .env файла
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Загружаем переменные из .env
set -a
source .env
set +a

# Проверяем обязательные переменные
check_var "DOMAIN"
check_var "ADMIN_DOMAIN"
check_var "LETSENCRYPT_EMAIL"
check_var "XRAY_VLESS_PORT"
check_var "XRAY_WS_PORT"
check_var "XRAY_GRPC_PORT"
check_var "ADMIN_PANEL_PORT"

# Проверяем валидность email
if ! [[ "$LETSENCRYPT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Error: LETSENCRYPT_EMAIL is not a valid email address"
    exit 1
fi

# Проверяем валидность портов
for port in XRAY_VLESS_PORT XRAY_WS_PORT XRAY_GRPC_PORT ADMIN_PANEL_PORT; do
    if ! [[ "${!port}" =~ ^[0-9]+$ ]] || [ "${!port}" -lt 1 ] || [ "${!port}" -gt 65535 ]; then
        echo "Error: $port must be a number between 1 and 65535"
        exit 1
    fi
done

echo "All environment variables are properly set"
exit 0 