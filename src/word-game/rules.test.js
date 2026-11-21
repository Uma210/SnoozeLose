const { test } = require('node:test');
const assert = require('node:assert/strict');
const { isWord, scoreGuess, keyboardMarks } = require('./rules');

test('dictionary accepts four-, five-, and six-letter words and rejects malformed guesses', () => {
  for (const word of ['four', 'crane', 'apple', 'tears', 'cries', 'longer']) assert.equal(isWord(word), true);
  for (const word of ['cat', 'longest', 'zzzzz', 'a1ple', null]) assert.equal(isWord(word), false);
});

test('exact matches are reserved before scoring extra copies', () => {
  assert.deepEqual(scoreGuess('eerie', 'speed'), ['present', 'present', 'absent', 'absent', 'absent']);
  assert.deepEqual(scoreGuess('sassy', 'glass'), ['present', 'present', 'absent', 'exact', 'absent']);
  assert.deepEqual(scoreGuess('apple', 'apple'), Array(5).fill('exact'));
  assert.deepEqual(scoreGuess('noon', 'moon'), ['absent', 'exact', 'exact', 'exact']);
  assert.deepEqual(scoreGuess('pepper', 'people'), ['exact', 'exact', 'absent', 'exact', 'present', 'absent']);
});

test('keyboard keeps the strongest mark across copies and guesses', () => {
  assert.deepEqual(keyboardMarks(['sassy', 'crane'], 'glass'), {
    s: 'exact', a: 'exact', y: 'absent', c: 'absent', r: 'absent', n: 'absent', e: 'absent',
  });
});
