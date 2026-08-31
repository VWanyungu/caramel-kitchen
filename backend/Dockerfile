# Dockerfile — multi-stage production build

ARG ELIXIR_VERSION=1.16.3
ARG OTP_VERSION=26.2.5.21
ARG DEBIAN_VERSION=bullseye-20260824-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:bullseye-slim"

# ── Build stage ───────────────────────────────────────────────
FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && apt-get install -y \
  build-essential \
  git \
  curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Install dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile

COPY config/runtime.exs config/

RUN mix release

# ── Runner stage ───────────────────────────────────────────────
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y \
  libstdc++6 \
  openssl \
  libncurses5 \
  locales \
  ca-certificates \
  curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

ENV MIX_ENV="prod"
ENV RELEASE_DISTRIBUTION="none"

COPY --from=builder /app/_build/${MIX_ENV}/rel/caramel_kitchen ./
RUN chown -R nobody:nobody /app

USER nobody

CMD ["/app/bin/server"]

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:4000/health || exit 1
