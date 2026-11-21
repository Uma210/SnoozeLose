const words = new Set(require('./words.json'));
const WORD_LENGTH = 5;
const MAX_GUESSES = 6;
const RANK = { absent: 1, present: 2, exact: 3 };

function isWord(value) {
  return typeof value === 'string' && words.has(value);
}

function scoreGuess(guess, answer) {
  const unused = new Map();
  const marks = Array.from(guess, (letter, index) => {
    if (letter === answer[index]) return 'exact';
    const available = answer[index];
    unused.set(available, (unused.get(available) ?? 0) + 1);
    return 'absent';
  });

  marks.forEach((mark, index) => {
    const letter = guess[index];
    const remaining = unused.get(letter) ?? 0;
    if (mark !== 'exact' && remaining > 0) {
      marks[index] = 'present';
      unused.set(letter, remaining - 1);
    }
  });
  return marks;
}

function keyboardMarks(guesses, answer) {
  const keys = {};
  for (const guess of guesses) {
    scoreGuess(guess, answer).forEach((mark, index) => {
      const letter = guess[index];
      if (RANK[mark] > (RANK[keys[letter]] ?? 0)) keys[letter] = mark;
    });
  }
  return keys;
}

module.exports = { isWord, scoreGuess, keyboardMarks, WORD_LENGTH, MAX_GUESSES };
