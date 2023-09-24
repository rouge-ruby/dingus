PROJECT   ?= rouge-dingus

# Use git tags to set the version string
VERSION   ?= $(shell git describe --tags --always)
TAG       := $(VERSION)
IMAGE     := $(PROJECT):$(TAG)
PLATFORM  := linux/amd64

HOST_PORT ?= 9292

.PHONY: build-dev
build-dev: Dockerfile
	@docker buildx build --rm --platform=$(PLATFORM) \
		-t "$(IMAGE)-dev" \
		-f Dockerfile.dev .

.PHONY: build
build: Dockerfile
	@docker buildx build --rm --platform=$(PLATFORM) \
		-t "$(IMAGE)" .

.PHONY: run
run:
	@docker run --rm \
		--name $(PROJECT) \
		--publish $(HOST_PORT):9292 \
		"$(IMAGE)"

.PHONY: test
test:
	@docker run --rm -it \
		--name $(PROJECT) \
		--volume $(PWD):/app \
		"$(IMAGE)-dev" \
		bundle exec rake test

.PHONY: shell
shell:
	@docker run --rm -it \
		--name $(PROJECT) \
		--volume $(PWD):/app \
		"$(IMAGE)-dev" \
		bash
