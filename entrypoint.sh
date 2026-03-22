#!/bin/bash
set -eo pipefail

echo "Esperando a la base de datos..."
sleep 10

# Asegurar permisos base y migrar Laravel original ANTES de instalar mods
if [ -f "/app/.env" ]; then
    chmod 644 /app/.env
    chown nginx:nginx /app/.env || chown www-data:www-data /app/.env || true
fi
php artisan migrate --force --seed --step

# Instalar Blueprint y reconstruir assets SOLO si aún no está instalado.
# La guardia usa los mismos archivos que comprueba bpinstaller.sh.
if [ ! -f "/app/.blueprintrc" ] || [ ! -f "/app/blueprint.sh" ]; then
    echo "Instalando Blueprint framework..."
    bash /bpinstaller.sh

    # Después de instalar Blueprint, reconstruir los assets del panel modificado
    echo "Reconstruyendo assets del panel modificado por Blueprint..."

    # 1. Asegurar todas las dependencias de Node (ahora necesitamos las dev también para build)
    yarn install --frozen-lockfile

    # 2. Ejecutar comando de Blueprint para inyectar/preparar assets en resources
    php artisan blueprint:build --no-interaction || echo "⚠️  Fallo blueprint:build, continuando..."

    # 3. Compilar producción final (Webpack/Vite)
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn run build:production
else
    echo "Blueprint ya está instalado, saltando instalación."
fi

# Volver a asegurar permisos en caso de que Blueprint haya creado algo
echo "Ajustando permisos y migraciones finales..."
chown -R nginx:nginx /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint /app/public || chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint /app/public || true
chmod -R 775 /app/storage /app/bootstrap/cache /app/.blueprintrc /app/.blueprint /app/public || true

# Asegurar que el directorio de assets exista y tenga permisos
if [ -d "/app/public/assets" ]; then
    chown -R nginx:nginx /app/public/assets || chown -R www-data:www-data /app/public/assets || true
    chmod -R 755 /app/public/assets
fi

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
    for conf in /etc/nginx/http.d/*.conf; do
        if [ -f "$conf" ]; then
            grep -q "listen 443" "$conf" || \
            sed -i "s|listen 80;|listen 80;\n    listen 443 ssl;\n    http2 on;\n    ssl_certificate $CERT_FILE;\n    ssl_certificate_key $KEY_FILE;|g" "$conf"

            # Reemplazar server_name _ por el dominio de APP_URL si existe
            if [ -f "/app/.env" ]; then
                APP_DOMAIN=$(grep '^APP_URL=' /app/.env | cut -d'=' -f2 | tr -d '"' | sed 's|^https://||; s|^http://||; s|/.*||')
                if [ -n "$APP_DOMAIN" ]; then
                    sed -i "s|server_name _;|server_name $APP_DOMAIN;|g" "$conf"
                    echo "Configurado server_name a $APP_DOMAIN en $conf"
                fi
            fi
        fi
    done
fi

echo "Iniciando Pterodactyl..."
exec "$@"
