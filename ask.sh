#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

show_menu() {
  printf "%s\n" '  ┌─────┬──────────────────────────────────────────────┐'
  printf "%s\n" '  │  ID │ Description                                  │'
  printf "%s\n" '  ├─────┼──────────────────────────────────────────────┤'
  printf "%s\n" '  │  1  │ Create new site from Bedrock starter         │'
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
  else
    printf "  Unknown task: %s\n" "$task"
  fi

  sleep 2
  printf "\n"
done
