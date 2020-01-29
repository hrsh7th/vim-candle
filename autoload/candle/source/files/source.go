package main

import (
	"os"
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle"
)

func Start(process *candle.Process) {
	rootPath := process.GetString([]string{"root_path"})
	ignorePatterns := make([]string, 0)
	for i := 0; i < process.Len([]string{"ignore_patterns"}); i++ {
		ignorePatterns = append(ignorePatterns, process.GetString([]string{"ignore_patterns", strconv.Itoa(i)}))
	}

	ignoreMatcher := process.NewIgnoreMatcher(ignorePatterns)

	go func() {
		process.NotifyStart()

		ch := process.Walk(rootPath, func(pathname string, fi os.FileInfo) bool {
			return !ignoreMatcher(pathname, fi.IsDir())
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

