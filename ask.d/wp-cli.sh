#!/bin/sh

# id: 6
# group: RUN
# desc: WP-CLI - enter php container

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Run — WP-CLI — shell in php container\n"
printf "  Inside: php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root <command>\n"
compose exec php sh
