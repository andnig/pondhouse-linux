---
name: pondhouse-hetzner-deploy
description: Deploy services to the Pondhouse Hetzner Docker Swarm host. Use when setting up, updating, or diagnosing services on `hetzner.pondhouse`, especially tasks involving service folders under `/data/docker/`, persistent volumes under `/data/volumes/`, Traefik labels, Artifact Registry Docker images, the shared `ph-general` Postgres server, or creating deployment scripts for Pondhouse services.
---

# Pondhouse Hetzner Deploy

## Safety Rules

- Use SSH host `hetzner.pondhouse`.
- Never stop, restart, remove, or update unrelated stacks or services.
- Do not restart `ph-general`, `ph-traefik`, or any existing service unless the user explicitly asks.
- Before changing a remote service, inspect the current files and Docker state.
- Do not print secrets. For `.env` files, list keys with `cut -d= -f1` or update them in place without displaying values.
- Use `docker stack deploy` only for the target stack. This updates services in that stack, but not unrelated stacks.
- Prefer additive setup: create `/data/docker/<service>` and `/data/volumes/<service>`; do not modify existing app directories unless requested.

## Host Layout

- Service compose folders live under `/data/docker/<service>`.
- Persistent data lives under `/data/volumes/<service>`.
- The shared infrastructure stack is in `/data/docker/general` and runs as stack `ph-general`.
- Traefik config lives in `/data/docker/traefik` and runs as stack `ph-traefik`.
- Common external Docker networks:
  - `services`: internal service network, used for app-to-Postgres/Redis/internal-service access.
  - `traefik-public`: public routing network, used by services exposed through Traefik.

Useful inspection commands:

```bash
ssh hetzner.pondhouse 'docker stack ls; docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
ssh hetzner.pondhouse 'ls -la /data/docker; ls -la /data/volumes'
ssh hetzner.pondhouse 'docker network ls --format "{{.Name}}" | sort'
```

## Image Conventions

- Main registry prefix: `europe-west3-docker.pkg.dev/pondhouse-docs/pondhouse-docs-general`.
- Prefer service-specific image names: `<registry>/<service>:<tag>`.
- For split frontend/backend services, use `<service>-web:<tag>` and `<service>-api:<tag>`.
- Production release tags should be immutable, usually `vYYYYMMDD-N` or `vYYYYMMDD-HHMMSS`.
- Existing beta/internal images may use `beta-N`; keep the service's existing convention unless creating a new convention.
- Avoid deploying mutable `latest` unless the user explicitly wants it.

Build/push pattern:

```bash
tag="v$(date +%Y%m%d-%H%M%S)"
registry="europe-west3-docker.pkg.dev/pondhouse-docs/pondhouse-docs-general"
docker build -f Dockerfile -t "$registry/<service>:$tag" .
docker push "$registry/<service>:$tag"
```

## Compose Pattern

Store the stack file at `/data/docker/<service>/docker-compose.yml` and private environment at `/data/docker/<service>/.env`.

Single HTTP service exposed via Traefik:

```yaml
version: "3.8"

services:
  app:
    image: ${APP_IMAGE}
    env_file:
      - .env
    networks:
      - services
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.<service>.rule=Host(`<domain>`)"
        - "traefik.http.routers.<service>.entrypoints=websecure"
        - "traefik.http.routers.<service>.tls.certresolver=letsencrypt"
        - "traefik.http.services.<service>.loadbalancer.server.port=<container-port>"
      restart_policy:
        condition: on-failure

networks:
  services:
    external: true
  traefik-public:
    external: true
```

Split web/API on one domain:

```yaml
services:
  web:
    image: ${APP_WEB_IMAGE}
    networks:
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.<service>-web.rule=Host(`<domain>`)"
        - "traefik.http.routers.<service>-web.entrypoints=websecure"
        - "traefik.http.routers.<service>-web.tls.certresolver=letsencrypt"
        - "traefik.http.routers.<service>-web.priority=1"
        - "traefik.http.services.<service>-web.loadbalancer.server.port=3000"

  api:
    image: ${APP_API_IMAGE}
    env_file:
      - .env
    networks:
      - services
      - traefik-public
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.<service>-api.rule=Host(`<domain>`) && (PathPrefix(`/api`) || Path(`/health`))"
        - "traefik.http.routers.<service>-api.entrypoints=websecure"
        - "traefik.http.routers.<service>-api.tls.certresolver=letsencrypt"
        - "traefik.http.routers.<service>-api.priority=100"
        - "traefik.http.services.<service>-api.loadbalancer.server.port=3001"
```

Use one domain when the app uses cookie auth and the web app can call the API on the same origin. Use two domains only when the service explicitly supports cross-site cookies/CORS.

Deploy only the target stack:

```bash
ssh hetzner.pondhouse 'cd /data/docker/<service>; set -a; . ./.env; set +a; docker stack deploy -c docker-compose.yml <service>; docker stack services <service>'
```

## Shared Postgres

The general-purpose Postgres service runs in stack `ph-general` as service/container name pattern `ph-general_postgres-gp`. It is reachable from services on the `services` network as:

```text
ph-general_postgres-gp:5432
```

Use a dedicated database per app. Prefer two roles:

- owner/migration role: `<service>`
- runtime role: `<service>_app`

Application env convention:

```env
DATABASE_URL=postgresql://<service>_app:<runtime-password>@ph-general_postgres-gp:5432/<service-db>
MIGRATION_DATABASE_URL=postgresql://<service>:<owner-password>@ph-general_postgres-gp:5432/<service-db>
```

Create or verify database and roles by execing into the existing Postgres container. Do not restart Postgres.

```bash
ssh hetzner.pondhouse 'set -euo pipefail
cid=$(docker ps --filter name=ph-general_postgres-gp --format "{{.ID}}" | sed -n "1p")
docker exec -i "$cid" sh -lc '\''psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'\'' <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '\''<service>'\'') THEN
    CREATE ROLE <service> LOGIN PASSWORD '\''<owner-password>'\'' NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE INHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '\''<service>_app'\'') THEN
    CREATE ROLE <service>_app LOGIN PASSWORD '\''<runtime-password>'\'' NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE INHERIT;
  END IF;
END
\$\$;
SELECT '\''CREATE DATABASE <service-db> OWNER <service>'\'' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '\''<service-db>'\'')\gexec
\connect <service-db>
GRANT CONNECT ON DATABASE <service-db> TO <service>_app;
GRANT USAGE ON SCHEMA public TO <service>_app;
GRANT USAGE, CREATE ON SCHEMA public TO <service>;
ALTER DEFAULT PRIVILEGES FOR ROLE <service> IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO <service>_app;
ALTER DEFAULT PRIVILEGES FOR ROLE <service> IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO <service>_app;
SQL'
```

If migrations must run from an image before the app joins the `services` overlay network, use `--network host` and override DB host to `127.0.0.1` because Postgres publishes port `5432` on the host:

```bash
ssh hetzner.pondhouse 'docker run --rm --network host --env-file /data/docker/<service>/.env \
  -e MIGRATION_DATABASE_URL="postgresql://<service>:<owner-password>@127.0.0.1:5432/<service-db>" \
  -e DATABASE_URL="postgresql://<service>_app:<runtime-password>@127.0.0.1:5432/<service-db>" \
  <image> <migration-command>'
```

## Setup Workflow

1. Inspect existing stacks, networks, and matching service examples such as `/data/docker/invoice/docker-compose.yml`.
2. Create `/data/docker/<service>` and `/data/volumes/<service>` as needed.
3. Build and push immutable Docker image tags.
4. Create `.env` without printing secrets.
5. Create the app database and roles in `ph-general_postgres-gp`.
6. Write `docker-compose.yml` with Traefik labels and external networks.
7. Run migrations, if required.
8. Deploy only the target stack with `docker stack deploy`.
9. Verify with `docker stack services <service>`, public `https://<domain>/health` if available, and service logs.

Verification commands:

```bash
ssh hetzner.pondhouse 'docker stack services <service>; docker stack ps <service> --no-trunc | sed -n "1,20p"'
curl -fsS https://<domain>/health
ssh hetzner.pondhouse 'docker service logs <service>_<app-service> --since 5m 2>&1 || true'
```
