BINDIR = $(shell pwd)/bin
CST_VERSION = 1.10.0
SUDO =
DOCKER_BUILD_ARGS =
PKG_CONFIG_PATH = .

export PKG_CONFIG_PATH

debug: dev-deps
	cargo build

release: deps
	cargo build -r

docker-image:
	docker buildx build $(DOCKER_BUILD_ARGS) --tag ghcr.io/hsn723/reject-rbl-rcpt:$(shell git describe --tags --abbrev=0 --match "v*" || echo v0.0.0) .

test: debug
	tests/run-tests.sh

lint: deps
	cargo fmt
	cargo check

dev-deps: deps opendkim-tools

deps: libmilter-dev

opendkim-tools:
	if [ -z "$(shell which miltertest)" ]; then \
		$(SUDO) apt-get update && $(SUDO) apt-get install -y --no-install-recommends $@ ;\
	fi

libmilter-dev:
	if [ -z "$(shell dpkg -l $@ | grep -o "ii" || true )" ]; then \
		$(SUDO) apt-get update && $(SUDO) apt-get install -y --no-install-recommends $@ ;\
	fi

CONTAINER_STRUCTURE_TEST = $(BINDIR)/container-structure-test
$(CONTAINER_STRUCTURE_TEST):
	if [ -z "$(shell which container-structure-test)" ]; then \
		curl -LO https://storage.googleapis.com/container-structure-test/v$(CST_VERSION)/container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test && chmod +x container-structure-test && sudo mv container-structure-test /usr/local/bin/; \
	fi

.PHONY: container-structure-test
container-structure-test: $(CONTAINER_STRUCTURE_TEST)
	container-structure-test test --image ghcr.io/hsn723/reject-rbl-rcpt:$(shell git describe --tags --abbrev=0 --match "v*" || echo v0.0.0) --config cst.yaml
