package main

import "github.com/hrsh7th/vim-candle/go/candle"

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process, params candle.StartRequest) candle.StartResponse {
	go func() {
		items, ok := params.Params["items"].([]interface{})
		if !ok {
			process.NotifyDone()
			return
		}
		for _, item := range items {
			item, ok := item.(candle.Item)
			if ok {
				Items = append(Items, item)
			}
		}
		process.NotifyDone()
	}()
	return candle.StartResponse{}
}

