package main

import (
	"bufio"
	"fmt"
	"strconv"
	"strings"

	"github.com/hrsh7th/vim-candle/go/candle-server/candle"
)

func Start(process *candle.Process) {
	rootPath := process.GetString([]string{"root_path"})
	pattern := process.GetString([]string{"pattern"})

	command := make([]string, 0)
	for i := 0; i < process.Len([]string{"command"}); i++ {
		part := process.GetString([]string{"command", strconv.Itoa(i)})
		if part == "%PATTERN%" {
			command = append(command, pattern)
		} else if part == "%ROOT_PATH%" {
			command = append(command, rootPath)
		} else {
			command = append(command, part)
		}
	}

	go func() {
		process.NotifyStart()

		cmd := process.Command(command)
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			process.NotifyMessage(err.Error())
			process.NotifyDone()
			return
		}

		err = cmd.Start()
		if err != nil {
			process.NotifyMessage(err.Error())
			process.NotifyDone()
			return
		}

		index := 0
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			item := toItem(rootPath, index, scanner.Text())
			if item != nil {
				process.AddItem(item)
				index += 1
			}
		}

		process.NotifyDone()
	}()
}

func toItem(prefix string, index int, line string) map[string]interface{} {
	sub := strings.SplitN(line, ":", 3)
	if len(sub) != 3 {
		return nil
	}

	lnum, err := strconv.Atoi(sub[1])
	if err != nil {
		return nil
	}

	return map[string]interface{}{
		"id": strconv.Itoa(index),
		"title": fmt.Sprintf(
			"%s:%s\t%s",
			strings.TrimPrefix(sub[0], prefix),
			sub[1],
			sub[2],
		),
		"path": sub[0],
		"lnum": lnum,
		"text": sub[2],
	}
}
