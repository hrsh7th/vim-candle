package main

import (
	"path/filepath"
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle"
)

func Start(process *candle.Process) {
	ignoreGlobs := make([]string, process.Len([]string{"ignore-globs"}))
	rootPath := process.GetString([]string{"root-path"})

	go func() {
		ch := process.Walk(rootPath, func(pathname string) bool {
			for _, ignoreGlob := range ignoreGlobs {
				if matched, _ := filepath.Match(ignoreGlob, pathname); matched {
					return false
				}
			}
			return true
		})

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

