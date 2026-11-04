#!/bin/sh

# id: 8
# group: SETUP
# desc: Setup nginx/php volume mount check

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — check nginx/php volume mounts in compose\n"
