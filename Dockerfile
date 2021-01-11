FROM elixir:1.11.2-alpine AS builder

RUN apk --no-cache add build-base

WORKDIR /app

ARG MAILGUN_API_KEY
ARG MAILGUN_DOMAIN

ENV MAILGUN_DOMAIN=$MAILGUN_DOMAIN \
    MAILGUN_API_KEY=$MAILGUN_API_KEY

ENV MIX_ENV=prod

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix local.rebar
RUN mix local.hex --force
RUN mix do deps.get, deps.compile

COPY ./lib ./lib
COPY ./config ./config
COPY ./priv ./priv

RUN mix release

FROM alpine:latest AS BANK

ARG DB_URL
ARG SECRET_KEY_BASE

ENV DB_URL=$DB_URL \
    SECRET_KEY_BASE=$SECRET_KEY_BASE

# Base packages
RUN apk --no-cache upgrade && \
    apk add --no-cache openssl \
    ncurses-libs postgresql-client

# Creates a non root user and creates artifact
RUN adduser -D -h home/app app
WORKDIR /home/app

COPY --from=builder /app/_build .
RUN chown -R app: ./prod
USER app

COPY ./entrypoint.sh ./

CMD ["/bin/sh", "entrypoint.sh"]
