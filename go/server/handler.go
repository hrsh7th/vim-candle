package server

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/sourcegraph/jsonrpc2"
)

func NewHandler(logfile string) *Handler {
	file, err := os.OpenFile(logfile, os.O_CREATE|os.O_APPEND, 0660)
	if err != nil {
		fmt.Println("logfile can't open")
		os.Exit(1)
	}

	return &Handler{
		Logger:     log.New(file, "[CANDLE]", 0660),
		ProcessMap: make(map[string]*Process, 0),
	}
}

type Handler struct {
	Logger     *log.Logger
	ProcessMap map[string]*Process
}

func (h *Handler) Handle(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	switch {
	case req.Method == "start":
		return h.HandleStart(ctx, conn, req)
	}
	return nil, &jsonrpc2.Error{
		Code:    jsonrpc2.CodeMethodNotFound,
		Message: fmt.Sprintf("method not supported: %s", req.Method),
	}
}

