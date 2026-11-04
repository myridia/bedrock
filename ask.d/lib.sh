#!/bin/sh

gen_salt() {
  head -c 48 /dev/urandom | base64 | tr -d '\n='
}

compose() {
  docker compose -f "$ROOT/dockers/docker-compose.yml" "$@"
}

site_dir_from_compose() {
  sed -n 's|^[[:space:]]*- \.\./\([^/]*\)/\.env:.*|\1|p' "$ROOT/dockers/docker-compose.yml" | head -n1
}
