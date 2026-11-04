#!/bin/sh

# id: 2
# group: SETUP
# desc: Create env files (dockers/.env + site .env)

TASK_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TASK_DIR/.." && pwd)
. "$ROOT/ask.d/lib.sh"

printf "  Create env files — dockers/.env (compose) + <site>/.env (Bedrock)\n"
if [ -n "${SITE_DIR:-}" ]; then
  site_dir=$SITE_DIR
else
  printf "  Site directory [wordpress]: "
  read site_dir || exit 0
  [ -n "$site_dir" ] || site_dir="wordpress"
fi
site_path="$ROOT/$site_dir"
[ -d "$site_path" ] || { printf "  No site directory %s — run task 1 first.\n" "$site_dir"; exit 1; }

printf "  DB_USER [wordpress]: "
read db_user || exit 0
[ -n "$db_user" ] || db_user="wordpress"

printf "  DB_PASSWORD [pass]: "
read db_password || exit 0
[ -n "$db_password" ] || db_password="pass"
case "$db_password" in
  *"'"*) printf "  Single quotes are not supported in the password — aborted.\n"; exit 1 ;;
esac

printf "  DB_NAME [wordpress]: "
read db_name || exit 0
[ -n "$db_name" ] || db_name="wordpress"

printf "  MYSQL_ROOT_PASSWORD [pass]: "
read mysql_root_password || exit 0
[ -n "$mysql_root_password" ] || mysql_root_password="pass"

printf "  Site URL [http://localhost]: "
read wp_home || exit 0
[ -n "$wp_home" ] || wp_home="http://localhost"

db_prefix="wp_"

env_file="$ROOT/dockers/.env"
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
  printf "  %s is still a directory — remove it, then rerun task 2.\n" "$site_env"; exit 1
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
chmod 640 "$site_env"

printf "  Wrote %s (mode 600) and %s (mode 640). Do not commit them.\n" "$env_file" "$site_env"
