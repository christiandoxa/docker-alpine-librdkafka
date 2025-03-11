FROM alpine:latest

# Install librdkafka
RUN apk add --no-cache librdkafka librdkafka-dev bash

# Set working directory
WORKDIR /app

# Perintah default saat container dijalankan
CMD ["/bin/sh"]
