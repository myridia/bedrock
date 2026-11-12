#!/bin/sh

# id: 1
# group: SETUP
# desc: Create new site from Bedrock starter

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

if [ -n "${SITE_NAME:-}" ]; then
  sitename=$SITE_NAME
else
  printf "  Site name [wordpress]: "
  read sitename || exit 0
  [ -n "$sitename" ] || sitename="wordpress"
fi
site_path="$ROOT/$sitename"

if [ -f "$site_path/composer.json" ]; then
  printf "  Site %s already exists — skipping create-project.\n" "$sitename"
else
  printf "  Creating new site from Bedrock starter (%s)...\n" "$sitename"
  cd "$ROOT" && docker run --rm \
    --user "$(id -u):33" \
    -e COMPOSER_HOME=/tmp/composer \
    -v "$ROOT:/app" \
    composer create-project roots/bedrock "$sitename" \
    || { printf "  composer create-project failed — aborted.\n"; exit 1; }
fi

printf "  Updating docker-compose.yml to serve %s...\n" "$sitename"
sed -i "s|\.\./huwi/|../$sitename/|g; s|\.\./huwi:|../$sitename:|g; s|\.\./wordpress/|../$sitename/|g; s|\.\./wordpress:|../$sitename:|g" "$ROOT/dockers/docker-compose.yml"

printf "  Applying permissions (chown/chmod) on %s...\n" "$sitename"
chown -R "$(id -u):33" "$site_path" 2>/dev/null || printf "  chown skipped (need host user)\n"
chmod -R g+w "$site_path" 2>/dev/null || printf "  chmod skipped\n"
