# Gunakan base image Alpine versi 3.14
FROM alpine:3.14

# Install semua paket yang dibutuhkan termasuk unrar
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
    busybox-extras \
    wget \
    unrar

# Set working directory
WORKDIR /app

# Perintah default saat container dijalankan
CMD ["/bin/sh"]
