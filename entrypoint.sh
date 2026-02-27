#!/bin/bash
set -e


echo "Esperando a la base de datos..."
sleep 10

# execute migrations
echo "Ejecutando migraciones de base de datos..."
php artisan migrate --force --seed --step

# artix installation check
echo "Verificando instalación de Arix..."
#run artix command, if it fails, run migrations and optimizations
php artisan arix || ( \
    echo "Fallo en 'php artisan arix' o ya instalado, ejecutando reparación/migración..." && \
    php artisan migrate --force && \
    php artisan optimize:clear && \
    php artisan optimize \
)

# artix perms
echo "Corrigiendo permisos..."
chmod -R 755 /app/storage/* /app/bootstrap/cache
chown -R nginx:nginx /app/storage /app/bootstrap/cache


echo "Iniciando Pterodactyl..."
exec "$@"
