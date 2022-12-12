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

# tmpl-target-setup RULE_FUNC VARS
tmpl-target-setup = $(foreach x,$(2),$(eval $(call $(1),$(x))))
# tmpl-target-name TEMPLATE_STRING VARS
tmpl-target-name = $(foreach x,$(2),$(call $(1),$(x)))
# tmpl-targets PREFIX EXCLUDE_SUBSTR VARS
tmpl-targets = $(foreach x,$(3),$(if $(findstring $(2),$(x)),,$(1)-$(x)))

MILTERTEST_CASES = $(shell find tests/ -name "*.lua")
MILTERTEST_TARGETS = $(call tmpl-targets,miltertest,,$(MILTERTEST_CASES))
miltertest:
	@$(MAKE) debug
	$(MAKE) $(MILTERTEST_TARGETS)

tmpl-miltertest = miltertest-$(1)
define miltertest-setup
$(call tmpl-miltertest,$(1)): TARGET := $(1)
.PHONY: $(call tmpl-miltertest,$(1))
endef

$(call tmpl-target-setup,miltertest-setup,$(MILTERTEST_CASES))
$(call tmpl-target-name,tmpl-miltertest,$(MILTERTEST_CASES)):
	miltertest -s "${TARGET}"

lint: deps
	cargo fmt
	cargo check

dev-deps: deps install-miltertest

deps: libmilter-dev

install-miltertest:
	@if [ -z "$(shell which miltertest)" ]; then \
		$(SUDO) apt-get update && $(SUDO) apt-get install -y --no-install-recommends miltertest ;\
	fi

libmilter-dev:
	@if [ -z "$(shell dpkg -l $@ | grep -o "ii" || true )" ]; then \
		$(SUDO) apt-get update && $(SUDO) apt-get install -y --no-install-recommends $@ ;\
	fi

CONTAINER_STRUCTURE_TEST = $(BINDIR)/container-structure-test
$(CONTAINER_STRUCTURE_TEST):
	@if [ -z "$(shell which container-structure-test)" ]; then \
		curl -LO https://storage.googleapis.com/container-structure-test/v$(CST_VERSION)/container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test && chmod +x container-structure-test && sudo mv container-structure-test /usr/local/bin/; \
	fi

.PHONY: container-structure-test
container-structure-test: $(CONTAINER_STRUCTURE_TEST)
	container-structure-test test --image ghcr.io/hsn723/reject-rbl-rcpt:$(shell git describe --tags --abbrev=0 --match "v*" || echo v0.0.0) --config cst.yaml
