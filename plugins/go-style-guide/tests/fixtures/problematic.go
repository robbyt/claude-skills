package main

import (
	"fmt"
	"log"
	"os"
	"sync"
)

// Issue 1: Fire-and-forget goroutine (no lifecycle management)
func startWorker() {
	go func() {
		for {
			doWork()
		}
	}()
}

// Issue 2: Panic in library function (should return error)
func ParseConfig(data []byte) *Config {
	if len(data) == 0 {
		panic("empty config")
	}
	return &Config{}
}

// Issue 3: Mutex race - not holding lock during access
func (s *State) GetValue() int {
	s.mu.Lock()
	s.mu.Unlock()
	return s.value // Race!
}

// Issue 4: Error handling - logs AND returns (handles twice)
func writeFile(path string, data []byte) error {
	if err := os.WriteFile(path, data, 0644); err != nil {
		log.Printf("write failed: %v", err)
		return fmt.Errorf("write %s: %w", path, err)
	}
	return nil
}

// Issue 5: Closure variable capture - err = vs err :=
func Run() error {
	var wg sync.WaitGroup
	var err error

	wg.Add(1)
	go func() {
		defer wg.Done()
		err = taskA() // Race: captures outer err
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()
		err = taskB() // Race: captures outer err
	}()

	wg.Wait()
	return err
}

// Issue 6: Global mutable state
var cache = make(map[string]string)

func Get(key string) string {
	return cache[key]
}

// Supporting types
type Config struct{}
type State struct {
	mu    sync.Mutex
	value int
}

func doWork()      {}
func taskA() error { return nil }
func taskB() error { return nil }
func main()        {}
