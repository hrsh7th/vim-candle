package server

import (
	"context"
	"os"

	"github.com/d5/tengo/v2"
	"github.com/sourcegraph/jsonrpc2"
)

type Process struct {
	Ctx      context.Context
	Conn     *jsonrpc2.Conn
	Id       string
	Name     string
	Script   *tengo.Script
	Compiled *tengo.Compiled
}

func NewProcess(ctx context.Context, conn *jsonrpc2.Conn, id string, script string) (*Process, error) {
	source, err := load(script)
	if err != nil {
		return nil, err
	}

	return &Process{
		Ctx:    ctx,
		Conn:   conn,
		Id:     id,
		Name:   script,
		Script: tengo.NewScript(source),
	}, nil
}

func (process *Process) Start(params interface{}) error {
	process.Script.Add("params", params)

	process.Script.Add("notifyProgress", func(message string) {
		process.Conn.Notify(process.Ctx, "progress", ProgressMessage{
			Id:      process.Id,
			Type:    Progress,
			Message: message,
		})
	})

	process.Script.Add("notifyDone", func(message string) {
		process.Conn.Notify(process.Ctx, "progress", ProgressMessage{
			Id:      process.Id,
			Type:    Done,
			Message: message,
		})
	})

	compiled, err := process.Script.RunContext(context.Background())
	if err != nil {
		return err
	}
	process.Compiled = compiled
	return nil
}

func load(script string) ([]byte, error) {
	file, err := os.OpenFile(script, os.O_RDONLY, 0660)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	buffer := make([]byte, 0)
	for {
		n, err := file.Read(buffer)
		if err != nil {
			return nil, err
		}
		if n == 0 {
			break
		}
	}

	return buffer, nil
}
