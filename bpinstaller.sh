#!/bin/bash
set -eo pipefail

# Guardia: si Blueprint ya fue instalado en este contenedor, salir sin hacer nada
if [ -f "/app/.blueprintrc" ] && [ -f "/app/blueprint.sh" ]; then
    echo "Blueprint ya se encuentra instalado. Saltando."
    exit 0
fi

export TERM=xterm
export DEBIAN_FRONTEND=noninteractive

echo "🚀 Iniciando proceso de instalación de Blueprint en el contenedor..."

# Detectar usuario web correcto (en Alpine/Pterodactyl suele ser nginx, en otras imágenes www-data)
if id "nginx" &>/dev/null; then
    WEBUSER="nginx"
    OWNERSHIP="nginx:nginx"
else
    WEBUSER="www-data"
    OWNERSHIP="www-data:www-data"
fi

echo "Detectado usuario web: $WEBUSER"

# Crear la configuración de Blueprint (.blueprintrc) antes de ejecutar su instalador
cat > /app/.blueprintrc << BPRC
WEBUSER="$WEBUSER";
OWNERSHIP="$OWNERSHIP";
USERSHELL="/bin/bash";
BPRC

# Obtener la URL del último release de Blueprint (con soporte jq para mayor robustez)
echo "Obteniendo URL del último release de Blueprint..."
BLUEPRINT_URL=""
if command -v jq >/dev/null 2>&1; then
    # Usar jq para parsear el JSON con mayor fiabilidad
    BLUEPRINT_URL=$(curl -s --connect-timeout 30 --max-time 60 \
        https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | jq -r '.assets[]? | select(.name == "release.zip") | .browser_download_url' \
        | head -n 1)
else
    # Fallback: parseo por texto para máxima compatibilidad
    BLUEPRINT_URL=$(curl -s --connect-timeout 30 --max-time 60 \
        https://api.github.com/repos/BlueprintFramework/framework/releases/latest \
        | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
fi

if [ -z "$BLUEPRINT_URL" ]; then
    echo "⚠️  No se pudo obtener la URL del release, usando URL de fallback..."
    BLUEPRINT_URL="https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip"
fi

# Descargar el release oficial de Blueprint con tiempos de espera adecuados
echo "Descargando Blueprint desde: $BLUEPRINT_URL"
if ! curl --connect-timeout 30 --max-time 300 -Lo /app/release.zip "$BLUEPRINT_URL"; then
    echo "❌ Error: no se pudo descargar Blueprint framework."
    exit 1
fi

# Extraer en /app (directorio de trabajo del panel)
cd /app
if ! unzip -o release.zip; then
    echo "❌ Error: no se pudo extraer Blueprint framework."
    rm -f release.zip
    exit 1
fi
rm -f release.zip
chmod +x blueprint.sh

# Instalar dependencias de producción de Blueprint (requerido por el instalador)
echo "Instalando dependencias de yarn (producción)..."
if ! yarn install --production; then
    echo "❌ Error: no se pudieron instalar las dependencias de Blueprint."
    exit 1
fi

# Ejecutar el instalador de Blueprint
# .blueprintrc ya pre-configura las opciones interactivas, por lo que no se necesita 'yes |'
echo "Ejecutando instalador de Blueprint..."
if ! bash blueprint.sh; then
    echo "❌ Error: el instalador de Blueprint falló. Revisa los logs anteriores."
    exit 1
fi

echo "✨ Instalación de Blueprint completada exitosamente!"
