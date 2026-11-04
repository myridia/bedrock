#!/bin/sh

# id: 5
# group: RUN
# desc: Up - start stack (background default)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Up — docker compose up (background default)\n"
site_dir=$(site_dir_from_compose)
[ -n "$site_dir" ] || site_dir="wordpress"
if [ -d "$ROOT/$site_dir/.env" ]; then
  printf "  %s/.env is a directory — remove it and run task 2 first.\n" "$site_dir"; exit 1
fi
if [ ! -f "$ROOT/$site_dir/.env" ]; then
  printf "  No %s/.env — run task 2 first (Docker would create a directory at the mount path).\n" "$site_dir"; exit 1
fi

mode=${1:-}
if [ -z "$mode" ]; then
  printf "  Mode [background/foreground] (background): "
  read mode || exit 0
fi
case "$mode" in
  f|F|foreground|Foreground) compose up ;;
  *) compose up -d ;;
esac
