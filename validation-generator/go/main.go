package main

import (
	"bufio"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	STOP_TIMES_PATH   = "./../stop_times.txt"
	OUTPUT_PATH       = "./validations.json"
	NUM_VALIDATIONS   = 100000000
	BATCH_SIZE        = 10000 // Write to file every 10k records to avoid memory overflow
)

type StopTime struct {
	Time   int
	StopID string
}

type Validation struct {
	TripID         string `json:"trip_id"`
	StopID         string `json:"stop_id"`
	ValidationTime string `json:"validation_time"`
}

func parseTime(timeStr string) int {
	parts := strings.Split(timeStr, ":")
	if len(parts) != 3 {
		return 0
	}
	
	h, _ := strconv.Atoi(parts[0])
	m, _ := strconv.Atoi(parts[1])
	s, _ := strconv.Atoi(parts[2])
	
	return h*3600 + m*60 + s
}

func formatTime(seconds int) string {
	h := seconds / 3600
	m := (seconds % 3600) / 60
	s := seconds % 60
	return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
}

func isPeakHour(seconds int) bool {
	hour := float64(seconds) / 3600.0
	return (hour >= 7 && hour < 9.5) || (hour >= 16.5 && hour < 19)
}

func weightedRandomIndex(weights []float64) int {
	total := 0.0
	for _, w := range weights {
		total += w
	}
	
	r := rand.Float64() * total
	sum := 0.0
	
	for i, w := range weights {
		sum += w
		if r < sum {
			return i
		}
	}
	
	return len(weights) - 1
}

func getRandomItem(slice []string) string {
	return slice[rand.Intn(len(slice))]
}

func parseStopTimes(path string) (map[string][]StopTime, map[string]int, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.Comma = ','
	
	// Read header
	header, err := reader.Read()
	if err != nil {
		return nil, nil, err
	}
	
	// Find column indices
	var tripIDIdx, arrivalTimeIdx, stopIDIdx int = -1, -1, -1
	for i, col := range header {
		switch strings.TrimSpace(col) {
		case "trip_id":
			tripIDIdx = i
		case "arrival_time":
			arrivalTimeIdx = i
		case "stop_id":
			stopIDIdx = i
		}
	}
	
	if tripIDIdx == -1 || arrivalTimeIdx == -1 || stopIDIdx == -1 {
		return nil, nil, fmt.Errorf("required columns not found in CSV")
	}

	tripStops := make(map[string][]StopTime)
	stopFrequency := make(map[string]int)

	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, nil, err
		}
		
		if len(record) <= tripIDIdx || len(record) <= arrivalTimeIdx || len(record) <= stopIDIdx {
			continue
		}

		tripID := strings.TrimSpace(record[tripIDIdx])
		arrivalTime := strings.TrimSpace(record[arrivalTimeIdx])
		stopID := strings.TrimSpace(record[stopIDIdx])

		if tripID == "" || arrivalTime == "" || stopID == "" {
			continue
		}

		time := parseTime(arrivalTime)
		
		tripStops[tripID] = append(tripStops[tripID], StopTime{
			Time:   time,
			StopID: stopID,
		})
		
		stopFrequency[stopID]++
	}

	return tripStops, stopFrequency, nil
}

func generateValidation(tripStops map[string][]StopTime, stopFrequency map[string]int, tripIDs []string) *Validation {
	tripID := getRandomItem(tripIDs)
	stops := tripStops[tripID]
	
	if len(stops) == 0 {
		return nil
	}

	// Calculate weights
	weights := make([]float64, len(stops))
	for i, stop := range stops {
		base := 1.0
		if isPeakHour(stop.Time) {
			base = 5.0
		}
		freq := float64(stopFrequency[stop.StopID])
		if freq == 0 {
			freq = 1.0
		}
		weights[i] = base * freq
	}

	idx := weightedRandomIndex(weights)
	selectedStop := stops[idx]

	return &Validation{
		TripID:         tripID,
		StopID:         selectedStop.StopID,
		ValidationTime: formatTime(selectedStop.Time),
	}
}

func writeValidationsStream(tripStops map[string][]StopTime, stopFrequency map[string]int, outputPath string, count int) error {
	file, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	defer writer.Flush()

	// Get trip IDs slice for random selection
	tripIDs := make([]string, 0, len(tripStops))
	for tripID := range tripStops {
		tripIDs = append(tripIDs, tripID)
	}

	// Write opening bracket
	writer.WriteString("[\n")

	batch := make([]*Validation, 0, BATCH_SIZE)
	generated := 0
	isFirst := true

	for i := 0; i < count; i++ {
		validation := generateValidation(tripStops, stopFrequency, tripIDs)
		if validation == nil {
			continue
		}

		batch = append(batch, validation)

		// Write batch when full or at the end
		if len(batch) >= BATCH_SIZE || i == count-1 {
			for _, v := range batch {
				if !isFirst {
					writer.WriteString(",\n")
				} else {
					isFirst = false
				}

				jsonData, err := json.Marshal(v)
				if err != nil {
					return err
				}
				
				writer.WriteString("  ")
				writer.Write(jsonData)
				generated++
			}

			// Flush to disk
			writer.Flush()
			
			// Clear batch
			batch = batch[:0]

			// Show progress
			if generated%10000 == 0 {
				fmt.Printf("Generated %d validations...\n", generated)
			}
		}
	}

	// Write closing bracket
	writer.WriteString("\n]")
	writer.Flush()

	fmt.Printf("Total validations generated: %d\n", generated)
	return nil
}

func main() {
	// Seed random number generator
	rand.Seed(time.Now().UnixNano())

	fmt.Println("Parsing stop_times.txt...")
	tripStops, stopFrequency, err := parseStopTimes(STOP_TIMES_PATH)
	if err != nil {
		fmt.Printf("Error parsing stop times: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Found %d trips and %d unique stops\n", len(tripStops), len(stopFrequency))
	fmt.Printf("Generating %d validations...\n", NUM_VALIDATIONS)

	fmt.Printf("Saving to %s...\n", OUTPUT_PATH)
	err = writeValidationsStream(tripStops, stopFrequency, OUTPUT_PATH, NUM_VALIDATIONS)
	if err != nil {
		fmt.Printf("Error writing validations: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Done!")
}