FROM golang:alpine

# Install librdkafka
RUN apk update && apk add --no-cache build-base musl-dev librdkafka librdkafka-dev bash

# Set working directory
WORKDIR /app

# Perintah default saat container dijalankan
CMD ["/bin/sh"]
