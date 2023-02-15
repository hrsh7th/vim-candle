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
		"branch",
		"--all",
		`--format=%(HEAD)%09%(refname)%09%(upstream)%09%(upstream:trackshort)%09%(subject)`,
		"--sort=-authordate",
		"--sort=-push",
	).Output()
	if err != nil {
		process.Logger.Fatalln(err)
		process.NotifyMessage("error occured")
		process.NotifyDone()
		return
	}

	objects := make([]map[string]interface{}, 0)
	widths := map[string]int{}
	for i, line := range strings.Split(string(output), "\n") {
		if line != "" {
			columns := strings.Split(line, "\t")

			refparts := strings.Split(columns[1], "/")
			var name, label string
			var local bool
			if len(refparts) > 1 {
				local = refparts[1] == "heads"
				if local {
					name = strings.Join(refparts[2:], "/")
					label = name
				} else if len(refparts) > 3 {
					name = strings.Join(refparts[3:], "/")
					label = columns[1]
				}
			} else {
				local = true
				name = columns[1]
				label = columns[1]
			}
			object := map[string]interface{}{
				"id":             fmt.Sprint(i),
				"HEAD":           columns[0],
				"name":           name,
				"label":          label,
				"refname":        columns[1],
				"upstream":       columns[2],
				"upstream_track": columns[3],
				"subject":        columns[4],
				"local":          local,
			}
			objects = append(objects, object)
			for _, field := range []string{"HEAD", "label", "upstream", "upstream_track"} {
				widths[field] = max(len(object[field].(string)), widths[field])
			}
		}
	}
	for _, object := range objects {
		process.AddItem(candle.Item{
			"id": object["id"],
			"title": fmt.Sprintf(
				"%s   %-*s   %-*s   %-*s   %s",
				object["HEAD"],
				widths["label"],
				object["label"],
				widths["upstream_track"],
				object["upstream_track"],
				widths["upstream"],
				object["upstream"],
				object["subject"],
			),
			"name":           object["name"],
			"label":          object["label"],
			"refname":        object["refname"],
			"upstream":       object["upstream"],
			"upstream_track": object["upstream_track"],
			"subject":        object["subject"],
			"local":          object["local"],
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
