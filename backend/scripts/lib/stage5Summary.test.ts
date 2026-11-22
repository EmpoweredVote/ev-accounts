import { describe, it, expect } from 'vitest';
import {
  buildSummary, lintSummary, summaryVerdict, agreementRate, SummaryDraftSchema, SummaryCheckSchema,
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
  it('is clean for a good draft', () => { expect(lintSummary(two(), ctx(fs))).toEqual([]); });
  it('refuses a cite not in the person\'s findings', () => {
    expect(lintSummary(two('A.', 'B.', ['f1'], ['zzz']), ctx(fs)).join(' ')).toMatch(/zzz/);
  });
  it('refuses a sentence with no cites', () => {
    expect(lintSummary(two('A.', 'B.', ['f1'], []), ctx(fs)).join(' ')).toMatch(/no citation/i);
  });
  it('refuses 0, 1 or 6 sentences', () => {
    const s = { text: 'A.', cites: ['f1'] };
    expect(lintSummary(draft([]), ctx(fs)).join(' ')).toMatch(/2.5 sentences/);
    expect(lintSummary(draft([s]), ctx(fs)).join(' ')).toMatch(/2.5 sentences/);
    expect(lintSummary(draft(Array(6).fill(s)), ctx(fs)).join(' ')).toMatch(/2.5 sentences/);
    expect(lintSummary(draft(Array(5).fill(s)), ctx(fs))).toEqual([]);
  });
  it('refuses the word rung and a rung number', () => {
    expect(lintSummary(two('Holds rung 3.'), ctx(fs)).join(' ')).toMatch(/rung/i);
    expect(lintSummary(two('Sits on the ladder.'), ctx(fs)).join(' ')).toMatch(/ladder/i);
  });
  it('refuses a party name', () => {
    expect(lintSummary(two('Joined the Republican caucus.'), ctx(fs)).join(' ')).toMatch(/party/i);
  });
  it('refuses "often" with 2 distinct cites and passes with 3', () => {
    expect(lintSummary(two('He often votes yes.', 'B.', ['f1', 'f2']), ctx(fs)).join(' ')).toMatch(/often/);
    expect(lintSummary(two('He often votes yes.', 'B.', ['f1', 'f2', 'f4']), ctx(fs))).toEqual([]);
  });
  it('refuses "more than once" with 1 cite', () => {
    expect(lintSummary(two('She said so more than once.', 'B.', ['f1']), ctx(fs)).join(' ')).toMatch(/more than once/);
    expect(lintSummary(two('She said so more than once.', 'B.', ['f1', 'f2']), ctx(fs))).toEqual([]);
  });
  it('accepts only this person\'s findings when 40+ are supplied', () => {
    const many = Array.from({ length: 45 }, (_, i) => finding(`g${i}`, `https://x.example/${i}`));
    const mine = [...many, f1, f2];
    expect(lintSummary(two(), ctx(mine))).toEqual([]);
    expect(lintSummary(two('A.', 'B.', ['g44'], ['g0']), ctx(many)).join(' ')).toBe('');
    expect(lintSummary(two('A.', 'B.', ['f1'], ['f2']), ctx(many)).join(' ')).toMatch(/f1/);
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
  it('fails when claude fails', () => { expect(summaryVerdict([mk('claude', 'fail'), mk('gpt', 'pass')], 'S', req)).toBe('failed'); });
});

describe('agreementRate', () => {
  it('is the share that agree', () => {
    expect(agreementRate([{ all_agree: true }, { all_agree: false }, { all_agree: true }, { all_agree: true }])).toBe(0.75);
    expect(agreementRate([])).toBe(0);
  });
});
