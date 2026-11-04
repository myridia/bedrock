#!/bin/sh

# id: 4
# group: SETUP
# desc: Install WP core + default theme

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — install WP core + default theme\n"
if [ -n "${SITE_DIR:-}" ]; then
  site_dir=$SITE_DIR
else
  printf "  Site dir [wordpress]: "
  read site_dir || exit 0
  [ -n "$site_dir" ] || site_dir="wordpress"
fi
site_path="$ROOT/$site_dir"
site_env="$site_path/.env"
if [ -d "$site_env" ]; then
  printf "  %s is a directory (Docker created it for a missing mount source) — run task 2 to replace it.\n" "$site_env"; exit 1
fi
[ -f "$site_env" ] || { printf "  No %s/.env — run task 2 first.\n" "$site_dir"; exit 1; }
printf "  Applying permissions first...\n"
chown -R "$(id -u):33" "$site_path" 2>/dev/null || printf "  chown skipped (may need host user)\n"
chmod -R g+w "$site_path" 2>/dev/null || printf "  chmod skipped\n"

if [ -z "$(docker ps -q --filter 'name=bedrock_php' --filter 'status=running' 2>/dev/null)" ]; then
  printf "  Stack not running — starting db + php in the background...\n"
  compose up -d db php || { printf "  Could not start the containers — aborted.\n"; exit 1; }
fi

printf "  Waiting for the database...\n"
n=0
until compose exec -T db sh -c 'mariadb-admin ping -h 127.0.0.1 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent' >/dev/null 2>&1; do
  n=$((n + 1))
  if [ "$n" -ge 30 ]; then
    printf "  Database not ready after 60s.\n"
    exit 1
  fi
  sleep 2
done

wp_url=$(sed -n "s/^WP_HOME='\(.*\)'/\1/p" "$site_env" | head -n1)
[ -n "$wp_url" ] || wp_url="http://localhost"

printf "  Ensuring WP-CLI in the php container...\n"
compose exec -T php sh -c "test -x /tmp/wp-cli.phar || (curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /tmp/wp-cli.phar)" \
  || { printf "  Could not install WP-CLI in the php container.\n"; exit 1; }

wp="php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root"

if compose exec -T php sh -c "$wp core is-installed" >/dev/null 2>&1; then
  printf "  WP core is already installed — skipping core install.\n"
else
  printf "  Installing WP core for %s...\n" "$wp_url"
  compose exec -T php sh -c "$wp core install --url=$wp_url --title=Bedrock --admin_user=admin --admin_password=admin --admin_email=admin@example.com" \
    || { printf "  WP install failed. Check DB/connections and retry.\n"; exit 1; }
fi

printf "  Activating default theme (twentytwentyfive)...\n"
compose exec -T php sh -c "$wp theme activate twentytwentyfive || $wp theme install twentytwentyfive --activate" \
  || { printf "  Theme install/activate failed. Check network and wp-content permissions.\n"; exit 1; }

printf "  Done. Run task 5 to serve the site if the full stack is not up yet.\n"
