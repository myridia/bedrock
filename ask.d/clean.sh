#!/bin/sh

# id: 11
# group: MAINTENANCE
# desc: Clean - down, remove volumes + images, prune

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Clean — down, remove containers/network, remove volumes (bedrock_db / bedrock_wordpress), prune dangling images\n"
printf "  Clean — remove this stack's containers/network/volumes and prune dangling images. Continue? [y/N]: "
read confirm || exit 0
case "$confirm" in
  y|Y) ;;
  *) printf "  Aborted.\n"; exit 1 ;;
esac
compose down --remove-orphans
docker image prune -f
docker volume rm bedrock_db bedrock_wordpress 2>/dev/null || printf "  Volumes (bedrock_db / bedrock_wordpress) not removed — check manually.\n"
printf "  Done. Containers, network, dangling images, and volumes removed.\n"
