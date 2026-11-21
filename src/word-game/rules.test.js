const { test } = require('node:test');
const assert = require('node:assert/strict');
const { isWord, scoreGuess, keyboardMarks } = require('./rules');

test('dictionary accepts common five-letter words and rejects malformed guesses', () => {
  for (const word of ['crane', 'apple', 'tears', 'cries']) assert.equal(isWord(word), true);
  for (const word of ['zzzzz', 'four', 'longer', 'a1ple', null]) assert.equal(isWord(word), false);
});

test('exact matches are reserved before scoring extra copies', () => {
  assert.deepEqual(scoreGuess('eerie', 'speed'), ['present', 'present', 'absent', 'absent', 'absent']);
  assert.deepEqual(scoreGuess('sassy', 'glass'), ['present', 'present', 'absent', 'exact', 'absent']);
  assert.deepEqual(scoreGuess('apple', 'apple'), Array(5).fill('exact'));
});

test('keyboard keeps the strongest mark across copies and guesses', () => {
  assert.deepEqual(keyboardMarks(['sassy', 'crane'], 'glass'), {
    s: 'exact', a: 'exact', y: 'absent', c: 'absent', r: 'absent', n: 'absent', e: 'absent',
  });
});
