import AsyncStorage from '@react-native-async-storage/async-storage';
import { isWord, pickUnusedWord } from './rules';

export { pickUnusedWord as selectDatabaseWord };

const PREFIX = 'snoozelose:word:v1:';
export const SAMPLE_PUZZLE_ID = 'preview:sample';
const keyFor = (id) => id === SAMPLE_PUZZLE_ID
  ? 'snoozelose:word-sample:v1'
  : PREFIX + encodeURIComponent(id);
let preparation = Promise.resolve();

export async function loadWordPuzzle(occurrenceId) {
  const value = await AsyncStorage.getItem(keyFor(occurrenceId));
  return value ? JSON.parse(value) : null;
}

export function prepareWordPuzzle(occurrenceId, generateWord) {
  if (typeof occurrenceId !== 'string' || !occurrenceId.trim()) {
    return Promise.reject(new Error('An alarm occurrence ID is required.'));
  }

  const task = preparation.then(async () => {
    const existing = await loadWordPuzzle(occurrenceId);
    if (existing) return existing;

    const keys = (await AsyncStorage.getAllKeys()).filter((key) => key.startsWith(PREFIX));
    const records = await AsyncStorage.multiGet(keys);
    const excluded = records.flatMap(([, value]) => value ? [JSON.parse(value).answer] : []);
    const answer = await generateWord(excluded);
    if (!isWord(answer) || excluded.includes(answer)) {
      throw new Error('The generator did not return a new dictionary word.');
    }

    const puzzle = { occurrenceId, answer, guesses: [] };
    await saveWordPuzzle(puzzle);
    return puzzle;
  });

  preparation = task.catch(() => {});
  return task;
}

export function saveWordPuzzle(puzzle) {
  return AsyncStorage.setItem(keyFor(puzzle.occurrenceId), JSON.stringify(puzzle));
}
