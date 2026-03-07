# SensorArray

Ecommerce analytics dashboard (Phoenix LiveView + ETS).

## Local development (Postgres via Docker)

* Copy env template and (optionally) edit: `cp .env.example .env`  
  Both the app and Docker Compose read from `.env` (Postgres credentials). Do not commit `.env`.
* Start Postgres: `docker compose up -d db`  
  If you change `POSTGRES_USER`/`POSTGRES_PASSWORD` in `.env` after the DB was already created, recreate the volume so Postgres is re-initialized: `docker compose down && docker volume rm sensor_array_pgdata && docker compose up -d db`.
* Run `mix setup` (or `mix deps.get && mix ecto.create && mix ecto.migrate && mix assets.setup && mix assets.build`)
* Start Phoenix: `mix phx.server` or `iex -S mix phx.server`

Visit [`localhost:4000`](http://localhost:4000).

## Code quality and security

* **Credo** (style and consistency): `mix credo` or `mix credo --strict`
* **Sobelow** (security): `mix sobelow` or `mix sobelow --config`
* **Dialyzer** (types): `mix dialyzer` (builds PLT on first run)
* **Precommit** (format, credo, sobelow, tests): `mix precommit`

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
