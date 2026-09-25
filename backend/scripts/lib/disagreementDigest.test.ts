import { describe, it, expect } from 'vitest';
import { buildDisagreementDigest, MAX_EXAMPLES } from './disagreementDigest.js';
import type { CoderRow, Passage } from './coderLabel.js';

const P = (over: Partial<Passage> = {}): Passage => ({ snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question',
  v3_class: 'record', v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2022-01-01', instrument: 'HB 1', provision_quote: null, ...over });
const R = (topic_id: string, value: number | null, passages: Passage[] = [P()]): CoderRow => ({ politician_id: 'p', office_id: 'o', topic_id,
  served_revision_id: 'r', passages, v6_value: value, v6_blank_reason: value === null ? 'no-evidence' : null, rests_on: value === null ? [] : ['s1'],
  reasoning: 'x', needs_source: [], quotes: [] });

describe('buildDisagreementDigest (spec sec10.1)', () => {
  it('reports no splits when the three coders agree on everything', () => {
    const d = buildDisagreementDigest(new Map([1, 2, 3].map((s) => [s, [R('t1', 4)]])));
    expect(d.ranked).toEqual([]);
    expect(d.variables.every((v) => v.split_units === 0)).toBe(true);
  });
  it('ranks the variable that split, with the three values as the example', () => {
    const d = buildDisagreementDigest(new Map([
      [1, [R('t1', 4)]], [2, [R('t1', 4, [P({ v4_shape: 'multi-subject' })])]], [3, [R('t1', 4)]],
    ]));
    expect(d.ranked).toEqual(['v4_shape']);
    const v4 = d.variables.find((v) => v.variable === 'v4_shape')!;
    expect(v4).toMatchObject({ units: 1, split_units: 1 });
    expect(v4.examples).toEqual([{ unit: 'p|o|t1#s1', values: ['chair-shaped', 'multi-subject', 'chair-shaped'] }]);
  });
  it('treats the chair as a row-level unit with BLANK as a category', () => {
    const d = buildDisagreementDigest(new Map([[1, [R('t1', 4)]], [2, [R('t1', null)]], [3, [R('t1', 4)]]]));
    const v6 = d.variables.find((v) => v.variable === 'v6_chair')!;
    expect(v6.examples[0]).toEqual({ unit: 'p|o|t1', values: ['4', 'BLANK', '4'] });
  });
  it('still counts a unit coded by only two coders (a missing coder is null, not a split)', () => {
    const d = buildDisagreementDigest(new Map([[1, [R('t1', 4)]], [2, [R('t1', 5)]]]));
    const v6 = d.variables.find((v) => v.variable === 'v6_chair')!;
    expect(v6).toMatchObject({ units: 1, split_units: 1 });
    expect(v6.examples[0].values).toEqual(['4', '5', null]);
  });
  it('ranks by split RATE, not count', () => {
    // v5 splits on 1 of 1 passage; v6 splits on 1 of 2 rows.
    const d = buildDisagreementDigest(new Map([
      [1, [R('t1', 4), R('t2', 3, [P({ snapshot_id: 's2' })])]],
      [2, [R('t1', 4, [P({ v5_time: 'pre-seating' })]), R('t2', 2, [P({ snapshot_id: 's2' })])]],
    ]));
    expect(d.ranked.indexOf('v5_time')).toBeLessThan(d.ranked.indexOf('v6_chair'));
  });
  it(`keeps at most ${MAX_EXAMPLES} examples per variable`, () => {
    const topics = ['t1', 't2', 't3', 't4', 't5'];
    const d = buildDisagreementDigest(new Map([[1, topics.map((t) => R(t, 1))], [2, topics.map((t) => R(t, 2))]]));
    expect(d.variables.find((v) => v.variable === 'v6_chair')!.examples).toHaveLength(MAX_EXAMPLES);
  });
});
