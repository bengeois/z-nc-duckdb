import fs from 'fs';
import csv from 'csv-parser';

const STOP_TIMES_PATH = './stop_times.txt';
const OUTPUT_PATH = './validations.json';
const NUM_VALIDATIONS = 100000;

function parseTime(str) {
  const [h, m, s] = str.split(':').map(Number);
  return h * 3600 + m * 60 + s;
}

function formatTime(seconds) {
  const h = String(Math.floor(seconds / 3600)).padStart(2, '0');
  const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
  const s = String(seconds % 60).padStart(2, '0');
  return `${h}:${m}:${s}`;
}

function isPeakHour(seconds) {
  const hour = seconds / 3600;
  return (hour >= 7 && hour < 9.5) || (hour >= 16.5 && hour < 19);
}

function weightedRandomIndex(weights) {
  const total = weights.reduce((a, b) => a + b, 0);
  const r = Math.random() * total;
  let sum = 0;
  for (let i = 0; i < weights.length; i++) {
    sum += weights[i];
    if (r < sum) return i;
  }
  return weights.length - 1;
}

function getRandomItem(array) {
  return array[Math.floor(Math.random() * array.length)];
}

async function parseStopTimes(path) {
  const tripStops = new Map(); // trip_id → [{ time, stop_id }]
  const stopFrequency = new Map(); // stop_id → count

  return new Promise((resolve, reject) => {
    fs.createReadStream(path)
      .pipe(csv())
      .on('data', (row) => {
        const trip_id = row.trip_id;
        const arrival_time = row.arrival_time;
        const stop_id = row.stop_id;

        if (!trip_id || !arrival_time || !stop_id) return;

        const time = parseTime(arrival_time);

        if (!tripStops.has(trip_id)) {
          tripStops.set(trip_id, []);
        }
        tripStops.get(trip_id).push({ time, stop_id });

        stopFrequency.set(stop_id, (stopFrequency.get(stop_id) || 0) + 1);
      })
      .on('end', () => {
        resolve({ tripStops, stopFrequency });
      })
      .on('error', reject);
  });
}

function generateValidations(tripStops, stopFrequency, count) {
  const validations = [];
  const tripIds = [...tripStops.keys()];

  for (let i = 0; i < count; i++) {
    const trip_id = getRandomItem(tripIds);
    const stops = tripStops.get(trip_id);
    if (!stops?.length) continue;

    const weights = stops.map(({ time, stop_id }) => {
      const base = isPeakHour(time) ? 5 : 1;
      const freq = stopFrequency.get(stop_id) || 1;
      return base * freq;
    });

    const idx = weightedRandomIndex(weights);
    const { time, stop_id } = stops[idx];

    validations.push({
      trip_id,
      stop_id,
      validation_time: formatTime(time),
    });
  }

  return validations;
}

async function main() {
  console.log('Parsing stop_times.txt...');
  const { tripStops, stopFrequency } = await parseStopTimes(STOP_TIMES_PATH);

  console.log('Generating validations...');
  const validations = generateValidations(tripStops, stopFrequency, NUM_VALIDATIONS);

  console.log(`Saving to ${OUTPUT_PATH}...`);
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(validations, null, 2), 'utf-8');

  console.log('Done!');
}

main().catch(console.error);
