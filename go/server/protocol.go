package server

type StartRequest struct {
	Id     string                 `json:"id"`
	Script string                 `json:"source"`
	Params map[string]interface{} `json:"params"`
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

