package main

import (
	"os"
	"path/filepath"
	"sort"
	"strconv"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	rootPath := process.GetString([]string{"root_path"})
	sortBy := process.GetString([]string{"sort_by"})
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
		entries := make([]candle.Item, 0)
		for {
			entry, ok := <-ch
			if !ok {
				break
			}
			if !entry.FileInfo.IsDir() {
				item := toItem(index, entry.Pathname, home)
				if sortBy == "" {
					process.AddItem(item)
				} else {
					entries = append(entries, item)
				}
				index += 1
			}
		}

		sort.Slice(entries, func(i, j int) bool {
			if sortBy == "mtime" {
				return entries[i][sortBy].(int64) > entries[j][sortBy].(int64)
			}
			return true
		})

		for _, entry := range entries {
			process.AddItem(entry)
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
	var mtime int64
	stat, err := os.Stat(path)
	if err == nil {
		mtime = stat.ModTime().Unix()
	} else {
		mtime = 0
	}
	return candle.Item{
		"id":       strconv.Itoa(index),
		"title":    title,
		"filename": path,
		"mtime":    mtime,
		"is_dir":   false,
	}
}
