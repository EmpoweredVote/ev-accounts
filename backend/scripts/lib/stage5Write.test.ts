import { describe, it, expect } from 'vitest';
import { parse } from 'csv-parse/sync';
import { applyBatch, applyBlocker, assertDraftSeason, blankReasonFor, planBatch, refusePassagesNotOnPage } from './stage5Write.js';
import type { Stage5Code } from './stage5Code.js';
import { shownSha256, type QuoteCheck } from './stage5QuoteCheck.js';
import { findingId, type Finding, type PersonFindings } from './sourceStore.js';

const PID = '11111111-1111-4111-8111-111111111111';
const PID2 = '22222222-2222-4222-8222-222222222222';
const SEASON = '33333333-3333-4333-8333-333333333333';
const prov = { fetched_by: 't', fetched_at: '2026-10-22T00:00:00Z', method: 'webfetch' as const };
const mk = (f: Omit<Finding, 'id' | 'provenance' | 'topic_keys' | 'date_precision'>): Finding => {
  const base = { ...f, date_precision: 'day' as const, topic_keys: ['voting-rights'], provenance: prov };
  return { id: findingId(base), ...base } as Finding;
};
const words = mk({ kind: 'own-words', url: 'https://x.example/a', date: '2026-09-01', passage: 'Every voter should be able to vote by mail.', note: 'Backs mail voting.', subjects: ['mail voting'] });
const local = mk({ kind: 'record', url: 'https://town.example/minutes', date: '2024-02-01', act: 'yea', motion: 'Resolution 2024-3, polling places', local_record: true, note: 'Voted for a resolution adding two polling places.', subjects: ['polling places'] });
const vote = mk({ kind: 'record', url: 'https://x.example/b', date: '2011-04-12', instrument_id: 'IN-SB-483-2011', act: 'yea', motion: 'final passage', note: 'Voted yes on a photo-ID law.', subjects: ['voter ID at the polls'] });

const search = (at = '2026-10-20T12:00:00Z') => ({ topic_key: 'voting-rights', season: 3, subjects: ['voting'], places: ['https://x.example/', 'Ballotpedia'], found: 1, at, by: 't' });
const person = (pid: string, findings: Finding[]): PersonFindings => ({ politician_id: pid, findings, searches: [search()] });

const code = (over: Partial<Stage5Code>): Stage5Code => ({
  politician_id: PID, topic_key: 'voting-rights', season: 3, season_id: SEASON, revision_id: 'r',
  outcome: 'doesnt-fit', reasoning: 'Backs mail voting; no rung names it.', open_note: 'Speaks for mail voting, which no rung names.',
  blank_class: 'off-question', tags: ['related-question'], finding_ids: [words.id], evidence_basis: 'own-words',
  codebook: '0.6', coded_by: 'stage5-coder', coded_at: '2026-10-22T00:00:00Z', ...over,
} as Stage5Code);

const check = (f: Finding, over: Partial<QuoteCheck> = {}): QuoteCheck => ({
  finding_id: f.id, politician_id: PID, topic_key: 'voting-rights', verdict: 'passed', on_page: true, own_words: true,
  on_topic: true, names_party: false, shown_sha256: shownSha256(f.kind === 'own-words' ? f.passage! : f.note),
  ...(f.local_record ? { fair_summary: true } : {}),
  reason: 'On the page; their words; on topic.', checker: 'stage5-quote-checker', at: '2026-10-22T01:00:00Z', ...over,
});

const names = new Map([[PID, 'Jane Doe'], [PID2, 'John Roe']]);
const plan = (codes: Stage5Code[], people: PersonFindings[], checks: QuoteCheck[]) =>
  planBatch(codes, new Map(people.map((p) => [p.politician_id, p])), checks, { seasonId: SEASON, names });

describe('planBatch', () => {
  it('doesnt-fit with own words and a passed check → one outcome and one passage', () => {
    const r = plan([code({})], [person(PID, [words])], [check(words)]);
    expect(r.refused).toEqual([]);
    expect(r.outcomes).toEqual([{
      politician_id: PID, topic_key: 'voting-rights', season_id: SEASON, outcome: 'doesnt-fit',
      researched_on: '2026-10-20', checked_by: ['stage5-coder', 'stage5-quote-checker'],
    }]);
    expect(r.passages).toEqual([{
      politician_id: PID, topic_key: 'voting-rights', season_id: SEASON, finding_id: words.id, kind: 'own-words',
      passage: 'Every voter should be able to vote by mail.', shown_text: null, source_url: 'https://x.example/a', source_date: '2026-09-01',
      source_date_precision: 'day', quote_check: 'passed', quote_checked_at: '2026-10-22T01:00:00Z', quote_checker: 'stage5-quote-checker',
    }]);
  });

  it('a failed check keeps the outcome and refuses the passage', () => {
    const r = plan([code({})], [person(PID, [words])], [check(words, { verdict: 'failed', on_page: false, reason: 'Not on the page.' })]);
    expect(r.outcomes).toHaveLength(1);
    expect(r.passages).toEqual([]);
    expect(r.refused).toEqual([{ politician_id: PID, kind: 'passage', reason: expect.stringMatching(/quote check failed.*Not on the page/) }]);
  });

  it('no check at all refuses the passage', () => {
    const r = plan([code({})], [person(PID, [words])], []);
    expect(r.passages).toEqual([]);
    expect(r.refused[0].reason).toMatch(/no quote check/);
  });

  it('the newest check wins: a later failure overrides an earlier pass', () => {
    const r = plan([code({})], [person(PID, [words])], [
      check(words),
      check(words, { verdict: 'failed', on_topic: false, at: '2026-10-23T00:00:00Z', reason: 'Off topic.' }),
    ]);
    expect(r.passages).toEqual([]);
  });

  it('a check for another person or topic does not count', () => {
    expect(plan([code({})], [person(PID, [words])], [check(words, { politician_id: PID2 })]).passages).toEqual([]);
    expect(plan([code({})], [person(PID, [words])], [check(words, { topic_key: 'healthcare' })]).passages).toEqual([]);
  });

  describe('party labels (RULINGS.md "Party labels never reach a reader")', () => {
    const party = mk({ kind: 'own-words', url: 'https://x.example/p', date: '2026-09-02', passage: 'The Republicans want mail voting gone.', note: 'n', subjects: ['mail voting'] });
    const shown = 'The [some lawmakers] want mail voting gone.';

    it('a passage with a label and no shown text is refused, even with a passed check', () => {
      const r = plan([code({ finding_ids: [party.id] })], [person(PID, [party])], [check(party)]);
      expect(r.passages).toEqual([]);
      expect(r.refused[0].reason).toMatch(/party label would reach voters/);
    });

    it('a clean bracket edit is stored beside the exact words, and the check covers the shown text', () => {
      const r = plan([code({ finding_ids: [party.id] })], [person(PID, [party])], [check(party, { shown_text: shown, shown_sha256: shownSha256(shown) })]);
      expect(r.refused).toEqual([]);
      expect(r.passages.map((p) => [p.passage, p.shown_text])).toEqual([['The Republicans want mail voting gone.', shown]]);
    });

    it('a check hashed over the original words does not cover the shown text', () => {
      const r = plan([code({ finding_ids: [party.id] })], [person(PID, [party])], [check(party, { shown_text: shown })]);
      expect(r.passages).toEqual([]);
      expect(r.refused[0].reason).toMatch(/text changed since its quote check/);
    });

    it('a shown text that changes more than the label, or uses a word off the list, is refused', () => {
      for (const bad of ['The [some lawmakers] want voting gone.', 'The [conservatives] want mail voting gone.']) {
        const r = plan([code({ finding_ids: [party.id] })], [person(PID, [party])], [check(party, { shown_text: bad, shown_sha256: shownSha256(bad) })]);
        expect(r.passages, bad).toEqual([]);
        expect(r.refused[0].reason, bad).toMatch(/not a clean bracket edit/);
      }
    });

    it('a local record never carries a shown text', () => {
      const r = plan([code({ finding_ids: [words.id, local.id], evidence_basis: 'joint' })], [person(PID, [words, local])],
        [check(words), check(local, { shown_text: 'x [others]', shown_sha256: shownSha256('x [others]') })]);
      expect(r.passages.map((p) => p.kind)).toEqual(['own-words']);
      expect(r.refused[0].reason).toMatch(/only own words carry a bracketed shown text/);
    });
  });

  it('a local record is shown in plain words; a legislative record is not shown', () => {
    const r = plan([code({ finding_ids: [words.id, local.id, vote.id], evidence_basis: 'joint' })], [person(PID, [words, local, vote])], [check(words), check(local)]);
    expect(r.passages.map((p) => [p.kind, p.passage])).toEqual([
      ['own-words', 'Every voter should be able to vote by mail.'],
      ['local-record', 'Voted for a resolution adding two polling places.'],
    ]);
    expect(r.refused).toEqual([]);
  });

  it('a check of different text does not count: the shown text must hash to what was checked', () => {
    const r = plan([code({})], [person(PID, [words])], [check(words, { shown_sha256: shownSha256('Some other text.') })]);
    expect(r.passages).toEqual([]);
    expect(r.refused[0].reason).toMatch(/text changed since its quote check/);
  });

  it('a local record needs a fair-summary check', () => {
    const r = plan([code({ finding_ids: [words.id, local.id], evidence_basis: 'joint' })], [person(PID, [words, local])], [check(words), check(local, { fair_summary: undefined })]);
    expect(r.passages.map((p) => p.kind)).toEqual(['own-words']);
    expect(r.refused[0].reason).toMatch(/fair summary/);
  });

  it('a local record is never shown alone: with no own words left it is refused', () => {
    const r = plan([code({ finding_ids: [words.id, local.id], evidence_basis: 'joint' })], [person(PID, [words, local])], [check(local)]);
    expect(r.passages).toEqual([]);
    expect(r.refused.map((x) => x.reason)).toEqual([expect.stringMatching(/no quote check/), expect.stringMatching(/never shown alone/)]);
    expect(r.outcomes).toHaveLength(1);
  });

  it('tags a refused code apart from a refused passage', () => {
    const r = plan([code({ open_note: '' }), code({ politician_id: PID2 })], [person(PID, [words]), person(PID2, [words])], []);
    expect(r.refused.map((x) => [x.politician_id, x.kind])).toEqual([[PID, 'code'], [PID2, 'passage']]);
  });

  it('no-stance → outcome only, no passages', () => {
    const r = plan([code({ outcome: 'no-stance', finding_ids: [], evidence_basis: undefined, tags: [], blank_class: 'source-gap', open_note: undefined, reasoning: 'Searched; nothing.' })], [person(PID, [])], []);
    expect(r.outcomes.map((o) => o.outcome)).toEqual(['no-stance']);
    expect(r.passages).toEqual([]);
    expect(r.refused).toEqual([]);
  });

  it('a seated code → outcome only (the seat goes through research.csv)', () => {
    const r = plan([code({ outcome: 'seated', value: 4, tags: [], blank_class: undefined, open_note: undefined, finding_ids: [vote.id], evidence_basis: 'record' })], [person(PID, [vote])], []);
    expect(r.outcomes.map((o) => o.outcome)).toEqual(['seated']);
    expect(r.passages).toEqual([]);
  });

  it('refuses a code that fails its check, a code for another season, and a person with no findings file', () => {
    const r = plan([
      code({ open_note: '' }),
      code({ politician_id: PID2, season_id: '44444444-4444-4444-8444-444444444444' }),
    ], [person(PID, [words])], [check(words)]);
    expect(r.outcomes).toEqual([]);
    expect(r.refused.map((x) => x.politician_id)).toEqual([PID, PID2]);
    expect(r.refused[0].reason).toMatch(/open note/);
    expect(r.refused[1].reason).toMatch(/season/);
    const missing = plan([code({ politician_id: PID2 })], [person(PID, [words])], []);
    expect(missing.refused[0].reason).toMatch(/no findings file/);
  });

  it('refuses a second code for the same person and topic', () => {
    const r = plan([code({}), code({})], [person(PID, [words])], [check(words)]);
    expect(r.outcomes).toHaveLength(1);
    expect(r.refused[0].reason).toMatch(/more than one code/);
  });

  it('writes research.csv rows: a seat with its value, blanks as value 0 with a V6 reason', () => {
    const r = plan([
      code({ outcome: 'seated', value: 4, tags: [], blank_class: undefined, open_note: undefined, finding_ids: [vote.id], evidence_basis: 'record', reasoning: 'Voted yes on IN SB 483 (2011), a photo-ID law.' }),
      code({ politician_id: PID2, tags: ['direction-only'], blank_class: 'wording' }),
    ], [person(PID, [vote]), person(PID2, [words])], []);
    const rows = parse(r.researchCsv, { columns: true }) as Record<string, string>[];
    expect(rows).toEqual([
      { full_name: 'Jane Doe', topic_key: 'voting-rights', value: '4', reasoning: 'Voted yes on IN SB 483 (2011), a photo-ID law.', evidence_type: 'record', blank_reason: '', source_url_1: 'https://x.example/b', source_url_2: '' },
      { full_name: 'John Roe', topic_key: 'voting-rights', value: '0', reasoning: 'Backs mail voting; no rung names it.', evidence_type: 'blank', blank_reason: 'direction-only', source_url_1: 'https://x.example/a', source_url_2: 'https://x.example/' },
    ]);
    expect(r.notInCsv).toEqual([]);
  });

  it('an own-words seat is statement evidence, so it keeps the human hold', () => {
    const r = plan([code({ outcome: 'seated', value: 2, tags: [], blank_class: undefined, open_note: undefined, finding_ids: [words.id], evidence_basis: 'own-words' })], [person(PID, [words])], []);
    expect((parse(r.researchCsv, { columns: true }) as Record<string, string>[])[0].evidence_type).toBe('statement');
  });

  it('a blank with no V6 reason that fits is left out of research.csv and listed', () => {
    // A wording blank coded without shows_side: no single reason fits (an off-question blank now maps).
    const r = plan([code({ tags: ['unnamed-position'], blank_class: 'wording' })], [person(PID, [words])], [check(words)]);
    expect(r.outcomes).toHaveLength(1);
    expect(parse(r.researchCsv, { columns: true })).toEqual([]);
    expect(r.notInCsv).toEqual([{ politician_id: PID, reason: expect.stringMatching(/wording/) }]);
  });
});

describe('blankReasonFor', () => {
  it('maps the Stage 5 detail to codebook V6 where one reason fits', () => {
    expect(blankReasonFor(code({ outcome: 'no-stance', tags: [], blank_class: undefined }))).toBe('no-evidence');
    expect(blankReasonFor(code({ tags: ['direction-only'], blank_class: 'wording' }))).toBe('direction-only');
    expect(blankReasonFor(code({ tags: [], blank_class: 'nay-only' }))).toBe('direction-only');
    expect(blankReasonFor(code({ tags: [], blank_class: 'no-lever' }))).toBe('scope-unavailable');
    expect(blankReasonFor(code({ tags: ['between-rungs'], blank_class: 'wording' }))).toBe('adjacent-chairs');
  });
  it('maps gated and off-question blanks to no-evidence (runner ruling 2026-10-29)', () => {
    expect(blankReasonFor(code({ tags: [], blank_class: 'gate' }))).toBe('no-evidence');
    expect(blankReasonFor(code({ tags: [], blank_class: 'off-question' }))).toBe('no-evidence');
    expect(blankReasonFor(code({ tags: ['related-question'], blank_class: 'off-question' }))).toBe('no-evidence');
  });
  it('maps a blank by shows_side: a side is direction-only, no side is no-evidence', () => {
    expect(blankReasonFor(code({ tags: ['unnamed-position'], blank_class: 'wording', shows_side: true }))).toBe('direction-only');
    expect(blankReasonFor(code({ tags: ['related-question'], blank_class: 'off-question', shows_side: true }))).toBe('direction-only');
    expect(blankReasonFor(code({ tags: ['unnamed-position'], blank_class: 'wording', shows_side: false }))).toBe('no-evidence');
    // A gated record shows no side whatever the field says (the ruling names gated blanks).
    expect(blankReasonFor(code({ tags: [], blank_class: 'gate', shows_side: true }))).toBe('no-evidence');
  });
  it('still leaves a wording blank without shows_side to a hand row (codes written before the field)', () => {
    expect(blankReasonFor(code({ tags: ['unnamed-position'], blank_class: 'wording' }))).toBeNull();
  });
});

describe('assertDraftSeason', () => {
  it('passes a draft season and refuses an open one', () => {
    expect(() => assertDraftSeason({ id: SEASON, number: 3, name: 'Season 3', status: 'draft' })).not.toThrow();
    expect(() => assertDraftSeason({ id: SEASON, number: 2, name: 'Season 2', status: 'open' })).toThrow(/draft/);
  });
});

describe('applyBatch', () => {
  const TOPIC = '55555555-5555-4555-8555-555555555555';
  const fake = (topicRows: { id: string; asked: boolean }[] = [{ id: TOPIC, asked: true }]) => {
    const calls: { sql: string; params: unknown[] }[] = [];
    const q = async (sql: string, params: unknown[] = []) => {
      calls.push({ sql, params });
      if (/FROM inform\.seasons/.test(sql)) return { rows: [{ status: 'draft' }] };
      if (/FROM inform\.compass_topics/.test(sql)) return { rows: topicRows.map((t) => ({ id: t.id, topic_key: 'voting-rights', asked: t.asked })) };
      return { rows: [] };
    };
    return { q, calls };
  };
  const p = () => plan([code({})], [person(PID, [words])], [check(words)]);

  it('writes outcomes, then replaces passages, in one transaction', async () => {
    const { q, calls } = fake();
    const n = await applyBatch(q, p(), SEASON);
    expect(n).toEqual({ outcomes: 1, passages: 1 });
    const sqls = calls.map((c) => c.sql.trim().split(/\s+/).slice(0, 3).join(' '));
    expect(sqls[0]).toBe('BEGIN');
    expect(sqls.at(-1)).toBe('COMMIT');
    const outcomeAt = calls.findIndex((c) => /INSERT INTO inform\.topic_research_outcomes/.test(c.sql));
    const deleteAt = calls.findIndex((c) => /DELETE FROM inform\.own_words_passages/.test(c.sql));
    const passageAt = calls.findIndex((c) => /INSERT INTO inform\.own_words_passages/.test(c.sql));
    expect(outcomeAt).toBeGreaterThan(0);
    expect(deleteAt).toBeGreaterThan(outcomeAt);
    expect(passageAt).toBeGreaterThan(deleteAt);
    expect(calls[outcomeAt].params).toEqual([PID, TOPIC, SEASON, 'doesnt-fit', '2026-10-20', ['stage5-coder', 'stage5-quote-checker']]);
  });

  it('names shown_text only for a row that carries one (writes as before CA_0337 otherwise)', async () => {
    const party = mk({ kind: 'own-words', url: 'https://x.example/p', date: '2026-09-02', passage: 'The GOP wants mail voting gone.', note: 'n', subjects: ['mail voting'] });
    const shown = 'The [others] wants mail voting gone.';
    const { q, calls } = fake();
    await applyBatch(q, plan([code({ finding_ids: [words.id, party.id] })], [person(PID, [words, party])],
      [check(words), check(party, { shown_text: shown, shown_sha256: shownSha256(shown) })]), SEASON);
    const inserts = calls.filter((c) => /INSERT INTO inform\.own_words_passages/.test(c.sql));
    expect(inserts.map((c) => /shown_text/.test(c.sql))).toEqual([false, true]);
    expect(inserts[0].params).toHaveLength(12);
    expect(inserts[1].params.at(-1)).toBe(shown);
  });

  it('refuses a topic the draft season does not ask, and rolls back', async () => {
    const { q, calls } = fake([{ id: TOPIC, asked: false }]);
    await expect(applyBatch(q, p(), SEASON)).rejects.toThrow(/does not ask voting-rights/);
    expect(calls.at(-1)!.sql).toBe('ROLLBACK');
    expect(calls.some((c) => /INSERT/.test(c.sql))).toBe(false);
  });

  it('refuses a plan for another season', async () => {
    const { q } = fake();
    await expect(applyBatch(q, p(), '44444444-4444-4444-8444-444444444444')).rejects.toThrow(/season/);
  });
});

describe('applyBlocker', () => {
  it('blocks --apply while any code is refused, so an earlier write is never left stale', () => {
    const r = plan([code({ open_note: '' })], [person(PID, [words])], []);
    expect(applyBlocker(r)).toMatch(/1 code.*refused/);
  });
  it('lets passage refusals through: those passages stay off the page', () => {
    expect(applyBlocker(plan([code({})], [person(PID, [words])], []))).toBeNull();
  });
});

describe('stale and mixed-zone checks', () => {
  it('ignores a check older than the code: a check from an earlier run never carries over', () => {
    const r = plan([code({ coded_at: '2026-10-23T00:00:00Z' })], [person(PID, [words])], [check(words, { at: '2026-10-22T01:00:00Z' })]);
    expect(r.passages).toEqual([]);
    expect(r.refused[0].reason).toMatch(/no quote check since this code/);
  });
  it('picks the newest check by time, across time zones', () => {
    // 01:00-05:00 is 06:00Z, later than 05:00Z, though it sorts first as text.
    const r = plan([code({})], [person(PID, [words])], [
      check(words, { at: '2026-10-22T01:00:00-05:00' }),
      check(words, { verdict: 'failed', on_page: false, at: '2026-10-22T05:00:00Z', reason: 'Not on the page.' }),
    ]);
    expect(r.passages).toHaveLength(1);
  });
});

describe('applyBatch season guard', () => {
  it('re-checks inside the write that the season is still the draft one', async () => {
    const calls: string[] = [];
    const q = async (sql: string) => {
      calls.push(sql);
      if (/FROM inform\.seasons/.test(sql)) return { rows: [{ status: 'open' }] };
      return { rows: [] };
    };
    await expect(applyBatch(q, plan([code({})], [person(PID, [words])], [check(words)]), SEASON)).rejects.toThrow(/no longer a draft/);
    expect(calls.some((s) => /FOR SHARE/.test(s))).toBe(true);
    expect(calls.some((s) => /INSERT/.test(s))).toBe(false);
    expect(calls.at(-1)).toBe('ROLLBACK');
  });
});

describe('refusePassagesNotOnPage', () => {
  const r0 = () => plan([code({})], [person(PID, [words])], [check(words)]);
  it('keeps a passage found on the fetched page', async () => {
    const out = await refusePassagesNotOnPage(r0(), async () => '<p>He said: “Every voter should be able to vote by mail.”</p>');
    expect(out.passages).toHaveLength(1);
    expect(out.unchecked).toEqual([]);
  });
  it('refuses an own-words passage the page does not hold, whatever the agent said', async () => {
    const out = await refusePassagesNotOnPage(r0(), async () => '<p>Every voter should vote by mail.</p>');
    expect(out.passages).toEqual([]);
    expect(out.refused.at(-1)).toEqual({ politician_id: PID, kind: 'passage', reason: expect.stringMatching(/not on the page/) });
  });
  it('keeps a passage whose page cannot be fetched, and lists it', async () => {
    const out = await refusePassagesNotOnPage(r0(), async () => { throw new Error('403'); });
    expect(out.passages).toHaveLength(1);
    expect(out.unchecked).toEqual([{ politician_id: PID, reason: expect.stringMatching(/could not re-fetch.*403/) }]);
  });
  it('drops a local record whose only own words were refused', async () => {
    const both = plan([code({ finding_ids: [words.id, local.id], evidence_basis: 'joint' })], [person(PID, [words, local])], [check(words), check(local)]);
    const out = await refusePassagesNotOnPage(both, async (u) => (u.includes('minutes') ? 'x' : 'nothing here'));
    expect(out.passages).toEqual([]);
  });
});
