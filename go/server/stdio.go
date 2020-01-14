package server

import "os"

type Stdio struct{}

func (Stdio) Read(b []byte) (int, error) {
	return os.Stdin.Read(b)
}

func (Stdio) Write(b []byte) (int, error) {
	return os.Stdin.Write(b)
}

func (Stdio) Close() error {
	return os.Stdin.Close()
}

