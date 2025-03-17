FROM golang:alpine

# Install librdkafka dan paket tambahan
RUN apk update && apk add --no-cache \
    build-base \
    musl-dev \
    librdkafka \
    librdkafka-dev \
    bash \
    filezilla \
    curl \
    openssl \
    lftp \
    iputils \
    openssh \
    zip \
    tar \
    telnet \
    wget

# Set working directory
WORKDIR /app

# Perintah default saat container dijalankan
CMD ["/bin/sh"]
