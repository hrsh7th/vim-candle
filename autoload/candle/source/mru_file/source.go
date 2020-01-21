package main

import (
	"bufio"
	"os"

	"github.com/hrsh7th/vim-candle/go/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process) {
	go func() {
		filepath := process.GetString([]string{"filepath"})
		if _, err := os.Stat(filepath); err != nil {
			return
		}

		file, err := os.Open(filepath)
		if err != nil {
			return
		}
		defer file.Close()

		var filepaths_ []string = make([]string, 0)
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			filepaths_ = append(filepaths_, scanner.Text())
		}

		var filepaths []string = make([]string, len(filepaths_))
		for i, filepath := range filepaths_ {
			filepaths[len(filepaths_)-i-1] = filepath
		}

		mark := make(map[string]bool)
		uniqued := []string{}
		for _, filepath := range filepaths {
			if !mark[filepath] {
				mark[filepath] = true
				uniqued = append(uniqued, filepath)
			}
		}

		for i, filepath := range uniqued {
			Items = append(Items, toItem(i, filepath))
		}

		process.NotifyDone()
	}()
}

func toItem(index int, filepath string) candle.Item {
	return map[string]interface{}{
		"id":    index,
		"title": filepath,
		"path":  filepath,
	}
}
