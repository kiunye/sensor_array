# SensorArray

Ecommerce analytics dashboard (Phoenix LiveView + ETS). See project root `sensor_array_PRD.md` for full spec.

## Local development (Postgres via Docker)

* Start Postgres: `docker compose up -d db`
* Optional: set `DATABASE_URL=ecto://postgres:postgres@localhost/sensor_array_dev` if not using default
* Run `mix setup` (or `mix deps.get && mix ecto.create && mix ecto.migrate && mix assets.setup && mix assets.build`)
* Start Phoenix: `mix phx.server` or `iex -S mix phx.server`

Visit [`localhost:4000`](http://localhost:4000).

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
