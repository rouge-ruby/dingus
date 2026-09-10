FROM ruby:4.0-alpine AS base

LABEL org.opencontainers.image.source=https://codeberg.org/rouge-ruby/dingus

ARG BUNDLER_VERSION=2.6.9
ENV BUNDLER_VERSION=$BUNDLER_VERSION

ARG RACK_ENV
ENV RACK_ENV=$RACK_ENV

ARG UID=1001
ARG GID=1001

ARG BIND_CONTROL=unix:/run/dingus-control.sock
ENV BIND_CONTROL=$BIND_CONTROL

ARG BIND=unix:/run/dingus.sock
ENV BIND=$BIND

ARG STDOUT_LOG=/log/puma-out.log
ENV STDOUT_LOG=$STDOUT_LOG

ARG STDERR_LOG=/log/puma-err.log
ENV STDERR_LOG=$STDERR_LOG

RUN apk add --update --no-cache \
  build-base \
  git \
  bash \
  net-tools \
  iproute2 \
  vim

RUN gem update --system \
    && gem install bundler -v "${BUNDLER_VERSION}"

RUN addgroup -g "${GID}" app \
  && adduser -D -u "${UID}" -G app -h /apphome app

USER app
WORKDIR /app

RUN bash -c '[[ "${RACK_ENV}" == "production" ]] && { \
  bundle config set --global frozen true; \
  bundle config set --global without "development test"; \
}'

CMD exec bundle exec puma \
  --no-config \
  --control-url "$BIND_CONTROL" \
  --control-token "$CONTROL_TOKEN" \
  --bind "$BIND" \
  --environment "$RACK_ENV" \
  --redirect-stdout "$STDOUT_LOG" \
  --redirect-append \
  --log-requests \
  /app/config.ru
