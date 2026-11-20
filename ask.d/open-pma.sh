#!/bin/sh

# id: 44
# group: LINKS
# desc: Open phpMyAdmin in browser

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

url="http://localhost:81/"

printf "  Open — phpMyAdmin — %s\n" "$url"
open_url "$url"
