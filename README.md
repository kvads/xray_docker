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
- Домен или поддомен, указывающий на ваш сервер
- Открытые порты 80 и 443 на сервере
- Доступ к серверу по SSH

## Установка

1. **Подготовка сервера:**
   ```bash
   # Обновление системы
   sudo apt update && sudo apt upgrade -y
   
   # Установка Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Установка Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Клонирование репозитория:**
   ```bash
   git clone <repository-url>
   cd xray-docker
   ```

3. **Запуск установки:**
   ```bash
   # Делаем скрипт установки исполняемым
   chmod +x setup.sh
   
   # Запускаем установку
   ./setup.sh
   ```

   Скрипт попросит ввести:
   - Домен (например, example.com)
   - Email для Let's Encrypt
   - Порты для различных протоколов (можно оставить по умолчанию)

4. **Проверка установки:**
   ```bash
   # Проверка статуса контейнеров
   docker-compose ps
   
   # Просмотр логов
   docker-compose logs -f
   ```

## Использование

### Панель управления

1. Доступ к панели управления: `https://admin.your-domain.com`
2. API endpoints:
   - `POST /api/users` - Добавить нового пользователя
   - `GET /api/users` - Список всех пользователей
   - `DELETE /api/users/:id` - Удалить пользователя

### Конфигурация клиентов

Система поддерживает несколько протоколов:

1. **VLESS + XTLS Vision** (Порт 8443)
   - Самый быстрый и современный протокол
   - Рекомендуется для большинства случаев

2. **WebSocket + TLS** (Порт 8080)
   - Хорошо работает через прокси
   - Подходит для обхода блокировок

3. **gRPC** (Порт 2087)
   - Эффективный транспорт
   - Подходит для streaming данных

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

## Устранение неполадок

1. **Проверка логов:**
   ```bash
   # Все сервисы
   docker-compose logs -f
   
   # Конкретный сервис
   docker-compose logs -f xray
   docker-compose logs -f nginx-proxy
   ```

2. **Проверка SSL-сертификатов:**
   ```bash
   docker-compose exec letsencrypt-companion ls -la /etc/nginx/ssl
   ```

3. **Проверка конфигурации Xray:**
   ```bash
   docker-compose exec xray cat /etc/xray/config.json
   ```

4. **Перезапуск сервисов:**
   ```bash
   docker-compose restart
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