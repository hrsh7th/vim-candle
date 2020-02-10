package candle

import "context"

/**
 * NotifyStart
 */
func (process *Process) NotifyStart() {
	process.lastProgressTime = now()
	process.query = ""
	process.allItems = []Item{}
	process.filteredItems = []Item{}
	process.conn.Notify(context.Background(), "start", &ProgressMessage{
		Id:            process.id,
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyProgress
 */
func (process *Process) NotifyProgress() {
	process.conn.Notify(context.Background(), "progress", &ProgressMessage{
		Id:            process.id,
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyDone
 */
func (process *Process) NotifyDone() {
	process.conn.Notify(context.Background(), "done", &DoneMessage{
		Id:            process.id,
		Total:         process.total(),
		FilteredTotal: process.filteredTotal(),
	})
}

/**
 * NotifyMessage
 */
func (process *Process) NotifyMessage(message string) {
	process.conn.Notify(context.Background(), "message", &MessageMessage{
		Id:      process.id,
		Message: message,
	})
}
