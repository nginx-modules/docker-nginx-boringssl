# **NGINX** built with **BoringSSL** & **TLSv1.3**

### Docker image

[![](https://img.shields.io/docker/automated/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/builds/) [![](https://img.shields.io/docker/pulls/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/) [![](https://img.shields.io/docker/stars/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/)

[![Docker Image CI](https://github.com/nginx-modules/docker-nginx-boringssl/actions/workflows/docker-image.yml/badge.svg)](https://github.com/nginx-modules/docker-nginx-boringssl/actions/workflows/docker-image.yml)

### Supported tags and respective `Dockerfile` links

* Stable Release
  - `docker.io/denji/nginx-boringssl:stable-alpine` - (Linux x86_64-v4)
  - `docker.io/denji/nginx-boringssl:stable-aarch64-alpine` - (Linux AArch64 - ARMv8)
  - `docker.io/denji/nginx-boringssl:stable-armv7-alpine` - (Linux ARMv7 - 32-bit)

* Mainline Release
  - `docker.io/denji/nginx-boringssl:mainline-alpine` - (Linux x86_64-v4)
  - `docker.io/denji/nginx-boringssl:mainline-aarch64-alpine` - (Linux AArch64 - ARMv8)
  - `docker.io/denji/nginx-boringssl:mainline-armv7-alpine` - (Linux ARMv7 - 32-bit)

#### Before you can use

This project is unstable state because of the rolling release **BoringSSL**, and modules.

#### Features

- Images are used Alpine Linux.
- NGINX built **BoringSSL**.
- PCRE with JIT enabled.
- HTTP/2.0 (+NPN) support.
- Async I/O using threads support.
- Dynamic TLS records patch CloudFlare support (and configured).
- Gzip static `.gz` files support enabled
- Brotli static `.br` files support (and configured).
  - Brotli on-the-fly disabled (dynamic compression unstable)

#### Notes

- Linux 3.17+, and the latest Docker stable are recommended.
- BoringSSL is naming ECDH curves differently, some modifications will be required if you want to use your own SSL/TLS config file.
  For example, `secp384r1` (OpenSSL, LibreSSL) is `P-384` (BoringSSL).
  BoringSSL does support multiple curves with its implementation of `SSL_CTX_set1_curves_list()`,
  an example is provided in the default `/etc/nginx/confssl_params`.
  `X25519` is actually the safest curve you can use so it should be the first curve in your list.
- BoringSSL can use cipher groups: a group is defined by brackets and ciphers are separated by `|` like this : `[cipher1|cipher2|cipher3]`.
  Ciphers in a group are considered equivalent on the server-side and let the client decide which cipher is the best.
  This can be useful when using ChaCha20, because AES remains faster than ChaCha20 on AES-NI devices.

#### Based on the Official NGINX Dockerfile & `Wonderfall/boring-nginx`
