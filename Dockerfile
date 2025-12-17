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
    libgcc \
    git

# Install unrar (unrar-alpine) - using latest GitHub release
RUN set -eux; \
    mkdir -p /usr/local/bin; \
    curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/latest \
    | jq -r '.assets[] | select(.name == "unrar") | .id' \
    | xargs -I {} curl -LsSf https://api.github.com/repos/EDM115/unrar-alpine/releases/assets/{} \
    | jq -r '.browser_download_url' \
    | xargs -I {} curl -Lsf {} -o /tmp/unrar; \
    install -m755 /tmp/unrar /usr/local/bin/unrar; \
    rm -f /tmp/unrar

# Install grpcurl (latest stable, multi-arch) - download release asset robustly
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    rel_json="$(curl -LsSf -H 'Accept: application/vnd.github+json' https://api.github.com/repos/fullstorydev/grpcurl/releases/latest)"; \
    tag="$(echo "$rel_json" | jq -r '.tag_name')"; \
    ver="${tag#v}"; \
    case "$arch" in \
      x86_64)  candidates="grpcurl_${ver}_linux_x86_64.tar.gz grpcurl_${ver}_linux_amd64.tar.gz" ;; \
      aarch64) candidates="grpcurl_${ver}_linux_arm64.tar.gz" ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    tar_url=""; tar_name=""; \
    for n in $candidates; do \
      u="$(echo "$rel_json" | jq -r --arg n "$n" '.assets[] | select(.name==$n) | .browser_download_url' | head -n1)"; \
      if [ -n "$u" ] && [ "$u" != "null" ]; then tar_url="$u"; tar_name="$n"; break; fi; \
    done; \
    [ -n "$tar_url" ] || { echo "asset not found for grpcurl ${ver} on ${arch}. Tried: $candidates"; exit 1; }; \
    sums_url="$(echo "$rel_json" | jq -r --arg n "grpcurl_${ver}_checksums.txt" '.assets[] | select(.name==$n) | .browser_download_url')"; \
    curl -Lsf "$tar_url"  -o /tmp/grpcurl.tgz; \
    if [ -n "$sums_url" ] && [ "$sums_url" != "null" ]; then \
      curl -Lsf "$sums_url" -o /tmp/grpcurl_checksums.txt; \
      grep "  ${tar_name}$" /tmp/grpcurl_checksums.txt | sed "s|  ${tar_name}$|  /tmp/grpcurl.tgz|" | sha256sum -c -; \
      rm -f /tmp/grpcurl_checksums.txt; \
    fi; \
    tar -xzf /tmp/grpcurl.tgz -C /tmp; \
    install -m755 /tmp/grpcurl /usr/local/bin/grpcurl; \
    rm -f /tmp/grpcurl /tmp/grpcurl.tgz

# Install buf (latest stable, multi-arch) + verify using GitHub asset digest if present
# Buf Linux assets include buf-Linux-x86_64 / buf-Linux-aarch64 :contentReference[oaicite:4]{index=4}
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64)  buf_asset="buf-Linux-x86_64" ;; \
      aarch64) buf_asset="buf-Linux-aarch64" ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    rel_json="$(curl -LsSf -H 'Accept: application/vnd.github+json' https://api.github.com/repos/bufbuild/buf/releases/latest)"; \
    buf_url="$(echo "$rel_json" | jq -r --arg n "$buf_asset" '.assets[] | select(.name==$n) | .browser_download_url')"; \
    buf_digest="$(echo "$rel_json" | jq -r --arg n "$buf_asset" '.assets[] | select(.name==$n) | (.digest // empty)')"; \
    [ -n "$buf_url" ] || { echo "asset not found: $buf_asset"; exit 1; }; \
    curl -Lsf "$buf_url" -o /tmp/buf; \
    if [ -n "$buf_digest" ]; then echo "${buf_digest#sha256:}  /tmp/buf" | sha256sum -c -; fi; \
    install -m755 /tmp/buf /usr/local/bin/buf; \
    rm -f /tmp/buf; \
    buf --version

# Install protoc (latest stable, multi-arch) + verify using GitHub asset digest if present
# Protobuf release assets include protoc-<ver>-linux-x86_64.zip and protoc-<ver>-linux-aarch_64.zip :contentReference[oaicite:5]{index=5}
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64)  protoc_platform="linux-x86_64" ;; \
      aarch64) protoc_platform="linux-aarch_64" ;; \
      *) echo "unsupported arch: $arch"; exit 1 ;; \
    esac; \
    rel_json="$(curl -LsSf -H 'Accept: application/vnd.github+json' https://api.github.com/repos/protocolbuffers/protobuf/releases/latest)"; \
    tag="$(echo "$rel_json" | jq -r '.tag_name')"; \
    ver="${tag#v}"; \
    protoc_asset="protoc-${ver}-${protoc_platform}.zip"; \
    protoc_url="$(echo "$rel_json" | jq -r --arg n "$protoc_asset" '.assets[] | select(.name==$n) | .browser_download_url')"; \
    protoc_digest="$(echo "$rel_json" | jq -r --arg n "$protoc_asset" '.assets[] | select(.name==$n) | (.digest // empty)')"; \
    [ -n "$protoc_url" ] || { echo "asset not found: $protoc_asset"; exit 1; }; \
    curl -Lsf "$protoc_url" -o /tmp/protoc.zip; \
    if [ -n "$protoc_digest" ]; then echo "${protoc_digest#sha256:}  /tmp/protoc.zip" | sha256sum -c -; fi; \
    unzip -q /tmp/protoc.zip -d /tmp/protoc; \
    install -m755 /tmp/protoc/bin/protoc /usr/local/bin/protoc; \
    mkdir -p /usr/local/include; \
    cp -r /tmp/protoc/include/* /usr/local/include/; \
    rm -rf /tmp/protoc /tmp/protoc.zip; \
    protoc --version

# Install protoc plugins for codegen (latest)
# grpc-go quickstart recommends installing protoc-gen-go & protoc-gen-go-grpc via go install ...@latest :contentReference[oaicite:6]{index=6}
# grpc-gateway docs recommend installing protoc-gen-grpc-gateway via go install .../v2/...@latest :contentReference[oaicite:7]{index=7}
RUN set -eux; \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@latest

WORKDIR /app
CMD ["/bin/sh"]
