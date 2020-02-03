package main

import (
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	go func() {
		process.NotifyStart()

		length := process.Len([]string{"items"})
		for i := 0; i < length; i++ {
			process.AddItem(process.Get([]string{"items", strconv.Itoa(i)}).(map[string]interface{}))
		}

		process.NotifyDone()
	}()
}

