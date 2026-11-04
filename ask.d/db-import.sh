#!/bin/sh

# id: 6
# group: SETUP
# desc: Setup DB import / seed

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Setup — DB import / seed\n"
