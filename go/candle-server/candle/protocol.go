package candle

/**
 * Item
 */
type Item map[string]interface{}

/**
 * Start
 */
type StartRequest struct {
	Id   string                 `json:"id"`
	Path string                 `json:"path"`
	Args map[string]interface{} `json:"args"`
}

type StartResponse struct {
	Id string `json:"id"`
}

/**
 * Fetch
 */
type FetchRequest struct {
	Id    string `json:"id"`
	Query string `json:"query"`
	Index int    `json:"index"`
	Count int    `json:"count"`
}

type FetchResponse struct {
	Id            string `json:"id"`
	Items         []Item `json:"items"`
	Total         int    `json:"total"`
	FilteredTotal int    `json:"filtered_total"`
}

/**
 * Stop
 */
type StopRequest struct {
	Id string `json:"id"`
}

type StopResponse struct {
	Id string `json:"id"`
}

/**
 * Progress
 */
type ProgressMessage struct {
	Id            string `json:"id"`
	Total         int    `json:"total"`
	FilteredTotal int    `json:"filtered_total"`
}

/**
 * Done
 */
type DoneMessage struct {
	Id            string `json:"id"`
	Total         int    `json:"total"`
	FilteredTotal int    `json:"filtered_total"`
}

/**
 * Message
 */
type MessageMessage struct {
	Id      string `json:"id"`
	Message string `json:"message"`
}
