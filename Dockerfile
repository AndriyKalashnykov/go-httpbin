FROM golang:1.23.3-alpine@sha256:09742590377387b931261cbeb72ce56da1b0d750a27379f7385245b2b058b63a AS builder

WORKDIR /app
COPY go.mod ./
COPY go.sum ./
RUN go mod download
COPY . .
RUN export CGO_ENABLED=0; go build -a -o go-httpbin ./cmd/httpbin/main.go

FROM scratch
COPY --from=builder /app/go-httpbin /
EXPOSE 8080
ENTRYPOINT [ "/go-httpbin" ]
