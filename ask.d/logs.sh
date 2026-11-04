#!/bin/sh

# id: 8
# group: MAINTENANCE
# desc: Logs - tail nginx/php logs

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — Logs — tail nginx/php logs\n"
compose logs --tail=50 nginx php
