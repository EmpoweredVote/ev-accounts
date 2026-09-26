import { describe, it, expect } from 'vitest';
import { parseGoldFile, type GoldEntry } from './goldLabels.js';

const ok: GoldEntry = {
  item: 'G3', batch: '2026-09-26-shadow-gowan', politician_id: 'e71471f4-bef5-46ef-a1f2-f19f275b558d',
  office_id: 'fe457319-058b-4dc5-8540-dac64a6a328f', topic_key: 'ranked-choice-voting', mode: 'blind',
  blind: { value: 5, blank_reason: null, submitted_at: '2026-09-26T19:02:00Z' },
  final: { value: 5, blank_reason: null }, codebook_version: '0.3', reviewer_id: '854fbc06-40fc-458d-b523-20ef8e5ad1b2',
  excluded_from_cert: false, note: 'coders 3/3 rung 5',
};
const file = (entries: unknown[]) => ({ labeller: 'Chris Andrews', entries });

describe('parseGoldFile', () => {
  it('accepts a blind entry with a chair', () => expect(parseGoldFile(file([ok]))).toEqual({ ok: true, entries: [ok] }));
  it('accepts a blank with a reason, and a final that differs from the blind answer (adjudication)', () => {
    const e = { ...ok, blind: { value: null, blank_reason: 'no-evidence', submitted_at: ok.blind.submitted_at }, final: { value: null, blank_reason: 'direction-only' } };
    expect(parseGoldFile(file([e])).ok).toBe(true);
  });
  it.each([
    ['a chair AND a blank reason', { ...ok, blind: { ...ok.blind, blank_reason: 'no-evidence' } }, /G3: blind needs a chair XOR a blank reason/],
    ['neither a chair nor a blank reason', { ...ok, final: { value: null, blank_reason: null } }, /G3: final needs a chair XOR a blank reason/],
    ['an unknown blank reason', { ...ok, final: { value: null, blank_reason: 'adjacent' } }, /G3: final blank_reason "adjacent"/],
    ['a chair out of range', { ...ok, blind: { ...ok.blind, value: 6 } }, /G3: blind value 6/],
    ['a blind entry with no submitted_at', { ...ok, blind: { ...ok.blind, submitted_at: null } }, /G3: blind mode needs blind.submitted_at/],
    ['an unknown mode', { ...ok, mode: 'guess' }, /G3: mode "guess"/],
    ['a bad uuid', { ...ok, politician_id: 'x' }, /G3: politician_id is not a uuid/],
    ['an unknown key', { ...ok, extra: 1 }, /G3: unknown key "extra"/],
  ])('rejects %s', (_l, e, re) => {
    const r = parseGoldFile(file([e]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors.join('\n')).toMatch(re);
  });
  it('rejects two entries for the same item', () => {
    const r = parseGoldFile(file([ok, ok]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors.join('\n')).toMatch(/duplicate item "G3"/);
  });
});
