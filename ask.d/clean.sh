#!/bin/sh

# id: 35
# group: MAINTENANCE
# desc: Clean - down, volume + prune

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Clean — down, remove containers/network, remove the bedrock_db volume, prune dangling images\n"
printf "  Clean — remove this stack's containers/network/volume and prune dangling images. Continue? [y/N]: "
read confirm || exit 0
case "$confirm" in
  y|Y) ;;
  *) printf "  Aborted.\n"; exit 1 ;;
esac
compose down --remove-orphans
docker image prune -f
docker volume rm bedrock_db 2>/dev/null || printf "  Volume bedrock_db not removed — check manually.\n"
printf "  Done. Containers, network, dangling images, and the db volume removed.\n"
