const { createServer } = require('node:http');
const { isWord } = require('../src/word-game/rules');

async function generateWord(excluded, { apiKey, model, fetchImpl = fetch }) {
  const rejected = new Set(excluded);
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const response = await fetchImpl('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(15000),
      body: JSON.stringify({
        model,
        store: false,
        instructions: 'Propose one common, family-friendly English word with exactly five ASCII letters. Use lowercase. Avoid proper nouns, abbreviations, and excluded words.',
        input: JSON.stringify({ excluded: [...rejected] }),
        text: {
          format: {
            type: 'json_schema',
            name: 'puzzle_word',
            strict: true,
            schema: {
              type: 'object',
              properties: { word: { type: 'string' } },
              required: ['word'],
              additionalProperties: false,
            },
          },
        },
      }),
    });
    if (!response.ok) throw new Error(`Word provider returned HTTP ${response.status}.`);
    const result = await response.json();
    const output = result.output?.flatMap((item) => item.content ?? []).find((item) => item.type === 'output_text');
    if (!output) continue;
    const word = JSON.parse(output.text).word;
    if (isWord(word) && !rejected.has(word)) return word;
    if (typeof word === 'string') rejected.add(word);
  }
  throw new Error('No unused dictionary word returned.');
}

function reply(response, status, data) {
  response.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  response.end(JSON.stringify(data));
}

function createWordServer(options) {
  return createServer(async (request, response) => {
    if (request.method !== 'POST' || request.url !== '/word-puzzles') {
      return reply(response, 404, { error: 'Not found.' });
    }
    if (!options.apiKey) return reply(response, 503, { error: 'Word generation is not configured.' });
    let excluded;
    try {
      const chunks = [];
      let size = 0;
      for await (const chunk of request.iterator({ destroyOnReturn: false })) {
        size += chunk.length;
        if (size > 200_000) {
          response.setHeader('Connection', 'close');
          return reply(response, 413, { error: 'Request is too large.' });
        }
        chunks.push(chunk);
      }
      ({ excluded } = JSON.parse(Buffer.concat(chunks).toString()));
      if (!Array.isArray(excluded) || !excluded.every(isWord)) throw new Error('Invalid exclusion list.');
    } catch {
      return reply(response, 400, { error: 'Expected an array of excluded dictionary words.' });
    }
    try {
      return reply(response, 200, { word: await generateWord(excluded, options) });
    } catch (error) {
      console.error(error.message);
      return reply(response, 502, { error: 'Could not generate a word.' });
    }
  });
}

if (require.main === module) {
  const port = Number(process.env.PORT || 8787);
  const host = process.env.WORD_API_HOST || '127.0.0.1';
  createWordServer({
    apiKey: process.env.OPENAI_API_KEY,
    model: process.env.OPENAI_WORD_MODEL || 'gpt-4.1-mini',
  }).listen(port, host, () => console.log(`Word server listening on http://${host}:${port}`));
}

module.exports = { generateWord };
