package main

import (
	"context"
	"fmt"
	"runtime"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
	"github.com/sourcegraph/jsonrpc2"
)

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	handler := candle.NewHandler("/tmp/candle.log")
	<-jsonrpc2.NewConn(
		context.Background(),
		jsonrpc2.NewBufferedStream(
			candle.Stdio{},
			jsonrpc2.VSCodeObjectCodec{},
		),
		jsonrpc2.HandlerWithError(handler.Handle),
	).DisconnectNotify()
	fmt.Printf("candle: disconnected.")
}
