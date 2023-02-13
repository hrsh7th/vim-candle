package main

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	workingDir := process.Args()["working_dir"].(string)

	process.NotifyStart()
	output, err := exec.Command(
		"git",
		"-C",
		workingDir,
		"log",
		"--max-count",
		"500",
		"--pretty=format:%H%x09%h%x09%P%x09%an%x09%ae%x09%ai%x09%s",
	).Output()
	if err != nil {
		process.Logger.Fatalln(err)
		process.NotifyMessage("error occured")
		process.NotifyDone()
		return
	}

	objects := make([]map[string]string, 0)

	author_name_width := 0
	for i, line := range strings.Split(string(output), "\n") {
		if line != "" {
			columns := strings.Split(line, "\t")
			object := map[string]string{
				"id":            fmt.Sprint(i),
				"commit_hash":   columns[0],
				"short_hash":    columns[1],
				"parent_hashes": columns[2],
				"author_name":   columns[3],
				"author_email":  columns[4],
				"author_date":   columns[5],
				"subject":       columns[6],
			}
			author_name_width = max(len(object["author_name"]), author_name_width)
			objects = append(objects, object)
		}
	}
	for _, object := range objects {
		process.AddItem(candle.Item{
			"id": object["id"],
			"title": fmt.Sprintf(
				"%s   %s   %-*s   %s",
				object["author_date"],
				object["short_hash"],
				author_name_width,
				object["author_name"],
				object["subject"],
			),
			"commit_hash":   object["commit_hash"],
			"short_hash":    object["short_hash"],
			"parent_hashes": object["parent_hashes"],
			"author_name":   object["author_name"],
			"author_email":  object["author_email"],
			"author_date":   object["author_date"],
			"subject":       object["subject"],
		})
	}

	process.NotifyDone()
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
