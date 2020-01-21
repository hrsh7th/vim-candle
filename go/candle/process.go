package candle

import (
	"context"
	"io/ioutil"
	"log"
	"reflect"
	"sort"
	"strconv"
	"strings"

	"github.com/containous/yaegi/interp"
	"github.com/containous/yaegi/stdlib"
	"github.com/sahilm/fuzzy"
	"github.com/sourcegraph/jsonrpc2"
)

type Process struct {
	Ctx    *context.Context
	Conn   *jsonrpc2.Conn
	Logger *log.Logger
	Query  string
	Items  []Item

	Id     string
	Script string
	Params map[string]interface{}
	Interp *interp.Interpreter
}

/**
 * NewProcess
 */
func NewProcess(handler *Handler, ctx *context.Context, conn *jsonrpc2.Conn) (*Process, error) {
	return &Process{
		Ctx:    ctx,
		Conn:   conn,
		Logger: handler.Logger,
		Query:  "",
		Items:  make([]Item, 0),
	}, nil
}

/**
 * Start
 */
func (process *Process) Start(params StartRequest) (StartResponse, error) {
	process.Id = params.Id
	process.Script = params.Script
	process.Params = params.Params

	source, err := ioutil.ReadFile(process.Script)
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, err
	}

	stdlib.Symbols["github.com/hrsh7th/vim-candle/go/candle"] = map[string]reflect.Value{
		"Process": reflect.ValueOf((*Process)(nil)),
		"Item":    reflect.ValueOf((*Item)(nil)),
	}

	i := interp.New(interp.Options{})
	i.Use(stdlib.Symbols)
	if _, err := i.Eval(string(source)); err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	start_, err := i.Eval("Start")
	if err != nil {
		process.Logger.Println(err)
		return StartResponse{}, nil
	}

	start, ok := start_.Interface().(func(*Process))
	if !ok {
		process.Logger.Println("Can't cast `Start`")
		return StartResponse{}, nil
	}

	process.Interp = i
	start(process)

	return StartResponse{}, nil
}

/**
 * Fetch
 */
func (process *Process) Fetch(params FetchRequest) (FetchResponse, error) {
	process.Items = process.query(params.Query)
	return FetchResponse{
		Id:    params.Id,
		Items: process.slice(process.Items, params.Index, params.Index+params.Count),
		Total: len(process.Items),
	}, nil
}

/**
 * Len
 */
func (process *Process) Len(keys []string) int {
	value := process.Get(keys)
	if value == nil {
		return 0
	}
	list, ok := value.([]interface{})
	if ok {
		return len(list)
	}
	return 0
}

/**
 * GetInt
 */
func (process *Process) GetInt(keys []string) int {
	value, ok := process.Get(keys).(int)
	if !ok {
		return 0
	}
	return value
}

/**
 * GetString
 */
func (process *Process) GetString(keys []string) string {
	value, ok := process.Get(keys).(string)
	if !ok {
		return ""
	}
	return value
}

/**
 * Get
 */
func (process *Process) Get(keys []string) interface{} {
	var current interface{} = process.Params
	for _, key := range keys {
		switch reflect.TypeOf(current) {

		// map[string]interface{}
		case reflect.TypeOf(map[string]interface{}{}):
			current = current.(map[string]interface{})[key].(interface{})

		// map[int]interface{}
		case reflect.TypeOf(map[int]interface{}{}):
			key, err := strconv.Atoi(key)
			if err != nil {
				return nil
			}
			current = current.(map[int]interface{})[key].(interface{})

		// []interface{}
		case reflect.TypeOf([]interface{}{}):
			key, err := strconv.Atoi(key)
			if err != nil {
				return nil
			}
			current = current.([]interface{})[key].(interface{})

		default:
			return nil
		}
	}
	return current
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
	if len(query) == 0 {
		return process.items()
	}

	var items []Item
	if process.Query != "" && strings.HasPrefix(query, process.Query) {
		items = process.Items
	} else {
		items = process.items()
	}
	process.Query = query

	returns := items
	for _, part := range strings.Split(query, " ") {
		part = strings.Trim(part, " ")
		if part == "" {
			continue
		}

		words := make([]string, len(returns))
		for i, item := range returns {
			words[i] = item["title"].(string)
		}

		matches := fuzzy.Find(part, words)
		sort.Sort(matches)

		var matched []Item = make([]Item, 0)
		for _, match := range matches {
			matched = append(matched, returns[match.Index])
		}
		returns = matched
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

