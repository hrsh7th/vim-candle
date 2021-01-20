package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
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

		home, err := os.UserHomeDir()
		if err != nil {
			home = ""
		}

		ignoreMatcher := process.NewIgnoreMatcher(ignorePatterns)

		// get file lines
		var paths []string = make([]string, 0)
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			paths = append(paths, scanner.Text())
		}

		// add items
		candidates := paths
		candidates = reverse(candidates)
		candidates = unique(candidates)
		for i, candidate := range candidates {
			// skip if ignore patterns matches.
			if ignoreMatcher(candidate, true) {
				continue
			}
			if invalid(candidate) {
				continue
			}
			process.AddItem(toItem(process, i, candidate, home))
		}

		// write back uniqued lines
		ioutil.WriteFile(filepath, []byte(strings.Join(reverse(candidates), "\n")+"\n"), 0666)

		process.NotifyDone()
	}()
}

func toItem(process *candle.Process, index int, path string, home string) candle.Item {
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

func invalid(path string) bool {
	if stat, err := os.Stat(path); err != nil || stat.IsDir() {
		return true
	}
	return false
}

func reverse(paths []string) []string {
	length := len(paths)
	newPaths := make([]string, length)
	for i, path := range paths {
		newPaths[length-i-1] = path
	}
	return newPaths
}

func unique(paths []string) []string {
	uniqued := make(map[string]bool, 0)
	newPaths := make([]string, 0)
	for _, path := range paths {
		if !uniqued[path] {
			uniqued[path] = true
			newPaths = append(newPaths, path)
		}
	}
	return newPaths
}
