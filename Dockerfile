FROM golang:1.25.1-alpine@sha256:cb0b8e92b8b63b1ba16ce78d926fcba5d4f9ff241855115568006affc3ae6557 AS builder

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
