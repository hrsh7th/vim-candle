package main

import (
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	workingDir := process.Args()["working_dir"].(string)

	process.NotifyStart()
	output, err := exec.Command("git", "-C", workingDir, "status", "--short").Output()
	if err != nil {
		process.Logger.Fatalln(err)
		process.NotifyMessage("error occured")
		process.NotifyDone()
		return
	}
	for i, line := range strings.Split(string(output), "\n") {
		if line != "" {
			status := line[0:2]
			var filename string
			var filename_before string
			if status == "R " || status == " R" {
				regex := regexp.MustCompile(`^(.*)\s->\s(.*)$`)
				match := regex.FindAllStringSubmatch(line[3:], -1)
				filename = filepath.Join(workingDir, match[0][2])
				filename_before = filepath.Join(workingDir, match[0][1])
			} else {
				filename = filepath.Join(workingDir, line[3:])
				filename_before = filepath.Join(workingDir, line[3:])
			}
			process.AddItem(candle.Item{
				"id":       i,
				"title":    line,
				"status":   line[0:2],
				"filename": filename,
				"filename_before": filename_before,
			})
		}
	}

	process.NotifyDone()
}
