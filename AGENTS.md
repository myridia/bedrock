# AGENTS.md — bedrock

## What it is

**bedrocks** is the WordPress **Bedrock** starter (roots/bedrock, Composer-managed,
GPL-3.0) for the Salamander jewelry business group. The generated site lives in
`huwi/`; a Docker stack in `dockers/` serves it.

## Stack

- WordPress via roots/bedrock (Composer, `config/` outside the web root)
- nginx + `myridia/php8.4fpm` + MariaDB + phpMyAdmin, all containers `bedrock_*`
- Table prefix `dx36fd_`; DB credentials come from gitignored `dockers/.env`

## Structure

```
bedrocks/
├── ask.sh              # 14-task menu (setup + run)
├── bedrock.svg         # README logo
├── LICENSE             # GPL-3.0
├── .gitignore          # WordPress + dockers/.env
├── dockers/
│   ├── docker-compose.yml
│   ├── php.ini
│   └── etc/            # nginx, phpmyadmin, mysql configs
└── huwi/               # roots/bedrock site (created by ask.sh task 1)
    ├── config/         # application.php etc., mounted at /usr/share/nginx/config/
    ├── web/            # WordPress files served by nginx, mounted at /usr/share/nginx/html/
    └── vendor/         # Composer dependencies
```

## Build & Run

All through `ask.sh` (the user runs it, never the agent):

- 1 — create a new site from the starter (`composer create-project roots/bedrock <sitename>`, then rewrites the `../huwi/` paths in the compose file)
- 2 — write two env files, both mode 600 and gitignored: `dockers/.env` (compose: DB user/password/name + MySQL root password) and `<site>/.env` (Bedrock: `DB_HOST=db`, `DB_PREFIX=dx36fd_`, `WP_HOME`/`WP_SITEURL`, generated salts)
- 3 — `composer install` in the site directory (task 1 already did this; use it only to re-sync dependencies)
- 4 — install WP core via WP-CLI inside the php container — needs `<site>/.env` from task 2 and the stack up
- 5–9 — site config, DB import/seed, host permissions, volume-mount check, open_basedir/php.ini fix
- 10 — `docker compose -f dockers/docker-compose.yml up`
- 11–14 — WP-CLI in php container, status, logs, restart

The nginx/php services mount `../huwi/config/` at `/usr/share/nginx/config/`;
the php service also mounts `../huwi/.env` at `/usr/share/nginx/.env` (Bedrock
root). Both mounts are required for the site to come up and for `wp core install`
to reach the database. Task 1 rewrites the `../huwi/` paths in the compose file
to the name of the site it creates.

Create the site `.env` (task 2) **before** starting the stack: if the file is
missing, Docker creates an empty **directory** at that path, and a bind mount
cannot be swapped under a running container — remove the directory, rerun task 2,
then recreate the php container.

## Conventions

- Workspace-wide rules live in `~/webs/Agents/AGENTS.md`.
- README logo rule applies here (logo file: `bedrock.svg`, first README line).
- Starting/finishing work: read `~/webs/Agents/todo.md` when the trigger matches.
