.DEFAULT_GOAL := help

APP_NAME       := go-httpbin
CURRENTTAG     := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "dev")
NEWTAG ?= $(shell bash -c 'read -p "Please provide a new tag (current tag - ${CURRENTTAG}): " newtag; echo $$newtag')

# === Tool Versions (pinned) ===
GOLANGCI_VERSION := 2.1.6
ACT_VERSION      := 0.2.87
HADOLINT_VERSION := 2.12.0
NVM_VERSION      := 0.40.4
GVM_SHA          := dd652539fa4b771840846f8319fad303c7d0a8d2 # v1.0.22

GOFLAGS        ?= -mod=mod
GOOS           ?= linux
GOARCH         ?= amd64
OSXCROSS_PATH  := /opt/osxcross-clang-17.0.3-macosx-14.0/target/bin

# Semver regex for release validation
SEMVER_REGEX := ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$$

# Parse Go version from go.mod
GO_VERSIONS := $(shell find . -name 'go.mod' -exec grep -oP '^go \K[0-9.]+' {} \; | sort -uV)
GO_VERSION  := $(shell grep -oP '^go \K[0-9.]+' go.mod)

# GoReleaser cross-compile builder version (derived from go.mod)
GO_BUILDER_VERSION := v$(shell grep -oP '^go \K[0-9]+\.[0-9]+' go.mod)

# Helper: run a command under the correct Go version
# In CI, actions/setup-go provides Go directly — gvm is not needed.
# Locally, gvm sets GOROOT/GOPATH/PATH in a subshell.
HAS_GVM := $(shell [ -s "$$HOME/.gvm/scripts/gvm" ] && echo true || echo false)
define go-exec
$(if $(filter true,$(HAS_GVM)),bash -c '. $$GVM_ROOT/scripts/gvm && gvm use go$(GO_VERSION) >/dev/null && $(1)',bash -c '$(1)')
endef

IS_DARWIN := 0
IS_LINUX := 0
IS_FREEBSD := 0
IS_WINDOWS := 0
IS_AMD64 := 0
IS_AARCH64 := 0
IS_RISCV64 := 0

# Test Windows apart because it doesn't support `uname -s`.
ifeq ($(OS), Windows_NT)
	# We can assume it will likely be in amd64.
	IS_AMD64 := 1
	IS_WINDOWS := 1
else
	# Platform
	uname := $(shell uname -s)

	ifeq ($(uname), Darwin)
		IS_DARWIN := 1
	else ifeq ($(uname), Linux)
		IS_LINUX := 1
	else ifeq ($(uname), FreeBSD)
		IS_FREEBSD := 1
	else
		# We use spaces instead of tabs to indent `$(error)`
		# otherwise it's considered as a command outside a
		# target and it will fail.
                $(error Unrecognized platform, expect `Darwin`, `Linux` or `Windows_NT`)
	endif

	# Architecture
	uname := $(shell uname -m)

	ifneq (, $(filter $(uname), x86_64 amd64))
		IS_AMD64 := 1
	else ifneq (, $(filter $(uname), aarch64 arm64))
		IS_AARCH64 := 1
	else ifneq (, $(filter $(uname), riscv64))
		IS_RISCV64 := 1
	else
		# We use spaces instead of tabs to indent `$(error)`
		# otherwise it's considered as a command outside a
		# target and it will fail.
                $(error Unrecognized architecture, expect `x86_64`, `aarch64`, `arm64`, 'riscv64')
	endif
endif

#help: @ List available tasks
help:
	@clear
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-24s\033[0m - %s\n", $$1, $$2}'

#clean: @ Cleanup
clean:
	@rm -rf ./dist

#deps: @ Install and verify required dependencies
deps:
	@# Install gvm if not present (local development only, CI uses actions/setup-go)
	@if [ -z "$$CI" ] && [ ! -s "$$HOME/.gvm/scripts/gvm" ]; then \
		echo "Installing gvm (Go Version Manager)..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/$(GVM_SHA)/binscripts/gvm-installer | bash -s $(GVM_SHA); \
		echo ""; \
		echo "gvm installed. Please restart your shell or run:"; \
		echo "  source $$HOME/.gvm/scripts/gvm"; \
		echo "Then re-run 'make deps' to install Go $(GO_VERSION) via gvm."; \
		exit 0; \
	fi
	@if [ "$(HAS_GVM)" = "true" ]; then \
		for v in $(GO_VERSIONS); do \
			bash -c '. $$GVM_ROOT/scripts/gvm && gvm list' 2>/dev/null | grep -q "go$$v" || { \
				echo "Installing Go $$v via gvm..."; \
				bash -c '. $$GVM_ROOT/scripts/gvm && gvm install go'"$$v"' -B'; \
			}; \
		done; \
	else \
		command -v go >/dev/null 2>&1 || { echo "Error: Go required. Install gvm from https://github.com/moovweb/gvm or Go from https://go.dev/dl/"; exit 1; }; \
	fi
	@command -v git >/dev/null 2>&1 || { echo "ERROR: git is not installed"; exit 1; }
	@$(call go-exec,command -v golangci-lint) >/dev/null 2>&1 || { echo "Installing golangci-lint $(GOLANGCI_VERSION)..."; \
		$(call go-exec,go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v$(GOLANGCI_VERSION)); }
	@echo "All dependencies are available."

#deps-check: @ Show required Go versions and gvm status
deps-check:
	@echo "Go versions required: $(GO_VERSIONS)"
	@echo "Primary Go version:   $(GO_VERSION)"
	@command -v gvm >/dev/null 2>&1 && { \
		bash -c '. $$GVM_ROOT/scripts/gvm && gvm list'; \
	} || echo "gvm not installed — install from https://github.com/moovweb/gvm"

#deps-act: @ Install act for local CI
deps-act: deps
	@command -v act >/dev/null 2>&1 || { echo "Installing act $(ACT_VERSION)..."; \
		curl -sSfL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin v$(ACT_VERSION); \
	}

#deps-hadolint: @ Install hadolint for Dockerfile linting
deps-hadolint: deps
	@command -v hadolint >/dev/null 2>&1 || { echo "Installing hadolint $(HADOLINT_VERSION)..."; \
		curl -sSfL -o /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v$(HADOLINT_VERSION)/hadolint-Linux-x86_64 && \
		install -m 755 /tmp/hadolint /usr/local/bin/hadolint && \
		rm -f /tmp/hadolint; \
	}

#deps-renovate: @ Install nvm and npm for Renovate
deps-renovate:
	@command -v node >/dev/null 2>&1 || { \
		echo "Installing nvm $(NVM_VERSION)..."; \
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$(NVM_VERSION)/install.sh | bash; \
		export NVM_DIR="$$HOME/.nvm"; \
		[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
		nvm install --lts; \
	}

#test: @ Run tests
test: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go test ./...)

#format: @ Check Go source formatting
format: deps
	@$(call go-exec,test -z "$$(gofmt -l .)" || { gofmt -l . && echo "Files above are not formatted. Run: gofmt -w ."; exit 1; })

#lint: @ Run linter (golangci-lint + hadolint)
lint: deps deps-hadolint
	@$(call go-exec,golangci-lint run ./...)
	@hadolint Dockerfile

#coverage-check: @ Run tests with coverage and verify threshold
coverage-check: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go test -coverprofile=coverage.out ./...)
	@COVERAGE=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | tr -d '%'); \
		echo "Total coverage: $${COVERAGE}%"; \
		RESULT=$$(echo "$${COVERAGE} < 80" | bc -l); \
		if [ "$${RESULT}" -eq 1 ]; then \
			echo "ERROR: Coverage $${COVERAGE}% is below 80% threshold"; exit 1; \
		fi

#build: @ Build binary
build: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) CGO_ENABLED=0 && go build -a -o go-httpbin ./cmd/httpbin/main.go)

#run: @ Run binary
run: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go run ./cmd/httpbin/main.go)

#get: @ Download and install dependency packages
get: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go get . && go mod tidy)

#test-release-linux: @ Test GoReleaser Linux build
test-release-linux: clean
	@docker run --rm --privileged \
		-v $(CURDIR):/golang-cross-example \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(GOPATH)/src:/go/src \
		-w /golang-cross-example \
		ghcr.io/gythialy/golang-cross:$(GO_BUILDER_VERSION) --skip=publish --clean --snapshot --config .goreleaser-Linux.yml

#test-release-darwin: @ Test GoReleaser Darwin build
test-release-darwin: clean
	@docker run --rm --privileged \
		-v $(CURDIR):/golang-cross-example \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(GOPATH)/src:/go/src \
		-w /golang-cross-example \
		ghcr.io/gythialy/golang-cross:$(GO_BUILDER_VERSION) --skip=publish --clean --snapshot --config .goreleaser-Darwin-cross.yml

#release: @ Create and push a new tag
release: build
	$(eval NT=$(NEWTAG))
	@if ! echo "$(NT)" | grep -qE '$(SEMVER_REGEX)'; then \
		echo "ERROR: '$(NT)' is not a valid semver tag (expected format: vX.Y.Z[-prerelease])"; \
		exit 1; \
	fi
	@if git rev-parse -q --verify "refs/tags/$(NT)" >/dev/null 2>&1; then echo "ERROR: tag $(NT) already exists locally. Pick a new version or delete it: git tag -d $(NT)"; exit 1; fi
	@if git ls-remote --exit-code --tags origin "refs/tags/$(NT)" >/dev/null 2>&1; then echo "ERROR: tag $(NT) already exists on origin. Pick a new version."; exit 1; fi
	@echo -n "Are you sure to create and push ${NT} tag? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo ${NT} > ./version.txt
	@git add -A
	@git commit -a -s -m "Cut ${NT} release"
	@git tag -a -m "Cut ${NT} release" ${NT}
	@git push origin ${NT}
	@git push
	@echo "Done."

#update: @ Update dependencies to latest versions
update: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go get -u ./... && go mod tidy)

#version: @ Print current version (tag)
version:
	@echo $(CURRENTTAG)

#ci: @ Run all CI checks locally
ci: deps format lint test coverage-check build
	@echo "All CI checks passed."

#ci-run: @ Run GitHub Actions workflow locally using act
ci-run: deps-act
	@act push --container-architecture linux/amd64 \
		--artifact-server-path /tmp/act-artifacts

#image-build: @ Build Docker image
image-build: build
	@docker build -t $(APP_NAME):$(CURRENTTAG) .

#renovate-validate: @ Validate Renovate configuration
renovate-validate: deps-renovate
	@npx --yes renovate --platform=local

.PHONY: help clean deps deps-check deps-act deps-hadolint deps-renovate test format lint \
	coverage-check build run get test-release-linux test-release-darwin release update \
	version ci ci-run image-build renovate-validate
