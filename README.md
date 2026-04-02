[![CI](https://github.com/AndriyKalashnykov/go-httpbin/actions/workflows/ci.yml/badge.svg)](https://github.com/AndriyKalashnykov/go-httpbin/actions/workflows/ci.yml)
[![Hits](https://hits.sh/github.com/AndriyKalashnykov/go-httpbin.svg?view=today-total&style=plastic)](https://hits.sh/github.com/AndriyKalashnykov/go-httpbin/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/go-httpbin)
[![GoDoc](https://pkg.go.dev/badge/github.com/AndriyKalashnykov/go-httpbin)](https://pkg.go.dev/github.com/AndriyKalashnykov/go-httpbin)

# go-httpbin

A Go handler that lets you test your HTTP client, retry logic, streaming behavior, timeouts etc.
with the endpoints of [httpbin.org](http://httpbin.org) locally in a [net/http/httptest.Server](https://pkg.go.dev/net/http/httptest).
This way, you can write tests without relying on an external dependency like httpbin.org.

## Quick Start

```bash
make deps      # install and verify required tools
make build     # build the binary
make test      # run tests
make run       # start the server on :8080
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Go](https://go.dev/dl/) | 1.26+ | Language runtime and compiler |
| [GNU Make](https://www.gnu.org/software/make/) | 3.81+ | Build orchestration |
| [Docker](https://www.docker.com/) | latest | Container builds and GoReleaser |
| [golangci-lint](https://golangci-lint.run/) | 2.1.6+ | Go linter (auto-installed by `make deps`) |
| [gvm](https://github.com/moovweb/gvm) | latest | Go version management (optional) |

Install all required dependencies:

```bash
make deps
```

## Available Make Targets

Run `make help` to see all available targets.

### Build & Run

| Target | Description |
|--------|-------------|
| `make build` | Build binary |
| `make run` | Run binary |
| `make clean` | Cleanup |
| `make get` | Download and install dependency packages |
| `make update` | Update dependencies to latest versions |

### Code Quality

| Target | Description |
|--------|-------------|
| `make format` | Check Go source formatting |
| `make lint` | Run linter (golangci-lint + hadolint) |
| `make test` | Run tests |
| `make coverage-check` | Run tests with coverage and verify threshold |

### CI

| Target | Description |
|--------|-------------|
| `make ci` | Run all CI checks locally (format, lint, test, coverage, build) |
| `make ci-run` | Run GitHub Actions workflow locally using [act](https://github.com/nektos/act) |

### Docker

| Target | Description |
|--------|-------------|
| `make image-build` | Build Docker image |

### Release

| Target | Description |
|--------|-------------|
| `make test-release-linux` | Test GoReleaser Linux build |
| `make test-release-darwin` | Test GoReleaser Darwin build |
| `make release` | Create and push a new tag |

### Utilities

| Target | Description |
|--------|-------------|
| `make help` | List available tasks |
| `make deps` | Install and verify required dependencies |
| `make deps-check` | Show required Go versions and gvm status |
| `make deps-act` | Install act for local CI |
| `make deps-hadolint` | Install hadolint for Dockerfile linting |
| `make deps-renovate` | Install nvm and npm for Renovate |
| `make version` | Print current version (tag) |
| `make renovate-validate` | Validate Renovate configuration |

## Endpoints

- `/ip` Returns Origin IP.
- `/user-agent` Returns user-agent.
- `/headers` Returns headers.
- `/get` Returns GET data.
- `/status/:code` Returns given HTTP Status code.
- `/redirect/:n` 302 Redirects _n_ times.
- `/absolute-redirect/:n` 302 Absolute redirects _n_ times.
- `/redirect-to?url=foo` 302 Redirects to the _foo_ URL.
- `/stream/:n` Streams _n_ lines of JSON objects.
- `/delay/:n` Delays responding for _min(n, 10)_ seconds.
- `/bytes/:n` Generates _n_ random bytes of binary data, accepts optional _seed_ integer parameter.
- `/cookies` Returns the cookies.
- `/cookies/set?name=value` Sets one or more simple cookies.
- `/cookies/delete?name` Deletes one or more simple cookies.
- `/drip?numbytes=n&duration=s&delay=s&code=code` Drips data over a duration after
  an optional initial _delay_, then optionally returns with the given status _code_.
- `/cache` Returns 200 unless an If-Modified-Since or If-None-Match header is provided, when it returns a 304.
- `/cache/:n` Sets a Cache-Control header for _n_ seconds.
- `/gzip` Returns gzip-encoded data.
- `/deflate` Returns deflate-encoded data.
- `/brotli` Returns brotli-encoded data.
- `/robots.txt` Returns some robots.txt rules.
- `/deny` Denied by robots.txt file.
- `/basic-auth/:user/:passwd` Challenges HTTP Basic Auth.
- `/hidden-basic-auth/:user/:passwd` Challenges HTTP Basic Auth and returns 404 on failure.
- `/html` Returns some HTML.
- `/xml` Returns some XML.
- `/image/gif` Returns page containing an animated GIF image.
- `/image/png` Returns page containing a PNG image.
- `/image/jpeg` Returns page containing a JPEG image.

## How to use

Standing up a Go server running httpbin endpoints is just 1 line:

```go
package main

import (
    "log"
    "net/http"
    "github.com/AndriyKalashnykov/go-httpbin"
)

func main() {
	log.Fatal(http.ListenAndServe(":8080", httpbin.GetMux()))
}
```

Let's say you do not want a server running all the time because you just want to
test your HTTP logic after all. Integrating `httpbin` to your tests is very simple:

```go
package test

import (
    "testing"
    "net/http"
    "net/http/httptest"

    "github.com/AndriyKalashnykov/go-httpbin"
)

func TestDownload(t *testing.T) {
    srv := httptest.NewServer(httpbin.GetMux())
    defer srv.Close()

    resp, err := http.Get(srv.URL + "/bytes/65536")
    if err != nil {
        t.Fatal(err)
    }
    // read from an actual HTTP server hosted locally
    // test whatever you are going to test...
}
```

go-httpbin works from the command line as well:

```
$ go install github.com/AndriyKalashnykov/go-httpbin/cmd/httpbin
$ $GOPATH/bin/httpbin -host :8080
```

## CI/CD

GitHub Actions runs on every push to `main`, tags `v*`, and pull requests.

| Job | Triggers | Steps |
|-----|----------|-------|
| **static-check** | push, PR, tags | Lint (golangci-lint + hadolint) |
| **build** | after static-check | Build binary |
| **test** | after static-check | Run tests |
| **release-binaries** | tags only | Cross-compile via GoReleaser (Linux + macOS) |
| **release-docker-images** | tags only | Build and push Docker image to GHCR |

The cleanup workflow (`cleanup-runs.yml`) runs weekly (Sunday midnight) to delete workflow runs older than 7 days, keeping a minimum of 5 runs.

[Renovate](https://docs.renovatebot.com/) keeps dependencies up to date with platform automerge enabled.
