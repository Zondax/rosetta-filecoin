package tests

import (
	"context"
	"testing"

	"github.com/coinbase/rosetta-sdk-go/fetcher"
)

const ServerURL= "http://localhost:8080"
var ctx = context.Background()

func TestNetworkList(t *testing.T) {

	// Create a new fetcher
	newFetcher := fetcher.New(
		ServerURL,
	)

	resp, _ := newFetcher.NetworkList(ctx, nil)

	if len(resp.NetworkIdentifiers) == 0 {
		t.Error()
	}

	if resp.NetworkIdentifiers[0].Blockchain != "Filecoin" {
		t.Error()
	}

	if resp.NetworkIdentifiers[0].Network != "testnet" {
		t.Error()
	}

}