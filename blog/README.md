# Blog

The Phoenix LiveView application for Soliloquy.

## Prerequisites

- Elixir ≥ 1.16 — [install guide](https://elixir-lang.org/install.html)
- Node.js ≥ 18
- Docker + Docker Compose

## Setup

### 1. Start the database

```bash
docker compose up -d
```

This starts a PostgreSQL 16 container on **host port 5433**.

### 2. Install dependencies and initialise the database

```bash
mix setup
```

This runs `mix deps.get`, creates the database, runs all migrations, seeds it, and compiles the frontend assets in one step.

### 3. Start the development server

```bash
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000).

## Common commands

| Command | What it does |
|---|---|
| `mix phx.server` | Start the dev server with hot reload |
| `mix ecto.migrate` | Run pending database migrations |
| `mix ecto.gen.migration <name>` | Generate a new migration file |
| `mix ecto.reset` | Drop and recreate the database from scratch |
| `mix test` | Run the test suite |
| `mix precommit` | Compile, format, and test — run before every commit |
| `docker compose down` | Stop the PostgreSQL container |

## Configuration

| File | Purpose |
|---|---|
| `config/dev.exs` | Local development settings |
| `config/test.exs` | Test environment settings |
| `config/runtime.exs` | Production settings (reads environment variables) |

## Environment variables (production)

| Variable | Description | Default |
|---|---|---|
| `DATABASE_URL` | Ecto-style database URL (`ecto://user:pass@host/db`) | — |
| `SECRET_KEY_BASE` | Cookie signing key — generate with `mix phx.gen.secret` | — |
| `PHX_HOST` | Public hostname (e.g. `myapp.fly.dev`) | `example.com` |
| `PORT` | HTTP port | `4000` |
| `POOL_SIZE` | Database connection pool size | `10` |
| `ECTO_IPV6` | Set to `true` to force IPv6 database connections | — |
