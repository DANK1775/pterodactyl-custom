#!/bin/bash
set -e

# ==============================================================================
# SCRIPT DE MIGRACIÓN AUTOMÁTICA DE PTERODACTYL (BAREMETAL -> DOCKER)
# ==============================================================================

# Variables Globales (Personalizables)
PTERO_DIR="/var/www/pterodactyl"
DOCKER_DIR="/srv/pterodactyl"
BACKUP_DIR="/root/pterodactyl_backup_$(date +%F_%H-%M)"
DB_CONTAINER_NAME="pterodactyl-database-1"
PANEL_CONTAINER_NAME="pterodactyl-panel-1"
COMPOSE_USER="pterodactyl"

echo "====================================================================="
echo "🦅 INICIANDO MIGRACIÓN AUTOMATIZADA: BAREMETAL A DOCKER"
echo "====================================================================="
echo "⚠️  ADVERTENCIA: Este script detendrá tu panel Pterodactyl actual y migrará los datos a Docker."
read -p "¿Deseas continuar en este servidor? (y/n) " response
if [[ "$response" != "y" ]]; then
    echo "Cancelado."
    exit 1
fi

echo -e "\n[1/7] 📂 Creando directorio de backup en $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

echo -e "\n[2/7] 🛑 Deteniendo servicios nativos obsoletos (nginx, php-fpm, pteroq)..."
systemctl stop pteroq.service 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
systemctl stop php8.1-fpm 2>/dev/null || true
systemctl stop php8.3-fpm 2>/dev/null || true
# Deshabilitar para evitar conflictos en reinicios de máquina host
systemctl disable pteroq.service 2>/dev/null || true

echo -e "\n[3/7] 💾 Exportando base de datos a SQL Seguro..."
if [ ! -f "$PTERO_DIR/.env" ]; then
    echo "❌ ERROR FATAL: No se encontró Pterodactyl base en $PTERO_DIR"
    exit 1
fi
DB_USER=$(grep -w DB_USERNAME $PTERO_DIR/.env | cut -d '=' -f2)
DB_PASS=$(grep -w DB_PASSWORD $PTERO_DIR/.env | cut -d '=' -f2)
DB_NAME=$(grep -w DB_DATABASE $PTERO_DIR/.env | cut -d '=' -f2)

if [ -z "$DB_PASS" ]; then
    echo "⚠️  No se pudo extraer la contraseña desde .env, forzando superusuario MySQL..."
    mysqldump -h 127.0.0.1 -u root -p "$DB_NAME" > "$BACKUP_DIR/panel_dump.sql"
else
    # Exportar DB local
    mysqldump -h 127.0.0.1 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/panel_dump.sql"
fi
echo "✅ Base de datos exportada con éxito."

echo -e "\n[4/7] 🐳 Preparando nuevo entorno Docker en $DOCKER_DIR..."
mkdir -p "$DOCKER_DIR/var"
mkdir -p "$DOCKER_DIR/logs"

# Copiando .env vital y storage importante
cp "$PTERO_DIR/.env" "$DOCKER_DIR/.env"
cp -rp "$PTERO_DIR/storage/." "$DOCKER_DIR/storage/"

# Ajuste global de Permisos Host-side
chown -R 100:101 "$DOCKER_DIR/var"
chmod -R 755 "$DOCKER_DIR/var"

echo -e "\n[5/7] 🚀 Iniciando contenedores de Docker (Requiere tu docker-compose.yml presente)..."
if [ ! -f "$DOCKER_DIR/docker-compose.yml" ]; then
    echo "❌ ERROR: No se encontró docker-compose.yml en $DOCKER_DIR."
    echo "Asegúrate de haber copiado tu repositorio de Docker a $DOCKER_DIR antes de ejecutar esto."
    exit 1
fi

cd "$DOCKER_DIR"
docker compose down || docker-compose down || true
docker compose up -d || docker-compose up -d

echo -e "\n[6/7] ⏳ Esperando a que el subsistema de base de datos MaríaDB inicie (20s)..."
sleep 20

echo -e "\n[7/7] 💉 Inyectando Base de datos antigua en el Docker DB..."
# Buscamos la contraseña que usa MariaDB definida en docker-compose
COMPOSE_DB_PASS=$(grep 'MYSQL_PASSWORD:' docker-compose.yml | awk -F'"' '{print $2}')
if [ -z "$COMPOSE_DB_PASS" ]; then
    # Intento 2 por si no usa comillas
    COMPOSE_DB_PASS=$(grep 'MYSQL_PASSWORD:' docker-compose.yml | awk '{print $2}')
fi

# Copia e inyecta el SQL usando el contenedor del Panel (más estable referencialmente)
docker cp "$BACKUP_DIR/panel_dump.sql" "$PANEL_CONTAINER_NAME:/app/panel_dump.sql"
docker exec -i "$PANEL_CONTAINER_NAME" mariadb -h database -u "$COMPOSE_USER" -p"$COMPOSE_DB_PASS" "$DB_NAME" < "$BACKUP_DIR/panel_dump.sql"
docker exec -i "$PANEL_CONTAINER_NAME" rm /app/panel_dump.sql

echo -e "\n🧹 Limpiando y sincronizando cachés finales de Laravel..."
docker exec -i "$PANEL_CONTAINER_NAME" bash -c "php artisan optimize:clear && php artisan config:clear && php artisan view:clear"
docker exec -i "$PANEL_CONTAINER_NAME" bash -c "chown -R nginx:nginx /app/storage /app/public || chown -R www-data:www-data /app/storage /app/public"

echo "====================================================================="
echo "✨ MIGRACIÓN TOTAL EXITOSA ✨"
echo "Todo tu Pterodactyl antiguo está ahora dockerizado y los servicios viejos detenidos."
echo "Puedes acceder a tu panel con tu dominio habitual."
echo "Backup de seguridad local guardado en: $BACKUP_DIR"
echo "====================================================================="
