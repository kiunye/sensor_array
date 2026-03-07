# Production release image (CI / Fly.io). Local dev runs app on host; use docker-compose for Postgres only.
FROM hexpm/elixir:1.17.3-erlang-27.1-alpine-3.20.3 AS build
WORKDIR /app
RUN apk add --no-cache build-base git
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
COPY . .
RUN MIX_ENV=prod mix release

FROM alpine:3.20.3
RUN apk add --no-cache libstdc++ openssl ncurses-libs
WORKDIR /app
COPY --from=build /app/_build/prod/rel/sensor_array ./
CMD ["bin/sensor_array", "start"]
