#!/bin/sh

# id: 9
# group: SETUP
# desc: Setup open_basedir / config fix

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — open_basedir / config fix (php.ini edited)\n"
