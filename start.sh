#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Pterodactyl Custom Panel - Script de inicio
# Uso: bash start.sh
# ──────────────────────────────────────────────────────────────
set -e

echo "=== Pterodactyl Custom Panel - Inicio ==="

# 1. Crear .env desde template si no existe
if [ ! -f .env ]; then
    echo "[1/3] Generando .env desde .env.example..."
    cp .env.example .env

    # Generar APP_KEY único
    if command -v openssl &>/dev/null; then
        APP_KEY="base64:$(openssl rand -base64 32)"
    elif command -v python3 &>/dev/null; then
        APP_KEY=$(python3 -c "import base64,os; print('base64:' + base64.b64encode(os.urandom(32)).decode())")
    elif command -v python &>/dev/null; then
        APP_KEY=$(python -c "import base64,os; print('base64:' + base64.b64encode(os.urandom(32)).decode())")
    else
        echo "ADVERTENCIA: No se pudo generar APP_KEY (no se encontro openssl ni python)."
        echo "           El entrypoint lo generara automaticamente dentro del contenedor."
        APP_KEY=""
    fi

    if [ -n "$APP_KEY" ]; then
        sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env
        echo "    APP_KEY generado correctamente."
    fi
else
    echo "[1/3] .env ya existe, saltando."
fi

# 2. Crear directorios de datos
echo "[2/3] Creando directorios de datos..."
mkdir -p data/database data/var data/logs data/certs

# 3. Levantar contenedores
echo "[3/3] Levantando contenedores..."
docker compose up -d

echo ""
echo "=== Panel iniciado ==="
echo "URL:      http://localhost"
echo ""
echo "Esperando a que el panel arranque (migraciones + Blueprint)..."
echo "Puedes ver el progreso con: docker compose logs -f panel"
echo ""
echo "Una vez listo, crea tu usuario admin con:"
echo "  docker compose exec panel php artisan p:user:make"
