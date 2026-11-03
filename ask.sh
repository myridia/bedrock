#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

show_menu() {
  printf "%s\n" '  ┌─────┬──────────────────────────────────────────────┐'
  printf "%s\n" '  │  ID │ Description                                  │'
  printf "%s\n" '  ├─────┼──────────────────────────────────────────────┤'
  printf "%s\n" '  │  1  │ Create new site from Bedrock starter         │'
  printf "%s\n" '  │  2  │ Create .env for docker-compose               │'
  printf "%s\n" '  │  3  │ Up — docker compose up                       │'
  printf "%s\n" '  │  4  │ Composer install (vendor/autoload.php)       │'
  printf "%s\n" '  │  0  │ Exit                                         │'
  printf "%s\n" '  └─────┴──────────────────────────────────────────────┘'
}

printf "\n  bedrock — Task Runner\n\n"

while true; do
  show_menu

  printf "  Enter Task ID: "
  read task || exit 0

  if [ "$task" = "0" ]; then
    printf "  Goodbye!\n"
    exit 0
  fi

  if [ "$task" = "1" ]; then
    printf "  Site name: "
    read sitename || exit 0
    [ -n "$sitename" ] || { printf "  No name given — aborted.\n"; sleep 2; continue; }
    printf "  Creating new site from Bedrock starter (%s)...\n" "$sitename"
    cd "$SCRIPT_DIR" && docker run --rm -v "$PWD:/app" composer create-project roots/bedrock "$sitename"
    printf "  Updating docker-compose.yml to serve %s...\n" "$sitename"
    sed -i "s|../huwi/|../$sitename/|g; s|../huwi:|../$sitename:|g" "$SCRIPT_DIR/dockers/docker-compose.yml"
  elif [ "$task" = "2" ]; then
    printf "  Create .env for docker-compose (dockers/.env)\n"
    env_file="$SCRIPT_DIR/dockers/.env"

    printf "  DB_USER [bedrock]: "
    read db_user || exit 0
    [ -n "$db_user" ] || db_user="bedrock"

    printf "  DB_PASSWORD: "
    read db_password || exit 0

    printf "  DB_NAME [bedrock]: "
    read db_name || exit 0
    [ -n "$db_name" ] || db_name="bedrock"

    printf "  MYSQL_ROOT_PASSWORD: "
    read mysql_root_password || exit 0

    {
      printf "DB_USER=%s\n" "$db_user"
      printf "DB_PASSWORD=%s\n" "$db_password"
      printf "DB_NAME=%s\n" "$db_name"
      printf "MYSQL_ROOT_PASSWORD=%s\n" "$mysql_root_password"
    } > "$env_file"

    chmod 600 "$env_file"
    printf "  Wrote %s (mode 600). Do not commit it.\n" "$env_file"
  elif [ "$task" = "3" ]; then
    printf "  Up — docker compose -f dockers/docker-compose.yml up\n"
    docker compose -f dockers/docker-compose.yml up
  elif [ "$task" = "4" ]; then
    printf "  Composer install (vendor/autoload.php)\n"
    printf "  Site directory [huwi]: "
    read site_dir || exit 0
    [ -n "$site_dir" ] || site_dir="huwi"
    site_path="$SCRIPT_DIR/$site_dir"
    [ -f "$site_path/composer.json" ] || { printf "  No composer.json in %s — aborted.\n" "$site_dir"; sleep 2; continue; }
    printf "  Running composer install in %s...\n" "$site_dir"
    docker run --rm -v "$site_path:/app" composer install
  else
    printf "  Unknown task: %s\n" "$task"
  fi

  sleep 2
  printf "\n"
done
