FROM golang:1.25.6-alpine@sha256:d9b2e14101f27ec8d09674cd01186798d227bb0daec90e032aeb1cd22ac0f029 AS builder

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
