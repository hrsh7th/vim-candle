package main

import (
	"os"
	"path/filepath"
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
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

		home, err := os.UserHomeDir()
		if err != nil {
			home = ""
		}

		ch := process.Walk(rootPath, func(pathname string, fi os.FileInfo) bool {
			return !ignoreMatcher(pathname, fi.IsDir())
		})

		index := 0
		for {
			entry, ok := <-ch
			if !ok {
				break
			}
			if !entry.FileInfo.IsDir() {
				process.AddItem(toItem(index, entry.Pathname, home))
				index += 1
			}
		}

		process.NotifyDone()
	}()

}

func toItem(index int, path string, home string) candle.Item {
	title := path
	if filepath.HasPrefix(path, home) {
		var err error
		title, err = filepath.Rel(home, path)
		if err == nil {
			title = "~/" + title
		}
	}
	return candle.Item{
		"id":       strconv.Itoa(index),
		"title":    title,
		"filename": path,
		"is_dir":   false,
	}
}
