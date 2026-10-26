import { describe, it, expect } from 'vitest';
import { formatRowsTsv, mergeResearch, topicExists, summarise, blankClassForReason, parseRowsTsv, formatReport, loadDbRows, formatReasonsTsv, formatSkippedTsv, sidecarPath, type SkippedRow } from './seatRate.js';

describe('seatRate', () => {
  it('zero rows', () => {
    const r = summarise([]);
    expect(r.total.rows).toBe(0);
    expect(r.total.affirmative?.rate ?? null).toBeNull();
    expect(formatReport(r)).toContain('no rows');
  });

  it('half value is seated in between', () => {
    const r = summarise([{ level: 'state', value: 2.5 }]);
    expect(r.byLevel.state.seated).toBe(1);
    expect(r.byLevel.state.perRung.between).toBe(1);
  });

  it('blank classes', () => {
    const r = summarise([
      { level: 'local', value: 0, blank_class: 'gate' },
      { level: 'local', value: 0 },
    ]);
    expect(r.byLevel.local.blank).toBe(2);
    expect(r.byLevel.local.byClass.gate).toBe(1);
    expect(r.byLevel.local.byClass.unclassified).toBe(1);
  });

  it('affirmative excludes gated and No', () => {
    const r = summarise([
      { level: 'state', value: 4, record_kind: 'vote-yes' },
      { level: 'state', value: 0, record_kind: 'vote-yes', gate: 'consent', blank_class: 'gate' },
      { level: 'state', value: 2, record_kind: 'vote-no' },
      { level: 'state', value: 0, record_kind: 'sponsor' },
    ]);
    expect(r.total.affirmative).toEqual({ rows: 2, seated: 1, rate: 0.5 });
  });

  it('blankClassForReason maps reasons', () => {
    expect(blankClassForReason('no-evidence')).toBe('source-gap');
    for (const g of ['near-unanimous', 'multi-subject', 'study-directive', 'pre-seating']) expect(blankClassForReason(g)).toBe('gate');
    for (const w of ['adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict']) expect(blankClassForReason(w)).toBe('wording');
    // A No vote's direction-only is never a wording loss, so the runner classifies it by reading.
    expect(blankClassForReason('direction-only')).toBeNull();
    expect(blankClassForReason('scope-unavailable')).toBe('no-lever');
    expect(blankClassForReason('banana')).toBeNull();
  });

  const H = 'politician_id\toffice_id\tlevel\tvalue\tblank_reason\tblank_class\trecord_kind\tgate';
  it('parseRowsTsv parses and errors with file, line, column', () => {
    const ok = parseRowsTsv(`${H}\np1\to1\tstate\t3\t\t\tvote-yes\t`, 'rows.tsv');
    expect(ok).toHaveLength(1);
    expect(ok[0].value).toBe(3);
    expect(ok[0].gate).toBeUndefined();
    const bad = `${H}\np1\to1\tstate\t3\t\t\tvote-yes\t\np2\to2\tstate\t0\tx\tbogus\tnone\t`;
    expect(() => parseRowsTsv(bad, 'rows.tsv')).toThrow(/rows\.tsv.*line 3.*blank_class/);
  });

  it('loadDbRows resolves one level per politician and keeps blank reason', async () => {
    const calls: unknown[][] = [];
    const q = async (_sql: string, params: unknown[] = []) => {
      calls.push(params);
      return { rows: [
        { politician_id: 'p1', office_id: 'o1', value: '0', district_type: 'STATE_UPPER', is_judicial: false, district_label: 'x', office_labels: ['Senator'], proposed_blank_reason: 'no-evidence', reasoning: 'Season 2 repair: blanked', first_reasoning: 'Voted Yea on a bill' },
        { politician_id: 'p2', office_id: 'o2', value: '2.5', district_type: 'NATIONAL_LOWER', is_judicial: false, district_label: 'y', office_labels: [], proposed_blank_reason: null },
        { politician_id: 'p4', office_id: null, value: '3', district_type: null, is_judicial: null, district_label: null, office_labels: [null, null], proposed_blank_reason: 'no-evidence' },
        { politician_id: 'p3', office_id: 'o3', value: '1', district_type: 'WEIRD', is_judicial: false, district_label: null, office_labels: [], proposed_blank_reason: null },
      ] };
    };
    const skipped: string[] = [];
    const why: string[] = [];
    const skippedRows: SkippedRow[] = [];
    const rows = await loadDbRows(q, 'k', 's', (id, w, row) => { skipped.push(id); why.push(w); if (row) skippedRows.push(row); });
    expect(calls[0]).toEqual(['k', 's']);
    expect(rows.map((r) => [r.level, r.value, r.blank_class])).toEqual([['state', 0, 'source-gap'], ['federal', 2.5, undefined]]);
    expect(skipped).toEqual(['p4', 'p3']);
    expect(why).toEqual(['no-office', 'unknown-level']);
    expect(skippedRows[0]).toEqual({ politician_id: 'p4', why: 'no-office', value: 3, blank_reason: 'no-evidence' });
    expect(rows[0]).toMatchObject({ reasoning: 'Season 2 repair: blanked', first_reasoning: 'Voted Yea on a bill' });
    expect(rows[1].reasoning).toBeUndefined();
  });

  it('reasons and skipped sidecars', () => {
    const reasons = formatReasonsTsv([
      { politician_id: 'p1', office_id: 'o1', level: 'state', value: 0, blank_reason: 'direction-only', record_kind: 'none', reasoning: 'line\tone\nline two', first_reasoning: 'old' },
    ]).split('\n');
    expect(reasons[0]).toBe('politician_id\tvalue\tblank_reason\treasoning\tfirst_reasoning');
    expect(reasons[1]).toBe('p1\t0\tdirection-only\tline one line two\told');
    const skipped = formatSkippedTsv([{ politician_id: 'p9', why: 'no-office', value: 5 }]).split('\n');
    expect(skipped[1]).toBe('p9\tno-office\t5\t');
    expect(sidecarPath('/r/stage0a/rows.tsv', 'reasons')).toBe('/r/stage0a/rows.reasons.tsv');
    expect(sidecarPath('/r/stage0a/rows', 'skipped')).toBe('/r/stage0a/rows.skipped.tsv');
  });

  it('new blank classes parse and count', () => {
    const rows = parseRowsTsv(`${H}\np1\to1\tstate\t0\t\toff-question\tnone\t\np2\to2\tstate\t0\tdirection-only\tnay-only\tvote-no\t`, 'r.tsv');
    const r = summarise(rows);
    expect(r.total.byClass['off-question']).toBe(1);
    expect(r.total.byClass['nay-only']).toBe(1);
    expect(formatReport(r)).toMatch(/off-question\s+nay-only/);
  });

  it('says to headline the overall rate when few rows are affirmative', () => {
    const few = summarise([{ level: 'state', value: 4, record_kind: 'vote-yes' }, { level: 'state', value: 0, record_kind: 'none' }]);
    expect(formatReport(few)).toMatch(/only 1 affirmative record\(s\); report the overall rate \(50\.0%\)/);
    const many = summarise(Array.from({ length: 10 }, () => ({ level: 'state' as const, value: 3, record_kind: 'vote-yes' as const })));
    expect(formatReport(many)).not.toMatch(/note:/);
    expect(formatReport(summarise([{ level: 'state', value: 3 }]))).not.toMatch(/note:/);
  });

  it('mergeResearch joins on politician_id', () => {
    const db = [
      { politician_id: 'a', office_id: 'o', level: 'state' as const, value: 0, record_kind: 'none' as const },
      { politician_id: 'b', office_id: 'o', level: 'state' as const, value: 3, record_kind: 'none' as const },
    ];
    const tsv = [
      { politician_id: 'a', office_id: 'o', level: 'state' as const, value: 0, blank_class: 'gate' as const, record_kind: 'vote-yes' as const, gate: 'consent' },
      { politician_id: 'z', office_id: 'o', level: 'state' as const, value: 1, record_kind: 'sponsor' as const },
    ];
    const m = mergeResearch(db, tsv);
    expect(m.rows[0]).toMatchObject({ blank_class: 'gate', record_kind: 'vote-yes', gate: 'consent' });
    expect(m.rows[1]).toEqual(db[1]);
    expect(m.researchOnly).toBe(1);
  });

  it('topicExists', async () => {
    expect(await topicExists(async () => ({ rows: [{}] }), 'k')).toBe(true);
    expect(await topicExists(async () => ({ rows: [] }), 'k')).toBe(false);
  });

  it('parseRowsTsv rejects a gate outside the gate list, with file, line and column', () => {
    for (const g of ['multi-subject', 'consent', 'higher-law-duty', 'near-unanimous', 'off-version-sponsor', 'pre-seating', 'study-directive']) {
      expect(parseRowsTsv(`${H}\np1\to1\tstate\t0\t\tgate\tvote-yes\t${g}`, 'r.tsv')[0].gate).toBe(g);
    }
    expect(() => parseRowsTsv(`${H}\np1\to1\tstate\t3\t\t\tvote-yes\t\np2\to2\tstate\t0\t\tgate\tvote-yes\tconsent-agenda`, 'r.tsv'))
      .toThrow(/r\.tsv: line 3, column gate: "consent-agenda" is not one of multi-subject, consent/);
  });

  it('formatRowsTsv writes a starter rows.tsv that parses back', () => {
    const rows = [
      { politician_id: 'p1', office_id: 'o1', level: 'state' as const, value: 3, record_kind: 'none' as const },
      { politician_id: 'p2', office_id: 'o2', level: 'school' as const, value: 0, blank_reason: 'near-unanimous', blank_class: 'gate' as const, record_kind: 'none' as const },
      { politician_id: 'p3', office_id: 'o3', level: 'local' as const, value: 0, blank_reason: 'odd\treason', record_kind: 'none' as const },
      { politician_id: 'p4', office_id: 'o4', level: 'federal' as const, value: 2.5, record_kind: 'vote-yes' as const, gate: 'consent' },
    ];
    const text = formatRowsTsv(rows);
    const lines = text.split('\n');
    expect(lines[0]).toBe(H);
    expect(lines[1]).toBe('p1\to1\tstate\t3\t\t\tnone\t');
    expect(lines[2]).toBe('p2\to2\tschool\t0\tnear-unanimous\tgate\tnone\t');
    expect(lines[4]).toBe('p4\to4\tfederal\t2.5\t\t\tnone\t');
    const back = parseRowsTsv(text, 'starter');
    expect(back).toHaveLength(4);
    expect(back[2].blank_reason).toBe('odd reason');
    expect(back[2].blank_class).toBeUndefined();
    expect(back.every((r) => r.record_kind === 'none' && r.gate === undefined)).toBe(true);
  });

  it('formatRowsTsv derives blank_class from the reason when the row has none', () => {
    const text = formatRowsTsv([{ politician_id: 'p', office_id: 'o', level: 'state', value: 0, blank_reason: 'compound-partial', record_kind: 'none' }]);
    expect(text.split('\n')[1]).toBe('p\to\tstate\t0\tcompound-partial\twording\tnone\t');
  });

  it('formatRowsTsv leaves a stored direction-only unclassified, and never writes reasoning', () => {
    const text = formatRowsTsv([{ politician_id: 'p', office_id: 'o', level: 'state', value: 0, blank_reason: 'direction-only', record_kind: 'none', reasoning: 'secret' }]);
    expect(text.split('\n')[1]).toBe('p\to\tstate\t0\tdirection-only\t\tnone\t');
    expect(text).not.toContain('secret');
  });
});
