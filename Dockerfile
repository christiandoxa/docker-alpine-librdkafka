FROM golang:1.25.5-alpine

ENV PATH="/go/bin:/usr/local/bin:${PATH}"

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
    unzip \
    tar \
    busybox-extras \
    wget \
    libstdc++ \
    libgcc

# Install unrar (unrar-alpine) - already latest release
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/latest \
    | jq -r '.assets[] | select(.name == "unrar") | .id' \
    | xargs -I {} curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/assets/{} \
    | jq -r '.browser_download_url' \
    | xargs -I {} curl -Lsf {} -o /tmp/unrar; \
    install -m755 /tmp/unrar /usr/local/bin; \
    rm -f /tmp/unrar

# Install grpcurl (latest stable, multi-arch)
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64) grpcurl_arch=linux_x86_64 ;; \
      aarch64) grpcurl_arch=linux_arm64 ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    rel_json="$(curl -LsSf https://api.github.com/repos/fullstorydev/grpcurl/releases/latest)"; \
    tag="$(echo "$rel_json" | jq -r '.tag_name')"; \
    ver="${tag#v}"; \
    asset="grpcurl_${ver}_${grpcurl_arch}.tar.gz"; \
    url="$(echo "$rel_json" | jq -r --arg name "$asset" '.assets[] | select(.name==$name) | .browser_download_url')"; \
    digest="$(echo "$rel_json" | jq -r --arg name "$asset" '.assets[] | select(.name==$name) | (.digest // "")')"; \
    [ -n "$url" ] || { echo "asset not found: $asset"; exit 1; }; \
    curl -Lsf "$url" -o /tmp/grpcurl.tgz; \
    if [ -n "$digest" ]; then echo "${digest#sha256:}  /tmp/grpcurl.tgz" | sha256sum -c -; fi; \
    tar -xzf /tmp/grpcurl.tgz -C /tmp; \
    install -m755 /tmp/grpcurl /usr/local/bin/grpcurl; \
    rm -f /tmp/grpcurl /tmp/grpcurl.tgz; \
    grpcurl -version || true

# Add: buf (latest stable)
RUN set -eux; \
    buf_tag="$(curl -LsSf https://api.github.com/repos/bufbuild/buf/releases/latest | jq -r '.tag_name')"; \
    go install "github.com/bufbuild/buf/cmd/buf@${buf_tag}"; \
    buf --version

# Add: protoc (Protocol Buffers compiler) (latest stable, multi-arch)
# Protobuf releases publish prebuilt protoc zip: protoc-$VERSION-$PLATFORM.zip :contentReference[oaicite:1]{index=1}
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64)  protoc_arch="linux-x86_64" ;; \
      aarch64) protoc_arch="linux-aarch_64" ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    rel_json="$(curl -LsSf https://api.github.com/repos/protocolbuffers/protobuf/releases/latest)"; \
    tag="$(echo "$rel_json" | jq -r '.tag_name')"; \
    ver="${tag#v}"; \
    asset="protoc-${ver}-${protoc_arch}.zip"; \
    url="$(echo "$rel_json" | jq -r --arg name "$asset" '.assets[] | select(.name==$name) | .browser_download_url')"; \
    digest="$(echo "$rel_json" | jq -r --arg name "$asset" '.assets[] | select(.name==$name) | (.digest // "")')"; \
    [ -n "$url" ] || { echo "asset not found: $asset"; exit 1; }; \
    curl -Lsf "$url" -o /tmp/protoc.zip; \
    if [ -n "$digest" ]; then echo "${digest#sha256:}  /tmp/protoc.zip" | sha256sum -c -; fi; \
    unzip -q /tmp/protoc.zip -d /tmp/protoc; \
    install -m755 /tmp/protoc/bin/protoc /usr/local/bin/protoc; \
    mkdir -p /usr/local/include; \
    cp -r /tmp/protoc/include/* /usr/local/include/; \
    rm -rf /tmp/protoc /tmp/protoc.zip; \
    protoc --version

WORKDIR /app
CMD ["/bin/sh"]
