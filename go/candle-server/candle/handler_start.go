package candle

import (
	"context"
	"encoding/json"

	"github.com/sourcegraph/jsonrpc2"
)

func (h *Handler) HandleStart(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	var params StartRequest
	if err := json.Unmarshal(*req.Params, &params); err != nil {
		h.Logger.Println(err)
		return nil, err
	}

	process, err := NewProcess(h, &ctx, conn)
	if err != nil {
		h.Logger.Println(err)
		return nil, err
	}

	h.ProcessMap[params.Id] = process

	return process.Start(params)
}
