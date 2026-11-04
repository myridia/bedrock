#!/bin/sh

# id: 15
# group: MAINTENANCE
# desc: Search-replace URLs (dry run + apply)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Maintenance — search-replace URLs in the database\n"

site_dir=$(site_dir_from_compose)
[ -n "$site_dir" ] || site_dir="wordpress"
site_env="$ROOT/$site_dir/.env"
[ -f "$site_env" ] || { printf "  No %s/.env — run task 2 first.\n" "$site_dir"; exit 1; }

current_url=$(sed -n "s/^WP_HOME='\(.*\)'/\1/p" "$site_env" | head -n1)
[ -n "$current_url" ] || current_url="http://localhost"

printf "  Old URL [%s]: " "$current_url"
read old_url || exit 0
[ -n "$old_url" ] || old_url=$current_url

printf "  New URL: "
read new_url || exit 0
[ -n "$new_url" ] || { printf "  New URL is required.\n"; exit 1; }
if [ "$old_url" = "$new_url" ]; then
  printf "  Old and new URL are the same.\n"; exit 1
fi

if [ -z "$(docker ps -q --filter 'name=bedrock_php' --filter 'status=running' 2>/dev/null)" ]; then
  printf "  Stack not running — starting db + php in the background...\n"
  compose up -d db php || { printf "  Could not start the containers — aborted.\n"; exit 1; }
fi
printf "  Waiting for the database...\n"
wait_for_db 30 || { printf "  Database not ready after 60s.\n"; exit 1; }

printf "  Ensuring WP-CLI in the php container...\n"
ensure_wp_cli || { printf "  Could not install WP-CLI in the php container.\n"; exit 1; }

printf "\n  Dry run: %s → %s\n\n" "$old_url" "$new_url"
wp_cli search-replace "$old_url" "$new_url" --all-tables --precise --skip-columns=guid --report-changed-only --dry-run \
  || { printf "  Dry run failed.\n"; exit 1; }

printf "\n  Apply this change? [y/N]: "
read confirm || exit 1
case "$confirm" in
  y|Y) ;;
  *) printf "  Aborted.\n"; exit 1 ;;
esac

printf "\n  Replacing %s → %s...\n\n" "$old_url" "$new_url"
wp_cli search-replace "$old_url" "$new_url" --all-tables --precise --skip-columns=guid --report-changed-only \
  || { printf "  Search-replace failed.\n"; exit 1; }

printf "\n  Done. The database now uses %s.\n" "$new_url"
printf "  For the served environment, set WP_HOME='%s' in %s and keep WP_SITEURL=\"\${WP_HOME}/wp\".\n" "$new_url" "$site_env"
