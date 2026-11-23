import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { displayName, readRosters, unquoteCell } from './coder-io.js';

describe('roster names', () => {
  it('reads a spreadsheet-quoted cell back as its text', () => {
    expect(unquoteCell('"Daniel Antonio ""Danny"" Alvarez"')).toBe('Daniel Antonio "Danny" Alvarez');
    expect(unquoteCell('Plain Name')).toBe('Plain Name');
  });

  it('readRosters unquotes every cell', () => {
    const dir = mkdtempSync(join(tmpdir(), 'roster-'));
    const p = join(dir, 'r.tsv');
    writeFileSync(p, 'politician_id\tfull_name\nid1\t"Earl L. ""Buddy"" Carter"\n');
    expect(readRosters([p]).get('id1')?.full_name).toBe('Earl L. "Buddy" Carter');
  });

  it('puts a nickname right after the first name', () => {
    expect(displayName('"Daniel Antonio ""Danny"" Alvarez"')).toBe('Daniel "Danny" Antonio Alvarez');
    expect(displayName('Henry C. "Hank" Johnson, Jr.')).toBe('Henry "Hank" C. Johnson, Jr.');
    expect(displayName('Dan "Kilo" Sallis')).toBe('Dan "Kilo" Sallis');
    expect(displayName('Rick Williams')).toBe('Rick Williams');
  });
});
