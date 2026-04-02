# CLAUDE.md

## Project Overview

go-httpbin is a Go library and HTTP server that provides [httpbin.org](http://httpbin.org) endpoints locally for testing HTTP clients, retry logic, streaming behavior, and timeouts. It can be embedded in Go tests via `net/http/httptest.Server` or run as a standalone binary.

## Tech Stack

- **Language**: Go (version from go.mod)
- **Router**: gorilla/mux
- **Testing**: go test + testify
- **Linting**: golangci-lint (includes gocritic via .golangci.yml) + hadolint (Dockerfile)
- **Container**: Multi-stage Docker build (golang alpine -> scratch)
- **CI**: GitHub Actions
- **Dependencies**: Renovate (auto-merge all update types)

## Build & Test Commands

```bash
make help             # List available tasks
make build            # Build binary (CGO_ENABLED=0)
make test             # Run tests
make format           # Check Go source formatting
make lint             # Run golangci-lint + hadolint
make coverage-check   # Run tests with coverage and verify threshold
make ci               # Run all CI checks: format, lint, test, coverage, build
make ci-run           # Run GitHub Actions workflow locally via act
make clean            # Remove dist directory
make deps             # Install and verify required tools (auto-installs gvm)
make deps-check       # Show required Go versions and gvm status
make deps-act         # Install act for local CI
make deps-hadolint    # Install hadolint for Dockerfile linting
make deps-renovate    # Install nvm and npm for Renovate
make run              # Run the server locally on :8080
make get              # Download and tidy dependencies
make update           # Update dependencies to latest versions
make image-build      # Build Docker image
make test-release-linux   # Test GoReleaser Linux build
make test-release-darwin  # Test GoReleaser Darwin build
make release          # Create and push a new semver tag
make version          # Print current version tag
make renovate-validate    # Validate Renovate configuration
```

## Project Structure

- `cmd/httpbin/main.go` - CLI entry point
- `handlers.go` - HTTP handler implementations
- `handlers_test.go` - Handler tests
- `example_test.go` - Example usage test
- `data.go` - Embedded response data
- `types.go` - Shared types
- `util.go` - Utility functions
- `.golangci.yml` - golangci-lint config (includes gocritic with all tags)
- `Dockerfile` - Multi-stage container build
- `.github/workflows/ci.yml` - CI pipeline (lint, build, test, release binaries, Docker images)
- `.github/workflows/cleanup-runs.yml` - Weekly cleanup of old workflow runs

## CI/CD

The CI workflow (`ci.yml`) runs on push to main, tags, pull requests, and workflow_call:

| Job | Trigger | Description |
|-----|---------|-------------|
| `static-check` | all | Lint via `make lint` (golangci-lint + hadolint) |
| `build` | after static-check | Build via `make build` |
| `test` | after static-check | Test via `make test` |
| `release-binaries` | tags only | Cross-compiles via GoReleaser (Linux + macOS) |
| `release-docker-images` | tags only | Builds and pushes Docker image to GHCR |

Note: The GitHub Actions CI splits lint, build, and test into separate parallel jobs (build and test run in parallel after static-check). The local `make ci` target runs the full pipeline sequentially: format, lint, test, coverage-check, build.

The cleanup workflow (`cleanup-runs.yml`) runs weekly (Sunday midnight) to delete workflow runs older than 7 days, keeping a minimum of 5 runs.

## Coding Conventions

- Use `GOFLAGS=-mod=mod` for module operations
- Binary output: `go-httpbin` in project root
- Tests use testify for assertions
- All CI steps delegate to Makefile targets
- Tool versions pinned in Makefile (golangci-lint, act, hadolint, nvm, gvm SHA)
- gvm used for local Go version management; CI uses actions/setup-go

## Skills

Use the following skills when working on related files:

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `renovate.json` | `/renovate` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |

When spawning subagents, always pass conventions from the respective skill into the agent's prompt.
