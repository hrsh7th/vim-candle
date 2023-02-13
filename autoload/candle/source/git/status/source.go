package main

import (
	"os/exec"
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
			process.AddItem(candle.Item{
				"id":       i,
				"title":    line,
				"status":   line[0:2],
				"filename": line[3:],
			})
		}
	}

	process.NotifyDone()
}
