# CLAUDE.md

## Project Overview

go-httpbin is a Go library and HTTP server that provides [httpbin.org](http://httpbin.org) endpoints locally for testing HTTP clients, retry logic, streaming behavior, and timeouts. It can be embedded in Go tests via `net/http/httptest.Server` or run as a standalone binary.

## Tech Stack

- **Language**: Go 1.26
- **Router**: gorilla/mux
- **Testing**: go test + testify
- **Linting**: golangci-lint
- **Container**: Multi-stage Docker build (golang alpine -> scratch)
- **CI**: GitHub Actions
- **Dependencies**: Renovate (auto-merge all update types)

## Build & Test Commands

```bash
make build       # Build binary (CGO_ENABLED=0)
make test        # Run tests
make lint        # Run golangci-lint
make ci          # Run all CI checks: deps, lint, test, build
make clean       # Remove dist directory
make deps        # Verify required tools are installed
make run         # Run the server locally on :8080
make get         # Download and tidy dependencies
make update      # Update dependencies to latest versions
make image       # Build Docker image
make release     # Create and push a new semver tag
make version     # Print current version tag
```

## Project Structure

- `cmd/httpbin/main.go` - CLI entry point
- `handlers.go` - HTTP handler implementations
- `handlers_test.go` - Handler tests
- `data.go` - Embedded response data
- `types.go` - Shared types
- `util.go` - Utility functions
- `Dockerfile` - Multi-stage container build
- `.github/workflows/ci.yml` - CI pipeline (build, test, release binaries, Docker images)
- `.github/workflows/cleanup-runs.yml` - Weekly cleanup of old workflow runs

## CI/CD

The CI workflow (`ci.yml`) runs on push to main, tags, and pull requests:

| Job | Trigger | Description |
|-----|---------|-------------|
| `setup` | all | Extracts Go version from go.mod |
| `builds` | all | Builds the binary via `make build` |
| `tests` | all (after builds) | Runs `make test` on ubuntu-latest |
| `release-binaries` | tags only | Cross-compiles via GoReleaser (Linux + macOS) |
| `release-docker-images` | tags only | Builds and pushes multi-arch Docker image to GHCR |

The cleanup workflow (`cleanup-runs.yml`) runs weekly (Sunday midnight) to delete workflow runs older than 7 days, keeping a minimum of 5 runs.

## Coding Conventions

- Use `GOFLAGS=-mod=mod` for module operations
- Binary output: `go-httpbin` in project root
- Tests use testify for assertions
- All CI steps delegate to Makefile targets

## Skills

Use the following skills when working on related files:

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `renovate.json` | `/renovate` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |

When spawning subagents, always pass conventions from the respective skill into the agent's prompt.
