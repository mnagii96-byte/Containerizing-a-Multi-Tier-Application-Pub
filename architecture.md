# Architecture

## Before: 7 VMs

The original project ran each component on its own Ubuntu VM, created with Terraform on
VMware Cloud Director and configured by hand or with scripts:

| Hostname | Role              |
|----------|-------------------|
| web01    | Nginx             |
| app01    | Tomcat 9, Java 11 |
| db01     | MariaDB           |
| mc01     | Memcached         |
| rmq01    | RabbitMQ          |
| nagios   | Nagios Core       |
| zabbix   | Zabbix server     |

## After: containers

Each VM became a container, defined in one `docker-compose.yml`.

### Networks

- `backend`: web01, app01, db01, mc01, rmq01, nagios, and zabbix (so both monitors can reach the app tier).
- `monitoring`: zabbix, zabbix-web, zabbix-db.

Containers on the same network reach each other by service name (for example `app01` connects to `db01:3306`).

### Volumes

| Volume        | Used by    | Holds                  |
|---------------|------------|------------------------|
| `db_data`     | db01       | MariaDB data           |
| `nagios_etc`  | nagios     | Nagios configuration   |
| `nagios_var`  | nagios     | Nagios state and logs  |
| `zabbix_db`   | zabbix-db  | Zabbix database        |

### Build vs pull

- **Built from a Dockerfile:** `app01` (builds the WAR with Maven, runs on Tomcat) and `web01` (Nginx with a custom proxy config).
- **Pulled as ready-made images:** everything else.

### Startup order

`app01` waits for `db01` to pass its healthcheck, so the app does not start before the database is ready.

## Key differences from the VM setup

- No manual installs or Ansible runs on each machine; the environment is rebuilt with one command.
- Configuration lives in Git alongside the code.
