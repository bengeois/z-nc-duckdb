# z-nc-duckdb

Zenika - NightClazz DuckDB

A project focused on analyzing the Nantes transportation system using DuckDB, with tools to generate realistic validation data from GTFS (General Transit Feed Specification) datasets.

## 📊 Data Source

Complete dataset of Nantes transportation system: 
https://data.nantesmetropole.fr/explore/dataset/244400404_transports_commun_naolib_nantes_metropole_gtfs/table/

## 🛠️ Installation

1. Clone the repository

2. Navigate to the validation generator:
   ```bash
   cd validation-generator
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Download `stop_times.txt` from gtfs_lumidata_id.zip file and place it in the `validation-generator/` directory

## 📝 Usage

### Basic Validation Generation

Generate simple validation data with random distribution:

```bash
node generate-validations.js
```

This will create 10,000 validation records with:
- Random trip selection
- Random time selection from available stops
- Output: `validations.json`

### Advanced Validation Generation

Generate more realistic validation data with weighted patterns:

```bash
node generate-validations-with-frequent-stops-and-hours.js
```

This will create 100,000 validation records with:
- **Peak hour weighting**: 5x more likely during rush hours
- **Popular stop weighting**: More validations at frequently used stops
- **Stop information**: Includes both trip and stop details
- Output: `validations.json`

### Configuration

You can modify the generation parameters by editing the constants in each script:

```javascript
// In generate-validations.js
const NUM_VALIDATIONS = 10000; // Adjust as needed

// In generate-validations-with-frequent-stops-and-hours.js
const NUM_VALIDATIONS = 100000; // Adjust as needed
```

## 📋 Output Format

### Basic Generator Output
```json
[
  {
    "trip_id": "12345",
    "validation_time": "08:30:15"
  },
  ...
]
```

### Advanced Generator Output
```json
[
  {
    "trip_id": "12345",
    "stop_id": "STOP_001",
    "validation_time": "08:30:15"
  },
  ...
]
```

## 🔧 Technical Details

### Peak Hour Detection
The advanced generator identifies peak hours as:
- Morning: 7:00 AM - 9:30 AM
- Evening: 4:30 PM - 7:00 PM

### Weighting Algorithm
The validation probability for each stop is calculated as:
```
weight = base_multiplier × stop_frequency
```
Where:
- `base_multiplier` = 5 during peak hours, 1 otherwise
- `stop_frequency` = number of times the stop appears in the dataset

## 🔗 Related Resources

- [DuckDB Documentation](https://duckdb.org/docs/)
- [GTFS Reference](https://gtfs.org/reference/)
- [Nantes Open Data Portal](https://data.nantesmetropole.fr/)