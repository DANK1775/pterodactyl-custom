FROM ghcr.io/pterodactyl/panel:latest

USER root

WORKDIR /app

# install dependencies and blueprint
RUN apk update && \
    apk add --no-cache ca-certificates curl git gnupg unzip wget zip bash tar sed nodejs npm yarn ncurses mysql-client && \
    npm i -g yarn && \
    yarn install --frozen-lockfile

# NO BORRAR blueprint.sh para que se pueda usar como herramienta CLI dentro del contenedor
RUN URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4) && \
    wget "$URL" -O release.zip && \
    unzip -o release.zip && \
    chmod +x blueprint.sh && \
    yarn add cross-env && \
    bash blueprint.sh -i blueprint && \
    rm release.zip


# install arix theme (only files)
RUN wget "https://download1654.mediafire.com/pjaa9xov3jcgBlZ4t0l4M96mq2HvB9s8rES1iOtFD7dYnfL5cVsoxJZD4FfKUZO_7c0hUCmg9BVH97SCn3GRvoxJOk_fHSkD2a181U6wPrqATMPcBa3WUGzVNM0p8MsSCgpkPqHeR4nP5dmqKpgrXBmTZo1JSah9mNwUi44fJ1wfiTU/6oannuzfkkqc1h1/Arix+Theme+v2.0.6.zip" -O arix-theme.zip && \
    unzip -o arix-theme.zip -d /tmp/arix && \
    cp -rf /tmp/arix/pterodactyl/* /app/ && \
    rm -rf /tmp/arix arix-theme.zip

# build assets
RUN export NODE_OPTIONS=--openssl-legacy-provider && \
    yarn build:production

# Configurar cliente MariaDB para no exigir SSL (Fix ERROR 2026)
# NOTA DE SEGURIDAD: Esto deshabilita SSL para la conexión entre Panel -> Base de Datos (interna en Docker).
# Es necesario porque el contenedor de MariaDB por defecto no tiene certificados configurados y el cliente
# nuevo rechaza conexiones planas.
#
# SI EN EL FUTURO QUIERES FORZAR SSL/TLS EN PRODUCCIÓN:
# 1. Configura certificados SSL válidos en el servicio de 'database' (mariadb) en docker-compose.yml.
# 2. Elimina o comenta el siguiente bloque RUN.
RUN mkdir -p /etc/my.cnf.d && \
    echo "[client]" > /etc/my.cnf.d/nossl.cnf && \
    echo "ssl=0" >> /etc/my.cnf.d/nossl.cnf && \
    echo "ssl-verify-server-cert=0" >> /etc/my.cnf.d/nossl.cnf

# Crear directorio de logs de supervisord
RUN mkdir -p /var/log/supervisord

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# run entrypoint script (migration and setup) and then start supervisor
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
