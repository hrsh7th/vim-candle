package candle

import (
	"context"
	"io/ioutil"
	"log"
	"os"
	"reflect"
	"strings"
	"time"

	"github.com/sourcegraph/jsonrpc2"
	"github.com/traefik/yaegi/interp"
	"github.com/traefik/yaegi/stdlib"
	"github.com/traefik/yaegi/stdlib/unrestricted"
	"github.com/traefik/yaegi/stdlib/unsafe"
)

type Process struct {
	ctx    *context.Context
	conn   *jsonrpc2.Conn
	Logger *log.Logger

	lastProgressTime int64
	query            string
	allItems         []Item
	filteredItems    []Item

	id     string
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
	process.id = params.Id
	process.path = params.Path
	process.args = params.Args

	source, err := ioutil.ReadFile(process.path)
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, err
	}

	i := interp.New(interp.Options{
		GoPath: os.Getenv("GOPATH"),
	})

	i.Use(interp.Exports{
		"github.com/hrsh7th/vim-candle/go/candle-server/candle/candle": {
			"Process": reflect.ValueOf((*Process)(nil)),
			"Item":    reflect.ValueOf((*Item)(nil)),
		},
	})
	i.Use(interp.Symbols)
	i.Use(stdlib.Symbols)
	i.Use(unsafe.Symbols)
	i.Use(unrestricted.Symbols)

	if _, err = i.Eval(string(source)); err != nil {
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

	go func() {
		defer func() {
			if err := recover(); err != nil {
				process.Logger.Printf(err.(string))
			}
		}()
		start(process)
	}()

	return StartResponse{}, nil
}

/**
 * Args
 */
func (process *Process) Args() map[string]interface{} {
	return process.args
}

/**
 * Fetch
 */
func (process *Process) Fetch(params FetchRequest) (FetchResponse, error) {
	params.Query = strings.TrimSpace(params.Query)

	if params.Query != process.query {
		process.filteredItems = process.filter(params.Query, process.allItems)
		process.query = params.Query
	}

	return FetchResponse{
		Items:         slice(process.filteredItems, params.Index, params.Index+params.Count),
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	}, nil
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
	if len(items) == 0 {
		return items
	}

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
