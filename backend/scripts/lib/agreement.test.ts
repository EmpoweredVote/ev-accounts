import { describe, it, expect } from 'vitest';
import { agree, consensusSlot, type CoderRowLabel } from './agreement.js';

const L = (slot: number, value: number | null, rests_on: string[] = ['a'], over: Partial<CoderRowLabel> = {}): CoderRowLabel =>
  ({ slot, valid: true, value, blank_reason: value === null ? 'no-evidence' : null, rests_on, needs_source: [], ...over });

describe('agree (spec section 1.5, section 5.5)', () => {
  it('unanimous chair with a shared source', () =>
    expect(agree([L(1, 4, ['a', 'b']), L(2, 4, ['a']), L(3, 4, ['a', 'c'])])).toEqual({ kind: 'unanimous-chair', value: 4, shared_sources: ['a'] }));
  it('same chair on disjoint sources is NOT unanimous', () =>
    expect(agree([L(1, 4, ['a']), L(2, 4, ['b']), L(3, 4, ['a'])])).toEqual({ kind: 'disjoint-sources', value: 4 }));
  it('unanimous blank needs the same reason', () => {
    expect(agree([L(1, null), L(2, null), L(3, null)])).toEqual({ kind: 'unanimous-blank', reason: 'no-evidence' });
    expect(agree([L(1, null), L(2, null, [], { blank_reason: 'direction-only' }), L(3, null)]).kind).toBe('split');
  });
  it('a split names every coder value', () =>
    expect(agree([L(1, 4), L(2, 5), L(3, 4)])).toEqual({ kind: 'split', values: [4, 5, 4] }));
  it('an invalid or absent coder makes the row coder-missing, even when the other two agree', () => {
    expect(agree([L(1, 4), L(2, 4), L(3, 4, ['a'], { valid: false })])).toEqual({ kind: 'coder-missing', missing: [3] });
    expect(agree([L(1, 4), L(2, 4)])).toEqual({ kind: 'coder-missing', missing: [3] });
  });
  it('any source request holds the row, before any agreement is read', () =>
    expect(agree([L(1, 4), L(2, 4, ['a'], { needs_source: ['roll call'] }), L(3, 4)])).toEqual({ kind: 'needs-source', requests: ['roll call'] }));
});

describe('consensusSlot', () => {
  it('picks the agreeing coder with the tightest basis', () =>
    expect(consensusSlot([L(1, 4, ['a', 'b']), L(2, 4, ['a']), L(3, 5, [])], 4)).toBe(2));
});
