package main

import (
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle"
)

func Start(process *candle.Process) {
	rootPath := process.GetString([]string{"root-path"})
	ignoreGlobs := make([]string, 0)
	for i := 0; i < process.Len([]string{"ignore-globs"}); i++ {
		ignoreGlobs = append(ignoreGlobs, process.GetString([]string{"ignore-globs", strconv.Itoa(i)}))
	}

	go func() {
		ch := process.Walk(rootPath, ignoreGlobs)

		index := 0
		for {
			pathname, ok := <-ch
			if !ok {
				break
			}
			process.AddItem(toItem(index, pathname))
			index += 1
		}
		process.NotifyDone()
	}()

}

func toItem(index int, pathname string) candle.Item {
	return candle.Item{
		"id":    strconv.Itoa(index),
		"title": pathname,
		"path":  pathname,
	}
}

