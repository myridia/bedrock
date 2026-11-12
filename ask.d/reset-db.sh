#!/bin/sh

# id: 10
# group: MAINTENANCE
# desc: Reset DB - drop volume, re-init from .env

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Reset DB — drop the bedrock_db volume and re-init from dockers/.env\n"
printf "  All data in the database is lost. Continue? [y/N]: "
read confirm || exit 0
case "$confirm" in
  y|Y) ;;
  *) printf "  Aborted.\n"; exit 1 ;;
esac
compose down
docker volume rm bedrock_db 2>/dev/null || printf "  Volume bedrock_db not removed — check 'docker volume ls'.\n"
printf "  Remaining bedrock volumes:\n"
docker volume ls --filter "name=bedrock" --format '  {{.Name}}'
printf "  Done. Task 5 starts the stack again; MariaDB re-creates the user from dockers/.env.\n"
