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
├── ask.sh              # menu + dispatcher (built from ask.d/ metadata)
├── ask.d/              # task scripts by name (+ lib.sh); TaskID is metadata
├── bedrock.svg         # README logo
├── LICENSE             # GPL-3.0
├── .gitignore          # WordPress + dockers/.env
├── dockers/
│   ├── docker-compose.yml
│   ├── php.ini
│   ├── init/           # DB dumps imported when an empty bedrock_db volume starts
│   └── etc/            # nginx, phpmyadmin, mysql configs
└── wordpress/          # roots/bedrock site (created by ask.sh task 11)
    ├── config/         # application.php etc., mounted at /usr/share/nginx/config/
    ├── web/            # WordPress files served by nginx, mounted at /usr/share/nginx/html/
    └── vendor/         # Composer dependencies
```

## Build & Run

All through `ask.sh` (the user runs it, never the agent). The menu is generated from the `# id:` / `# group:` / `# desc:` metadata at the top of each `ask.d/<name>.sh`, grouped into SETUP, RUN, MAINTENANCE, and LINKS; filenames carry no number, so a task can be renumbered or run directly, e.g. `./ask.d/up.sh`.

- 11 — create a new site from the starter (`composer create-project roots/bedrock <sitename>`, then rewrites the `../huwi/` paths in the compose file; the checked-in compose already points at `../wordpress/`)
- 12 — write two env files, both gitignored: `dockers/.env` (compose: DB user/password/name + MySQL root password, mode 600) and `<site>/.env` (Bedrock: `DB_HOST=db`, `DB_PREFIX=wp_`, `WP_HOME`/`WP_SITEURL`, generated salts, mode 640 so the php-fpm `www-data` group can read it)
- 13 — `composer install` in the site directory (task 11 already did this; use it only to re-sync dependencies). Tasks 11 and 13 run Composer as the host UID with group 33 (`--user "$(id -u):33"`), so the files are not left root-owned and the site `.env` stays writable.
- 14 — install WP core via WP-CLI inside the php container — needs `<site>/.env` from task 12, but **not** a manually started stack: if `bedrock_php` is not running it starts `db` + `php` with `compose up -d`, waits up to 60 s for MariaDB, then runs WP-CLI with `--path=/usr/share/nginx/html/wp` (Bedrock's `wp-cli.yml` says `path: web/wp`; the core lives in `web/wp`, config in `web/`). It skips the install when `wp core is-installed`, then activates `twentytwentyfive` (Composer-provided), falling back to `wp theme install twentytwentyfive --activate` if missing. Run task 21 afterwards to serve the site.
- 15 — full setup in one run (all SETUP steps): `create-site` → `env-files` → `composer-install` → `up` in the background → wait for MariaDB → `install-core`. It prompts once for the site name and exports `SITE_NAME`/`SITE_DIR` so the child tasks do not ask again. An existing site directory is reused instead of failing `composer create-project`, so a partial run can be retried.
- 21 — `docker compose -f dockers/docker-compose.yml up`; asks background/foreground, background is the default (refuses to start if `<site>/.env` is missing or a directory). `./ask.d/up.sh foreground` skips the question.
- 22 — stop the stack — `docker compose down`; containers and the network are removed, volumes stay (DB is safe). Task 21 recreates everything. `down --remove-orphans` stays with tasks 35 (clean) and 34 (reset DB).
- 23 — WP-CLI in php container
- 31–33 — maintenance: status, logs, restart
- 34 — maintenance: reset the database — `down`, remove the `bedrock_db` volume, so MariaDB re-creates the user from `dockers/.env` on the next start
- 35 — maintenance: clean — `down --remove-orphans`, remove the `bedrock_db` volume, and `docker image prune -f`
- 36 — maintenance: export the database — ensures `bedrock_db` is running, waits for MariaDB, then `mariadb-dump --single-transaction --routines --triggers` piped through `gzip -9` into `backups/bedrock-db-<timestamp>.sql.gz` (mode 600). The same file is copied to `dockers/init/bedrock.sql.gz`, which MariaDB imports when an empty `bedrock_db` volume is initialized (`.sql.gz` is natively supported by the entrypoint). Both paths are gitignored; the task prints the matching restore command (`zcat`).
- 37 — maintenance: import a dump — asks the target, **docker is the default** (imports into `bedrock_db` via its `MYSQL_*` env), or `production` (asks host/port/user/password/database and uses the local `mariadb`/`mysql` client, falling back to a temporary `mariadb` container). The dump defaults to the newest `backups/*.sql{,.gz}`, and both paths confirm before overwriting. `.gz` is transparently decompressed on import.
- 38 — maintenance: URL search-replace — asks old (default: `WP_HOME` from the site `.env`) and new URL, starts `db` + `php` if needed, runs `wp search-replace --all-tables --precise --skip-columns=guid --report-changed-only` as a **dry run**, confirms, then applies. `guid` is left untouched. Remember to update `WP_HOME` in the target environment's `.env` too.
- 41–44 — links: open the site (`WP_HOME`), the admin (`/wp/wp-admin/`), the login (`/wp/wp-login.php`), or phpMyAdmin (`http://localhost:81/`) in a browser. Detection order is brave → chromium → firefox → safari, then `xdg-open` as fallback; the site URLs come from `WP_HOME` in the site `.env`.

The menu sorts by group (SETUP, RUN, MAINTENANCE, LINKS) and then by `# id:`. Each
group has its own number series: 11–15 SETUP, 21–23 RUN, 31–38 MAINTENANCE, 41–44 LINKS.

Individual tasks accept the same environment variables as the full setup where
it saves a prompt: `SITE_NAME` (create-site) and `SITE_DIR` (env-files,
composer-install, install-core). For example
`SITE_DIR=wordpress ./ask.d/env-files.sh` skips the directory question, and
`./ask.d/up.sh foreground` skips the background/foreground question.

The nginx/php services mount `../wordpress/config/` at `/usr/share/nginx/config/`;
the php service also mounts `../wordpress/.env` at `/usr/share/nginx/.env` (Bedrock
root). Both mounts are required for the site to come up and for `wp core install`
to reach the database. Task 11's `sed` rewrites the `../huwi/` or `../wordpress/` paths
in the compose file to the name of the site it creates; the checked-in compose
already points at `../wordpress/`.

Create the site `.env` (task 12) **before** starting the stack: if the file is
missing, Docker creates an empty **directory** at that path, and a bind mount
cannot be swapped under a running container — remove the directory, rerun task 12,
then recreate the php container.

MariaDB only creates `DB_USER`/`DB_PASSWORD` when the `bedrock_db` volume is
**first initialized**. Changing credentials in `dockers/.env` later has no effect
on the existing volume (phpMyAdmin then reports `Access denied for user
'bedrock'`) — use task 34 to drop the volume and let it re-initialize.

## Conventions

- Workspace-wide rules live in `~/webs/Agents/AGENTS.md`.
- README logo rule applies here (logo file: `bedrock.svg`, first README line).
- Starting/finishing work: read `~/webs/Agents/todo.md` when the trigger matches.
