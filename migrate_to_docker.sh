#!/bin/bash

set -e
# variables globales
BACKUP_DIR="/root/pterodactyl_backup_$(date +%F_%H-%M)"
PTERO_DIR="/var/www/pterodactyl"
DOCKER_DIR="/srv/pterodactyl"

echo "⚠️  ADVERTENCIA: Este script detendrá tu panel Pterodactyl actual y migrará los datos a Docker."
echo "Asegúrate de tener un backup completo antes de continuar."
read -p "¿Deseas continuar? (y/n) " response
if [[ "$response" != "y" ]]; then
    echo "Cancelado."
    exit 1
fi

echo "📂 Creando directorio de backup en $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

# 1. Detener servicios de ptero bare metal antes de migrar (necesario para evitar corrupciones )
echo "🛑 Deteniendo servicios (nginx, php-fpm, pteroq)..."
systemctl stop pteroq.service || true
systemctl stop nginx || true
systemctl stop php8.3-fpm || true # Ajustar versión de PHP

# 2. Backup de Base de Datos
echo "💾 Exportando base de datos..."
# Intentar obtener credenciales del .env
DB_USER=$(grep DB_USERNAME $PTERO_DIR/.env | cut -d '=' -f2)
DB_PASS=$(grep DB_PASSWORD $PTERO_DIR/.env | cut -d '=' -f2)
DB_NAME=$(grep DB_DATABASE $PTERO_DIR/.env | cut -d '=' -f2)
if [ -z "$DB_PASS" ]; then
    echo "❌ No se pudo leer la contraseña de la DB del archivo .env"
    echo "Por favor ingresa la contraseña de root de MySQL para hacer el dump:"
    mysqldump -h 127.0.0.1 -u root -p panel > "$BACKUP_DIR/panel_dump.sql"
else
    mysqldump -h 127.0.0.1 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/panel_dump.sql"
fi

echo "✅ Base de datos exportada a $BACKUP_DIR/panel_dump.sql"

# 3. Copiar archivos importantes
echo "📦 Copiando archivos de configuración y almacenamiento..."
cp "$PTERO_DIR/.env" "$BACKUP_DIR/.env"
cp -r "$PTERO_DIR/storage" "$BACKUP_DIR/storage"
# cp -r "$PTERO_DIR/public" "$BACKUP_DIR/public" # Generalmente no necesario si se usa imagen docker, pero storage sí.

# 4. Preparar entorno Docker
echo "🐳 Preparando entorno Docker en $DOCKER_DIR..."
mkdir -p "$DOCKER_DIR/var"
mkdir -p "$DOCKER_DIR/nginx"
mkdir -p "$DOCKER_DIR/certs" # Volumen para certificados SSL si se usan, opcional
mkdir -p "$DOCKER_DIR/logs"
mkdir -p "$DOCKER_DIR/database" # Volumen para MariaDB

# Mover datos al volumen de docker
echo "🚚 Migrando datos a volúmenes de Docker..."
cp "$BACKUP_DIR/.env" "$DOCKER_DIR/.env"
cp -rp "$BACKUP_DIR/storage/." "$DOCKER_DIR/storage/" # Mapeo típico: /app/var -> volumen interno

# Importante: Permisos para que el contenedor pueda escribir en storage
echo "🔑 Ajustando permisos..."
chown -R 100:101 "$DOCKER_DIR/var" # UID:GID de nginx/ptero en contenedor suele ser 100:101 o www-data
chmod -R 755 "$DOCKER_DIR/var"

# 5. Instrucciones finales
echo "✅ Migración de archivos completada."
echo "----------------------------------------------------"
echo "PASOS SIGUIENTES:"
echo "1. Copia tu 'docker-compose.yml' y 'Dockerfile' a '$DOCKER_DIR'."
echo "2. Mueve el dump SQL '$BACKUP_DIR/panel_dump.sql' a '$DOCKER_DIR/database_init/dump.sql' (crea la carpeta si no existe) o impórtalo manualmente después de levantar el contenedor."
echo "   Nota: Si usas la imagen oficial de MariaDB, puedes poner el .sql en /docker-entrypoint-initdb.d/ para que se importe al inicio."
echo "3. Ejecuta 'docker-compose up -d --build' en '$DOCKER_DIR'."
echo "4. Verifica los logs con 'docker-compose logs -f'."
echo "----------------------------------------------------"

