package main

import (
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	go func() {
		process.NotifyStart()

		for i := 0; i < process.Len([]string{"items"}); i++ {
			process.AddItem(process.Get([]string{"items", strconv.Itoa(i)}).(map[string]interface{}))
		}

		process.NotifyDone()
	}()
}
