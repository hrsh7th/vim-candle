package candle

import "os"

type Stdio struct{}

func (Stdio) Read(b []byte) (int, error) {
	return os.Stdin.Read(b)
}

func (Stdio) Write(b []byte) (int, error) {
	return os.Stdout.Write(b)
}

func (Stdio) Close() error {
	if err := os.Stdin.Close(); err != nil {
		return err
	}
	return os.Stdout.Close()
}

