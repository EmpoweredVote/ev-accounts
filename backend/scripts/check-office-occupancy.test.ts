import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync, execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// The guard resolves files through git (`rev-parse --show-toplevel`, `ls-files`), so each case
// builds a throwaway repo and runs the script as a subprocess, exactly as CI does.
//
// What this pins is the LINE a violation is reported on. stripComments() once deleted /* ... */
// blocks outright, newlines included, so every finding after a multi-line block comment was
// reported too low: on 2026-09-23 `check:occupancy:all` sent readers to
// senate-candidate-fec.ts:263 for a join that sat on line 291. The count was right; the pointer
// was wrong. Each fixture puts its violation after a multi-line block, and the expected line is
// read off the RAW source, never recomputed the way the guard computes it.

const SCRIPT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'check-office-occupancy.mjs'
);

// A 17-line header like the one in senate-candidate-fec.ts, the file where the drift was seen.
const HEADER = ['/**', ...Array.from({ length: 15 }, (_, i) => ` * header line ${i + 1}`), ' */'].join('\n');

const OFFICES_READ = [
  HEADER,
  "import { pool } from './db.js';",
  '',
  '/**',
  ' * A second doc block, so the drift is more than one block deep.',
  ' */',
  'export async function load() {',
  '  return pool.query(`',
  '    SELECT p.id',
  '      FROM essentials.politicians p',
  '      JOIN essentials.offices o ON o.politician_id = p.id',
  '  `);',
  '}',
  '',
].join('\n');

let root: string;
beforeAll(() => { root = mkdtempSync(path.join(tmpdir(), 'occupancy-')); });
afterAll(() => { rmSync(root, { recursive: true, force: true }); });

// A caller's git environment (a pre-commit hook sets GIT_INDEX_FILE, for one) would point the
// subprocess's git at the wrong repository, and a BASE_REF would change what the gate scans.
const env = Object.fromEntries(
  Object.entries(process.env).filter(([k]) => !k.startsWith('GIT_') && k !== 'BASE_REF')
);

let n = 0;
/** Write `files` into a fresh git repo and run the guard there. `track` stages them for --all. */
function run(
  files: Record<string, string>,
  { all = false, track = false } = {}
): { code: number; out: string } {
  const dir = path.join(root, `case-${++n}`);
  mkdirSync(dir, { recursive: true });
  execFileSync('git', ['init', '-q'], { cwd: dir, env });
  for (const [rel, contents] of Object.entries(files)) {
    mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    writeFileSync(path.join(dir, rel), contents, 'utf8');
  }
  if (track) execFileSync('git', ['add', '--', ...Object.keys(files)], { cwd: dir, env });
  const r = spawnSync('node', [SCRIPT, ...(all ? ['--all'] : [])], { cwd: dir, env, encoding: 'utf8' });
  return { code: r.status ?? -1, out: `${r.stdout ?? ''}${r.stderr ?? ''}` };
}

/** 1-based line of the first raw source line containing `needle`. */
function realLine(src: string, needle: string): number {
  const i = src.split('\n').findIndex((l) => l.includes(needle));
  if (i < 0) throw new Error(`fixture does not contain ${needle}`);
  return i + 1;
}

/** The line number the guard printed for `rel`, or null if it never named the file. */
function reportedLine(out: string, rel: string): number | null {
  const m = out.match(new RegExp(`${rel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}:(\\d+)`));
  return m ? Number(m[1]) : null;
}

describe('check-office-occupancy — reported line matches the source after block comments', () => {
  it('branch gate: offices.politician_id read below two doc blocks', () => {
    const rel = 'backend/scripts/seeder.ts';
    const r = run({ [rel]: OFFICES_READ });
    // Positive control: the guard must SEE the violation, or a line check below means nothing.
    expect(r.code).toBe(1);
    expect(reportedLine(r.out, rel)).toBe(realLine(OFFICES_READ, 'o.politician_id'));
  });

  it('branch gate: violation on the same line a block comment closes', () => {
    const rel = 'backend/scripts/inline.sql';
    const src = '/* opens here\n   closes here */ SELECT 1 FROM essentials.offices o WHERE o.politician_id = 1;\n';
    const r = run({ [rel]: src });
    expect(r.code).toBe(1);
    expect(reportedLine(r.out, rel)).toBe(2);
  });

  it('branch gate: politicians INSERT without is_incumbent, below the header', () => {
    const rel = 'backend/scripts/insert.ts';
    const src = [
      HEADER,
      'export const sql = `',
      '  INSERT INTO essentials.politicians (id, full_name)',
      '  VALUES ($1, $2)',
      '`;',
      '',
    ].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(1);
    expect(r.out).toContain('without an explicit is_incumbent');
    expect(reportedLine(r.out, rel)).toBe(realLine(src, 'INSERT INTO essentials.politicians'));
  });

  it('--all inventory: same file, same real line', () => {
    const rel = 'backend/scripts/seeder.ts';
    const r = run({ [rel]: OFFICES_READ }, { all: true, track: true });
    expect(r.code).toBe(0); // the inventory never fails on a one-off seeder
    expect(r.out).toContain('1 still read the dropped column');
    expect(reportedLine(r.out, rel)).toBe(realLine(OFFICES_READ, 'o.politician_id'));
  });
});

describe('check-office-occupancy — comments are still stripped', () => {
  it('a multi-line block comment that only mentions the old column is not a violation', () => {
    const src = [
      '/*',
      ' * Before phase 5 this read JOIN essentials.offices o ON o.politician_id = p.id.',
      ' */',
      'SELECT 1 FROM essentials.office_current_holder och WHERE och.office_id = $1;',
      '',
    ].join('\n');
    const r = run({ 'backend/migrations/0001_note.sql': src });
    expect(r.code).toBe(0);
    expect(r.out).toContain('Office occupancy OK — 1 changed file(s) scanned');
  });
});

describe('check-office-occupancy — its own test is exempt, like the guard itself', () => {
  // This file holds the forbidden patterns as fixtures on purpose. Scanned, it would fail the
  // branch gate on any PR that touches it and add a row to the --all inventory.
  it('the fixtures in this test file are not violations', () => {
    const r = run({ 'backend/scripts/check-office-occupancy.test.ts': OFFICES_READ });
    expect(r.code).toBe(0);
    expect(r.out).toContain('Office occupancy OK — 0 changed file(s) scanned');
  });
});
