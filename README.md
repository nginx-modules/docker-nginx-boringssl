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
- **PCRE2** with JIT enabled.
- **HTTP/2** (+NPN) support.
- **Async I/O** using threads supported.
- **Dynamic TLS record patch** for Cloudflare (enabled).
* **zlib-ng** instead of **zlib**
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

---

## Supply chain

- **Signing**: every image digest (per-arch and the multi-arch index) is signed with cosign keyless (Sigstore, GitHub OIDC) on GHCR and Docker Hub. Verify:
  ```sh
  cosign verify ghcr.io/nginx-modules/nginx-boringssl:mainline-alpine \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    --certificate-identity-regexp '^https://github.com/nginx-modules/docker-nginx-boringssl/\.github/workflows/docker-image\.yml@'
  ```
- **Attestations**: buildkit provenance (`mode=max`) and an SBOM are attached to each per-arch image. The index additionally carries a signed GitHub build-provenance attestation:
  ```sh
  gh attestation verify oci://ghcr.io/nginx-modules/nginx-boringssl:mainline-alpine --repo nginx-modules/docker-nginx-boringssl
  ```
- **Metadata**: `org.opencontainers.image.created` is the commit time and `revision` the full commit SHA, both as image-config labels and as index annotations.

## Image layout and build speed

- The published image is a **single layer**: the Dockerfile builds in parallel stages (BoringSSL, nginx release, nginx debug) and the final stage is a flattened copy of the runtime root filesystem. The release workflow fails if a built image has more than one layer.
- BoringSSL lives in its own stage, so an nginx / module / patch bump does not rebuild it. Build cache is stored in GHCR (`buildcache-*` tags), and LTO uses `-flto=auto` (parallel link).
- Releases are queued, never cancelled: every commit is published in commit order, and the merge job refuses to move a tag backwards (e.g. a stale re-run of an older commit).
- `tools/compare-images.sh <old> <new>` compares runtime config and filesystem of two images (use it after changing the Dockerfile layout).

## Reproducibility

Build inputs are pinned: Alpine base digest, BoringSSL commit, ngx_brotli / headers-more / njs commits, and the dynamic-TLS patch (commit + sha256). File timestamps are clamped to the commit time (`SOURCE_DATE_EPOCH`, `rewrite-timestamp`).

**Not guaranteed bit-for-bit reproducible**: `apk add` resolves current Alpine package versions at build time. The `Reproducibility check` workflow rebuilds each release twice and reports whether the digests match and, if not, which layers differ. Treat the image as *reproducible only while that check is green*.
