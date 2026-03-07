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

# Configurar SSL si se proveen certificados
CERT_FILE=""
KEY_FILE=""

if [ -f "/etc/certs/cert.pem" ] && [ -f "/etc/certs/key.pem" ]; then
    CERT_FILE="/etc/certs/cert.pem"
    KEY_FILE="/etc/certs/key.pem"
elif [ -f "/etc/certs/fullchain.pem" ] && [ -f "/etc/certs/privkey.pem" ]; then
    CERT_FILE="/etc/certs/fullchain.pem"
    KEY_FILE="/etc/certs/privkey.pem"
fi

if [ -n "$CERT_FILE" ] && [ -n "$KEY_FILE" ]; then
    echo "Certificados detectados en /etc/certs/. Configurando Nginx para usar SSL..."
    # Busca en cualquier archivo de coniguración de nginx para asegurarse de inyectar el SSL donde esté escuchando el puerto 80
    for conf in /etc/nginx/http.d/*.conf /etc/nginx/sites-available/default; do
        if [ -f "$conf" ]; then
            grep -q "listen 443" "$conf" || \
            sed -i "s/listen 80;/listen 80;\n    listen 443 ssl http2;\n    ssl_certificate $CERT_FILE;\n    ssl_certificate_key $KEY_FILE;/g" "$conf"
        fi
    done
fi

echo "Iniciando Pterodactyl..."
exec "$@"
