#!/bin/sh

# id: 36
# group: MAINTENANCE
# desc: Export DB dump - backups/ + init/

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Maintenance — export database dump\n"

if [ -z "$(docker ps -q --filter 'name=bedrock_db' --filter 'status=running' 2>/dev/null)" ]; then
  printf "  Database container not running — starting db...\n"
  compose up -d db || { printf "  Could not start the db container.\n"; exit 1; }
fi

printf "  Waiting for the database...\n"
wait_for_db 30 || { printf "  Database not ready after 60s.\n"; exit 1; }

backup_dir="$ROOT/backups"
mkdir -p "$backup_dir" || { printf "  Cannot create %s.\n" "$backup_dir"; exit 1; }
stamp=$(date +%Y%m%d-%H%M%S)
dump="$backup_dir/bedrock-db-$stamp.sql.gz"

if compose exec -T db sh -c 'command -v mariadb-dump' >/dev/null 2>&1; then
  dumper=mariadb-dump
else
  dumper=mysqldump
fi

printf "  Dumping with %s to %s...\n" "$dumper" "$dump"
compose exec -T db sh -c "MYSQL_PWD=\"\$MYSQL_PASSWORD\" $dumper --single-transaction --routines --triggers -u\"\$MYSQL_USER\" \"\$MYSQL_DATABASE\"" | gzip -9 > "$dump" \
  || { rm -f "$dump"; printf "  Dump failed.\n"; exit 1; }

if [ ! -s "$dump" ]; then
  rm -f "$dump"
  printf "  Dump is empty — aborted.\n"
  exit 1
fi
chmod 600 "$dump"

init_dir="$ROOT/dockers/init"
mkdir -p "$init_dir" || { printf "  Cannot create %s.\n" "$init_dir"; exit 1; }
init_file="$init_dir/bedrock.sql.gz"
cp "$dump" "$init_file" || { printf "  Could not copy the dump to %s.\n" "$init_file"; exit 1; }
chmod 600 "$init_file"

printf "  Wrote %s (%s bytes).\n" "$dump" "$(wc -c < "$dump" | tr -d ' ')"
printf "  Default seed: %s — imported when an empty bedrock_db volume is first initialized.\n" "$init_file"
printf "  Restore: zcat %s | docker compose -f %s/dockers/docker-compose.yml exec -T db sh -c 'MYSQL_PWD=\$MYSQL_PASSWORD mariadb -u\$MYSQL_USER \$MYSQL_DATABASE'\n" "$dump" "$ROOT"
