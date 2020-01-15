package server

type Item struct {
	Title string `json:"title"`
}

type StartRequest struct {
	Id     string                 `json:"id"`
	Script string                 `json:"script"`
	Params map[string]interface{} `json:"params"`
}

type FetchRequest struct {
	Id    string `json:"id"`
	Index int    `json:"index"`
	Count int    `json:"count"`
}

type FetchResponse struct {
	Id    string `json:"id"`
	Items []Item `json:"items"`
}

type StartResponse struct {
}

type ProgressMessage struct {
	Id      string       `json:"id"`
	Type    ProgressType `json:"type"`
	Message string       `json:"message"`
}

type ProgressType int

const (
	Progress ProgressType = iota
	Done
)
