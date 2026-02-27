FROM ghcr.io/pterodactyl/panel:latest

USER root
WORKDIR /app

RUN apk update && \
    apk add --no-cache bash curl wget unzip tar sed nodejs yarn && \
    rm -rf /var/cache/apk/*

# 4. Descargar, instalar Blueprint y borrar el instalador
RUN wget https://github.com/teamblueprint/main/releases/latest/download/blueprint.zip -O blueprint.zip && \
    unzip -o blueprint.zip && \
    chmod +x blueprint.sh && \
    bash blueprint.sh && \
    # BORRAR ARCHIVOS RESIDUALES DE BLUEPRINT
    rm blueprint.zip blueprint.sh

# 5. Descargar plugins, moverlos, instalarlos y limpiar
# Ejemplo estático de cómo se vería un plugin
RUN wget https://ejemplo.com/descarga/tema-oscuro.blueprint -O tema-oscuro.blueprint && \
    # Blueprint instala el archivo .blueprint
    blueprint -i tema-oscuro && \
    # BORRAR EL ARCHIVO .blueprint DESPUÉS DE INSTALAR
    rm tema-oscuro.blueprint

# 6. Devolver permisos al usuario de Nginx/PHP (Crítico para que el panel web no dé Error 500)
RUN chown -R nginx:nginx /app/*
