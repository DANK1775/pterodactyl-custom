#!/bin/bash
set -e


echo "Esperando a la base de datos..."
sleep 10

# Asegurar permisos correctos en el contenedor
echo "Ajustando permisos..."
chown -R nginx:nginx /app/storage /app/bootstrap/cache /app/.blueprint || chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/.blueprint || true
chmod -R 775 /app/storage /app/bootstrap/cache /app/.blueprint
if [ -f "/app/.env" ]; then
    chmod 644 /app/.env
    chown nginx:nginx /app/.env || chown www-data:www-data /app/.env || true
fi

# execute migrations
echo "Ejecutando migraciones de base de datos..."
php artisan migrate --force --seed --step


echo "Iniciando Pterodactyl..."
exec "$@"
