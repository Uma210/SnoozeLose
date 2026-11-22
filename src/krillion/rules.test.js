import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  advanceDive, answerPrompt, beginPrompt, createDive, DIVE_LENGTH, echoDepth, evaluateAnswer,
  FEEDBACK_TIME, PROMPT_TIME, promptBank, reserveDive,
} from './rules.js';

const fruit = 'Name a fruit';
const makeDive = () => createDive('alarm-occurrence', 'simpler', Array(DIVE_LENGTH).fill(fruit));

function record(puzzle, value, now) {
  const answered = answerPrompt(puzzle, puzzle.results.length, value, now);
  return advanceDive(answered, now + FEEDBACK_TIME);
}

test('the prepared dive uses seven distinct prompts from its difficulty', () => {
  assert.equal(promptBank.length, 1483);
  const first = reserveDive('standard', [], () => 0);
  const second = reserveDive('standard', first.history, () => 0);
  assert.equal(new Set(first.prompts).size, DIVE_LENGTH);
  assert.equal(second.prompts.some(prompt => first.prompts.includes(prompt)), false);
  assert.ok(first.prompts.every(text => promptBank.find(prompt => prompt.text === text).mode === 'standard'));
});

test('picking a dive consumes the last unseen prompt before rollover', () => {
  const simpler = promptBank.filter(prompt => prompt.mode === 'simpler').map(prompt => prompt.text);
  const oldStandard = promptBank.find(prompt => prompt.mode === 'standard').text;
  const { prompts, history } = reserveDive('simpler', [...simpler.slice(0, -1), oldStandard], () => 0);
  assert.equal(prompts[0], simpler.at(-1));
  assert.equal(new Set(prompts).size, DIVE_LENGTH);
  assert.ok(history.includes(oldStandard));
});

test('a dive becomes solved only after its seventh prompt and feedback', () => {
  let puzzle = makeDive();
  assert.equal(puzzle.startedAt, null);
  let now = 1_000;
  puzzle = beginPrompt(puzzle, now);
  for (let index = 0; index < DIVE_LENGTH - 1; index++) {
    puzzle = record(puzzle, 'apple', now + 300);
    assert.equal(puzzle.phase, 'playing');
    now = puzzle.startedAt;
  }
  const last = answerPrompt(puzzle, 6, 'persimmon', now + 300);
  assert.equal(last.phase, 'feedback');
  assert.equal(advanceDive(last, now + 300 + FEEDBACK_TIME - 1), last);
  const solved = advanceDive(last, now + 300 + FEEDBACK_TIME);
  assert.equal(solved.phase, 'solved');
  assert.equal(solved.occurrenceId, 'alarm-occurrence');
  assert.equal(solved.results.length, DIVE_LENGTH);
  assert.equal(solved.results.at(-1).points, 80);
});

test('a third miss on the final prompt still requires a restart', () => {
  let puzzle = beginPrompt(makeDive(), 0);
  for (const answer of ['invalid', 'apple', 'invalid', 'apple', 'apple', 'apple', 'invalid']) {
    puzzle = record(puzzle, answer, puzzle.startedAt + 100);
  }
  assert.equal(puzzle.phase, 'restart');
  assert.equal(puzzle.results.length, DIVE_LENGTH);
  assert.equal(advanceDive(puzzle, 100_000), puzzle);
});

test('late answers become timeouts and stale submissions cannot advance a prompt', () => {
  const opened = beginPrompt(makeDive(), 0);
  assert.equal(beginPrompt(opened, 2_000), opened);
  const late = answerPrompt(opened, 0, 'apple', PROMPT_TIME);
  assert.deepEqual(late.results[0], { answer: '', points: 0, hint: 'apple' });
  const next = advanceDive(late, PROMPT_TIME + FEEDBACK_TIME);
  assert.equal(answerPrompt(next, 0, 'apple', PROMPT_TIME + FEEDBACK_TIME), next);
});

test('rarer echoes go deeper and constrained prompts check their answer filters', () => {
  assert.ok(echoDepth(evaluateAnswer(fruit, 'Persimmon').points) > echoDepth(evaluateAnswer(fruit, 'a APPLE!').points));
  assert.equal(evaluateAnswer('Name a fruit that starts with P', 'apple').points, 0);
  assert.ok(evaluateAnswer('Name a fruit that starts with P', 'pears').points > 0);
});
