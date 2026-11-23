import { describe, it, expect } from 'vitest';
import {
  actClaimProblems, buildSummary, lintSummary, summaryVerdict, agreementRate, SummaryDraftSchema, SummaryCheckSchema,
  type SummaryDraft, type SummaryCheck,
} from './stage5Summary.js';
import { shownSha256 } from './stage5QuoteCheck.js';
import type { Finding } from './sourceStore.js';
import type { Stage5Code } from './stage5Code.js';

const PID = '11111111-1111-4111-8111-111111111111';
function finding(id: string, url: string): Finding {
  return {
    id, kind: 'own-words', url, date: '2024-01-01', date_precision: 'day', passage: 'p', note: 'n',
    subjects: ['s'], topic_keys: ['gun-policy'], provenance: {} as Finding['provenance'],
  } as Finding;
}
const f1 = finding('f1', 'https://a.example/one');
const f2 = finding('f2', 'https://b.example/two');
const f3 = finding('f3', 'https://a.example/one/#frag');
const f4 = finding('f4', 'https://c.example/four');
const code = { politician_id: PID, topic_key: 'gun-policy' } as Stage5Code;
const ctx = (findings: Finding[]) => ({ findings, code, sides: '1,2,3/4,5' });
const draft = (sentences: { text: string; cites: string[] }[]): SummaryDraft => ({ politician_id: PID, topic_key: 'gun-policy', sentences });
const two = (a = 'A.', b = 'B.', ca = ['f1'], cb = ['f2']) => draft([{ text: a, cites: ca }, { text: b, cites: cb }]);
/** two() behind an opening line, the shape the lint requires of a summary of two or more sentences. */
const led = (a = 'A.', b = 'B.', ca = ['f1'], cb = ['f2']): SummaryDraft =>
  ({ ...two(a, b, ca, cb), sentences: [{ text: 'He leans one way.', lead: true }, ...two(a, b, ca, cb).sentences] });

describe('buildSummary', () => {
  it('numbers by first use and places markers before closing punctuation', () => {
    const r = buildSummary(two('A.', 'B.', ['f2'], ['f1', 'f2']), [f1, f2]);
    expect(r.text).toBe('A [1]. B [2, 1].');
    expect(r.sources).toEqual([f2.url, f1.url]);
    expect(r.sha256).toBe(shownSha256(r.text));
  });
  it('gives two findings on one URL one number', () => {
    const r = buildSummary(draft([{ text: 'A.', cites: ['f1'] }, { text: 'B.', cites: ['f3'] }]), [f1, f3]);
    expect(r.sources).toHaveLength(1);
    expect(r.text).toBe('A [1]. B [1].');
    const s = buildSummary(draft([{ text: 'A.', cites: ['f1', 'f3'] }, { text: 'B.', cites: ['f1'] }]), [f1, f3]);
    expect(s.text).toBe('A [1]. B [1].');
  });
  it('throws on a cite it cannot find', () => {
    expect(() => buildSummary(two(), [f1])).toThrow(/f2/);
  });
});

describe('lintSummary', () => {
  const fs = [f1, f2, f3, f4];
  it('requires an opening line once a summary has two or more sentences (ruling 6)', () => {
    expect(lintSummary(two(), ctx(fs)).join(' ')).toMatch(/opens with a plain-direction line/);
    expect(lintSummary(draft([{ text: 'A.', cites: ['f1'] }]), ctx(fs))).toEqual([]);
  });
  it('is clean for a good draft', () => { expect(lintSummary(led(), ctx(fs))).toEqual([]); });
  it('refuses a cite not in the person\'s findings', () => {
    expect(lintSummary(led('A.', 'B.', ['f1'], ['zzz']), ctx(fs)).join(' ')).toMatch(/zzz/);
  });
  it('refuses a sentence with no cites', () => {
    expect(lintSummary(led('A.', 'B.', ['f1'], []), ctx(fs)).join(' ')).toMatch(/no citation/i);
  });
  it('refuses 0 or 6 sentences and accepts 1 (ruling 2026-11-22: one finding is often enough)', () => {
    const s = { text: 'A.', cites: ['f1'] };
    expect(lintSummary(draft([]), ctx(fs)).join(' ')).toMatch(/1.5 sentences/);
    expect(lintSummary(draft([s]), ctx(fs))).toEqual([]);
    expect(lintSummary(draft(Array(6).fill(s)), ctx(fs)).join(' ')).toMatch(/1.5 sentences/);
    expect(lintSummary(draft([{ text: 'Lead.', lead: true } as never, ...Array(4).fill(s)]), ctx(fs))).toEqual([]);
  });
  it('refuses an entry holding two sentences, accepts abbreviations', () => {
    expect(lintSummary(led('It passed. Then it failed.'), ctx(fs)).join(' ')).toMatch(/more than one sentence/);
    expect(lintSummary(led('The U.S. Senate passed it.'), ctx(fs))).toEqual([]);
    expect(lintSummary(led('Sen. Smith spoke, e.g. Dr. Jones agreed.'), ctx(fs))).toEqual([]);
  });
  it('reads a middle initial as part of a name, not a sentence end', () => {
    expect(lintSummary(led('Danica A. Roem voted for A.', 'Richard H. Stuart voted for B.'), ctx(fs))).toEqual([]);
    expect(lintSummary(led('He voted for it. She voted for B.'), ctx(fs)).join()).toMatch(/more than one sentence/);
  });
  it('refuses the word rung and a rung number', () => {
    expect(lintSummary(led('Holds rung 3.'), ctx(fs)).join(' ')).toMatch(/rung/i);
    expect(lintSummary(led('Sits on the ladder.'), ctx(fs)).join(' ')).toMatch(/ladder/i);
  });
  it('refuses a party name', () => {
    expect(lintSummary(led('Joined the Republican caucus.'), ctx(fs)).join(' ')).toMatch(/party/i);
  });
  it('refuses "often" with 2 distinct cites and passes with 3', () => {
    expect(lintSummary(led('He often votes yes.', 'B.', ['f1', 'f2']), ctx(fs)).join(' ')).toMatch(/often/);
    expect(lintSummary(led('He often votes yes.', 'B.', ['f1', 'f2', 'f4']), ctx(fs))).toEqual([]);
  });
  it('refuses "more than once" with 1 cite', () => {
    expect(lintSummary(led('She said so more than once.', 'B.', ['f1']), ctx(fs)).join(' ')).toMatch(/more than once/);
    expect(lintSummary(led('She said so more than once.', 'B.', ['f1', 'f2']), ctx(fs))).toEqual([]);
  });
  it('accepts only this person\'s findings when 40+ are supplied', () => {
    const many = Array.from({ length: 45 }, (_, i) => finding(`g${i}`, `https://x.example/${i}`));
    const mine = [...many, f1, f2];
    expect(lintSummary(led(), ctx(mine))).toEqual([]);
    expect(lintSummary(led('A.', 'B.', ['g44'], ['g0']), ctx(many)).join(' ')).toBe('');
    expect(lintSummary(led('A.', 'B.', ['f1'], ['f2']), ctx(many)).join(' ')).toMatch(/f1/);
  });
});

describe('schemas', () => {
  it('parse', () => {
    expect(SummaryDraftSchema.parse(two()).sentences).toHaveLength(2);
    const c = { politician_id: PID, topic_key: 't', text_sha256: 'x', checker: 'c', family: 'gpt', sentences: [], verdict: 'pass', at: '2026-11-22T10:00:00-05:00' };
    expect(SummaryCheckSchema.parse(c).family).toBe('gpt');
    expect(() => SummaryCheckSchema.parse({ ...c, at: '2026-11-22' })).toThrow();
  });
});

describe('summaryVerdict', () => {
  const mk = (family: SummaryCheck['family'], verdict: 'pass' | 'fail', sha = 'S'): SummaryCheck => ({
    politician_id: PID, topic_key: 't', text_sha256: sha, checker: 'x', family, sentences: [], verdict, at: '2026-11-22T10:00:00Z',
  });
  const req: SummaryCheck['family'][] = ['claude', 'gpt'];
  it('passes when all required pass on the sha', () => { expect(summaryVerdict([mk('claude', 'pass'), mk('gpt', 'pass')], 'S', req)).toBe('passed'); });
  it('holds on any fail', () => { expect(summaryVerdict([mk('claude', 'pass'), mk('gpt', 'fail')], 'S', req)).toBe('held'); });
  it('ignores another sha, so a missing family holds', () => {
    expect(summaryVerdict([mk('claude', 'pass'), mk('gpt', 'pass', 'OTHER')], 'S', req)).toBe('held');
  });
  it('treats a failing sentence as a fail even when the top verdict passes', () => {
    const bad = { ...mk('gpt', 'pass'), sentences: [{ index: 0, verdict: 'fail' as const, reason: 'x' }] };
    expect(summaryVerdict([mk('claude', 'pass'), bad], 'S', req)).toBe('held');
    const badClaude = { ...mk('claude', 'pass'), sentences: [{ index: 1, verdict: 'fail' as const, reason: 'x' }] };
    expect(summaryVerdict([badClaude, mk('gpt', 'pass')], 'S', req)).toBe('failed');
  });
  it('does not let a re-run on the same text clear an earlier fail', () => {
    const g1 = { ...mk('gpt', 'fail'), at: '2026-11-22T10:00:00Z' };
    const g2 = { ...mk('gpt', 'pass'), at: '2026-11-22T11:00:00Z' };
    expect(summaryVerdict([mk('claude', 'pass'), g1, g2], 'S', req)).toBe('held');
  });
  it('schema refuses pass with a failing sentence', () => {
    const c = { ...mk('gpt', 'pass'), sentences: [{ index: 0, verdict: 'fail', reason: 'x' }] };
    expect(() => SummaryCheckSchema.parse(c)).toThrow();
  });
  it('fails when claude fails', () => { expect(summaryVerdict([mk('claude', 'fail'), mk('gpt', 'pass')], 'S', req)).toBe('failed'); });
});

describe('agreementRate', () => {
  it('is the share that agree', () => {
    expect(agreementRate([{ all_agree: true }, { all_agree: false }, { all_agree: true }, { all_agree: true }])).toBe(0.75);
    expect(agreementRate([])).toBe(0);
  });
});

// Ruling 2026-11-22 (runner): a summary reads as one paragraph about the person — an opening line in plain words
// with no marker, then acts grouped by what they did, each part carrying its own markers.
describe('lead line and parts', () => {
  const fs = [f1, f2, f4];
  const lead = (text: string) => ({ text, lead: true as const });
  const parts = (...p: [string, string[]][]) => ({ parts: p.map(([text, cites]) => ({ text, cites })) });
  const d = (...sentences: unknown[]) => ({ politician_id: PID, topic_key: 'gun-policy', sentences }) as SummaryDraft;

  it('renders a marker after each part, moving a trailing comma after the marker', () => {
    const r = buildSummary(d(parts(['He voted to end the license requirement,', ['f1']], ['to honor more licenses', ['f2']], ['and to repeal the silencer ban.', ['f4']])), fs);
    expect(r.text).toBe('He voted to end the license requirement [1], to honor more licenses [2] and to repeal the silencer ban [3].');
    expect(r.sentences).toEqual([r.text]);
    expect(r.cites).toEqual([['f1', 'f2', 'f4']]);
  });
  it('renders the lead with no marker and gives it every cite in the summary', () => {
    const r = buildSummary(d(lead('He has voted to loosen limits on guns.'), { text: 'He voted for A.', cites: ['f2'] }, parts(['He backed B', ['f1']], ['and C.', ['f4']])), fs);
    expect(r.text).toBe('He has voted to loosen limits on guns. He voted for A [1]. He backed B [2] and C [3].');
    expect(r.sentences).toEqual(['He has voted to loosen limits on guns.', 'He voted for A [1].', 'He backed B [2] and C [3].']);
    expect(r.cites).toEqual([['f2', 'f1', 'f4'], ['f2'], ['f1', 'f4']]);
    expect(r.sources).toEqual([f2.url, f1.url, f4.url]);
  });
  it('lints a good lead-and-parts draft clean', () => {
    expect(lintSummary(d(lead('He has often voted to loosen limits on guns.'), parts(['He voted for A,', ['f1']], ['B', ['f2']], ['and C.', ['f4']])), ctx(fs))).toEqual([]);
  });
  it('refuses a lead that is not first, a lead alone, a lead with cites, and a part with no cite', () => {
    expect(lintSummary(d({ text: 'A.', cites: ['f1'] }, lead('Lead.')), ctx(fs)).join()).toMatch(/opening line must be the first/);
    expect(lintSummary(d(lead('Lead.')), ctx(fs)).join()).toMatch(/opening line needs at least one cited sentence after it/);
    expect(lintSummary(d({ text: 'Lead.', lead: true, cites: ['f1'] }, { text: 'A.', cites: ['f1'] }), ctx(fs)).join()).toMatch(/opening line carries no cites/);
    expect(lintSummary(d(parts(['A', ['f1']], ['and B.', []])), ctx(fs)).join()).toMatch(/part 2: no citation/);
  });
  it('refuses a sentence with both text and parts, and markers inside a part', () => {
    expect(lintSummary(d({ text: 'A.', cites: ['f1'], parts: [{ text: 'A.', cites: ['f1'] }] }), ctx(fs)).join()).toMatch(/either text or parts/);
    expect(lintSummary(d(parts(['A [1]', ['f1']], ['and B.', ['f2']])), ctx(fs)).join()).toMatch(/citation markers/);
  });
  it('counts a quantity word in the lead against every cite in the summary', () => {
    expect(lintSummary(d(lead('He often voted for gun bills.'), { text: 'A.', cites: ['f1'] }, { text: 'B.', cites: ['f2'] }), ctx(fs)).join()).toMatch(/"often" with 2/);
  });
  it('counts sentences in a lead-plus-parts summary, lead included, 1-5', () => {
    const s = { text: 'A.', cites: ['f1'] };
    expect(lintSummary(d(lead('L.'), s, s, s, s, s), ctx(fs)).join()).toMatch(/1-5 sentences; this has 6/);
  });
});

describe('actClaimProblems: "sponsored" or "voted" must match the cited findings', () => {
  const rec = (id: string, bill: string, act: string): Finding => ({
    id, kind: 'record', url: `https://example.gov/${bill}`, date: '2024-01-01', date_precision: 'day', act, instrument_id: bill,
    note: 'n', subjects: ['s'], topic_keys: ['gun-policy'], provenance: {} as Finding['provenance'],
  } as Finding);
  const fs = [rec('v1', 'XX-HB-1-2024', 'yea'), rec('s1', 'XX-HB-1-2024', 'sponsor'), rec('v2', 'XX-HB-2-2024', 'yea'),
    rec('s3', 'XX-HB-3-2024', 'sponsor'), rec('o4', 'XX-HB-4-2024', 'signed'), finding('w5', 'https://example.com/s')];
  const one = (parts: { text: string; cites: string[] }[]) => actClaimProblems({ politician_id: 'p', topic_key: 'gun-policy', sentences: [{ parts }] }, fs);

  it('refuses "co-sponsored and voted for" of a bill with a vote only, and of a later part that inherits it', () => {
    expect(one([{ text: 'He co-sponsored and voted for bills to do A', cites: ['v1', 's1', 'v2'] }, { text: 'and to do B.', cites: ['s3'] }])).toEqual([
      'sentence 1, part 1: says the person sponsored XX-HB-2-2024, but its cited findings show only a vote; cite the sponsorship finding or say only "voted"',
      'sentence 1, part 2: says the person voted on XX-HB-3-2024, but its cited findings show only a sponsorship; cite the vote finding or say only "sponsored"',
    ]);
    expect(one([{ text: 'He was an author of, and in the Senate voted for, a bill to do A.', cites: ['v2'] }])).toHaveLength(1);
  });

  it('passes it when every bill has both findings, and passes a single claim that matches', () => {
    expect(one([{ text: 'He co-sponsored and voted for a bill to do A', cites: ['v1', 's1'] }, { text: 'and co-sponsored a bill to do C.', cites: ['s3'] }])).toEqual([]);
    expect(one([{ text: 'He voted for bills to do A', cites: ['v1'] }, { text: 'and to do B.', cites: ['v2'] }])).toEqual([]);
  });

  it('refuses a single claim the findings do not show', () => {
    expect(one([{ text: 'He co-sponsored a bill to do B.', cites: ['v2'] }])).toHaveLength(1);
    expect(one([{ text: 'He voted against a bill to do C.', cites: ['s3'] }])).toHaveLength(1);
  });

  it('keeps an aside to its own part: the parts after still inherit the sentence verb', () => {
    expect(one([{ text: 'He voted for a bill to do B,', cites: ['v2'] }, { text: 'for a bill he co-sponsored to do A,', cites: ['v1', 's1'] },
      { text: 'and for a bill to do B again.', cites: ['v2'] }])).toEqual([]);
    expect(one([{ text: 'He voted for a bill to do A,', cites: ['v1'] }, { text: 'and for a bill to do B, which he co-sponsored.', cites: ['v2'] }])).toHaveLength(1);
  });

  it('leaves to the checker what code cannot decide', () => {
    // Two separate claims in one part: which bill each is about is not in the draft.
    expect(one([{ text: 'He voted for one in 2022 and co-sponsored one in 2024.', cites: ['v2', 's3'] }])).toEqual([]);
    expect(one([{ text: 'He co-sponsored and voted for A, and voted for a similar bill.', cites: ['v1', 's1', 'v2'] }])).toEqual([]);
    // After an unclear part nothing is inherited.
    expect(one([{ text: 'He voted for one and co-sponsored one', cites: ['v2', 's3'] }, { text: 'and to do C.', cites: ['s3'] }])).toEqual([]);
    // An act that is neither, a statement, and a part with no act word.
    expect(one([{ text: 'He voted for a bill to do D.', cites: ['o4'] }])).toEqual([]);
    expect(one([{ text: 'He said he voted for gun rights.', cites: ['w5'] }])).toEqual([]);
    expect(one([{ text: 'A bill to do C.', cites: ['s3'] }])).toEqual([]);
  });

  it('is part of lintSummary', () => {
    const draft: SummaryDraft = { politician_id: 'p', topic_key: 'gun-policy', sentences: [{ text: 'He co-sponsored a bill to do B.', cites: ['v2'] }] };
    expect(lintSummary(draft, { findings: fs, code: { outcome: 'doesnt-fit' } as Stage5Code, sides: '1,2,3/4,5' }).join(' ')).toContain('says the person sponsored XX-HB-2-2024');
  });
});
