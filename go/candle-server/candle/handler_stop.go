package candle

import (
	"context"
	"encoding/json"

	"github.com/sourcegraph/jsonrpc2"
)

func (h *Handler) HandleStop(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	var params StopRequest
	if err := json.Unmarshal(*req.Params, &params); err != nil {
		h.Logger.Println(err)
		return nil, err
	}

	h.ProcessMap[params.Id] = nil

	return nil, nil
}
