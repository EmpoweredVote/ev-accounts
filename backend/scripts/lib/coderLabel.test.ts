import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { CODEBOOK_VERSION, validateCoderLabelFile, passageAllowsChair, rowKey, type Passage, type CoderRow } from './coderLabel.js';

const SNAP = 'aaaaaaaa-0000-0000-0000-000000000001';
const snapshotText = new Map([[SNAP, 'The Senate voted 21-8 to override the veto of H.B. 11, which requires students to compete on teams matching their sex at birth.']]);
const passage = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: SNAP, v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11 (2022)',
  provision_quote: 'requires students to compete on teams matching their sex at birth', note: '', ...over,
});
const row = (over: Partial<CoderRow> = {}): CoderRow => ({
  politician_id: 'p1', office_id: 'o1', topic_id: 't1', served_revision_id: 'r1',
  passages: [passage()], v6_value: 4, v6_blank_reason: null, rests_on: [SNAP],
  reasoning: 'Led the override of H.B. 11, whose text is the rung.', needs_source: [], quotes: [], ...over,
});
const file = (rows: CoderRow[], over: Record<string, unknown> = {}) => ({ codebook_version: CODEBOOK_VERSION, coder_slot: 1, rows, ...over });
const ctx = { snapshotText, expectedSlot: 1 };

describe('CODEBOOK_VERSION', () => {
  it('equals the **Version:** line of the codebook (drift guard)', () => {
    const md = readFileSync(fileURLToPath(new URL('../../../docs/codebook/stance-and-quote-codebook.md', import.meta.url)), 'utf8');
    expect(md).toMatch(new RegExp(`\\*\\*Version:\\*\\* ${CODEBOOK_VERSION.replace('.', '\\.')} `));
  });
});

describe('passageAllowsChair', () => {
  it('allows a chair-shaped, in-term, on-question own act', () => expect(passageAllowsChair(passage())).toBe(true));
  it.each([
    ['third-party characterization', { v1_attribution: 'third-party-characterization' }],
    ['adjacent', { v2_relevance: 'adjacent' }],
    ['not-evidence (scorecard)', { v3_class: 'not-evidence' }],
    ['multi-subject vote (vote ladder)', { v4_shape: 'multi-subject' }],
    ['procedural vote', { v4_shape: 'procedural' }],
    ['pre-seating', { v5_time: 'pre-seating' }],
  ] as const)('refuses %s', (_label, over) => expect(passageAllowsChair(passage(over as Partial<Passage>))).toBe(false));
});

describe('validateCoderLabelFile', () => {
  it('accepts a valid file', () => {
    const r = validateCoderLabelFile(file([row()]), ctx);
    expect(r.fileErrors).toEqual([]);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].errors).toEqual([]);
    expect(r.rows[0].key).toBe(rowKey({ politician_id: 'p1', office_id: 'o1', topic_id: 't1' }));
  });
  it('refuses a wrong codebook version and a wrong slot at file level', () => {
    const r = validateCoderLabelFile(file([row()], { codebook_version: '0.1', coder_slot: 2 }), ctx);
    expect(r.fileErrors).toEqual([`codebook_version 0.1 != ${CODEBOOK_VERSION}`, 'coder_slot 2 != 1']);
  });
  it('refuses a non-object', () => {
    expect(validateCoderLabelFile('prose instead of JSON', ctx).fileErrors).toEqual(['not an object with a rows array']);
  });
  it('requires value null iff a blank reason is set', () => {
    const r = validateCoderLabelFile(file([row({ v6_value: null, v6_blank_reason: null })]), ctx);
    expect(r.rows[0].errors).toContain('v6: value is null but no blank reason');
    const r2 = validateCoderLabelFile(file([row({ v6_value: 4, v6_blank_reason: 'no-evidence' })]), ctx);
    expect(r2.rows[0].errors).toContain('v6: value and blank reason both set');
  });
  it('refuses an out-of-range or fractional chair', () => {
    expect(validateCoderLabelFile(file([row({ v6_value: 6 })]), ctx).rows[0].errors).toContain('v6: value 6 not an integer 1..5');
    expect(validateCoderLabelFile(file([row({ v6_value: 2.5 })]), ctx).rows[0].errors).toContain('v6: value 2.5 not an integer 1..5');
  });
  it('requires a numeric chair to rest on at least one passage that allows a chair', () => {
    expect(validateCoderLabelFile(file([row({ rests_on: [] })]), ctx).rows[0].errors).toContain('rests_on: empty for a numeric chair');
    const bad = row({ passages: [passage({ v4_shape: 'multi-subject' })] });
    expect(validateCoderLabelFile(file([bad]), ctx).rows[0].errors).toContain(`rests_on: ${SNAP} does not allow a chair (V1-V5)`);
  });
  it('refuses a cited snapshot that does not exist', () => {
    const ghost = 'aaaaaaaa-0000-0000-0000-00000000dead';
    const r = validateCoderLabelFile(file([row({ rests_on: [ghost], passages: [passage({ snapshot_id: ghost })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage: unknown snapshot ${ghost}`);
  });
  it('refuses a provision_quote that is not verbatim in its snapshot', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ provision_quote: 'bans all transgender athletes from all sport' })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage ${SNAP}: provision_quote not verbatim in snapshot`);
  });
  it('refuses a quote not verbatim in its snapshot, and an unknown V7 tier', () => {
    const q = { snapshot_id: SNAP, text: 'I will ban it all', v7_tier: 'strong', v7_flag: null, v8_quotable: true, v8_codes: [] };
    const errs = validateCoderLabelFile(file([row({ quotes: [q as never] })]), ctx).rows[0].errors;
    expect(errs).toContain('quote: text not verbatim in snapshot');
    expect(errs).toContain('quote: v7_tier strong not allowed');
  });
  it('lets a quotable quote carry only the non-gating non-differentiating-goal code', () => {
    const q = { snapshot_id: SNAP, text: 'override the veto', v7_tier: 'none', v7_flag: null, v8_quotable: true, v8_codes: ['is-attack'] };
    expect(validateCoderLabelFile(file([row({ quotes: [q] })]), ctx).rows[0].errors)
      .toContain('quote: v8_quotable true but gating codes present');
  });
  it('refuses an unknown enum value in a passage', () => {
    const errs = validateCoderLabelFile(file([row({ passages: [passage({ v3_class: 'statement' as never })] })]), ctx).rows[0].errors;
    expect(errs).toContain(`passage ${SNAP}: v3_class statement not allowed`);
  });
  it('validates rows independently — one bad row does not invalidate a good one', () => {
    const r = validateCoderLabelFile(file([row(), row({ topic_id: 't2', v6_value: 9 })]), ctx);
    expect(r.rows[0].errors).toEqual([]);
    expect(r.rows[1].errors.length).toBeGreaterThan(0);
  });
  // Final review item 2: a date the CONFIRM checks cannot compare must not pass as valid.
  it.each([['March 2010'], ['unknown'], ['2010-13'], ['2010-02-30'], ['2010-1-5'], ['20101']])('refuses passage date %s', (d) =>
    expect(validateCoderLabelFile(file([row({ passages: [passage({ date: d })] })]), ctx).rows[0].errors)
      .toContain(`passage ${SNAP}: date ${d} not YYYY, YYYY-MM or YYYY-MM-DD`));
  it.each([['2010'], ['2010-03'], ['2024-02-29'], [null]])('accepts passage date %s', (d) =>
    expect(validateCoderLabelFile(file([row({ passages: [passage({ date: d })] })]), ctx).rows[0].errors).toEqual([]));
});
