FROM alpine:latest

# Install librdkafka
RUN apk update && apk add --no-cache gcc musl-dev librdkafka librdkafka-dev bash

# Set working directory
WORKDIR /app

# Perintah default saat container dijalankan
CMD ["/bin/sh"]
