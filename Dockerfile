FROM ruby:3.2.2-alpine AS base

RUN apk add --update --no-cache nodejs

# This stage is responsible for installing gems
FROM base as dependencies

RUN apk add --update --no-cache build-base

COPY Gemfile Gemfile.lock ./

RUN bundle config set without development

RUN bundle check || bundle install --jobs=3 --retry=3

# This stage is what we run the app
FROM base

WORKDIR /app

COPY --from=dependencies /usr/local/bundle /usr/local/bundle

COPY . ./

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
