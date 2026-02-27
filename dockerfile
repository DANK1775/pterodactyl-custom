FROM ghcr.io/pterodactyl/panel:latest

USER root

WORKDIR /app

# install dependencies and blueprint
RUN apk update && \
    apk add --no-cache ca-certificates curl git gnupg unzip wget zip bash tar sed nodejs npm yarn ncurses mysql-client && \
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
RUN wget "https://download1654.mediafire.com/homf35pfe6sgmDRVxao9o76NfJS_P-cU5Y9VSBlcoxCYx7Jxk5jZj5W-crwklbOngvuw3FzBTEX0O1_mXiy1rzemfH61AUUROd0s944ZtdGLNMA5Zx1wB3opdJU9N3cPwwB2B-zPXZQu9zi1E0tfzLs0U2mscWVRrp5q_4NqTe6jPqs/6oannuzfkkqc1h1/Arix+Theme+v2.0.6.zip" -O arix-theme.zip &&\
    unzip -o arix-theme.zip -d /app/ && \
    rm arix-theme.zip

# build assets
RUN export NODE_OPTIONS=--openssl-legacy-provider && \
    yarn build:production

# Configurar cliente MariaDB para no exigir SSL (Fix ERROR 2026)
RUN mkdir -p /etc/my.cnf.d && \
    echo "[client]" > /etc/my.cnf.d/nossl.cnf && \
    echo "ssl=0" >> /etc/my.cnf.d/nossl.cnf && \
    echo "ssl-verify-server-cert=0" >> /etc/my.cnf.d/nossl.cnf

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# run entrypoint script (migration and setup) and then start supervisor
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
