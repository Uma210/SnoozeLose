import AsyncStorage from '@react-native-async-storage/async-storage';
import { createDive, reserveDive } from './rules';

const SEEN = 'snoozelose:krillion:history:v1';
const key = id => `snoozelose:krillion:occurrence:v1:${encodeURIComponent(id)}`;
let pending = Promise.resolve();

function serialize(work) {
  const operation = pending.then(work);
  pending = operation.catch(() => {});
  return operation;
}

export async function loadKrillionPuzzle(occurrenceId) {
  const saved = await AsyncStorage.getItem(key(occurrenceId));
  return saved ? JSON.parse(saved) : null;
}

async function assignDive(occurrenceId, mode) {
  const seen = JSON.parse(await AsyncStorage.getItem(SEEN) ?? '[]');
  const { prompts, history } = reserveDive(mode, seen);
  const dive = createDive(occurrenceId, mode, prompts);
  await AsyncStorage.multiSet([[key(occurrenceId), JSON.stringify(dive)], [SEEN, JSON.stringify(history)]]);
  return dive;
}

export function prepareKrillionPuzzle(occurrenceId) {
  if (typeof occurrenceId !== 'string' || !occurrenceId.trim()) {
    return Promise.reject(new Error('An alarm occurrence ID is required.'));
  }
  return serialize(async () => (await loadKrillionPuzzle(occurrenceId)) ?? assignDive(occurrenceId, 'standard'));
}

export function updateKrillionPuzzle(occurrenceId, update) {
  return serialize(async () => {
    const saved = await loadKrillionPuzzle(occurrenceId);
    if (!saved) throw new Error('This alarm has no prepared Krillion dive.');
    const next = update(saved);
    if (saved !== next) await AsyncStorage.setItem(key(occurrenceId), JSON.stringify(next));
    return next;
  });
}

export function restartKrillionPuzzle(occurrenceId, simpler) {
  return serialize(async () => {
    const saved = await loadKrillionPuzzle(occurrenceId);
    if (!saved) throw new Error('This alarm has no prepared Krillion dive.');
    if (saved.phase !== 'restart') return saved;
    return assignDive(occurrenceId, simpler ? 'simpler' : saved.mode);
  });
}
