FROM golang:1.25.3-alpine@sha256:20ee0b674f987514ae3afb295b6a2a4e5fa11de8cc53a289343bbdab59b0df59 AS builder

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
