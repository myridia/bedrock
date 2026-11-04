# AGENTS.md — bedrock

## What it is

**bedrocks** is the WordPress **Bedrock** starter (roots/bedrock, Composer-managed,
GPL-3.0) for the Salamander jewelry business group. The generated site lives in
`wordpress/`; a Docker stack in `dockers/` serves it.

## Stack

- WordPress via roots/bedrock (Composer, `config/` outside the web root)
- nginx + `myridia/php8.4fpm` + MariaDB + phpMyAdmin, all containers `bedrock_*`
- Table prefix `wp_` (Bedrock `DB_PREFIX` in `<site>/.env`); DB credentials come from gitignored `dockers/.env`

## Structure

```
bedrocks/
├── ask.sh              # 16-task menu (setup + run)
├── bedrock.svg         # README logo
├── LICENSE             # GPL-3.0
├── .gitignore          # WordPress + dockers/.env
├── dockers/
│   ├── docker-compose.yml
│   ├── php.ini
│   └── etc/            # nginx, phpmyadmin, mysql configs
└── wordpress/          # roots/bedrock site (created by ask.sh task 1)
    ├── config/         # application.php etc., mounted at /usr/share/nginx/config/
    ├── web/            # WordPress files served by nginx, mounted at /usr/share/nginx/html/
    └── vendor/         # Composer dependencies
```

## Build & Run

All through `ask.sh` (the user runs it, never the agent):

- 1 — create a new site from the starter (`composer create-project roots/bedrock <sitename>`, then rewrites the `../huwi/` paths in the compose file; the checked-in compose already points at `../wordpress/`)
- 2 — write two env files, both mode 600 and gitignored: `dockers/.env` (compose: DB user/password/name + MySQL root password) and `<site>/.env` (Bedrock: `DB_HOST=db`, `DB_PREFIX=wp_`, `WP_HOME`/`WP_SITEURL`, generated salts)
- 3 — `composer install` in the site directory (task 1 already did this; use it only to re-sync dependencies)
- 4 — install WP core via WP-CLI inside the php container — needs `<site>/.env` from task 2 and the stack up. WP-CLI runs with `--path=/usr/share/nginx/html/wp` (Bedrock's `wp-cli.yml` says `path: web/wp`; the core lives in `web/wp`, config in `web/`).
- 5–9 — site config, DB import/seed, host permissions, volume-mount check, open_basedir/php.ini fix
- 10 — `docker compose -f dockers/docker-compose.yml up` (refuses to start if `<site>/.env` is missing or a directory)
- 11–14 — WP-CLI in php container, status, logs, restart
- 15 — reset the database: `down`, remove the `bedrock_db` volume, so MariaDB re-creates the user from `dockers/.env` on the next start
- 16 — clean: `down --remove-orphans`, remove the `bedrock_db`/`bedrock_wordpress` volumes, and `docker image prune -f`

The nginx/php services mount `../wordpress/config/` at `/usr/share/nginx/config/`;
the php service also mounts `../wordpress/.env` at `/usr/share/nginx/.env` (Bedrock
root). Both mounts are required for the site to come up and for `wp core install`
to reach the database. Task 1's `sed` rewrites `../huwi/` paths in the compose file
to the name of the site it creates; the checked-in compose already points at
`../wordpress/`, so a differently named site needs the mounts edited by hand.

Create the site `.env` (task 2) **before** starting the stack: if the file is
missing, Docker creates an empty **directory** at that path, and a bind mount
cannot be swapped under a running container — remove the directory, rerun task 2,
then recreate the php container.

MariaDB only creates `DB_USER`/`DB_PASSWORD` when the `bedrock_db` volume is
**first initialized**. Changing credentials in `dockers/.env` later has no effect
on the existing volume (phpMyAdmin then reports `Access denied for user
'bedrock'`) — use task 15 to drop the volume and let it re-initialize.

## Conventions

- Workspace-wide rules live in `~/webs/Agents/AGENTS.md`.
- README logo rule applies here (logo file: `bedrock.svg`, first README line).
- Starting/finishing work: read `~/webs/Agents/todo.md` when the trigger matches.
