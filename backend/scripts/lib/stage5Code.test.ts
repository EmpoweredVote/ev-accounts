import { describe, it, expect } from 'vitest';
import { checkCode, Stage5CodeSchema, type Stage5Code } from './stage5Code.js';
import { findingId, type Finding, type PersonFindings } from './sourceStore.js';

const PID = '11111111-1111-4111-8111-111111111111';
const prov = { fetched_by: 't', fetched_at: '2026-10-22T00:00:00Z', method: 'webfetch' as const };
const mk = (f: Omit<Finding, 'id' | 'provenance' | 'topic_keys' | 'date_precision'>): Finding => {
  const base = { ...f, date_precision: 'day' as const, topic_keys: ['voting-rights'], provenance: prov };
  return { id: findingId(base), ...base } as Finding;
};
const words = mk({ kind: 'own-words', url: 'https://x.example/a', date: '2026-09-01', passage: 'Show ID to vote.', note: 'n', subjects: ['voter ID at the polls'] });
const vote = mk({ kind: 'record', url: 'https://x.example/b', date: '2011-04-12', instrument_id: 'IN-SB-483-2011', act: 'yea', motion: 'final passage', note: 'n', subjects: ['voter ID at the polls'] });
const local = mk({ kind: 'record', url: 'https://x.example/c', date: '2024-02-01', act: 'yea', local_record: true, note: 'n', subjects: ['voter ID at the polls'] });

const searched = { topic_key: 'voting-rights', season: 3, subjects: ['voter ID'], places: ['site'], found: 0, at: '2026-10-22T00:00:00Z', by: 't' };
const person = (findings: Finding[], searches = [searched]): PersonFindings => ({ politician_id: PID, findings, searches });

const code = (over: Partial<Stage5Code>): Stage5Code => ({
  politician_id: PID, topic_key: 'voting-rights', season: 3, season_id: 's', revision_id: 'r',
  outcome: 'seated', value: 4, reasoning: 'Sponsored a strict photo-ID law.', tags: [], finding_ids: [vote.id],
  evidence_basis: 'record', codebook: '0.6', coded_by: 'coder', coded_at: '2026-10-22T00:00:00Z', ...over,
} as Stage5Code);

describe('checkCode', () => {
  it('accepts a valid code of each outcome', () => {
    expect(checkCode(code({}), person([vote]))).toEqual([]);
    expect(checkCode(code({ outcome: 'doesnt-fit', value: undefined, open_note: 'Backs ID but names no rung act.', tags: ['direction-only'], finding_ids: [words.id], evidence_basis: 'own-words', blank_class: 'wording' }), person([words]))).toEqual([]);
    expect(checkCode(code({ outcome: 'no-stance', value: undefined, finding_ids: [], evidence_basis: undefined, reasoning: 'Searched site, OTR, Ballotpedia; nothing on the subject.' }), person([]))).toEqual([]);
  });

  it('needs a value for a seat', () => {
    expect(checkCode(code({ value: undefined }), person([vote]))).toEqual([expect.stringMatching(/value/)]);
  });

  it('refuses a value on anything but a seat', () => {
    expect(checkCode(code({ outcome: 'doesnt-fit', open_note: 'x', evidence_basis: 'record' }), person([vote])).join()).toMatch(/value/);
  });

  it('needs an open note for doesnt-fit', () => {
    expect(checkCode(code({ outcome: 'doesnt-fit', value: undefined, open_note: '  ' }), person([vote])).join()).toMatch(/open note/);
  });

  it('refuses a cited finding that is not in the person file', () => {
    expect(checkCode(code({ finding_ids: ['f'.repeat(64)] }), person([vote])).join()).toMatch(/not in the findings/);
  });

  it('needs at least one finding for a seat or a doesnt-fit', () => {
    expect(checkCode(code({ finding_ids: [] }), person([vote])).join()).toMatch(/at least one finding/);
  });

  it('refuses a seat that rests on local records alone', () => {
    expect(checkCode(code({ finding_ids: [local.id] }), person([local])).join()).toMatch(/local record never seats alone/);
    expect(checkCode(code({ finding_ids: [local.id, words.id], evidence_basis: 'joint' }), person([local, words]))).toEqual([]);
  });

  it('needs own words beside any local record a seat cites', () => {
    expect(checkCode(code({ finding_ids: [local.id, vote.id] }), person([local, vote])).join()).toMatch(/own words/);
  });

  it('refuses a cited finding that is not on this topic', () => {
    const other = { ...vote, topic_keys: ['abortion'] };
    expect(checkCode(code({ finding_ids: [other.id] }), person([other])).join()).toMatch(/not on voting-rights/);
  });

  it('needs evidence_basis to match the cited kinds', () => {
    expect(checkCode(code({ evidence_basis: 'own-words' }), person([vote])).join()).toMatch(/evidence_basis/);
    expect(checkCode(code({ finding_ids: [vote.id, words.id], evidence_basis: 'joint' }), person([vote, words]))).toEqual([]);
  });

  it('refuses no-stance without a search for this topic and season', () => {
    const c = code({ outcome: 'no-stance', value: undefined, finding_ids: [], evidence_basis: undefined });
    expect(checkCode(c, person([], [{ ...searched, season: 2 }])).join()).toMatch(/no search/);
  });

  it('refuses no-stance when on-topic findings are on file', () => {
    const c = code({ outcome: 'no-stance', value: undefined, finding_ids: [], evidence_basis: undefined });
    expect(checkCode(c, person([vote])).join()).toMatch(/findings on file/);
  });

  it('refuses source-gap on a doesnt-fit, and tags on a seat', () => {
    expect(checkCode(code({ outcome: 'doesnt-fit', value: undefined, open_note: 'x', blank_class: 'source-gap' }), person([vote])).join()).toMatch(/source-gap/);
    expect(checkCode(code({ tags: ['between-rungs'] }), person([vote])).join()).toMatch(/tags/);
  });
});

describe('Stage5CodeSchema', () => {
  it('accepts half values and refuses out-of-range ones', () => {
    expect(Stage5CodeSchema.safeParse(code({ value: 2.5 })).success).toBe(true);
    expect(Stage5CodeSchema.safeParse(code({ value: 2.3 })).success).toBe(false);
    expect(Stage5CodeSchema.safeParse(code({ value: 6 })).success).toBe(false);
  });
  it('refuses an unknown tag', () => {
    expect(Stage5CodeSchema.safeParse(code({ tags: ['nonsense' as never] })).success).toBe(false);
  });
});
