# Validations Generator

## 📝 Usage

### JavaScript Implementation

#### Basic Validation Generation
Generate simple validation data with random distribution:

```bash
cd validation-generator/js
node generate-validations.js
```

This creates 10,000 validation records with random trip and time selection.

#### Advanced Validation Generation
Generate realistic validation data with weighted patterns:

```bash
cd validation-generator/js
node generate-validations-with-frequent-stops-and-hours.js
```

This creates 10,000,000 validation records with intelligent weighting.

### Go Implementation (Recommended for Large Datasets)

Generate high-performance validation data:

```bash
cd validation-generator/go
go run main.go 100000000 2025-06-22
```

### Configuration

#### JavaScript
Edit constants in the respective `.js` files:
```javascript
const NUM_VALIDATIONS = 10000000; // Adjust as needed
const VALIDATION_DATE = "2025-06-22"; // Adjust as needed
```

#### Go
Use arguments passed to the Go program:
```bash
go run main.go <numValidations> <validationDate>
```

## 📋 Output Format

Both implementations generate identical JSON format:

```json
[
  {
    "trip_id": "12345",
    "stop_id": "STOP_001",
    "validation_time": "08:30:15",
    "validation_date": "2025-06-22"
  },
  ...
]
```

## ⚡ Performance Comparison

| Implementation | Dataset Size | Memory Usage | Execution Time* |
| -------------- | ------------ | ------------ | --------------- |
| JavaScript     | 1M records   | ~200MB       | ~30 seconds     |
| JavaScript     | 10M records  | ~500MB       | ~5 minutes      |
| **Go**         | 1M records   | ~50MB        | ~5 seconds      |
| **Go**         | 100M records | ~100MB       | ~8 minutes      |

*Approximate times on modern hardware

## 🔧 Technical Details

### Peak Hour Detection
Both implementations identify peak hours as:
- **Morning**: 7:00 AM - 9:30 AM
- **Evening**: 4:30 PM - 7:00 PM

### Weighting Algorithm
The validation probability for each stop is calculated as:
```
weight = base_multiplier × stop_frequency
```
Where:
- `base_multiplier` = 5 during peak hours, 1 otherwise
- `stop_frequency` = number of times the stop appears in the dataset
