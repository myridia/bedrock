#!/bin/sh

# id: 7
# group: SETUP
# desc: Setup permissions (host dir)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — apply host permissions (chown/chmod)\n"
site_dir=$(site_dir_from_compose)
[ -n "$site_dir" ] || site_dir="wordpress"
printf "  User runs: chown -R 1000:33 %s && chmod -R g+w %s/%s\n" "$ROOT" "$ROOT" "$site_dir"
