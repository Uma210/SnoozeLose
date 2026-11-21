import { categoryLabels, pools, starterPrompts } from './catalog.js';

export const PROMPT_TIME = 20_000;
export const FEEDBACK_TIME = 1_500;
export const DIVE_LENGTH = 7;
export const MISS_LIMIT = 3;

const answers = Object.fromEntries(Object.entries(pools).map(([category, entries]) => [
  category,
  entries.split(',').map(entry => {
    const delimiter = entry.lastIndexOf(':');
    return { names: entry.slice(0, delimiter).split('/'), points: Number(entry.slice(delimiter + 1)) };
  }),
]));

function allowedAnswers([, category, filter, value]) {
  return answers[category].filter(({ names }) => {
    const name = names[0].replace(/[^a-z ]/g, '');
    switch (filter) {
      case 's': return name.startsWith(value);
      case 'h': return name.includes(value);
      case 'e': return name.endsWith(value);
      case 'x': return !name.includes(value);
      case 'n': return name.replace(/ /g, '').length === value;
      default: return true;
    }
  });
}

function buildCatalog() {
  const catalog = new Map();

  function add(tuple, isGenerated = false) {
    const [text, category, , , level] = tuple;
    if (catalog.has(text)) return;
    const options = allowedAnswers(tuple);
    if (options.length < 3 || (isGenerated && options.length === answers[category].length)) return;
    catalog.set(text, { text, category, mode: level === 1 ? 'simpler' : 'standard', options });
  }

  starterPrompts.forEach(tuple => add(tuple));
  for (const [category, label] of Object.entries(categoryLabels)) {
    for (const lower of 'abcdefghijklmnopqrstuvwxyz') {
      const upper = lower.toUpperCase();
      add([`Name ${label} that starts with ${upper}`, category, 's', lower, 2], true);
      add([`Name ${label} with the letter ${upper} in its name`, category, 'h', lower, 2], true);
      add([`Name ${label} whose name ends in ${upper}`, category, 'e', lower, 2], true);
      add([`Name ${label} without the letter ${upper} in its name`, category, 'x', lower, 2], true);
    }
    for (let size = 3; size <= 12; size++) {
      add([`Name ${label} whose name is exactly ${size} letters long`, category, 'n', size, 2], true);
    }
  }
  return catalog;
}

const catalog = buildCatalog();
export const promptBank = [...catalog.values()];

export function reserveDive(mode, history, random = Math.random) {
  const bank = promptBank.filter(prompt => prompt.mode === mode);
  if (!bank.length) throw new Error('Unknown Krillion difficulty.');
  const seen = new Set(history.filter(text => catalog.has(text)));
  const prompts = [];
  const categories = new Set();
  while (prompts.length < DIVE_LENGTH) {
    let fresh = bank.filter(prompt => !seen.has(prompt.text));
    if (!fresh.length) {
      bank.forEach(prompt => seen.delete(prompt.text));
      fresh = bank;
    }
    const eligible = fresh.filter(prompt => !prompts.includes(prompt.text));
    const newCategories = eligible.filter(prompt => !categories.has(prompt.category));
    const candidates = newCategories.length ? newCategories : eligible;
    const prompt = candidates[Math.floor(random() * candidates.length)];
    prompts.push(prompt.text);
    categories.add(prompt.category);
    seen.add(prompt.text);
  }
  return { prompts, history: [...seen] };
}

function normalize(value) {
  return value.toLowerCase().replace(/[^a-z0-9 ]/g, '').replace(/^(the|a|an) /, '')
    .replace(/ (sauce|dip|cheese)$/, '').replace(/\s+/g, ' ').trim();
}

export function evaluateAnswer(prompt, raw) {
  const entry = catalog.get(prompt);
  const submitted = normalize(raw);
  const singular = submitted.replace(/s$/, '');
  const hit = submitted && entry.options.find(({ names }) => names.some(name => {
    const known = normalize(name);
    return known === submitted || known === singular || known.replace(/s$/, '') === submitted;
  }));
  const points = hit ? hit.points : 0;
  const example = entry.options.reduce((best, option) => option.points < best.points ? option : best);
  return { answer: raw.trim(), points, hint: points ? '' : example.names[0] };
}

export const echoDepth = points => points ? 100 + 9 * points : 0;
export const echoTier = points => points >= 50 ? 'Legendary' : points >= 20 ? 'Rare' : points >= 7 ? 'Uncommon' : 'Common';
export const missCount = puzzle => puzzle.results.filter(result => !result.points).length;

export function createDive(occurrenceId, mode, prompts) {
  return { occurrenceId, mode, prompts, results: [], phase: 'playing', startedAt: null, advanceAt: null };
}

export function beginPrompt(puzzle, now) {
  return puzzle.phase === 'playing' && puzzle.startedAt === null ? { ...puzzle, startedAt: now } : puzzle;
}

export function answerPrompt(puzzle, index, raw, now) {
  if (puzzle.phase !== 'playing' || puzzle.startedAt === null || index !== puzzle.results.length) return puzzle;
  const answer = now - puzzle.startedAt >= PROMPT_TIME ? '' : raw;
  const result = evaluateAnswer(puzzle.prompts[index], answer);
  return { ...puzzle, results: [...puzzle.results, result], phase: 'feedback', advanceAt: now + FEEDBACK_TIME };
}

export function advanceDive(puzzle, now) {
  if (puzzle.phase !== 'feedback' || now < puzzle.advanceAt) return puzzle;
  if (missCount(puzzle) >= MISS_LIMIT) return { ...puzzle, phase: 'restart', advanceAt: null };
  if (puzzle.results.length === DIVE_LENGTH) return { ...puzzle, phase: 'solved', advanceAt: null };
  return { ...puzzle, phase: 'playing', startedAt: now, advanceAt: null };
}
