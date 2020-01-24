package candle

import (
	"context"
	"io/ioutil"
	"log"
	"reflect"
	"strings"
	"time"

	"github.com/containous/yaegi/interp"
	"github.com/containous/yaegi/stdlib"
	"github.com/sourcegraph/jsonrpc2"
)

type Process struct {
	ctx              *context.Context
	conn             *jsonrpc2.Conn
	Logger           *log.Logger
	query            string
	lastProgressTime int64
	allItems         []Item
	filteredItems    []Item
	id               string
	script           string
	params           map[string]interface{}
	interp           *interp.Interpreter
}

/**
 * NewProcess
 */
func NewProcess(handler *Handler, ctx *context.Context, conn *jsonrpc2.Conn) (*Process, error) {
	return &Process{
		ctx:              ctx,
		conn:             conn,
		Logger:           handler.Logger,
		lastProgressTime: now(),
		query:            "",
		allItems:         make([]Item, 0),
		filteredItems:    make([]Item, 0),
	}, nil
}

/**
 * Start
 */
func (process *Process) Start(params StartRequest) (StartResponse, error) {
	process.id = params.Id
	process.script = params.Script
	process.params = params.Params

	source, err := ioutil.ReadFile(process.script)
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, err
	}

	i := interp.New(interp.Options{})

	stdlib.Symbols["github.com/hrsh7th/vim-candle/go/candle"] = map[string]reflect.Value{
		"Process": reflect.ValueOf((*Process)(nil)),
		"Item":    reflect.ValueOf((*Item)(nil)),
	}

	i.Use(stdlib.Symbols)
	if _, err := i.Eval(string(source)); err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	value, err := i.Eval("Start")
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	start, ok := value.Interface().(func(*Process))
	if !ok {
		process.Logger.Println("Can't cast `Start`")
		return StartResponse{}, nil
	}

	process.interp = i

	start(process)

	return StartResponse{}, nil
}

/**
 * Fetch
 */
func (process *Process) Fetch(params FetchRequest) (FetchResponse, error) {
	process.filteredItems = process.filter(params.Query)
	return FetchResponse{
		Id:    params.Id,
		Items: slice(process.filteredItems, params.Index, params.Index+params.Count),
		Total: len(process.filteredItems),
	}, nil
}

/**
 * NotifyProgress
 */
func (process *Process) NotifyProgress() {
	process.conn.Notify(context.Background(), "progress", &ProgressMessage{
		Id:    process.id,
		Total: len(process.allItems),
	})
}

/**
 * NotifyDone
 */
func (process *Process) NotifyDone() {
	process.conn.Notify(context.Background(), "done", &DoneMessage{
		Id:    process.id,
		Total: len(process.allItems),
	})
}

/**
 * AddItem
 */
func (process *Process) AddItem(item Item) {
	process.allItems = append(process.allItems, item)
	if now()-process.lastProgressTime > 500 {
		process.NotifyProgress()
		process.lastProgressTime = now()
	}
}

/**
 * filter
 */
func (process *Process) filter(query string) []Item {
	query = strings.TrimSpace(query)

	var items []Item
	if process.query != "" && query != "" && strings.HasPrefix(query, process.query) {
		items = process.filteredItems
	} else {
		items = process.allItems
	}

	switch process.params["filter"] {
	case "fuzzy":
		items = process.fuzzy(query, items)
	case "regexp":
		items = process.regexp(query, items)
	case "substring":
		items = process.substring(query, items)
	default:
		items = process.substring(query, items)
	}
	process.filteredItems = items
	process.query = query
	return items
}

/**
 * slice
 */
func slice(items []Item, start int, end int) []Item {
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
 * now
 */
func now() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}
