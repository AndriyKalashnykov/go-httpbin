package httpbin_test

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httptest"

	httpbin "github.com/AndriyKalashnykov/go-httpbin"
)

func ExampleGetMux_httptest() {
	srv := httptest.NewServer(httpbin.GetMux())
	defer srv.Close()

	resp, err := http.Get(srv.URL + "/bytes/65536")
	if err != nil {
		log.Fatal(err) //nolint:gocritic // standard example pattern
	}
	defer resp.Body.Close() //nolint:errcheck // example code

	// read from an actual HTTP server hosted locally
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Retrieved %d bytes.\n", len(b))
	// Output: Retrieved 65536 bytes.
}

func ExampleGetMux_server() {
	log.Fatal(http.ListenAndServe(":8080", httpbin.GetMux()))
}
