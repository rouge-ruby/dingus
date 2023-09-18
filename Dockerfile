FROM ruby:3.2.2-alpine AS base

LABEL org.opencontainers.image.source https://github.com/rouge-ruby/dingus

RUN apk add --update --no-cache nodejs \
    && rm -rf /var/cache/apk/*

# This stage is responsible for installing gems
FROM base as dependencies

RUN apk add --no-cache build-base

COPY Gemfile Gemfile.lock ./

RUN bundle config set without development

RUN bundle check || bundle install --jobs=3 --retry=3

# This stage is what we run the app
FROM base

RUN adduser -D app

USER app

WORKDIR /app

COPY --from=dependencies /usr/local/bundle /usr/local/bundle

COPY --chown=app . ./

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
