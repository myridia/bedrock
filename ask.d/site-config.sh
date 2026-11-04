#!/bin/sh

# id: 5
# group: SETUP
# desc: Set WP site config

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — set WP site config\n"
