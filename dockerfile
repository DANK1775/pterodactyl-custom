FROM ghcr.io/pterodactyl/panel:latest

USER root

WORKDIR /app

# install dependencies and blueprint
RUN apk update && \
    apk add --no-cache ca-certificates curl git gnupg unzip wget zip bash tar sed nodejs npm yarn ncurses && \
    npm i -g yarn && \
    yarn install --frozen-lockfile

# download only files of blueprint
RUN URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4) && \
    wget "$URL" -O release.zip && \
    unzip -o release.zip && \
    chmod +x blueprint.sh && \
    bash blueprint.sh && \
    rm release.zip blueprint.sh

# install arix theme (only files)
RUN wget "https://files.catbox.moe/9kkfpt.zip" -O arix-theme.zip &&\
    unzip -o arix-theme.zip -d /app/ && \
    rm arix-theme.zip

# build assets
RUN export NODE_OPTIONS=--openssl-legacy-provider && \
    yarn build:production

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# run entrypoint script (migration and setup) and then start supervisor
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
