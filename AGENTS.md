# AGENTS.md — bedrock

## What it is

**bedrocks** is a starter repository ("Bedrock starter") for the Salamander jewelry
business group. It currently contains only `LICENSE`, `.gitignore` (WordPress-flavored)
and `README.md`. No application code yet.

## Stack

- Starter stage — no stack chosen yet.

## Structure

```
bedrocks/
├── .gitignore        # WordPress-flavored starter ignore list
├── LICENSE           # GPL-3.0
├── README.md         # Bedrock starter
└── dockers/
    ├── docker-compose.yml  # Composer build + nginx/php/mariadb
    └── etc/                # nginx, php, mysql configs
└── huwi/                # Bedrock project root (created with `ask.sh` task 1)
    ├── config/            # site-wide config files (application.php etc.)
    ├── web/               # WordPress files served by nginx
    └── vendor/            # Composer dependencies
```

## Build & Run

- Task 1 (`ask.sh`): create a new site from the starter — prompts for the sitename, then runs `docker run --rm -v "$PWD:/app" composer create-project roots/bedrock <sitename>`.
- Task 2 (`ask.sh`): create `.env` for docker-compose (database credentials).
- Task 3 (`ask.sh`): composer install in site directory.
- Task 4 (`ask.sh`): bring up the stack — needs `huwi/config/application.php` available in `/usr/share/nginx/config/`.
  Fixed: added `- ../huwi/config/:/usr/share/nginx/config/` to nginx volumes in `dockers/docker-compose.yml`.
- Task 5 (`ask.sh`): WP-CLI — run `wp help` or other wp-cli commands in the php container (uses `--allow-root`). Example: `wp --allow-root core update`.

## Conventions

- Workspace-wide rules live in `~/webs/Agents/AGENTS.md`.
- README logo rule applies here (logo file: `bedrock.svg`, first README line).
- Starting/finishing work: read `~/webs/Agents/todo.md` when the trigger matches.
