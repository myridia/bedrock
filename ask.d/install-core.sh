#!/bin/sh

# id: 4
# group: SETUP
# desc: Install WP core (WP-CLI setup)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — install WP core (WP-CLI setup)\n"
printf "  Site dir [wordpress]: "
read site_dir || exit 0
[ -n "$site_dir" ] || site_dir="wordpress"
site_path="$ROOT/$site_dir"
site_env="$site_path/.env"
if [ -d "$site_env" ]; then
  printf "  %s is a directory (Docker created it for a missing mount source) — run task 2 to replace it.\n" "$site_env"; exit 1
fi
[ -f "$site_env" ] || { printf "  No %s/.env — run task 2 first.\n" "$site_dir"; exit 1; }
printf "  Applying permissions first...\n"
chown -R 1000:33 "$site_path" 2>/dev/null || printf "  chown skipped (may need host user)\n"
chmod -R g+w "$site_path" 2>/dev/null || printf "  chmod skipped\n"
printf "  Checking containers (task 10 must be run first if not up)...\n"
docker ps --filter "name=bedrock_" --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -q 'Up' || { printf "  Containers not running — run task 10 first.\n"; exit 1; }
wp_url=$(sed -n "s/^WP_HOME='\(.*\)'/\1/p" "$site_env" | head -n1)
[ -n "$wp_url" ] || wp_url="http://localhost"
printf "  Downloading wp-cli.phar and running install for %s...\n" "$wp_url"
compose exec -T php sh -c "curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /tmp/wp-cli.phar && php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root core install --url=$wp_url --title=Bedrock --admin_user=admin --admin_password=admin --admin_email=admin@example.com" || printf "  WP install failed. Check DB/connections and retry.\n"
