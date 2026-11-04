#!/bin/sh

# id: 14
# group: MAINTENANCE
# desc: Import DB dump (docker/production)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Maintenance — import database dump\n"

printf "  Target [docker/production] (docker): "
read target || exit 0
[ -n "$target" ] || target="docker"

latest=$(ls -1t "$ROOT"/backups/*.sql 2>/dev/null | head -n1)
if [ -n "$latest" ]; then
  printf "  Dump file [%s]: " "$latest"
else
  printf "  Dump file: "
fi
read dump || exit 0
[ -n "$dump" ] || dump=$latest
if [ -z "$dump" ]; then
  printf "  No dump file given — run the export task first.\n"; exit 1
fi
if [ ! -f "$dump" ] && [ -f "$ROOT/$dump" ]; then
  dump="$ROOT/$dump"
fi
[ -f "$dump" ] || { printf "  No such file: %s\n" "$dump"; exit 1; }
[ -s "$dump" ] || { printf "  %s is empty — aborted.\n" "$dump"; exit 1; }

confirm_import() {
  printf "  Continue? [y/N]: "
  read reply || exit 1
  case "$reply" in
    y|Y) ;;
    *) printf "  Aborted.\n"; exit 1 ;;
  esac
}

case "$target" in
  d|D|docker|Docker)
    if [ -z "$(docker ps -q --filter 'name=bedrock_db' --filter 'status=running' 2>/dev/null)" ]; then
      printf "  Database container not running — starting db...\n"
      compose up -d db || { printf "  Could not start the db container.\n"; exit 1; }
    fi
    printf "  Waiting for the database...\n"
    wait_for_db 30 || { printf "  Database not ready after 60s.\n"; exit 1; }

    db_name=$(sed -n 's/^DB_NAME=//p' "$ROOT/dockers/.env" 2>/dev/null | head -n1)
    printf "  Import %s into the docker database%s.\n" "$dump" "${db_name:+ ($db_name)}"
    printf "  Existing tables with the same names will be replaced. "
    confirm_import

    compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE"' < "$dump" \
      || { printf "  Import failed.\n"; exit 1; }
    printf "  Imported into the docker database.\n"
    ;;

  p|P|production|Production)
    printf "  DB host: "
    read db_host || exit 0
    [ -n "$db_host" ] || { printf "  Host is required.\n"; exit 1; }
    printf "  DB port [3306]: "
    read db_port || exit 0
    [ -n "$db_port" ] || db_port=3306
    printf "  DB user: "
    read db_user || exit 0
    [ -n "$db_user" ] || { printf "  User is required.\n"; exit 1; }
    printf "  DB password (empty for none): "
    read db_pass || exit 0
    printf "  DB name: "
    read db_name || exit 0
    [ -n "$db_name" ] || { printf "  Database name is required.\n"; exit 1; }

    printf "  Import %s into %s@%s:%s/%s. " "$dump" "$db_user" "$db_host" "$db_port" "$db_name"
    confirm_import

    if command -v mariadb >/dev/null 2>&1; then
      client=mariadb
    elif command -v mysql >/dev/null 2>&1; then
      client=mysql
    else
      client=""
    fi

    if [ -n "$client" ]; then
      MYSQL_PWD="$db_pass" "$client" -h "$db_host" -P "$db_port" -u "$db_user" "$db_name" < "$dump" \
        || { printf "  Import failed.\n"; exit 1; }
    else
      printf "  No local mysql client — using a temporary mariadb container.\n"
      net=""
      case "$db_host" in
        localhost|127.0.0.1) net="--network host" ;;
      esac
      docker run --rm -i $net -e MYSQL_PWD="$db_pass" mariadb:latest \
        mariadb -h "$db_host" -P "$db_port" -u "$db_user" "$db_name" < "$dump" \
        || { printf "  Import failed.\n"; exit 1; }
    fi
    printf "  Imported into the production database.\n"
    ;;

  *)
    printf "  Unknown target: %s (use docker or production).\n" "$target"; exit 1
    ;;
esac
