import { test } from 'node:test';
import assert from 'node:assert/strict';
import { extractSpan } from '../extract-canonical-rules.mjs';

test('each named span resolves non-empty from the on-the-record corpus', () => {
  for (const name of ['gates', 'deid', 'note']) {
    const txt = extractSpan(name);
    assert.ok(txt && txt.trim().length > 40, `${name} span empty or missing`);
  }
});

test('the gates span carries the ranking-question and differentiation rules', () => {
  const gates = extractSpan('gates').toLowerCase();
  assert.match(gates, /ranking question|on-question/);
  assert.match(gates, /differ/);   // non-differentiating / differentiation
});
