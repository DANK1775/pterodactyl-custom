FROM ghcr.io/pterodactyl/panel:latest

USER root

WORKDIR /app

# install dependencies and blueprint
RUN apk update && \
    apk add --no-cache ca-certificates curl git gnupg unzip wget zip bash tar sed nodejs npm yarn && \
    npm i -g yarn && \
    yarn install --frozen-lockfile

RUN URL=$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4) && \
    wget "$URL" -O release.zip && \
    unzip -o release.zip

RUN echo 'WEBUSER="nginx";' > /app/.blueprintrc && \
    echo 'OWNERSHIP="nginx:nginx";' >> /app/.blueprintrc && \
    echo 'USERSHELL="/bin/ash";' >> /app/.blueprintrc && \
    echo 'FOLDER="/app";' >> /app/.blueprintrc


RUN chmod +x blueprint.sh && \
    bash blueprint.sh && \
    rm release.zip blueprint.sh .blueprintrc

# 5. install pluguins and themes (.blueprint)
# RUN wget https://grrr.com/loquesea.blueprint -O loquesea.blueprint && \
#     blueprint -i loquesea && \
#     rm loquesea.blueprint

# Clean cache
RUN chown -R nginx:nginx /app/* && \
    rm -rf /var/cache/apk/*
