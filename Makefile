.DEFAULT_GOAL := help
CURRENTTAG:=$(shell git describe --tags --abbrev=0)
NEWTAG ?= $(shell bash -c 'read -p "Please provide a new tag (currnet tag - ${CURRENTTAG}): " newtag; echo $$newtag')
GOFLAGS=-mod=mod
GO_BUILDER_VERSION=v1.21.3

#help: @ List available tasks
help:
	@clear
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-13s\033[0m - %s\n", $$1, $$2}'

#clean: @ Cleanup
clean:
	@rm -rf ./dist

#test: @ Run tests
test:
	@export GOFLAGS=$(GOFLAGS); go test $(go list ./...)

#build: @ Build binary
build:
	@export GOFLAGS=$(GOFLAGS); export CGO_ENABLED=0; go build -a -o go-httpbin ./cmd/httpbin/main.go

#run: @ Run binary
run:
	@export RPCENDPOINT=https://rpc.ankr.com/eth; export GOFLAGS=$(GOFLAGS); go run ./cmd/httpbin/main.go

#get: @ Download and install dependency packages
get:
	@export GOFLAGS=$(GOFLAGS); go get . ; go mod tidy

test-release: clean
#	docker run --rm --privileged \
#		-v $(CURDIR):/golang-cross-example \
#		-v /var/run/docker.sock:/var/run/docker.sock \
#		-v $(GOPATH)/src:/go/src \
#		-w /golang-cross-example \
#		ghcr.io/gythialy/golang-cross:$(GO_BUILDER_VERSION) --skip=publish --clean --snapshot

	export PATH=/opt/osxcross-clang-17.0.3-macosx-14.0/target/bin:${PATH} && goreleaser --skip=publish --clean --snapshot

#release: @ Create and push a new tag
release: build
	$(eval NT=$(NEWTAG))
	@echo -n "Are you sure to create and push ${NT} tag? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo ${NT} > ./version.txt
	@git add -A
	@git commit -a -s -m "Cut ${NT} release"
	@git tag -a -m "Cut ${NT} release" ${NT}
	@git push origin ${NT}
	@git push
	@echo "Done."

#update: @ Update dependencies to latest versions
update:
	@export GOFLAGS=$(GOFLAGS); go get -u; go mod tidy

#version: @ Print current version(tag)
version:
	@echo $(shell git describe --tags --abbrev=0)

#image-build: @ Build a Docker image
image-build:
	docker build -t go-httpbin:$(CURRENTTAG) .
