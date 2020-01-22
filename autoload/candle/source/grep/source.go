package main

import (
	"bufio"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/hrsh7th/vim-candle/go/candle"
)

var Items []candle.Item = make([]candle.Item, 0)

func Start(process *candle.Process) {
	pattern := process.GetString([]string{"pattern"})
	cwd := process.GetString([]string{"cwd"})

	go func() {
		cmd := exec.Command("grep", "-rin", pattern, cwd)
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			process.Logger.Println(err)
			return
		}

		err = cmd.Start()
		if err != nil {
			process.Logger.Println(err)
			return
		}

		index := 0
		now := makeTimestamp()
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			item := toItem(cwd, index, scanner.Text())
			if item != nil {
				Items = append(Items, item)
				index += 1
				if makeTimestamp()-now > 100 {
					process.NotifyProgress()
					now = makeTimestamp()
				}
			}
		}

		process.NotifyDone()
	}()
}

func makeTimestamp() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
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
	}
}
