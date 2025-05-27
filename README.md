# Xray Docker Setup

Этот репозиторий содержит Docker-based настройку Xray с автоматическим управлением SSL-сертификатами и панелью управления пользователями.

## Возможности

- Поддержка нескольких протоколов:
  - VLESS + XTLS Vision (основной протокол)
  - WebSocket + TLS (для обхода блокировок)
  - gRPC (эффективный транспорт)
- Автоматическое управление SSL-сертификатами через Let's Encrypt
- Панель управления пользователями
- SQLite база данных для хранения пользователей
- Nginx proxy для SSL-терминации

## Требования

- Docker и Docker Compose
- Домен, указывающий на ваш сервер
- Открытые порты: 8081, 8444, 8443, 8080, 2087, 3000

## Быстрый старт

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd xray-docker
```

2. Запустите скрипт установки:
```bash
chmod +x setup.sh
./setup.sh
```

Скрипт попросит ввести:
- Домен (например, example.com)
- Email для Let's Encrypt
- Порты для различных протоколов (можно оставить по умолчанию)

3. После успешной установки, админ-панель будет доступна по адресу:
```
https://admin.your-domain.com:8444
```

## Используемые порты
- 8081:80 - HTTP (внутренний порт nginx)
- 8444:443 - HTTPS (внутренний порт nginx)
- 8443 - VLESS + XTLS
- 8080 - WebSocket
- 2087 - gRPC
- 3000 - Admin Panel

## Проверка статуса
```bash
# Проверка логов
docker-compose logs -f

# Проверка статуса контейнеров
docker-compose ps
```

## Устранение неполадок

### Проверка занятых портов
```bash
sudo lsof -i :443
sudo lsof -i :80
```

### Проверка SSL сертификатов
```bash
ls -la nginx-proxy/ssl/${DOMAIN}/
```

### Проверка логов
```bash
# Логи nginx-proxy
docker-compose logs nginx-proxy

# Логи letsencrypt-companion
docker-compose logs letsencrypt-companion

# Логи xray
docker-compose logs xray

# Логи admin-panel
docker-compose logs admin-panel
```

## Структура проекта
```
.
├── admin-panel/
│   └── data/           # База данных админ-панели
├── nginx-proxy/
│   └── ssl/           # SSL сертификаты
├── xray/
│   ├── config/        # Конфигурация Xray
│   └── logs/          # Логи Xray
├── .env               # Переменные окружения
├── docker-compose.yml # Конфигурация Docker Compose
└── setup.sh           # Скрипт установки
```

## Обновление

```bash
# Остановка сервисов
docker-compose down

# Получение обновлений
git pull

# Перезапуск с новыми настройками
docker-compose up -d
```

## Резервное копирование

```bash
# Создание бэкапа
tar -czf xray-backup-$(date +%Y%m%d).tar.gz \
    xray/data \
    nginx-proxy/ssl \
    admin-panel/data

# Восстановление из бэкапа
tar -xzf xray-backup-YYYYMMDD.tar.gz
```

## Безопасность

- Все соединения шифруются с помощью TLS
- ID пользователей генерируются как UUID
- Включено ограничение скорости
- Регулярные обновления безопасности

## Поддержка

При возникновении проблем:
1. Проверьте логи
2. Убедитесь, что все порты открыты
3. Проверьте DNS-записи
4. Проверьте SSL-сертификаты

## Лицензия

MIT