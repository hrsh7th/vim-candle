package candle

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"

	"github.com/monochromegane/go-gitignore"
	"github.com/saracen/walker"
)

type WalkEntry = struct {
	Pathname string
	FileInfo os.FileInfo
}

/**
 * Walk
 */
func (process *Process) Walk(root string, callback func(pathname string, fi os.FileInfo) bool) chan WalkEntry {
	ch := make(chan WalkEntry, 0)

	go func() {
		walker.Walk(root, func(pathname string, fi os.FileInfo) error {
			if !callback(pathname, fi) {
				if fi.IsDir() {
					return filepath.SkipDir
				} else {
					return nil
				}
			}

			ch <- WalkEntry{Pathname: pathname, FileInfo: fi}

			return nil
		})
		close(ch)
	}()
	return ch
}

/**
 * Command
 */
func (process *Process) Command(command []string) *exec.Cmd {
	return exec.Command(command[0], command[1:]...)
}

/**
 * NewGitIgnore
 */
func (process *Process) NewIgnoreMatcher(patterns []string) func(pathname string, isDir bool) bool {
	found := false
	for _, pattern := range patterns {
		if len(pattern) > 1 {
			found = true
			break
		}
	}
	if !found {
		return func(pathname string, isDir bool) bool {
			return false
		}
	}
	reader := strings.NewReader(strings.Join(patterns, "\n"))
	gitignore := gitignore.NewGitIgnoreFromReader("/", reader)
	return gitignore.Match
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
	var current interface{} = process.args
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
