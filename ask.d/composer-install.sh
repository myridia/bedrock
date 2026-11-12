#!/bin/sh

# id: 3
# group: SETUP
# desc: Composer install (vendor/autoload.php)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Composer install (vendor/autoload.php)\n"
if [ -n "${SITE_DIR:-}" ]; then
  site_dir=$SITE_DIR
else
  printf "  Site directory [wordpress]: "
  read site_dir || exit 0
  [ -n "$site_dir" ] || site_dir="wordpress"
fi
site_path="$ROOT/$site_dir"
[ -f "$site_path/composer.json" ] || { printf "  No composer.json in %s — aborted.\n" "$site_dir"; exit 1; }
printf "  Running composer install in %s...\n" "$site_dir"
docker run --rm \
  --user "$(id -u):33" \
  -e COMPOSER_HOME=/tmp/composer \
  -v "$site_path:/app" \
  composer install \
  || { printf "  composer install failed — aborted.\n"; exit 1; }
