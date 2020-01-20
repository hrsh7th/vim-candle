package main

import (
	"encoding/json"
	"os"

	"github.com/hrsh7th/vim-candle/go/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process, paramsstr string) {
	var params map[string]interface{}
	if err := json.Unmarshal([]byte(paramsstr), &params); err != nil {
		process.Logger.Println(err)
		return
	}

	filepaths := params["filepaths"].([]string)

	go func() {
		for _, filepath := range filepaths {
			if _, err := os.Stat(filepath); err != nil {
				Items = append(Items, toItem(len(Items), filepath))
			}
		}
	}()
}

func toItem(index int, filepath string) candle.Item {
	return map[string]interface{}{
		"id":    index,
		"title": filepath,
	}
}
