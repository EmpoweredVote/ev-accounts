import { describe, expect, it } from 'vitest';
import { checkAtIngest, finalizeCode, labelsIn, rungTextsFromLadder, storeIdToken, strangeBills, personBills, unsourcedQuotes, type CodeHeader } from './stage5Ingest.js';
import type { PersonFindings } from './sourceStore.js';

const PID = '11111111-1111-4111-8111-111111111111';
const header: CodeHeader = { topic_key: 'gun-policy', season: 3, season_id: 'S', revision_id: 'R', codebook: '0.6' };
const prov = { fetched_by: 'test', fetched_at: '2026-11-01T00:00:00Z', method: 'api' as const };
const vote = {
  id: 'a'.repeat(64), kind: 'record' as const, url: 'https://legis.example/hb1324', date: '2026-03-06', date_precision: 'day' as const,
  instrument_id: 'GA-HB-1324-2025', act: 'yea' as const, motion: 'Passage', gate_by_topic: { 'gun-policy': 'none' },
  note: 'GA House passage: yea.', subjects: ['state silencer ban repealed'], topic_keys: ['gun-policy'], provenance: prov,
};
const words = {
  id: 'b'.repeat(64), kind: 'own-words' as const, url: 'https://campaign.example/issues', date: '2026-01-01', date_precision: 'month' as const,
  passage: 'I will always defend the right of law-abiding citizens to carry without a permit.',
  note: 'Campaign issues page; says "carry without a permit" in the heading.', subjects: ['permitless carry'], topic_keys: ['gun-policy'], provenance: prov,
};
const otherTopic = { ...words, id: 'c'.repeat(64), passage: 'Photo ID keeps elections secure.', topic_keys: ['voting-rights'] };
const pf: PersonFindings = { politician_id: PID, findings: [vote, words, otherTopic], searches: [{ topic_key: 'gun-policy', season: 3, subjects: [], places: ['web'], found: 2, at: '2026-11-01', by: 'x' }] };
const instruments = new Map([['GA-HB-1324-2025', { title: 'HB1324: Crimes and offenses; possessing a silencer; repeal prohibition', operative_text: 'Code Section 16-11-122, relating to possession of a silencer, is repealed in its entirety.' }]]);
const ladder = '   Question: "How should the government regulate firearms?"\n   4. Make carrying a gun easier, such as honoring carry permits from other states.\n   5. Repeal laws that require a permit or registration for a gun, such as the permit to carry.';
const ctx = { instruments, rungTexts: rungTextsFromLadder(ladder) };

const seat = (reasoning: string, ids = [vote.id]) => finalizeCode(
  { politician_id: PID, outcome: 'seated', value: 5, reasoning, finding_ids: ids }, header, pf, new Date('2026-11-12T10:00:00Z'));

describe('finalizeCode', () => {
  it('takes season fields from the header, sets coded_at, and computes evidence_basis from the cited kinds', () => {
    const c = finalizeCode({ politician_id: PID, outcome: 'seated', value: 5, reasoning: 'x', finding_ids: [vote.id, words.id], evidence_basis: 'record', season: 9, coded_at: '2099-01-01' }, header, pf, new Date('2026-11-12T10:00:00Z'));
    expect(c.evidence_basis).toBe('joint');
    expect(c.season).toBe(3);
    expect(c.coded_at).toBe('2026-11-12T10:00:00.000Z');
    expect(c.coded_by).toBe('stage5-coder');
    expect(finalizeCode({ politician_id: PID, outcome: 'seated', value: 5, reasoning: 'x', finding_ids: [words.id] }, header, pf, new Date()).evidence_basis).toBe('own-words');
  });
  it('leaves evidence_basis out of a no-stance code', () => {
    const c = finalizeCode({ politician_id: PID, outcome: 'no-stance', reasoning: 'searched', evidence_basis: 'record' }, header, pf, new Date());
    expect(c.evidence_basis).toBeUndefined();
  });
});

describe('checkAtIngest', () => {
  it('passes a clean seat', () => {
    expect(checkAtIngest(seat('A Yea on HB 1324 (2025), which repeals the silencer ban: "relating to possession of a silencer, is repealed in its entirety". That is "Repeal laws that require a permit or registration for a gun".'), pf, ctx)).toEqual([]);
  });
  it('refuses a bill the person has no finding on', () => {
    const p = checkAtIngest(seat('A Yea on HB 1324, like the Yea votes on HB 51 and SB 2.'), pf, ctx);
    expect(p.filter((x) => x.includes('not in this person'))).toHaveLength(2);
  });
  it('refuses a store id from another state named as an example', () => {
    expect(checkAtIngest(seat('A Yea on GA-HB-1324-2025, read like TX-SB-1596-2025.'), pf, ctx).join()).toContain('TX-SB-1596-2025');
  });
  it('refuses annex labels, and does not also report them as bills', () => {
    const p = checkAtIngest(seat('Under S3 and R5-AZ, a Yea on HB 1324 is a rung 5 act (C2 does not apply).'), pf, ctx);
    expect(p.filter((x) => x.includes('label'))).toHaveLength(3);
    expect(p.some((x) => x.includes('not in this person'))).toBe(false);
  });
  it('refuses a quote found in no cited source, and accepts one from a cited passage, a quoted note span or an ellipsis edit', () => {
    expect(checkAtIngest(seat('He voted "to abolish every gun permit in the state" on HB 1324.'), pf, ctx).join()).toContain('quote marks');
    const ok = seat('She wrote "defend the right of law-abiding citizens to carry", and the page heads it "carry without a permit" … "is repealed in its entirety".', [vote.id, words.id]);
    expect(checkAtIngest(ok, pf, ctx)).toEqual([]);
    expect(checkAtIngest(seat('The bill says "Code Section 16-11-122 ... is repealed in its entirety".'), pf, ctx)).toEqual([]);
  });
  it('does not take a quote from a finding the code does not cite, and names that finding', () => {
    expect(checkAtIngest(seat('A Yea on HB 1324; she wrote "defend the right of law-abiding citizens".'), pf, ctx).join()).toContain(`finding ${'b'.repeat(12)}…, which the code does not cite`);
  });
  it('accepts a rung quoted with an ellipsis', () => {
    expect(checkAtIngest(seat('That is rung 5, "Repeal laws that require a permit ... such as the permit to carry".'), pf, ctx)).toEqual([]);
  });
  it('still runs checkCode', () => {
    const c = finalizeCode({ politician_id: PID, outcome: 'seated', reasoning: 'HB 1324', finding_ids: [vote.id] }, header, pf, new Date());
    expect(checkAtIngest(c, pf, ctx)).toContain('a seat needs a value');
  });
});

describe('helpers', () => {
  it('reads labels but never a bill', () => {
    expect(labelsIn('S1, S8, Q4, C37, H12, R8, R5-L and R5-AZ; not S. 2747, S 1496, SB 204, H 3003, V4.1, MA-ACTS-C135-2024 or MA-S-1677-2025.'))
      .toEqual(['S1', 'S8', 'Q4', 'C37', 'H12', 'R8', 'R5-L', 'R5-AZ']);
  });
  it('turns a store id into the gate token', () => {
    expect(storeIdToken('GA-HB-1324-2025')).toBe('hb1324');
    expect(storeIdToken('MA-H-4135-AMDT-4-2023')).toBe('h4135');
    expect(storeIdToken('MA-ACTS-C135-2024')).toBeNull();
  });
  it('knows a person\'s bills from ids, titles and notes', () => {
    const b = personBills(pf, 'gun-policy', instruments);
    expect(strangeBills('HB 1324, H.B. 1324, HB1324 and GA-HB-1324-2025', b)).toEqual([]);
    expect(strangeBills('HB 13240', b)).toEqual(['HB 13240']);
  });
  it('ignores quotes under four words and quotes of the ladder', () => {
    expect(unsourcedQuotes('a "ghost gun" and "honoring carry permits from other states"', [], rungTextsFromLadder(ladder))).toEqual([]);
  });
});
