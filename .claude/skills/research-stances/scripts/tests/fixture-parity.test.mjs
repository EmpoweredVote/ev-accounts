import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { checkQuoteRow } from '../build-and-check.mjs';

const here = dirname(fileURLToPath(import.meta.url));
// scripts/tests -> ev-accounts root is 5 up; sibling on-the-record holds the fixtures.
// OTR_ROOT overrides this default when the on-the-record checkout isn't at the plain
// sibling path (e.g. this worktree layout, where it lives under a nested worktree).
const OTR = process.env.OTR_ROOT || resolve(here, '..', '..', '..', '..', '..', 'on-the-record');
const FIX = resolve(OTR, 'docs/quote-curation/fixtures/mechanical-checks.json');

test('build-and-check matches the shared fixture contract', () => {
  const cases = JSON.parse(readFileSync(FIX, 'utf8'));
  for (const c of cases) {
    const got = new Set(checkQuoteRow(c.row).map(f => f.check_id));
    assert.deepEqual([...got].sort(), [...c.expect].sort(), `${c.name}: ${[...got]} != ${c.expect}`);
  }
});
