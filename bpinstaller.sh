#!/bin/bash
set -e

# Variable de control extra (opcional pero recomendada)
if [ -f "/app/.blueprintrc" ] && [ -f "/app/blueprint.sh" ]; then
    echo "Blueprint ya se encuentra instalado. Saltando."
    exit 0
fi

export TERM=xterm
export DEBIAN_FRONTEND=noninteractive

echo "🚀 Iniciando proceso de instalación de Blueprint en el contenedor..."
echo "Descargando e instalando Blueprint..."

# Detectar usuario web correcto (en Alpine/Pterodactyl suele ser nginx, en otras imágenes www-data)
if id "nginx" &>/dev/null; then
    WEBUSER="nginx"
    OWNERSHIP="nginx:nginx"
else
    WEBUSER="www-data"
    OWNERSHIP="www-data:www-data"
fi

echo "Detectado usuario web: $WEBUSER"

# Creamos la configuración para Blueprint
echo \
"WEBUSER=\"$WEBUSER\";
OWNERSHIP=\"$OWNERSHIP\";
USERSHELL=\"/bin/bash\";" > /app/.blueprintrc

# Descargar release oficial usando la URL directa de la documentación
wget "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O /app/release.zip
unzip -o /app/release.zip
chmod +x blueprint.sh

# Instalar dependencias de Node antes de ejecutar Blueprint (según doc)
echo "Instalando dependencias de yarn..."
yarn install --frozen-lockfile

# Ejecutar el instalador de Blueprint
# La documentación dice "bash blueprint.sh", usaremos yes para automatizar los prompts
echo "Ejecutando instalador de Blueprint..."
yes | bash blueprint.sh
# Y tal como pediste: borramos el contenido del script para que no vuelva a ejecutarse
# y lo reemplazamos por un simple "echo" en caso de que el entrypoint lo invoque de nuevo.
cat << 'EOF' > "$0"
#!/bin/bash
echo "✅ Blueprint ya fue instalado en este contenedor previamente (script vaciado)."
EOF

echo "✨ Instalación de Blueprint completada exitosamente!"
