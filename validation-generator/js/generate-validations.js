import fs from 'fs';
import readline from 'readline';

const STOP_TIMES_PATH = './stop_times.txt';
const OUTPUT_PATH = './validations.json';
const NUM_VALIDATIONS = 10000; // Ajuste à volonté
const VALIDATION_DATE = '2025-06-22'; // Ajuste à volonté

async function parseStopTimes(filePath) {
  const fileStream = fs.createReadStream(filePath);
  const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });

  const tripTimes = new Map();

  let header = [];
  for await (const line of rl) {
    if (!header.length) {
      header = line.split(',');
      continue;
    }

    const values = line.split(',');
    const row = Object.fromEntries(header.map((key, i) => [key, values[i]]));

    const { trip_id, arrival_time } = row;
    if (!tripTimes.has(trip_id)) tripTimes.set(trip_id, []);
    tripTimes.get(trip_id).push(arrival_time);
  }

  // Trie les heures pour chaque trip
  for (const [trip_id, times] of tripTimes) {
    tripTimes.set(
      trip_id,
      times
        .filter(Boolean)
        .map(t => parseTime(t))
        .sort((a, b) => a - b)
    );
  }

  return tripTimes;
}

function parseTime(timeStr) {
  // gère les cas où l'heure est > 24h (ex: 25:12:00)
  const [hh, mm, ss] = timeStr.split(':').map(Number);
  return hh * 3600 + mm * 60 + ss;
}

function formatTime(seconds) {
  const hh = Math.floor(seconds / 3600).toString().padStart(2, '0');
  const mm = Math.floor((seconds % 3600) / 60).toString().padStart(2, '0');
  const ss = (seconds % 60).toString().padStart(2, '0');
  return `${hh}:${mm}:${ss}`;
}

function getRandomItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generateValidations(tripTimes, count) {
  const validations = [];
  const tripIds = [...tripTimes.keys()];

  for (let i = 0; i < count; i++) {
    const trip_id = getRandomItem(tripIds);
    const times = tripTimes.get(trip_id);
    const timestamp = getRandomItem(times);

    validations.push({
      trip_id,
      validation_time: formatTime(timestamp),
      validation_date: VALIDATION_DATE,
    });
  }

  return validations;
}

async function main() {
  console.log('Parsing stop_times.txt...');
  const tripTimes = await parseStopTimes(STOP_TIMES_PATH);
  console.log(`Found ${tripTimes.size} trips.`);

  console.log(`Generating ${NUM_VALIDATIONS} validations...`);
  const validations = generateValidations(tripTimes, NUM_VALIDATIONS);

  console.log(`Writing to ${OUTPUT_PATH}...`);
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(validations, null, 2));
  console.log('Done.');
}

main().catch(console.error);
