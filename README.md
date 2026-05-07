# Soliloquy

A personal blog application built with Elixir, Phoenix LiveView, and PostgreSQL.

## Stack

| Layer | Technology |
|---|---|
| Language | Elixir 1.19+ / Erlang OTP 28 |
| Web framework | Phoenix 1.8 |
| Real-time UI | Phoenix LiveView |
| Database | PostgreSQL 16 (Docker) |
| ORM | Ecto |
| CSS | Tailwind CSS v4 |
| Icons | Heroicons v2 |
| HTTP server | Bandit |

## Project layout

```
soliloquy/
└── blog/        # The Phoenix application
```

## Prerequisites

- Elixir ≥ 1.16 — [install guide](https://elixir-lang.org/install.html)
- Node.js ≥ 18
- Docker + Docker Compose

## Getting started

### 1. Start the database

```bash
cd blog
docker compose up -d
```

The PostgreSQL container runs on **host port 5433** (the host's native PostgreSQL on 5432 is left untouched).

### 2. Install dependencies and set up the database

```bash
mix setup
```

This single command runs `mix deps.get`, creates the database, runs migrations, seeds it, and compiles the frontend assets.

### 3. Start the development server

```bash
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000).

## Useful commands

| Command | What it does |
|---|---|
| `mix phx.server` | Start the dev server with hot reload |
| `mix ecto.migrate` | Run pending database migrations |
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

In production the app expects the following environment variables:

- `DATABASE_URL` — full Ecto-style database URL (`ecto://user:pass@host/db`)
- `SECRET_KEY_BASE` — generated with `mix phx.gen.secret`
- `PHX_HOST` — the public hostname (e.g. `myapp.fly.dev`)
- `PORT` — HTTP port (default `4000`)
- `POOL_SIZE` — database connection pool size (default `10`)
- `ECTO_IPV6` — set to `true` to force IPv6 connections
