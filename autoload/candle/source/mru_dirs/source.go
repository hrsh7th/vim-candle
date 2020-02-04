package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process) {
	filepath := process.GetString([]string{"filepath"})
	if _, err := os.Stat(filepath); err != nil {
		process.NotifyMessage(fmt.Sprintf("`%s` is not valid filepath.", filepath))
		process.NotifyDone()
		return
	}

	ignorePatterns := make([]string, 0)
	for i := 0; i < process.Len([]string{"ignore_patterns"}); i++ {
		ignorePatterns = append(ignorePatterns, process.GetString([]string{"ignore_patterns", strconv.Itoa(i)}))
	}

	go func() {
		process.NotifyStart()

		file, err := os.Open(filepath)
		if err != nil {
			return
		}
		defer file.Close()

		ignoreMatcher := process.NewIgnoreMatcher(ignorePatterns)

		// get file lines
		var paths []string = make([]string, 0)
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			path := scanner.Text()

			// skip already deleted file
			if stat, err := os.Stat(path); err != nil || !stat.IsDir() {
				continue
			}

			paths = append(paths, path)
		}

		// add items
		reversed := reverse(paths)
		uniqued := unique(reversed)
		for i, path := range uniqued {
			// skip if ignore patterns matches.
			if ignoreMatcher(path, true) {
				continue
			}
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

