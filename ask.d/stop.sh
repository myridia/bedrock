#!/bin/sh

# id: 22
# group: RUN
# desc: Stop - stop stack (containers stay)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Stop — stop the stack (containers stay)\n"
compose stop
