#!/bin/sh

# id: 3
# group: SETUP
# desc: Composer install (vendor/autoload.php)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Composer install (vendor/autoload.php)\n"
printf "  Site directory [wordpress]: "
read site_dir || exit 0
[ -n "$site_dir" ] || site_dir="wordpress"
site_path="$ROOT/$site_dir"
[ -f "$site_path/composer.json" ] || { printf "  No composer.json in %s — aborted.\n" "$site_dir"; exit 1; }
printf "  Running composer install in %s...\n" "$site_dir"
docker run --rm -v "$site_path:/app" composer install
