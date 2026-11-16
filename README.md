# VProfile on Docker: Multi-Tier Java Web App with Monitoring

This project moves a multi-tier Java web application, originally deployed on 7 separate VMs
(provisioned with Terraform on VMware Cloud Director), to Docker containers managed by a single
`docker-compose.yml`.

## Architecture

| Service      | Image / Build              | Role                              | Port (host) |
|--------------|----------------------------|-----------------------------------|-------------|
| `web01`      | Build `./web01` (Nginx)    | Reverse proxy, front door         | 80          |
| `app01`      | Build `./app01` (Tomcat 9) | Java application (VProfile)       | internal    |
| `db01`       | `mariadb:10.11`            | MariaDB database                  | internal    |
| `mc01`       | `memcached:1.6`            | Caching layer                     | internal    |
| `rmq01`      | `rabbitmq:3-management`    | Message broker                    | 15672       |
| `nagios`     | `jasonrivers/nagios`       | Nagios monitoring                 | 8081        |
| `zabbix`     | `zabbix/zabbix-server-mysql` | Zabbix server                   | 10051       |
| `zabbix-web` | `zabbix/zabbix-web-nginx-mysql` | Zabbix web UI                | 8082        |
| `zabbix-db`  | `mysql:8.4`                | Zabbix database                   | internal    |

Request flow: `User -> web01 (Nginx) -> app01 (Tomcat) -> db01 / mc01 / rmq01`

Service names match the original VM hostnames, so the application's
`application.properties` works without changes.

See [docs/architecture.md](docs/architecture.md) for details.

## Project structure

```
.
├── docker-compose.yml
├── .env.example
├── .gitignore
├── app01/
│   └── Dockerfile
├── web01/
│   ├── Dockerfile
│   └── nginx.conf
├── db01/
│   └── db_backup.sql
└── docs/
    ├── architecture.md
    └── troubleshooting.md
```

## Prerequisites

- Docker Engine and Docker Compose v2
- Internet access (to pull images and clone the application source)
- `db01/db_backup.sql` is included in this repo (taken from the
  [vprofile-project](https://github.com/hkhcoder/vprofile-project) repo)

## Quick start

```bash
git clone <your-repo-url>
cd <your-repo>

# Optional: set your own passwords (defaults work for a lab)
cp .env.example .env

# Build and start everything
docker compose up -d --build

# Check status
docker compose ps
```

The first run takes a few minutes (image downloads and a Maven build).

## Access

| Service  | URL                         | Default login            |
|----------|-----------------------------|--------------------------|
| App      | `http://<host>/`            | `admin_vp` / `admin_vp`  |
| Nagios   | `http://<host>:8081`        | `nagiosadmin` / `nagios` |
| Zabbix   | `http://<host>:8082`        | `Admin` / `zabbix`       |
| RabbitMQ | `http://<host>:15672`       | `test` / `test`          |

Change all default credentials before using this outside a lab.

## Common commands

```bash
docker compose logs -f app01     # follow logs of one service
docker compose restart web01     # restart one service
docker compose down              # stop and remove containers (keeps data)
docker compose down -v           # stop and also delete data volumes
```

## Notes

- The database schema is loaded only on the first start, when the `db_data` volume is empty.
- Nagios starts with sample config; add your hosts in the `nagios_etc` volume.
- Passwords come from `.env` (copy `.env.example`). Without a `.env`, lab defaults are used. `.env` is git-ignored.
- The app's DB and RabbitMQ credentials are baked into the VProfile source (`admin/admin123`, `test/test`). If you change `DB_USER`, `DB_PASSWORD`, `RABBITMQ_USER` or `RABBITMQ_PASSWORD`, the app must be rebuilt with matching settings.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).
