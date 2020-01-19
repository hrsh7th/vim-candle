package candle

import (
	"context"
	"io/ioutil"
	"log"
	"reflect"

	"github.com/containous/yaegi/interp"
	"github.com/containous/yaegi/stdlib"
	"github.com/sahilm/fuzzy"
	"github.com/sourcegraph/jsonrpc2"
)

type Process struct {
	Ctx    *context.Context
	Conn   *jsonrpc2.Conn
	Id     string
	Name   string
	Script string
	Logger *log.Logger
	Interp *interp.Interpreter
}

/**
 * NewProcess
 */
func NewProcess(handler *Handler, ctx *context.Context, conn *jsonrpc2.Conn, id string, script string) (*Process, error) {
	return &Process{
		Ctx:    ctx,
		Conn:   conn,
		Id:     id,
		Script: script,
		Logger: handler.Logger,
	}, nil
}

/**
 * Start
 */
func (process *Process) Start(params StartRequest) (StartResponse, error) {
	source, err := ioutil.ReadFile(process.Script)
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, err
	}

	process.Interp = interp.New(interp.Options{})
	stdlib.Symbols["github.com/hrsh7th/vim-candle/go/candle"] = map[string]reflect.Value{
		"Process":        reflect.ValueOf((*Process)(nil)),
		"Item":           reflect.ValueOf((*Item)(nil)),
		"StartRequest":   reflect.ValueOf((*StartRequest)(nil)),
		"StartResponse":  reflect.ValueOf((*StartResponse)(nil)),
		"NotifyProgress": reflect.ValueOf(process.NotifyProgress),
		"NotifyDone":     reflect.ValueOf(process.NotifyDone),
	}
	process.Interp.Use(stdlib.Symbols)
	_, err = process.Interp.Eval(string(source))
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	value, err := process.Interp.Eval("Start")
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	start, ok := value.Interface().(func(*Process, StartRequest) StartResponse)
	if !ok {
		process.Logger.Println("Can't cast `Start`")
		return StartResponse{}, nil
	}

	return start(process, params), nil
}

/**
 * Fetch
 */
func (process *Process) Fetch(params FetchRequest) (FetchResponse, error) {
	items := process.query(params.Query)
	return FetchResponse{
		Id:    params.Id,
		Items: process.slice(items, params.Index, params.Index+params.Count),
		Total: len(items),
	}, nil
}

/**
 * NotifyProgress
 */
func (process *Process) NotifyProgress() {
	process.Conn.Notify(context.Background(), "progress", &ProgressMessage{
		Id:    process.Id,
		Total: len(process.items()),
	})
}

/**
 * NotifyDone
 */
func (process *Process) NotifyDone() {
	process.Conn.Notify(context.Background(), "done", &DoneMessage{
		Id:    process.Id,
		Total: len(process.items()),
	})
}

/**
 * items
 */
func (process *Process) items() []Item {
	if process.Interp == nil {
		return make([]Item, 0)
	}

	value, err := process.Interp.Eval("Items")
	if err != nil {
		process.Logger.Println(err)
		return make([]Item, 0)
	}

	items, ok := value.Interface().([]Item)
	if !ok {
		process.Logger.Println("Can't cast `Items`")
		return make([]Item, 0)
	}

	returns := make([]Item, len(items))
	for i, item := range items {
		if _, ok = item["id"]; !ok {
			process.Logger.Printf("%d: has not property `id`", i)
			continue
		}
		if _, ok = item["title"]; !ok {
			process.Logger.Printf("%d: has not property `title`", i)
			continue
		}
		returns[i] = item
	}
	return returns
}

/**
 * query
 */
func (process *Process) query(query string) []Item {
	items := process.items()

	if len(query) == 0 {
		return items
	}

	words := make([]string, len(items))
	for i, item := range items {
		words[i] = item["title"].(string)
	}

	matches := fuzzy.Find(query, words)

	returns := make([]Item, len(matches))
	for i, match := range matches {
		returns[i] = items[match.Index]
	}
	return returns
}

/**
 * slice
 */
func (process *Process) slice(items []Item, start int, end int) []Item {
	if start >= len(items) {
		start = len(items) - 1
	}
	if start < 0 {
		start = 0
	}

	if end > len(items) {
		end = len(items)
	}
	if end < 0 {
		end = 0
	}
	return items[start:end]
}

/**
 * contains
 */
func (process *Process) contains(array []string, target string) bool {
	for _, item := range array {
		if item == target {
			return true
		}
	}
	return false
}
