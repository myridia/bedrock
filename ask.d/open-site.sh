#!/bin/sh

# id: 41
# group: LINKS
# desc: Open site in browser

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

site_dir=$(site_dir_from_compose)
[ -n "$site_dir" ] || site_dir="wordpress"
site_env="$ROOT/$site_dir/.env"
[ -f "$site_env" ] || { printf "  No %s — run task 12 first.\n" "$site_env"; exit 1; }

wp_home=$(site_env_value WP_HOME "$site_env")
[ -n "$wp_home" ] || wp_home="http://localhost"

printf "  Open — site — %s\n" "$wp_home"
open_url "$wp_home"
