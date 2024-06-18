FROM ruby:3.3.3-alpine AS base

LABEL org.opencontainers.image.source https://github.com/rouge-ruby/dingus

RUN apk add --update --no-cache \
    nodejs=20.13.1-r0 \
    && rm -rf /var/cache/apk/*

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
