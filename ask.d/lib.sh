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

wait_for_db() {
  tries=${1:-30}
  n=0
  until compose exec -T db sh -c 'mariadb-admin ping -h 127.0.0.1 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent' >/dev/null 2>&1; do
    n=$((n + 1))
    [ "$n" -lt "$tries" ] || return 1
    sleep 2
  done
}

ensure_wp_cli() {
  compose exec -T php sh -c "test -x /tmp/wp-cli.phar || (curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /tmp/wp-cli.phar)"
}

wp_cli() {
  compose exec -T php php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root "$@"
}
