package server

import (
	"context"
	"encoding/json"

	"github.com/sourcegraph/jsonrpc2"
)

func (h *Handler) HandleStart(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	h.Logger.Printf("start")

	var params StartRequest
	if err := json.Unmarshal(*req.Params, &params); err != nil {
		return nil, err
	}

	process, err := NewProcess(ctx, conn, params.Id, params.Script)
	if err != nil {
		return nil, err
	}
	h.ProcessMap[params.Id] = process

	process.Start(params.Params)

	return StartResponse{}, nil
}

