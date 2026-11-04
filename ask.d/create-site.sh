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
printf "  Creating new site from Bedrock starter (%s)...\n" "$sitename"
cd "$ROOT" && docker run --rm -v "$ROOT:/app" composer create-project roots/bedrock "$sitename"
printf "  Updating docker-compose.yml to serve %s...\n" "$sitename"
sed -i "s|\.\./huwi/|../$sitename/|g; s|\.\./huwi:|../$sitename:|g; s|\.\./wordpress/|../$sitename/|g; s|\.\./wordpress:|../$sitename:|g" "$ROOT/dockers/docker-compose.yml"
printf "  Applying permissions (chown/chmod) on %s...\n" "$sitename"
chown -R 1000:33 "$ROOT/$sitename" 2>/dev/null || printf "  chown skipped (need host user)\n"
chmod -R g+w "$ROOT/$sitename" 2>/dev/null || printf "  chmod skipped\n"
