FROM golang:1.25.4-alpine

# Install tools & libraries
RUN apk add --no-cache \
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

# Install unrar (unrar-alpine)
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/latest \
    | jq -r '.assets[] | select(.name == "unrar") | .id' \
    | xargs -I {} curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/assets/{} \
    | jq -r '.browser_download_url' \
    | xargs -I {} curl -Lsf {} -o /tmp/unrar; \
    install -m755 /tmp/unrar /usr/local/bin; \
    rm -f /tmp/unrar

# Install grpcurl (multi-arch: x86_64 / arm64)
ARG GRPCURL_VERSION=1.9.1
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64) grpcurl_arch=linux_x86_64 ;; \
      aarch64) grpcurl_arch=linux_arm64 ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    wget -O /tmp/grpcurl.tar.gz "https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_${grpcurl_arch}.tar.gz"; \
    tar -xzf /tmp/grpcurl.tar.gz -C /tmp; \
    install -m755 /tmp/grpcurl /usr/local/bin/grpcurl; \
    rm -f /tmp/grpcurl /tmp/grpcurl.tar.gz

WORKDIR /app

CMD ["/bin/sh"]
