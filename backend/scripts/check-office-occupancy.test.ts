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

  it('branch gate: politicians INSERT that names the dropped is_incumbent, below the header', () => {
    const rel = 'backend/scripts/insert.ts';
    const src = [
      HEADER,
      'export const sql = `',
      '  INSERT INTO essentials.politicians (id, full_name, is_incumbent)',
      '  VALUES ($1, $2, true)',
      '`;',
      '',
    ].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(1);
    expect(r.out).toContain('names is_incumbent — that column was dropped');
    expect(reportedLine(r.out, rel)).toBe(realLine(src, 'INSERT INTO essentials.politicians'));
  });

  it('branch gate: a MIGRATION naming is_incumbent is a record, not a violation', () => {
    // CA_0374 ran in production before CA_0378 dropped the column; its file must still merge.
    const rel = 'backend/migrations/CA_9999_applied_before_drop.sql';
    const src = ['INSERT INTO essentials.politicians (full_name, is_incumbent)', "VALUES ('A', true);", ''].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(0);
  });

  it('branch gate: a politicians INSERT without is_incumbent passes', () => {
    const rel = 'backend/scripts/insert-ok.ts';
    const src = [HEADER, 'export const sql = `', '  INSERT INTO essentials.politicians (id, full_name)', '  VALUES ($1, $2)', '`;', ''].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(0);
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

describe('check-office-occupancy — view aliases that legitimately carry politician_id', () => {
  // 🔴 THE SAME FALSE POSITIVE AS `ot`, WHICH THIS GUARD'S OWN COMMENT SAYS WENT UNNOTICED FOR A
  // YEAR. The offices-alias pattern is `o[0-9a-z]*`, which swallows the conventional alias of
  // any view whose name starts with "office". `essentials.office_next_term` (CC_0341) carries a
  // politician_id by design, exactly as `office_current_holder` does — reading it is the thing
  // ADR 0002 tells you to do, not the thing it forbids.
  it('ont.politician_id (essentials.office_next_term) is not a violation', () => {
    const src = [
      'SELECT och.politician_id AS holder, ont.politician_id AS incoming',
      '  FROM essentials.offices o',
      '  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id',
      '  LEFT JOIN essentials.office_next_term ont ON ont.office_id = o.id;',
      '',
    ].join('\n');
    const r = run({ 'backend/migrations/0002_next_term.sql': src });
    expect(r.code).toBe(0);
    expect(r.out).toContain('Office occupancy OK');
  });

  it('still catches a real offices read sitting right beside it', () => {
    // A positive control on the exemption: widening the lookahead must not blind the guard to
    // the column it exists for.
    const src = [
      'SELECT ont.politician_id FROM essentials.office_next_term ont;',
      'SELECT o.politician_id FROM essentials.offices o;',
      '',
    ].join('\n');
    const r = run({ 'backend/migrations/0003_mixed.sql': src });
    expect(r.code).toBe(1);
    expect(r.out).toContain('reads <offices alias>.politician_id');
  });
});

// ─────────────────────────────────────────────────────────────────────────────────────────────
// CC_0391: serving a TERM DATE from the deprecated per-person snapshot.
//
// This rule is scoped to backend/src — the read paths — because migrations and scripts
// legitimately WRITE politicians.valid_from (the staging importer fills it from the upstream
// feed). Both halves are tested: the read path must be caught, and the writers must not be.
//
// 🔴 The rule shipped broken the first time and a positive control is the only reason anybody
//    knew. It was generated through a shell heredoc into a template literal, which ate the
//    backslashes: `\b` became a literal BACKSPACE byte (0x08) inside the regex, so the pattern
//    demanded a control character that no source file contains and matched nothing, for ever.
//    The guard reported "OK" over a planted violation and `cat -A` was what finally showed it.
//    ▶ A GUARD THAT HAS NEVER BEEN WATCHED FAILING IS NOT A GUARD.
// ─────────────────────────────────────────────────────────────────────────────────────────────
describe('check-office-occupancy — term dates must come from the tenure, not the person', () => {
  const READ_PATH_SRC = [
    "export const SELECT = `",
    '  p.id, p.full_name,',
    "  COALESCE(p.valid_from, '') AS term_start,",
    "  COALESCE(p.valid_to, '') AS term_end",
    '`;',
    '',
  ].join('\n');

  it('backend/src reading p.valid_from for a term date is a violation', () => {
    const rel = 'backend/src/lib/someQueries.ts';
    const r = run({ [rel]: READ_PATH_SRC });
    expect(r.code).toBe(1);
    expect(r.out).toContain('deprecated politicians.valid_from');
    expect(reportedLine(r.out, rel)).toBe(realLine(READ_PATH_SRC, 'p.valid_from'));
  });

  it('p.term_date_precision and p.valid_to are caught the same way', () => {
    const rel = 'backend/src/lib/other.ts';
    const src = "const q = \"SELECT COALESCE(p.term_date_precision, '') AS term_date_precision\";\n";
    const r = run({ [rel]: src });
    expect(r.code).toBe(1);
  });

  it('the same read OUTSIDE backend/src is not a violation — importers write these columns', () => {
    const r = run({ 'backend/scripts/import-feed.ts': READ_PATH_SRC });
    expect(r.code).toBe(0);
  });

  it('an unqualified column list and EXCLUDED.valid_from are writes, not reads', () => {
    const rel = 'backend/src/lib/stagingish.ts';
    const src = [
      "const sql = `",
      '  INSERT INTO essentials.politicians (full_name, valid_from, valid_to)',
      '  VALUES ($1, $2, $3)',
      '  ON CONFLICT (external_id) DO UPDATE SET',
      '    valid_from = EXCLUDED.valid_from,',
      '    valid_to = EXCLUDED.valid_to',
      '`;',
      '',
    ].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(0);
  });

  it('a comment ABOUT the snapshot is not a violation', () => {
    const rel = 'backend/src/lib/noted.ts';
    const src = [
      '// Term dates come from office_current_holder now, never from p.valid_from.',
      "const q = \"SELECT COALESCE(to_char(och.term_start, 'YYYY-MM-DD'), '') AS term_start\";",
      '',
    ].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(0);
  });

  it('the fixed form — och.term_start through to_char — passes', () => {
    const rel = 'backend/src/lib/fixed.ts';
    const src = [
      "export const SELECT = `",
      "  COALESCE(to_char(och.term_start, 'YYYY-MM-DD'), '') AS term_start,",
      "  COALESCE(to_char(och.term_end, 'YYYY-MM-DD'), '') AS term_end,",
      "  COALESCE(CASE WHEN och.term_start IS NOT NULL THEN och.start_precision END, '') AS term_date_precision",
      '`;',
      '',
    ].join('\n');
    const r = run({ [rel]: src });
    expect(r.code).toBe(0);
  });
});
