#!/bin/sh

# id: 14
# group: RUN
# desc: Restart - restart the stack

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Restart — restart the stack\n"
compose restart
