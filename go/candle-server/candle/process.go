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
	ctx    *context.Context
	conn   *jsonrpc2.Conn
	Logger *log.Logger

	lastProgressTime int64
	query            string
	allItems         []Item
	filteredItems    []Item

	path   string
	args   map[string]interface{}
	interp *interp.Interpreter
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
		allItems:         []Item{},
		filteredItems:    []Item{},
	}, nil
}

/**
 * Start
 */
func (process *Process) Start(params StartRequest) (StartResponse, error) {
	process.path = params.Path
	process.args = params.Args

	source, err := ioutil.ReadFile(process.path)
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, err
	}

	i := interp.New(interp.Options{})

	stdlib.Symbols["github.com/hrsh7th/vim-candle/go/candle-server/candle"] = map[string]reflect.Value{
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
	params.Query = strings.TrimSpace(params.Query)

	if params.Query != process.query {
		var items []Item
		if process.query != "" && params.Query != "" && strings.HasPrefix(params.Query, process.query) {
			items = process.filteredItems
		} else {
			items = process.allItems
		}
		process.filteredItems = process.filter(params.Query, items)
		process.query = params.Query
	}

	return FetchResponse{
		Items:         slice(process.filteredItems, params.Index, params.Index+params.Count),
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	}, nil
}

/**
 * NotifyStart
 */
func (process *Process) NotifyStart() {
	process.lastProgressTime = now()
	process.query = ""
	process.allItems = []Item{}
	process.filteredItems = []Item{}
	process.conn.Notify(context.Background(), "start", &ProgressMessage{
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyProgress
 */
func (process *Process) NotifyProgress() {
	process.conn.Notify(context.Background(), "progress", &ProgressMessage{
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyDone
 */
func (process *Process) NotifyDone() {
	process.conn.Notify(context.Background(), "done", &DoneMessage{
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyMessage
 */
func (process *Process) NotifyMessage(message string) {
	process.conn.Notify(context.Background(), "message", &MessageMessage{
		Message: message,
	})
}

/**
 * AddItem
 */
func (process *Process) AddItem(item Item) {
	process.allItems = append(process.allItems, item)

	if len(process.filter(process.query, []Item{item})) == 1 {
		process.filteredItems = append(process.filteredItems, item)
	}

	if now()-process.lastProgressTime > 200 || len(process.allItems) == 100 {
		process.NotifyProgress()
		process.lastProgressTime = now()
	}
}

/**
 * total
 */
func (process *Process) total() int {
	return len(process.allItems)
}

/**
 * filteredTotal
 */
func (process *Process) filteredTotal() int {
	query := strings.TrimSpace(process.query)
	if len(query) > 0 {
		return len(process.filteredItems)
	}
	return process.total()
}

/**
 * filter
 */
func (process *Process) filter(query string, items []Item) []Item {
	switch process.args["filter"] {
	case "fuzzy":
		items = process.fuzzy(query, items)
	case "regexp":
		items = process.regexp(query, items)
	case "substring":
		items = process.substring(query, items)
	default:
		items = process.substring(query, items)
	}
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
