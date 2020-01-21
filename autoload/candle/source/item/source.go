package main

import (
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process) {
	go func() {
		length := process.Len([]string{"items"})
		for i := 0; i < length; i++ {
			Items = append(Items, process.Get("items", strconv.Itoa(i)).(map[string]interface{}))
		}
		process.NotifyDone()
	}()
}

