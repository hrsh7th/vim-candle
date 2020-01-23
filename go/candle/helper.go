package candle

import (
	"github.com/karrick/godirwalk"
	"reflect"
	"strconv"
)

/**
 * Walk
 */
func (process *Process) Walk(root string, callback func(pathname string) error) error {
	return godirwalk.Walk(root, &godirwalk.Options{
		Callback: func(pathname string, entry *godirwalk.Dirent) error {
			return callback(pathname)
		},
		Unsorted: false,
	})
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
	var current interface{} = process.params
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
