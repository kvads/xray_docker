#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка наличия Docker
check_docker() {
    log "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
}

# Проверка и создание .env файла
setup_env() {
    log "Setting up environment variables..."
    
    # Проверяем существование .env
    if [ -f .env ]; then
        warn "Found existing .env file. Creating backup..."
        cp .env .env.backup
    fi

    # Запрашиваем необходимые данные
    read -p "Enter your domain (e.g., example.com): " domain
    read -p "Enter your email for Let's Encrypt: " email
    read -p "Enter VLESS port (default: 8443): " vless_port
    read -p "Enter WebSocket port (default: 8080): " ws_port
    read -p "Enter gRPC port (default: 2087): " grpc_port
    read -p "Enter admin panel port (default: 3000): " admin_port

    # Устанавливаем значения по умолчанию
    vless_port=${vless_port:-8443}
    ws_port=${ws_port:-8080}
    grpc_port=${grpc_port:-2087}
    admin_port=${admin_port:-3000}

    # Создаем .env файл
    cat > .env << EOF
# Domain configuration
DOMAIN=${domain}
ADMIN_DOMAIN=admin.${domain}

# Let's Encrypt configuration
LETSENCRYPT_EMAIL=${email}

# Ports configuration
XRAY_VLESS_PORT=${vless_port}
XRAY_WS_PORT=${ws_port}
XRAY_GRPC_PORT=${grpc_port}

# Admin panel configuration
ADMIN_PANEL_PORT=${admin_port}
EOF

    log "Created .env file"
}

# Создание необходимых директорий
create_directories() {
    log "Creating necessary directories..."
    mkdir -p xray/{config,data} nginx-proxy/{conf.d,ssl} admin-panel
}

# Проверка и запуск сервисов
start_services() {
    log "Starting services..."
    
    # Проверяем переменные окружения
    ./check-env.sh || error "Environment check failed"
    
    # Запускаем сервисы
    docker-compose up -d || error "Failed to start services"
    
    # Проверяем статус
    if docker-compose ps | grep -q "Up"; then
        log "Services started successfully"
    else
        error "Some services failed to start"
    fi
}

# Основной процесс установки
main() {
    log "Starting installation process..."
    
    # Проверяем Docker
    check_docker
    
    # Создаем директории
    create_directories
    
    # Настраиваем .env
    setup_env
    
    # Запускаем сервисы
    start_services
    
    log "Installation completed successfully!"
    log "You can access the admin panel at: https://admin.${domain}"
    log "Check the logs with: docker-compose logs -f"
}

# Запускаем основной процесс
main 