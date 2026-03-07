FROM ruby:4.0-alpine AS base

LABEL org.opencontainers.image.source=https://github.com/rouge-ruby/dingus

ENV BUNDLER_VERSION=2.6.9

RUN gem update --system \
    && gem install bundler -v $BUNDLER_VERSION

# ---------------------------------
# This stage is responsible for installing gems
FROM base AS dep

RUN apk add --update --no-cache \
    build-base=0.5-r3

WORKDIR /app

COPY Gemfile Gemfile.lock ./

# Install core dependencies
RUN bundle config --local without development && \
    bundle install --jobs=3 --retry=3 && \
    bundle config --local frozen true

# ---------------------------------
# This stage is what we run the app
FROM base

RUN adduser -D app

WORKDIR /app

RUN apk add --update --no-cache \
  git \
  bash

USER app

COPY --from=dep /usr/local/bundle /usr/local/bundle
COPY --chown=app . ./

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
