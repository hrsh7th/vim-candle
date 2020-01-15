package main

import (
	"context"
	"fmt"

	"github.com/hrsh7th/vim-candle/server"
	"github.com/sourcegraph/jsonrpc2"
)

func main() {
	handler := server.NewHandler("/tmp/candle2.log")
	<-jsonrpc2.NewConn(
		context.Background(),
		jsonrpc2.NewBufferedStream(
			server.Stdio{},
			jsonrpc2.VSCodeObjectCodec{},
		),
		jsonrpc2.HandlerWithError(handler.Handle),
	).DisconnectNotify()
	fmt.Printf("candle: disconnected.")
}
