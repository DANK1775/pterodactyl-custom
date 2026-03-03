#!/bin/bash
set -e


echo "Esperando a la base de datos..."
sleep 10

# Asegurar permisos base y migrar Laravel original ANTES de instalar mods
if [ -f "/app/.env" ]; then
    chmod 644 /app/.env
    chown nginx:nginx /app/.env || chown www-data:www-data /app/.env || true
fi
php artisan migrate --force --seed --step

# Ejecutar instalador de Blueprint de un solo uso solo
if [ -x "/bpinstaller.sh" ]; then
    bash /bpinstaller.sh
fi

# Volver a asegurar permisos en caso de que Blueprint haya creado algo
echo "Ajustando permisos y migraciones finales..."
chown -R nginx:nginx /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint || chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint || true
chmod -R 775 /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint || true
#migracion final para asegurarnos que todo lo que se instalo migre (es un requisito de bp y algunos plugins)
php artisan migrate --force --seed --step


echo "Iniciando Pterodactyl..."
exec "$@"
