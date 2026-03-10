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

# Descargar el release oficial de Blueprint
echo "Descargando Blueprint desde GitHub Releases..."
wget -q "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O /app/release.zip

# Extraer en /app (directorio de trabajo del panel)
cd /app
unzip -o release.zip
rm -f release.zip
chmod +x blueprint.sh

# Instalar dependencias de Node antes de ejecutar Blueprint (requerido por el instalador)
echo "Instalando dependencias de yarn..."
yarn install --frozen-lockfile

# Ejecutar el instalador de Blueprint automatizando sus prompts interactivos con 'yes'
# pipefail garantiza que un error en blueprint.sh se propague correctamente
echo "Ejecutando instalador de Blueprint..."
yes | bash blueprint.sh || { echo "❌ Error: el instalador de Blueprint falló. Revisa los logs anteriores."; exit 1; }

echo "✨ Instalación de Blueprint completada exitosamente!"
