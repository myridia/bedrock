#!/bin/sh

# id: 22
# group: RUN
# desc: Stop - down containersx

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Stop — docker compose down (containers + network removed, volumes stay)\n"
compose down || exit 1
