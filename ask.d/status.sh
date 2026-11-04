#!/bin/sh

# id: 7
# group: MAINTENANCE
# desc: Status - show running containers

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Status — show running containers\n"
compose ps
