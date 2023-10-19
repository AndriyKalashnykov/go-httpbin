[![CI](https://github.com/AndriyKalashnykov/go-httpbin/actions/workflows/ci.yml/badge.svg)](https://github.com/AndriyKalashnykov/go-httpbin/actions/workflows/ci.yml)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FAndriyKalashnykov%2Fgo-httpbin&count_bg=%2340C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-brightgreen.svg)](https://opensource.org/licenses/Apache-2.0)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/go-httpbin)
[![Read GoDoc](https://godoc.org/github.com/AndriyKalashnykov/go-httpbin?status.svg)](https://godoc.org/github.com/AndriyKalashnykov/go-httpbin)
# go-httpbin

A Go handler that lets you test your HTTP client, retry logic, streaming behavior, timeouts etc.
with the endpoints of [httpbin.org](http://httpbin.org) locally in a [net/http/httptest.Server](https://pkg.go.dev/net/http/httptest).

This way, you can write tests without relying on an external dependency like [httpbin.org].

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
