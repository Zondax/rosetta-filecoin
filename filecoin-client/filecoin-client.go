package filecoin_client

import (
	"context"
	"crypto/tls"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/coinbase/rosetta-sdk-go/asserter"
	"github.com/coinbase/rosetta-sdk-go/client"
	"github.com/coinbase/rosetta-sdk-go/types"

	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"
	"google.golang.org/grpc/credentials"

	config "github.com/rosetta-filecoin/config"
	
	lotusCli "github.com/filecoin-project/lotus/cli"
	"github.com/urfave/cli/v2"

	lotusAPI "github.com/filecoin-project/lotus/api"
)

const (
	// serverURL is the URL of a Rosetta Server.
	serverURL = "http://localhost:8080"

	// agent is the user-agent on requests to the
	// Rosetta Server.
	agent = "rosetta-sdk-go"

	// defaultTimeout is the default timeout for
	// HTTP requests.
	defaultTimeout = 10 * time.Second
)

type (
	// FileCoinClient is the IoTex blockchain client interface.
	FileCoinClient interface {
		// GetSyncState returns the node's id
		GetSyncState(ctx context.Context) (string, error)
	}


	// FileCoinBlock is the Filecoin blockchain's block.
	 FileCoinBlock struct {
			Height       int64  // Block height.
			Hash         string // Block hash.
			Timestamp    int64  // UNIX time, converted to milliseconds.
			ParentHeight int64  // Height of parent block.
			ParentHash   string // Hash of parent block.
	}

	 Account struct {
			Nonce   uint64
			Balance string
	}


	// grpcFilecoinClient is an implementation of FileCoinClient using gRPC.
	grpcFileCoinClient struct {
		sync.RWMutex

		endpoint string
		grpcConn *grpc.ClientConn
		cfg      *config.Config
	}

)

// NewFileCoinClient returns an implementation of FileCoinClient
func NewFileCoinClient(cfg *config.Config) (cli FileCoinClient, err error) {
	opts := []grpc.DialOption{}
	if cfg.Server.SecureEndpoint {
		opts = append(opts, grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{})))
	} else {
		opts = append(opts, grpc.WithInsecure())
	}
	grpc, err := grpc.Dial(cfg.Server.Endpoint, opts...)
	if err != nil {
		return
	}
	cli = &grpcFileCoinClient{grpcConn: grpc, cfg: cfg}
	return
}

func (g grpcFileCoinClient) GetSyncState(ctx context.Context) (string, error) {
	cctx := cli.Context{}
	napi, closer, err := lotusCli.GetFullNodeAPI(&cctx)

	if err != nil {
		return "", err
	}
	defer closer()

	states, err := napi.SyncState(ctx)

	return states.ActiveSyncs[0].Message, err
}
