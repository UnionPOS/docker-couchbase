export DOCKER_ORG ?= unionpos
export DOCKER_IMAGE ?= $(DOCKER_ORG)/couchbase-enterprise-server
export DOCKER_TAG ?= 6.0.2
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS =

-include $(shell curl -sSL -o .build-harness "https://raw.githubusercontent.com/unionpos/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

build: docker/build
.PHONY: build

## update readme documents
docs: readme/deps readme
.PHONY: docs

run:
	docker container run --rm \
		--publish "8091-8096:8091-8096" \
		--publish "18091-18096:18091-18096" \
		--publish "11207:11207" \
		--publish "11210-11211:11210-11211" \
		--attach STDOUT ${DOCKER_IMAGE_NAME}
.PHONY: run

it:
	docker run -it ${DOCKER_IMAGE_NAME} /bin/bash
.PHONY: it
