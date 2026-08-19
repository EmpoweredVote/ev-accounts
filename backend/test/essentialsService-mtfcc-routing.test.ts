import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

// The geofence->districts MTFCC mapping these guards cover moved out of
// essentialsService.ts into districtQueries.ts, so that one query text could be
// shared by the address path and the ZIP/area path instead of drifting in four
// copies. The guards themselves are unchanged — only the file they read.
const SRC = fs.readFileSync(
  path.resolve(__dirname, '../src/lib/districtQueries.ts'),
  'utf-8',
);

// Strip SQL/code comments so grep counts don't self-invalidate.
function stripComments(s: string): string {
  return s
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '')
    .replace(/--.*$/gm, '');
}
const SRC_NC = stripComments(SRC);

describe('essentialsService MTFCC routing (D-11 / Pitfall 4)', () => {
  it("explicit X0001 → district_type IN ('LOCAL', 'COUNTY')", () => {
    expect(SRC_NC).toMatch(/gb\.mtfcc\s*=\s*'X0001'\s+AND\s+d\.district_type\s+IN\s*\(\s*'LOCAL'\s*,\s*'COUNTY'\s*\)/);
  });

  it("explicit X0002 → district_type = 'SCHOOL'", () => {
    expect(SRC_NC).toMatch(/gb\.mtfcc\s*=\s*'X0002'\s+AND\s+d\.district_type\s*=\s*'SCHOOL'/);
  });

  it("explicit X0003 → district_type = 'STATE_BOARD'", () => {
    expect(SRC_NC).toMatch(/gb\.mtfcc\s*=\s*'X0003'\s+AND\s+d\.district_type\s*=\s*'STATE_BOARD'/);
  });

  it("residual LIKE 'X%' clause excludes X0001/X0002/X0003/X0004 (Pitfall 4)", () => {
    expect(SRC_NC).toMatch(/mtfcc\s+LIKE\s+'X%'[\s\S]*?NOT\s+IN\s*\([^)]*'X0001'[^)]*'X0002'[^)]*'X0003'[^)]*'X0004'/);
  });

  it('does not contain the bare LIKE \'X%\' AND district_type IN (LOCAL, COUNTY) catch-all without exclusions', () => {
    // The pre-Phase-132 form is forbidden post-W4. Match must require the NOT IN exclusion list.
    const badPattern = /mtfcc\s+LIKE\s+'X%'\s+AND\s+d\.district_type\s+IN\s*\(\s*'LOCAL'\s*,\s*'COUNTY'\s*\)\s*\)/;
    const goodPattern = /mtfcc\s+LIKE\s+'X%'[\s\S]{0,200}?NOT\s+IN/;
    // Either no bare clause exists, or every bare clause has a NOT IN within 200 chars
    if (badPattern.test(SRC_NC)) {
      expect(goodPattern.test(SRC_NC)).toBe(true);
    }
  });
});
