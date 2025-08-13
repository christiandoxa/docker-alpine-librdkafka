FROM golang:1.25rc3-alpine3.22

RUN apk update && apk add --no-cache \
    build-base \
    musl-dev \
    librdkafka \
    librdkafka-dev \
    bash \
    filezilla \
    curl \
    jq \
    openssl \
    ca-certificates \
    lftp \
    iputils \
    openssh \
    zip \
    tar \
    busybox-extras \
    wget \
    libstdc++ \
    libgcc

RUN set -eux; \
    mkdir -p /usr/local/bin; \
    curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/latest \
    | jq -r '.assets[] | select(.name == "unrar") | .id' \
    | xargs -I {} curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/assets/{} \
    | jq -r '.browser_download_url' \
    | xargs -I {} curl -Lsf {} -o /tmp/unrar; \
    install -m755 /tmp/unrar /usr/local/bin; \
    rm -f /tmp/unrar

WORKDIR /app

CMD ["/bin/sh"]
