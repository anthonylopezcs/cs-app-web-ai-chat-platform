# Levantar Scoops XI en local con Docker

Esta guía usa el Compose de desarrollo del repositorio. Construye este fork. No uses `docker-compose.production.yaml`: esa receta descarga la imagen pública `chatwoot/chatwoot:latest` y no corre este código.

Hace falta Docker Desktop (o Docker Engine) con el comando `docker compose`.

## 1. Variables de entorno

En la raíz del repositorio:

```bash
cp .env.example .env
openssl rand -hex 64
```

Pega el resultado de `openssl` en `SECRET_KEY_BASE`. Deja el resto de estas claves así:

```bash
FRONTEND_URL=http://localhost:3000
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DATABASE=chatwoot_dev
REDIS_PASSWORD=redis
REDIS_URL=redis://:redis@redis:6379
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
RAILS_ENV=development
```

`.env` no se commitea.

Sin `POSTGRES_PASSWORD`, la imagen de Postgres no arranca. Sin `REDIS_PASSWORD`, el comando de Redis recibe un `--requirepass` vacío y también falla. `REDIS_URL` tiene que llevar la misma clave (`:redis` entre `redis://` y `@`).

## 2. Postgres en el Compose

`docker-compose.yaml` ya deja Postgres así. Si lo cambias, estos valores tienen que seguir coincidiendo con el `.env`:

```yaml
  postgres:
    image: pgvector/pgvector:pg16
    restart: always
    ports:
      - '5432:5432'
    volumes:
      - postgres:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot_dev
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
```

`POSTGRES_PASSWORD` y `POSTGRES_DB` tienen que coincidir con `POSTGRES_PASSWORD` y `POSTGRES_DATABASE` del `.env`. Redis ya lee `REDIS_PASSWORD` desde `.env`; no hace falta tocarlo.

## 3. Construir y levantar

Desde la raíz del repositorio:

```bash
docker compose up --build
```

La primera vez tarda: compila la imagen de Ruby, instala las gemas y corre `pnpm install` en Vite. Postgres, Redis, Mailhog, Sidekiq, Vite y Rails quedan en marcha.

Cuando el contenedor `rails` ya está arriba y el log dice que la base acepta conexiones:

```bash
docker compose exec rails bundle exec rails db:chatwoot_prepare
```

Ese comando crea el esquema y carga el seed de desarrollo. Hay que ejecutarlo una vez por base nueva. Si el contenedor `rails` todavía no existe, espera a que `docker compose up` lo deje en running y vuelve a lanzarlo.

## 4. Entrar

| Qué | Dónde |
| --- | --- |
| Aplicación | http://localhost:3000 |
| Usuario | `john@acme.inc` |
| Contraseña | `Password1!` |
| Correo de desarrollo | http://localhost:8025 |
| Vite | http://localhost:3036 |

El usuario es super admin de la instalación y administrador de la cuenta Acme Inc. El seed también crea un inbox de widget web.

## 5. Parar y volver a levantar

```bash
docker compose down
```

Los volúmenes de Postgres, Redis y dependencias se conservan. La siguiente vez basta con:

```bash
docker compose up
```

No hace falta repetir `db:chatwoot_prepare` si el volumen de Postgres sigue ahí.

Para borrar también los datos:

```bash
docker compose down -v
```

Después hay que repetir el `up` y `db:chatwoot_prepare`.

## Puertos que ocupa

`3000` (Rails), `3036` (Vite), `5432` (Postgres), `6379` (Redis), `1025` y `8025` (Mailhog). Si alguno ya está en uso en la máquina, el contenedor correspondiente no arranca.
