FROM ruby:3.2.2-alpine AS base

LABEL org.opencontainers.image.source https://github.com/rouge-ruby/dingus

RUN apk add --update --no-cache \
    nodejs=20.10.0-r1 \
    && rm -rf /var/cache/apk/*

RUN gem install bundler --no-document --conservative --version 2.4.19

# ---------------------------------
# This stage is responsible for installing gems
FROM base as dep

RUN apk add --no-cache \
    build-base=0.5-r3

WORKDIR /app

COPY Gemfile Gemfile.lock ./

# Install core dependencies
RUN bundle config --local without development && \
    bundle install --jobs=3 --retry=3

# ---------------------------------
# This stage is what we run the app
FROM base

RUN adduser -D app

USER app

WORKDIR /app

COPY --from=dep /usr/local/bundle /usr/local/bundle
COPY --chown=app . ./

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
