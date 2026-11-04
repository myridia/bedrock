#!/bin/sh

# id: 12
# group: SETUP
# desc: Full setup (site, env, stack, core)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Full setup — create site, env files, composer, stack, WP core\n"
if [ -n "${SITE_NAME:-}" ]; then
  site_name=$SITE_NAME
else
  printf "  Site name [wordpress]: "
  read site_name || exit 0
  [ -n "$site_name" ] || site_name="wordpress"
fi
SITE_NAME=$site_name
SITE_DIR=$site_name
export SITE_NAME SITE_DIR

sh "$ROOT/ask.d/create-site.sh" || exit 1
sh "$ROOT/ask.d/env-files.sh" || exit 1
sh "$ROOT/ask.d/composer-install.sh" || exit 1
sh "$ROOT/ask.d/up.sh" background || exit 1

sh "$ROOT/ask.d/install-core.sh" || exit 1
