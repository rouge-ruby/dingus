# Rouge Dingus

The online dingus for the [Rouge](https://github.com/rouge-ruby/rouge) project.

## Deploying

This repo is designed for deployment to [Fly.io](https://fly.io). Follow the
[instruction](https://fly.io/docs/speedrun/) on the official website to setup the
CLI and launch the application.

## Contributing

We support developing both locally and via Docker container.

### Local

Install all required dependencies

```shell
bundle install
```

Run all specs

```shell
bundle exec rake test
```

Run the application

```shell
bundle exec rackup
```

## Docker container

Build a development image

```shell
make build-dev
```

Run the image and enter the shell

```shell
make shell
```

Build an application image

```shell
make build
```

Run the application

```shell
make run
```

If you've noticed a problem or would like to propose a change, we're always
happy to receive contributions.

Everyone interacting in Rouge and its sub-projects' code bases is expected to follow
the Rouge Code of Conduct.

## Development

- The online dingus was originally created by Edward Loveall (@edwardloveall).
- It was rewritten as a Sinatra app by Michael Camilleri (@pyrmont).
- It is currently maintained by Tan Le (@tancnle).

## License

Except as otherwise noted, the online dingus is released under the MIT license.
Please see the `LICENSE` file for more information.
