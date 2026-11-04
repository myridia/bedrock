#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

gen_salt() {
  head -c 48 /dev/urandom | base64 | tr -d '\n='
}

show_menu() {
  printf "%s\n" '  ┌─────┬──────────────────────────────────────────────┐'
  printf "%s\n" '  │  ID │ Description                                  │'
  printf "%s\n" '  ├─────┼──────────────────────────────────────────────┤'
  printf "%s\n" '  │     │ SETUP                                        │'
  printf "%s\n" '  │  1  │ Create new site from Bedrock starter         │'
  printf "%s\n" '  │  2  │ Create env files (dockers/.env + site .env)  │'
  printf "%s\n" '  │  3  │ Composer install (vendor/autoload.php)       │'
  printf "%s\n" '  │  4  │ Install WP core (WP-CLI setup)                     │'
  printf "%s\n" '  │  5  │ Set WP site config                           │'
  printf "%s\n" '  │  6  │ Setup DB import / seed                       │'
  printf "%s\n" '  │  7  │ Setup permissions (host dir)                 │'
  printf "%s\n" '  │  8  │ Setup nginx/php volume mount check           │'
  printf "%s\n" '  │  9  │ Setup open_basedir / config fix                    │'
  printf "%s\n" '  ├─────┼──────────────────────────────────────────────┤'
  printf "%s\n" '  │     │ RUN                                          │'
  printf "%s\n" '  │ 10  │ Up — docker compose up                       │'
  printf "%s\n" '  │ 11  │ WP-CLI — enter php container for wp-cli            │'
  printf "%s\n" '  │ 12  │ Status — show running containers             │'
  printf "%s\n" '  │ 13  │ Logs — tail nginx/php logs                   │'
  printf "%s\n" '  │ 14  │ Restart — restart the stack                  │'
  printf "%s\n" '  │ 15  │ Reset DB — drop volume, re-init from .env          │'
  printf "%s\n" '  │ 16  │ Clean — down, remove volumes + images, prune  │'
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
    printf "  Create env files — dockers/.env (compose) + <site>/.env (Bedrock)\n"
    printf "  Site directory [wordpress]: "
    read site_dir || exit 0
    [ -n "$site_dir" ] || site_dir="wordpress"
    site_path="$SCRIPT_DIR/$site_dir"
    [ -d "$site_path" ] || { printf "  No site directory %s — run task 1 first.\n" "$site_dir"; sleep 2; continue; }

    printf "  DB_USER [wordpress]: "
    read db_user || exit 0
    [ -n "$db_user" ] || db_user="wordpress"

    printf "  DB_PASSWORD [pass]: "
    read db_password || exit 0
    [ -n "$db_password" ] || db_password="pass"
    case "$db_password" in
      *"'"*) printf "  Single quotes are not supported in the password — aborted.\n"; sleep 2; continue ;;
    esac

    printf "  DB_NAME [wordpress]: "
    read db_name || exit 0
    [ -n "$db_name" ] || db_name="wordpress"

    printf "  MYSQL_ROOT_PASSWORD: "
    read mysql_root_password || exit 0
    [ -n "$mysql_root_password" ] || { printf "  Empty root password — aborted.\n"; sleep 2; continue; }

    printf "  Site URL [http://localhost]: "
    read wp_home || exit 0
    [ -n "$wp_home" ] || wp_home="http://localhost"

    db_prefix="wp_"

    env_file="$SCRIPT_DIR/dockers/.env"
    {
      printf "DB_USER=%s\n" "$db_user"
      printf "DB_PASSWORD=%s\n" "$db_password"
      printf "DB_NAME=%s\n" "$db_name"
      printf "MYSQL_ROOT_PASSWORD=%s\n" "$mysql_root_password"
    } > "$env_file"
    chmod 600 "$env_file"

    site_env="$site_path/.env"
    if [ -d "$site_env" ]; then
      rmdir "$site_env" 2>/dev/null && printf "  Removed empty directory at %s (Docker created it for a missing mount source).\n" "$site_env"
    fi
    if [ -d "$site_env" ]; then
      printf "  %s is still a directory — remove it, then rerun task 2.\n" "$site_env"; sleep 2; continue
    fi
    {
      printf "DB_NAME='%s'\n" "$db_name"
      printf "DB_USER='%s'\n" "$db_user"
      printf "DB_PASSWORD='%s'\n" "$db_password"
      printf "DB_HOST='db'\n"
      printf "DB_PREFIX='%s'\n" "$db_prefix"
      printf "WP_ENV='development'\n"
      printf "WP_HOME='%s'\n" "$wp_home"
      printf 'WP_SITEURL="${WP_HOME}/wp"\n'
      printf "AUTH_KEY='%s'\n" "$(gen_salt)"
      printf "SECURE_AUTH_KEY='%s'\n" "$(gen_salt)"
      printf "LOGGED_IN_KEY='%s'\n" "$(gen_salt)"
      printf "NONCE_KEY='%s'\n" "$(gen_salt)"
      printf "AUTH_SALT='%s'\n" "$(gen_salt)"
      printf "SECURE_AUTH_SALT='%s'\n" "$(gen_salt)"
      printf "LOGGED_IN_SALT='%s'\n" "$(gen_salt)"
      printf "NONCE_SALT='%s'\n" "$(gen_salt)"
    } > "$site_env"
    chmod 600 "$site_env"

    printf "  Wrote %s and %s (mode 600). Do not commit them.\n" "$env_file" "$site_env"
  elif [ "$task" = "3" ]; then
    printf "  Composer install (vendor/autoload.php)\n"
    printf "  Site directory [wordpress]: "
    read site_dir || exit 0
    [ -n "$site_dir" ] || site_dir="wordpress"
    site_path="$SCRIPT_DIR/$site_dir"
    [ -f "$site_path/composer.json" ] || { printf "  No composer.json in %s — aborted.\n" "$site_dir"; sleep 2; continue; }
    printf "  Running composer install in %s...\n" "$site_dir"
    docker run --rm -v "$site_path:/app" composer install
  elif [ "$task" = "4" ]; then
    printf "  Setup — install WP core (WP-CLI setup)\n"
    printf "  Site dir [wordpress]: "
    read site_dir || exit 0
    [ -n "$site_dir" ] || site_dir="wordpress"
    site_path="$SCRIPT_DIR/$site_dir"
    site_env="$site_path/.env"
    if [ -d "$site_env" ]; then
      printf "  %s is a directory (Docker created it for a missing mount source) — run task 2 to replace it.\n" "$site_env"; sleep 2; continue
    fi
    [ -f "$site_env" ] || { printf "  No %s/.env — run task 2 first.\n" "$site_dir"; sleep 2; continue; }
    printf "  Applying permissions first...\n"
    chown -R 1000:33 "$site_path" 2>/dev/null || printf "  chown skipped (may need host user)\n"
    chmod -R g+w "$site_path" 2>/dev/null || printf "  chmod skipped\n"
    printf "  Checking containers (task 10 must be run first if not up)...\n"
    docker ps --filter "name=bedrock_" --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -q 'Up' || { printf "  Containers not running — run task 10 first.\n"; sleep 2; continue; }
    wp_url=$(sed -n "s/^WP_HOME='\(.*\)'/\1/p" "$site_env" | head -n1)
    [ -n "$wp_url" ] || wp_url="http://localhost"
    printf "  Downloading wp-cli.phar and running install for %s...\n" "$wp_url"
    docker compose -f "$SCRIPT_DIR/dockers/docker-compose.yml" exec -T php sh -c "curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /tmp/wp-cli.phar && php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root core install --url=$wp_url --title=Bedrock --admin_user=admin --admin_password=admin --admin_email=admin@example.com" || printf "  WP install failed. Check DB/connections and retry.\n"
  elif [ "$task" = "5" ]; then
    printf "  Setup — set WP site config\n"
  elif [ "$task" = "6" ]; then
    printf "  Setup — DB import / seed\n"
  elif [ "$task" = "7" ]; then
    printf "  Setup — apply host permissions (chown/chmod)\n"
    printf "  User runs: chown -R 1000:33 %s && chmod -R g+w %s/huwi\n" "$SCRIPT_DIR" "$SCRIPT_DIR"
  elif [ "$task" = "8" ]; then
    printf "  Setup — check nginx/php volume mounts in compose\n"
  elif [ "$task" = "9" ]; then
    printf "  Setup — open_basedir / config fix (php.ini edited)\n"
  elif [ "$task" = "10" ]; then
    printf "  Run — Up — docker compose -f dockers/docker-compose.yml up\n"
    site_dir=$(sed -n 's|^[[:space:]]*- \.\./\([^/]*\)/\.env:.*|\1|p' "$SCRIPT_DIR/dockers/docker-compose.yml" | head -n1)
    [ -n "$site_dir" ] || site_dir="wordpress"
    if [ -d "$SCRIPT_DIR/$site_dir/.env" ]; then
      printf "  %s/.env is a directory — remove it and run task 2 first.\n" "$site_dir"; sleep 2; continue
    fi
    if [ ! -f "$SCRIPT_DIR/$site_dir/.env" ]; then
      printf "  No %s/.env — run task 2 first (Docker would create a directory at the mount path).\n" "$site_dir"; sleep 2; continue
    fi
    docker compose -f "$SCRIPT_DIR/dockers/docker-compose.yml" up
  elif [ "$task" = "11" ]; then
    printf "  Run — WP-CLI — shell in php container\n"
    printf "  Inside: php /tmp/wp-cli.phar --path=/usr/share/nginx/html/wp --allow-root <command>\n"
    docker compose -f "$SCRIPT_DIR/dockers/docker-compose.yml" exec php sh
  elif [ "$task" = "12" ]; then
    printf "  Run — Status — show running containers\n"
    docker compose -f dockers/docker-compose.yml ps
  elif [ "$task" = "13" ]; then
    printf "  Run — Logs — tail nginx/php logs\n"
    docker compose -f dockers/docker-compose.yml logs --tail=50 nginx php
  elif [ "$task" = "14" ]; then
    printf "  Run — Restart — restart the stack\n"
    docker compose -f dockers/docker-compose.yml restart
  elif [ "$task" = "15" ]; then
    printf "  Reset DB — drop the bedrock_db volume and re-init from dockers/.env\n"
    printf "  All data in the database is lost. Continue? [y/N]: "
    read confirm || exit 0
    case "$confirm" in
      y|Y) ;;
      *) printf "  Aborted.\n"; sleep 2; continue ;;
    esac
    docker compose -f "$SCRIPT_DIR/dockers/docker-compose.yml" down
    docker volume rm bedrock_db 2>/dev/null || printf "  Volume bedrock_db not removed — check 'docker volume ls'.\n"
    printf "  Remaining bedrock volumes:\n"
    docker volume ls --filter "name=bedrock" --format '  {{.Name}}'
    printf "  Done. Task 10 starts the stack again; MariaDB re-creates the user from dockers/.env.\n"
  elif [ "$task" = "16" ]; then
    printf "  Clean — down, remove containers/network, remove volumes (bedrock_db / bedrock_wordpress), prune dangling images\n"
    printf "  Clean — remove this stack's containers/network/volumes and prune dangling images. Continue? [y/N]: "
    read confirm || exit 0
    case "$confirm" in
      y|Y) ;;
      *) printf "  Aborted.\n"; sleep 2; continue ;;
    esac
    docker compose -f "$SCRIPT_DIR/dockers/docker-compose.yml" down --remove-orphans
    docker image prune -f
    docker volume rm bedrock_db bedrock_wordpress 2>/dev/null || printf "  Volumes (bedrock_db / bedrock_wordpress) not removed — check manually.\n"
    printf "  Done. Containers, network, dangling images, and volumes removed.\n"
  else
    printf "  Unknown task: %s\n" "$task"
  fi

  sleep 2
  printf "\n"
done
