package candle

import (
	"regexp"
	"strings"

	"github.com/sahilm/fuzzy"
)

/**
 * regexp
 */
func (process *Process) regexp(query string, items []Item) []Item {
	for _, q := range strings.Split(query, " ") {
		q = strings.TrimSpace(q)
		if len(q) == 0 {
			continue
		}

		matches := make([]Item, 0)
		for _, item := range items {
			if match, err := regexp.MatchString(q, item["title"].(string)); match {
				matches = append(matches, item)
			} else if err != nil {
				process.Logger.Println(err)
			}
		}
		items = matches
	}
	return items
}

/**
 * fuzzy
 */
func (process *Process) fuzzy(query string, items []Item) []Item {
	for _, q := range strings.Split(query, " ") {
		q = strings.TrimSpace(q)
		if len(q) == 0 {
			continue
		}

		words := make([]string, len(items))
		for i, item := range items {
			words[i] = item["title"].(string)
		}

		matches := fuzzy.Find(q, words)
		new_items := make([]Item, len(matches))
		for i, match := range matches {
			new_items[i] = items[match.Index]
		}
		items = new_items
	}
	return items
}

/**
 * substring
 */
func (process *Process) substring(query string, items []Item) []Item {
	for _, q := range strings.Split(query, " ") {
		q = strings.TrimSpace(q)
		if len(q) == 0 {
			continue
		}

		matches := make([]Item, 0)
		for _, item := range items {
			negate := strings.HasPrefix(q, "!")
			if negate {
				q = strings.TrimLeft(q, "!")
				if !strings.Contains(strings.ToLower(item["title"].(string)), strings.ToLower(q)) {
					matches = append(matches, item)
				}
			} else {
				if strings.Contains(strings.ToLower(item["title"].(string)), strings.ToLower(q)) {
					matches = append(matches, item)
				}
			}
		}
		items = matches
	}
	return items
}

