import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { NO_WRITE_ENV, writeRefusal } from './noWriteGuard.js';

const scripts = join(dirname(fileURLToPath(import.meta.url)), '..');

describe('the slim-session write guard', () => {
  it('refuses only when the flag is exactly 1', () => {
    expect(writeRefusal({})).toBeNull();
    expect(writeRefusal({ [NO_WRITE_ENV]: '0' })).toBeNull();
    expect(writeRefusal({ [NO_WRITE_ENV]: '' })).toBeNull();
    expect(writeRefusal({ [NO_WRITE_ENV]: '1' })).toMatch(/slim session/);
  });

  // A writer that forgets the call is unguarded, and nothing else would say so.
  it.each([
    ['topic-stage5-write.ts', /if \(apply\) refuseWriteInSlimSession\(/],
    ['verify-stance-research.ts', /if \(APPLY\) refuseWriteInSlimSession\(/],
    ['stage5/approve-batch.ts', /^refuseWriteInSlimSession\(/m],
  ])('%s calls the guard before it can write', (file, call) => {
    const src = readFileSync(join(scripts, file), 'utf8');
    expect(src).toMatch(call);
    expect(src).toContain("noWriteGuard.js");
  });

  it('write-batch.sh refuses apply in a slim session before it runs the writer', () => {
    const sh = readFileSync(join(scripts, 'stage5/write-batch.sh'), 'utf8');
    const guard = sh.indexOf(NO_WRITE_ENV); const writer = sh.indexOf('topic-stage5-write.ts');
    expect(guard).toBeGreaterThan(-1);
    expect(guard).toBeLessThan(writer);
  });
});
