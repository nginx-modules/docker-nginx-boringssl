#!/usr/bin/env bash
# Parity check between two image refs (e.g. the previous single-RUN release image and a
# new multi-stage build). Compares runtime config and the filesystem (path, type, mode,
# uid:gid, size, symlink target). Exit 0 = identical, 1 = differences.
#   tools/compare-images.sh ghcr.io/nginx-modules/nginx-boringssl:mainline-alpine local/new:test
# Expected (benign) differences: the labels created/revision/base.name, the ENV/layer
# structure (new image is a single layer), and binaries' sizes if -flto=auto changes codegen.
set -euo pipefail
(( $# == 2 )) || { echo "usage: $0 <old-image> <new-image>" >&2; exit 2; }
tmp="$(mktemp -d)"; trap 'rm -rf "${tmp}"' EXIT

summarize() {  # <image> <outprefix>
  local img="$1" out="$2" cid
  docker image inspect "${img}" --format \
    '{{json .Config.Env}} {{json .Config.Cmd}} {{json .Config.Entrypoint}} {{json .Config.ExposedPorts}} {{.Config.StopSignal}} {{json .Config.User}} {{json .Config.WorkingDir}}' \
    | jq -S . 2>/dev/null > "${out}.config" || true
  docker image inspect "${img}" --format '{{json .Config.Labels}}' | jq -S . > "${out}.labels"
  docker image inspect "${img}" --format '{{len .RootFS.Layers}}' > "${out}.layers"
  cid="$(docker create "${img}")"
  docker export "${cid}" | tar --numeric-owner -tvf - \
    | awk '{ $4=""; $5=""; print }' | sort -k6 > "${out}.fs"      # drop mtime columns
  docker rm "${cid}" > /dev/null
}

summarize "$1" "${tmp}/old"; summarize "$2" "${tmp}/new"
rc=0
echo "layers: old=$(cat "${tmp}/old.layers") new=$(cat "${tmp}/new.layers")"
for k in config labels fs; do
  echo "=== ${k} ==="
  diff -u "${tmp}/old.${k}" "${tmp}/new.${k}" && echo "(identical)" || rc=1
done
exit "${rc}"
