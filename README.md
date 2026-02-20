# NGINX with BoringSSL

[**NGINX built with BoringSSL**](https://github.com/nginx-modules/docker-nginx-boringssl)

---

[![Automated Build](https://img.shields.io/docker/automated/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/builds/) 
[![Pulls](https://img.shields.io/docker/pulls/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/) 
[![Stars](https://img.shields.io/docker/stars/denji/nginx-boringssl.svg)](https://hub.docker.com/r/denji/nginx-boringssl/)

[![Docker Image CI](https://github.com/nginx-modules/docker-nginx-boringssl/actions/workflows/docker-image.yml/badge.svg)](https://github.com/nginx-modules/docker-nginx-boringssl/actions/workflows/docker-image.yml)

## Docker Image

Images are published to both registries:
- `docker.io/denji/nginx-boringssl`
- `ghcr.io/nginx-modules/nginx-boringssl`

---

## Supported tags and architectures

| Tag pattern | Architectures |
|-------------|---------------|
| `stable-alpine`, `mainline-alpine` | x86_64, ARMv6/7 (32-bit), AArch64 (ARMv8), RISC-V64 |
| `stable-aarch64-alpine`, `mainline-aarch64-alpine` | AArch64 (ARMv8) |
| `stable-armv6-alpine`, `mainline-armv6-alpine` | ARMv6 (32-bit) |
| `stable-armv7-alpine`, `mainline-armv7-alpine` | ARMv7 (32-bit) |
| `stable-riscv64-alpine`, `mainline-riscv64-alpine` | RISC-V 64 |

---

## Stability Notice

This project is currently in an **experimental state** due to the continuously evolving BoringSSL releases and third-party module integration. Production deployments should consider testing compatibility before adoption.

---

## Features

- Based on **Alpine Linux**.
- **PCRE** with JIT enabled.
- **HTTP/2** (+NPN) support.
- **Async I/O** using threads supported.
- **Dynamic TLS record patch** for Cloudflare (enabled).
- **Gzip static `.gz` files** support enabled.
- **Brotli static `.br` files** support enabled.
  - On-the-fly Brotli compression is **disabled** (unstable).
- Based on **Official NGINX Dockerfile** and [`Wonderfall/boring-nginx`](https://github.com/Wonderfall/boring-nginx).

---

## Implementation Notes

- Recommended environment: **Linux kernel 3.17+** and the latest stable Docker version.
- BoringSSL represents **ECDH curves differently** compared to OpenSSL/LibreSSL:
  - `secp384r1` → `P-384`.
  - `X25519` is the most secure curve and should be prioritized.
  - Multiple curves can be defined via `SSL_CTX_set1_curves_list()`. Default configuration is provided in `/etc/nginx/conf/ssl_params`.
- Cipher groups can be defined using bracket notation: `[cipher1|cipher2|cipher3]`.
  - Ciphers within a group are treated as equivalent; the client selects the optimal cipher.
  - This mechanism is particularly useful for ChaCha20, while AES remains faster on hardware with AES-NI support.

---
