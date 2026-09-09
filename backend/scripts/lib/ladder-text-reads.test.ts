import { describe, it, expect, afterEach } from 'vitest';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BACKEND = path.resolve(HERE, '..', '..');
const GATE = path.join(BACKEND, 'scripts', 'check-ladder-text-reads.mjs');

// A file planted in the scanned tree, then removed. Named so a stray copy is obvious.
const PLANT = path.join(BACKEND, 'scripts', '_ladder_text_positive_control.mjs');

function runGate() {
  try {
    return { code: 0, out: execFileSync('node', [GATE], { cwd: BACKEND, encoding: 'utf8' }) };
  } catch (e: any) {
    return { code: e.status ?? 1, out: (e.stdout ?? '') + (e.stderr ?? '') };
  }
}

afterEach(() => { if (fs.existsSync(PLANT)) fs.unlinkSync(PLANT); });

describe('check-ladder-text-reads', () => {
  it('is GREEN on the tree as committed', () => {
    const { code, out } = runGate();
    expect(out).toContain('OK — no new reads of frozen ladder text');
    expect(code).toBe(0);
  });

  // 🔴 THE POSITIVE CONTROL. A gate that only ever says OK is indistinguishable from
  // a gate that cannot see. This plants a real offender in the scanned tree and
  // requires the gate to fail on it, then removes it.
  it('🔴 FAILS on a newly planted read of frozen ladder text', () => {
    fs.writeFileSync(PLANT, [
      'const sql = `SELECT s.value, s.text',
      '  FROM inform.compass_stances s',
      '  JOIN inform.compass_topics t ON t.id = s.topic_id`;',
      'export default sql;',
    ].join('\n'));
    const { code, out } = runGate();
    expect(code).toBe(1);
    expect(out).toContain('_ladder_text_positive_control.mjs');
    expect(out).toContain('reads frozen ladder text without naming a versioned source');
  });

  it('accepts the same query once it names the versioned source', () => {
    fs.writeFileSync(PLANT, [
      'const sql = `SELECT sr.value, sr.text',
      '  FROM inform.season_questions sq',
      '  JOIN inform.compass_topics t ON t.id = sq.topic_id',
      '  JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = sq.topic_revision_id`;',
      'export default sql;',
    ].join('\n'));
    const { code } = runGate();
    expect(code).toBe(0);
  });

  it('accepts a frozen read that declares WHY, and refuses a bare marker', () => {
    const query = [
      'const sql = `SELECT value, text FROM inform.compass_stances WHERE topic_id = $1',
      '  MARKER`;',
      'export default sql;',
    ].join('\n');

    // Bare marker — refused, exactly as @season-scope refuses one without a reason.
    fs.writeFileSync(PLANT, query.replace('MARKER', '-- @ladder-text: frozen-ok'));
    expect(runGate().code).toBe(1);

    // With a reason — accepted.
    fs.writeFileSync(PLANT, query.replace(
      'MARKER',
      '-- @ladder-text: frozen-ok — the rewrite workflow diffs the OLD v1 wording against the proposal',
    ));
    expect(runGate().code).toBe(0);
  });

  it('does not flag a WRITE to the frozen row, which is how the editor maintains it', () => {
    // ⚠ Opposite polarity to check-answer-season-consumers, where the marker is
    // REFUSED on a write. Here the write is the safe case and the read is the defect.
    fs.writeFileSync(PLANT, [
      'const sql = `INSERT INTO inform.compass_stances (topic_id, value, text) VALUES ($1, $2, $3)`;',
      'export default sql;',
    ].join('\n'));
    expect(runGate().code).toBe(0);
  });

  it('does not flag a query that touches the table without reading its text', () => {
    fs.writeFileSync(PLANT, [
      'const sql = `SELECT s.id, s.value FROM inform.compass_stances s WHERE s.topic_id = $1`;',
      'export default sql;',
    ].join('\n'));
    expect(runGate().code).toBe(0);
  });

  it('does not mistake a ::text cast for a frozen text column', () => {
    fs.writeFileSync(PLANT, [
      'const sql = `SELECT s.id::text AS id FROM inform.compass_stances s WHERE s.topic_id = $1`;',
      'export default sql;',
    ].join('\n'));
    expect(runGate().code).toBe(0);
  });

  it('keeps a generated baseline rather than a hand-typed one', () => {
    const baseline = path.join(BACKEND, 'scripts', 'lib', 'ladder-text-baseline.json');
    expect(fs.existsSync(baseline)).toBe(true);
    const parsed = JSON.parse(fs.readFileSync(baseline, 'utf8'));
    // Every entry must be a positive integer count keyed by a repo-relative path.
    for (const [rel, n] of Object.entries(parsed)) {
      expect(rel).toMatch(/^(src|scripts)\//);
      expect(typeof n).toBe('number');
      expect(n as number).toBeGreaterThan(0);
    }
  });
});
