package candle

/**
 * Item
 */
type Item map[string]interface{}

/**
 * Start
 */
type StartRequest struct {
	Path string                 `json:"path"`
	Args map[string]interface{} `json:"args"`
}

type StartResponse struct {
}

/**
 * Fetch
 */
type FetchRequest struct {
	Query string `json:"query"`
	Index int    `json:"index"`
	Count int    `json:"count"`
}

type FetchResponse struct {
	Items         []Item `json:"items"`
	Total         int    `json:"total"`
	FilteredTotal int    `json:"filtered_total"`
}

/**
 * Progress
 */
type ProgressMessage struct {
	Total         int `json:"total"`
	FilteredTotal int `json:"filtered_total"`
}

/**
 * Done
 */
type DoneMessage struct {
	Total         int `json:"total"`
	FilteredTotal int `json:"filtered_total"`
}

/**
 * Message
 */
type MessageMessage struct {
	Message string `json:"message"`
}
