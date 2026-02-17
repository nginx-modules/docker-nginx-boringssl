# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# ALPINE VERSION SELECTION HISTORY
# -----------------------------------------------------------------------------

# FROM alpine:edge    # Bleeding edge; frequent breaking changes in musl/GCC

# (3.23) Fails: musl 1.2.5+ removed LFS64 (fopen64/fseeko64)
FROM alpine:latest

# FROM alpine:3.22    # Fails: GCC 14/15 strictness on BoringSSL PKI modules
# FROM alpine:3.21    # Fails: Missing legacy symbols required for BoringSSL link
# FROM alpine:3.20    # Mixed: Requires C++17 flag to bypass GCC 13 allocator errors

# RECOMMENDED: Best stability for BoringSSL cross-builds
# FROM alpine:3.19

# FROM alpine:3.18    # Legacy support; stable but nearing End-of-Life (EOL)

ENV NGINX_VERSION=1.29.5

ENV CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --with-http_v3_module \
    --add-dynamic-module=/usr/src/ngx_headers_more \
    --add-dynamic-module=/usr/src/ngx_brotli \
    --add-dynamic-module=/usr/src/njs/nginx \
    --with-openssl=/usr/src/boringssl \
"

RUN set -eux \
    \
    # -- System user -----------------------------------------------------------
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    \
    # -- Build dependencies ----------------------------------------------------
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        bind-tools \
        binutils \
        build-base \
        ca-certificates \
        cmake \
        curl \
        gcc \
        gd-dev \
        geoip-dev \
        git \
        gnupg \
        go \
        libc-dev \
        libgcc \
        libstdc++ \
        libtool \
        libxslt-dev \
        linux-headers \
        make \
        mercurial \
        pcre \
        pcre-dev \
        perl-dev \
        su-exec \
        tar \
        tzdata \
        zlib \
        zlib-dev \
    \
    # -- Download sources ------------------------------------------------------
    && curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"     -o nginx.tar.gz \
    && curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc" -o nginx.tar.gz.asc \
    \
    # -- GPG: fetch nginx signing keys (keyserver fallback chain) --------------
    && GPG_KEYS="43387825DDB1BB97EC36BA5D007C8D7C15D87369 A1EB079B8D3EB92B4EBD3139663AF51BD5E4D8D5" \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && found="" \
    && for server in \
           hkps://keys.openpgp.org \
           hkps://keyserver.ubuntu.com \
           hkp://ha.pool.sks-keyservers.net:80 \
           hkp://pgp.mit.edu:80 \
       ; do \
           echo "Fetching nginx GPG keys from ${server}"; \
           for key in ${GPG_KEYS}; do \
               gpg --keyserver "${server}" \
                   --keyserver-options timeout=10 \
                   --recv-keys "${key}" 2>/dev/null \
               && found=yes \
               || true; \
           done; \
           test "${found}" = yes && break || true; \
       done \
    && if [ -z "${found}" ]; then \
           echo "Falling back to nginx.org key download"; \
           curl -fsSL https://nginx.org/keys/nginx_signing.key -o nginx_signing.key \
           && gpg --import nginx_signing.key \
           && found=yes \
           || true; \
           rm -f nginx_signing.key; \
       fi \
    && test "${found}" = yes \
       || { echo >&2 "ERROR: failed to fetch nginx GPG keys"; exit 1; } \
    \
    # -- Verify signatures -----------------------------------------------------
    && { gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
         || { echo >&2 "ERROR: nginx tarball signature verification failed"; exit 1; }; } \
    && rm -rf "${GNUPGHOME}" nginx.tar.gz.asc \
    \
    # -- Extract sources -------------------------------------------------------
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz && rm nginx.tar.gz \
    \
    # -- Clone dynamic modules -------------------------------------------------
    && git clone --depth=1 --recurse-submodules \
           https://github.com/google/ngx_brotli /usr/src/ngx_brotli \
    && git clone --depth=1 \
           https://github.com/openresty/headers-more-nginx-module /usr/src/ngx_headers_more \
    && git clone --depth=1 \
           https://github.com/nginx/njs /usr/src/njs \
    \
    # -- Build BoringSSL via CMake ---------------------------------------------
    && git clone https://boringssl.googlesource.com/boringssl /usr/src/boringssl \
    && cd /usr/src/boringssl \
    && git checkout --force --quiet '0.20260211.0' \
    && cmake -B/usr/src/boringssl/build -S/usr/src/boringssl \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_STANDARD_REQUIRED=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_C_FLAGS="-flto -fno-fat-lto-objects -Wno-error=array-bounds -Wno-error=stringop-overread" \
        -DCMAKE_CXX_FLAGS="-flto -fno-fat-lto-objects -Wno-error=array-bounds -Wno-error=stringop-overread" \
        -DCMAKE_EXE_LINKER_FLAGS="-flto -lstdc++ -lgcc_s" \
    && make -C/usr/src/boringssl/build -j"$(getconf _NPROCESSORS_ONLN)" \
    \
    # -- Create the .openssl layout that nginx's configure detector expects ----
    # nginx's SSL detection probes <--with-openssl>/.openssl/include/openssl/ssl.h
    # and links against <--with-openssl>/.openssl/libssl.a + libcrypto.a.
    # We satisfy that contract with symlinks into the pre-built BoringSSL tree,
    # which makes nginx skip its own OpenSSL build step entirely.
    && mkdir -p /usr/src/boringssl/.openssl/lib \
    && mkdir -p /usr/src/boringssl/.openssl/include \
    && ln -sf /usr/src/boringssl/include/openssl \
              /usr/src/boringssl/.openssl/include/openssl \
    && ln -sf /usr/src/boringssl/build/libssl.a \
              /usr/src/boringssl/.openssl/lib/libssl.a \
    && ln -sf /usr/src/boringssl/build/libcrypto.a \
              /usr/src/boringssl/.openssl/lib/libcrypto.a \
    \
    # -- Patch -----------------------------------------------------------------
    && cd /usr/src/nginx-${NGINX_VERSION} \
    && curl -fsSL \
           "https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/refs/heads/master/nginx__dynamic_tls_records_1.29.2%2B.patch" \
           -o dynamic_tls_records.patch \
    && patch -p1 < dynamic_tls_records.patch \
    && rm dynamic_tls_records.patch \
    \
    # -- Release build & install -----------------------------------------------
    # --with-openssl points nginx to our pre-built BoringSSL; the detector finds
    # .openssl/include/openssl/ssl.h and considers SSL "already built".
    # -lstdc++ links the C++ runtime required by BoringSSL's static archives.
    && ./configure ${CONFIG} \
        --with-openssl="/usr/src/boringssl" \
        --with-cc-opt="-I/usr/src/boringssl/.openssl/include -DNGX_QUIC_OPENSSL_COMPAT=0 -flto -fno-fat-lto-objects" \
        --with-ld-opt="-L/usr/src/boringssl/.openssl/lib -flto -lstdc++ -lgcc_s" \
    && touch /usr/src/boringssl/.openssl/include/openssl/ssl.h \
    && make -j"$(getconf _NPROCESSORS_ONLN)" \
    && make install \
    \
    # -- Debug build -----------------------------------------------------------
    # make clean is required here: without it, make reuses .o files from the
    # release build (same source timestamps) and the "debug" binary silently
    # ends up compiled without -g and -DNGINX_DEBUG flags.
    && make clean \
    && ./configure ${CONFIG} --with-debug \
        --with-openssl="/usr/src/boringssl" \
        --with-cc-opt="-I/usr/src/boringssl/.openssl/include -DNGX_QUIC_OPENSSL_COMPAT=0 -flto -fno-fat-lto-objects" \
        --with-ld-opt="-L/usr/src/boringssl/.openssl/lib -flto -lstdc++ -lgcc_s" \
    && touch /usr/src/boringssl/.openssl/include/openssl/ssl.h \
    && make -j"$(getconf _NPROCESSORS_ONLN)" \
    && mv objs/nginx                           objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so  objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so        objs/ngx_http_geoip_module-debug.so \
    && mv objs/ngx_http_perl_module.so         objs/ngx_http_perl_module-debug.so \
    && mv objs/ngx_stream_geoip_module.so      objs/ngx_stream_geoip_module-debug.so \
    \
    # -- Install debug binaries & modules --------------------------------------
    && install -m 755 objs/nginx-debug                            /usr/sbin/nginx-debug \
    && install -m 755 objs/ngx_http_xslt_filter_module-debug.so  /usr/lib/nginx/modules/ \
    && install -m 755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ \
    && install -m 755 objs/ngx_http_geoip_module-debug.so        /usr/lib/nginx/modules/ \
    && install -m 755 objs/ngx_http_perl_module-debug.so         /usr/lib/nginx/modules/ \
    && install -m 755 objs/ngx_stream_geoip_module-debug.so      /usr/lib/nginx/modules/ \
    \
    # -- Web root & module symlink ---------------------------------------------
    && rm -rf /etc/nginx/html/ \
    && mkdir -p /etc/nginx/conf.d/ /usr/share/nginx/html/ \
    && install -m 644 html/index.html /usr/share/nginx/html/ \
    && install -m 644 html/50x.html   /usr/share/nginx/html/ \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    \
    # -- Strip release binaries (not debug) ------------------------------------
    && strip /usr/sbin/nginx \
    && strip /usr/lib/nginx/modules/*.so \
    \
    # -- Remove all build artefacts & source trees -----------------------------
    && rm -rf \
           /usr/src/nginx-${NGINX_VERSION} \
           /usr/src/boringssl \
           /usr/src/ngx_brotli \
           /usr/src/ngx_headers_more \
           /usr/src/njs \
    \
    # -- Grab envsubst, resolve runtime deps, drop all build tooling -----------
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner \
            /usr/sbin/nginx \
            /usr/lib/nginx/modules/*.so \
            /tmp/envsubst \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    ) tzdata ca-certificates" \
    && apk add --no-cache --virtual .nginx-rundeps ${runDeps} \
    && apk del .build-deps .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
    # -- Forward logs to Docker log collector ----------------------------------
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# -----------------------------------------------------------------------------
# Configuration files
# -----------------------------------------------------------------------------
COPY nginx.conf               /etc/nginx/nginx.conf
COPY nginx.vh.no-default.conf /etc/nginx/conf.d/default.conf

ARG TARGETARCH=unknown
ARG TARGETOS=unknown

LABEL org.opencontainers.image.title="NGINX with BoringSSL" \
      org.opencontainers.image.description="NGINX ${NGINX_VERSION} built on Alpine with BoringSSL, Brotli, and QUIC support" \
      org.opencontainers.image.source="https://github.com/nginx-modules/docker-nginx-boringssl" \
      org.opencontainers.image.authors="Denis Denisov <denji0k@gmail.com>" \
      org.opencontainers.image.version="${NGINX_VERSION}" \
      org.opencontainers.image.licenses="BSD-2-Clause" \
      org.opencontainers.image.architecture="${TARGETARCH}" \
      org.opencontainers.image.os="${TARGETOS}" \
      nginx.version="${NGINX_VERSION}" \
      nginx.ssl="BoringSSL" \
      nginx.release="mainline"

EXPOSE 80 443 443/udp

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
