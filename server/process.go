package server

import (
	"context"
	"os"

	"github.com/d5/tengo/v2"
	"github.com/sourcegraph/jsonrpc2"
)

type Process struct {
	Conn   *jsonrpc2.Conn
	Id     string
	Name   string
	Script *tengo.Script
}

func NewProcess(conn *jsonrpc2.Conn, id string, script string) (*Process, error) {
	source, err := load(script)
	if err != nil {
		return nil, err
	}

	return &Process{
		Conn:   conn,
		Id:     id,
		Name:   script,
		Script: tengo.NewScript(source),
	}, nil
}

func (process *Process) Start(params interface{}) (interface{}, error) {
	process.Script.Add("params", params)
	compiled, err := process.Script.RunContext(context.Background())
	if err != nil {
		return nil, err
	}
	return compiled.Get("results"), nil
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
