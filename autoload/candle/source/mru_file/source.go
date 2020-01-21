package main

import (
	"bufio"
	"os"
	"sort"

	"github.com/hrsh7th/vim-candle/go/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

type Filepaths []string

func (filepaths Filepaths) Len() int {
	return len(filepaths)
}

func (filepaths Filepaths) Swap(i int, j int) {
	filepaths[j], filepaths[i] = filepaths[i], filepaths[j]
}

func (filepaths Filepaths) Less(i int, j int) bool {
	return i < j
}

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

		var filepaths Filepaths = make(Filepaths, 0)
		index := 0
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			filepaths = append(filepaths, scanner.Text())
			index += 1
		}

		sort.Sort(sort.Reverse(filepaths))

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
