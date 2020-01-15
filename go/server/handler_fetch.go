package server

import (
	"context"
	"encoding/json"
	"strconv"

	"github.com/sourcegraph/jsonrpc2"
)

func (h *Handler) HandleFetch(ctx context.Context, conn *jsonrpc2.Conn, req *jsonrpc2.Request) (interface{}, error) {
	h.Logger.Printf("fetch")

	var params FetchRequest
	if err := json.Unmarshal(*req.Params, &params); err != nil {
		return nil, err
	}

	items := make([]Item, 0)

	for i := 0; i < params.Count; i++ {
		items = append(items, Item{
			Title: strconv.Itoa(i),
		})
	}

	return FetchResponse{
		Id:    params.Id,
		Items: items,
	}, nil
}

