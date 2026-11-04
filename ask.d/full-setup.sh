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

sh "$ROOT/ask.d/install-core.sh" || exit 1
