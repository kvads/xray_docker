#!/bin/bash

# Загружаем переменные окружения
source .env

# Функция для добавления TXT-записи
add_txt_record() {
    local domain=$1
    local value=$2
    
    echo "Добавьте следующую TXT-запись в DNS-настройки вашего домена:"
    echo "Имя: _acme-challenge.${domain}"
    echo "Тип: TXT"
    echo "Значение: ${value}"
    echo "TTL: 60"
    
    read -p "После добавления записи нажмите Enter для продолжения..."
}

# Функция для проверки TXT-записи
check_txt_record() {
    local domain=$1
    local value=$2
    
    echo "Проверка TXT-записи..."
    dig TXT _acme-challenge.${domain} +short
    
    read -p "Запись добавлена? (y/n): " answer
    if [ "$answer" != "y" ]; then
        echo "Пожалуйста, добавьте запись и повторите проверку"
        return 1
    fi
    return 0
}

# Основной процесс
echo "Начинаем процесс DNS-валидации для домена ${DOMAIN}"

# Запрашиваем значение для TXT-записи
read -p "Введите значение для TXT-записи (из логов letsencrypt-companion): " txt_value

# Добавляем TXT-запись для основного домена
add_txt_record "${DOMAIN}" "${txt_value}"
check_txt_record "${DOMAIN}" "${txt_value}" || exit 1

# Добавляем TXT-запись для админ-поддомена
add_txt_record "${ADMIN_DOMAIN}" "${txt_value}"
check_txt_record "${ADMIN_DOMAIN}" "${txt_value}" || exit 1

echo "DNS-валидация завершена успешно" 