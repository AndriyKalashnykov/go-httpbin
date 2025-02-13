FROM golang:1.24.0-alpine@sha256:5429efb7de864db15bd99b91b67608d52f97945837c7f6f7d1b779f9bfe46281 AS builder

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
