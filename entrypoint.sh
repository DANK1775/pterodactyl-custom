#!/bin/bash
set -e


echo "Esperando a la base de datos..."
sleep 10

# execute migrations
echo "Ejecutando migraciones de base de datos..."
php artisan migrate --force --seed --step


echo "Iniciando Pterodactyl..."
exec "$@"
