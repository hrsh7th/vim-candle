package main

import (
	"bufio"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

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

		// get file lines
		var paths []string = make([]string, 0)
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			path := scanner.Text()

			// skip already deleted file
			if _, err := os.Stat(path); err != nil {
				continue
			}

			paths = append(paths, path)
		}

		// add items
		reversed := reverse(paths)
		uniqued := unique(reversed)
		for i, path := range uniqued {
			process.AddItem(toItem(i, path))
		}

		// write back uniqued lines
		ioutil.WriteFile(filepath, []byte(strings.Join(reverse(uniqued), "\n")+"\n"), 0666)

		process.NotifyDone()
	}()
}

func toItem(index int, filepath string) candle.Item {
	return candle.Item{
		"id":    strconv.Itoa(index),
		"title": filepath,
		"path":  filepath,
	}
}

func reverse(strs []string) []string {
	length := len(strs)
	reversed := make([]string, length)
	for i, str := range strs {
		reversed[length-i-1] = str
	}
	return reversed
}

func unique(strs []string) []string {
	checked := make(map[string]bool, 0)
	uniqued := make([]string, 0)
	for _, str := range strs {
		if !checked[str] {
			checked[str] = true
			uniqued = append(uniqued, str)
		}
	}
	return uniqued
}

