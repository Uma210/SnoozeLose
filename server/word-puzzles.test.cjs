const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateWord } = require('./word-puzzles.cjs');

function fakeProvider(words, onRequest = () => {}) {
  return async (url, options) => {
    onRequest(url, JSON.parse(options.body));
    return {
      ok: true,
      json: async () => ({
        output: [{ content: [{ type: 'output_text', text: JSON.stringify({ word: words.shift() }) }] }],
      }),
    };
  };
}

test('generation rejects repeated and invalid words before returning an unused answer', async () => {
  const inputs = [];
  const fetchImpl = fakeProvider(['crane', 'zzzzz', 'apple'], (url, body) => {
    assert.equal(url, 'https://api.openai.com/v1/responses');
    assert.equal(body.text.format.strict, true);
    inputs.push(JSON.parse(body.input).excluded);
  });
  const word = await generateWord(['crane'], { apiKey: 'fake', model: 'fake', fetchImpl });
  assert.equal(word, 'apple');
  assert.deepEqual(inputs, [['crane'], ['crane'], ['crane', 'zzzzz']]);
});

test('generation fails if the provider never supplies a usable word', async () => {
  const fetchImpl = fakeProvider(['crane', 'zzzzz', 'crane']);
  await assert.rejects(generateWord(['crane'], { apiKey: 'fake', model: 'fake', fetchImpl }), /No unused dictionary word/);
});
