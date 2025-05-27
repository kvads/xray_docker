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

# Функция для извлечения значений из логов
extract_challenge_values() {
    echo "Извлекаем значения для TXT-записей из логов..."
    
    # Получаем последние логи
    local logs=$(docker-compose logs --tail=100 letsencrypt-companion)
    
    # Извлекаем значения для основного домена
    local main_domain_value=$(echo "$logs" | grep -A 1 "Verifying: ${DOMAIN}" | grep "acme-challenge" | awk -F'acme-challenge/' '{print $2}' | awk '{print $1}')
    
    # Извлекаем значения для админ-домена
    local admin_domain_value=$(echo "$logs" | grep -A 1 "Verifying: ${ADMIN_DOMAIN}" | grep "acme-challenge" | awk -F'acme-challenge/' '{print $2}' | awk '{print $1}')
    
    if [ -z "$main_domain_value" ] || [ -z "$admin_domain_value" ]; then
        echo "Не удалось найти значения в логах. Пожалуйста, введите их вручную:"
        read -p "Значение для ${DOMAIN}: " main_domain_value
        read -p "Значение для ${ADMIN_DOMAIN}: " admin_domain_value
    fi
    
    echo "Найдены значения:"
    echo "${DOMAIN}: ${main_domain_value}"
    echo "${ADMIN_DOMAIN}: ${admin_domain_value}"
    
    # Добавляем TXT-записи
    add_txt_record "${DOMAIN}" "${main_domain_value}"
    check_txt_record "${DOMAIN}" "${main_domain_value}" || exit 1
    
    add_txt_record "${ADMIN_DOMAIN}" "${admin_domain_value}"
    check_txt_record "${ADMIN_DOMAIN}" "${admin_domain_value}" || exit 1
}

# Основной процесс
echo "Начинаем процесс DNS-валидации для доменов ${DOMAIN} и ${ADMIN_DOMAIN}"

# Извлекаем значения и добавляем записи
extract_challenge_values

echo "DNS-валидация завершена успешно"
echo "Подождите несколько минут, пока Let's Encrypt проверит записи и выдаст сертификаты" 