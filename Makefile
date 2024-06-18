PROJECT   ?= rouge-dingus

# Use git tags to set the version string
VERSION   ?= $(shell git describe --tags --always)
TAG       := $(VERSION)
DEV_TAG   ?= dev
IMAGE     := $(PROJECT):$(TAG)
PLATFORM  := linux/amd64

HOST_PORT ?= 9292

.PHONY: build-dev
build-dev: Dockerfile
	@docker buildx build --rm --platform=$(PLATFORM) \
		-t "$(PROJECT):$(DEV_TAG)" \
		-f Dockerfile.dev .

.PHONY: build
build: Dockerfile
	@docker buildx build --rm --platform=$(PLATFORM) \
		-t "$(IMAGE)" .

.PHONY: run
run:
	@docker run --rm \
		--platform=$(PLATFORM) \
		--name $(PROJECT) \
		--publish $(HOST_PORT):9292 \
		"$(IMAGE)"

.PHONY: test
test:
	@docker run --rm -it \
		--platform=$(PLATFORM) \
		--name $(PROJECT) \
		--volume $(PWD):/app \
		"$(PROJECT):$(DEV_TAG)" \
		bundle exec rake test

.PHONY: shell
shell:
	@docker run --rm -it \
		--platform=$(PLATFORM) \
		--name $(PROJECT) \
		--volume $(PWD):/app \
		"$(PROJECT):$(DEV_TAG)" \
		bash
