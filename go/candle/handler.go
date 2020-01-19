package candle

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/sourcegraph/jsonrpc2"
)

func NewHandler(logfile string) *Handler {
	file, err := os.OpenFile(logfile, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0666)
	if err != nil {
		fmt.Println("logfile can't open")
		os.Exit(1)
	}

	return &Handler{
		Logger:     log.New(file, "[CANDLE]", log.LstdFlags|log.Ldate|log.Lshortfile),
		ProcessMap: make(map[string]*Process),
	}
}

type Handler struct {
	Logger     *log.Logger
	ProcessMap map[string]*Process
}

func (h *Handler) Handle(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	h.Logger.Printf(req.Method)

	switch {
	case req.Method == "start":
		return h.HandleStart(ctx, conn, req)
	case req.Method == "fetch":
		return h.HandleFetch(ctx, conn, req)
	}
	return nil, &jsonrpc2.Error{
		Code:    jsonrpc2.CodeMethodNotFound,
		Message: fmt.Sprintf("method not supported: %s", req.Method),
	}
}

func (h *Handler) GetProcess(id string) *Process {
	process, ok := h.ProcessMap[id]
	if ok {
		return process
	}
	return nil
}
