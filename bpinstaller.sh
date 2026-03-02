#!/bin/bash
set -e

# Variable de control extra (opcional pero recomendada)
if [ -f "/app/.bp_installed" ]; then
    echo "Blueprint ya se encuentra instalado. Saltando."
    exit 0
fi

echo "🚀 Iniciando proceso de instalación de Blueprint en el contenedor..."
echo "Descargando e instalando Blueprint..."

# Creamos la configuración para Blueprint adaptada al entorno Alpine/Docker que usamos
echo \
'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > /app/.blueprintrc

URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)
wget "$URL" -O /app/release.zip
unzip -o /app/release.zip
chmod +x blueprint.sh
yarn add cross-env

# Ejecutamos la instalación de blueprint.
# En este punto el .env ya existe en /app/ y está cargado por el entrypoint
bash blueprint.sh -i blueprint

rm release.zip

# Dejamos una marca para que Pterodactyl sepa que ya está instalado en este volumen var/app
touch /app/.bp_installed

# Y tal como pediste: borramos el contenido del script para que no vuelva a ejecutarse
# y lo reemplazamos por un simple "echo" en caso de que el entrypoint lo invoque de nuevo.
cat << 'EOF' > "$0"
#!/bin/bash
echo "✅ Blueprint ya fue instalado en este contenedor previamente (script vaciado)."
EOF

echo "✨ Instalación de Blueprint completada exitosamente!"
