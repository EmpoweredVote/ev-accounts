import { describe, expect, it } from 'vitest';
import { NEEDS_STANDING_CHECK, SCRIPT_CODER, checkCode, type Stage5Code } from './stage5Code.js';
import type { CoderFinding } from './stage5CoderInputs.js';
import { billName, decideRecord, namedInRulings, rulingsNameText, seededSample, sponsorGate, standingCheckDifferences, unitSections, wordsFor, type RuleBill, type RuleBillRow, type RuleInput } from './stage5RecordRule.js';
import type { PersonFindings } from './sourceStore.js';

let n = 0;
const vote = (bill: string, act: string, date: string, gate = 'none'): CoderFinding => ({
  id: `v${++n}`, kind: 'record', url: 'u', date, date_precision: 'day', instrument_id: bill, act: act as CoderFinding['act'], motion: 'Third Reading', gate,
  note: `XX House, Third Reading, ${date}: ${act} (tally 60–30); census gate: ${gate}.`,
});
const sponsor = (bill: string): CoderFinding => ({ id: `s${++n}`, kind: 'record', url: 'u', date: '2025', date_precision: 'year', instrument_id: bill, act: 'sponsor', note: `prime sponsor of ${bill} (list): t.` });
const table: Record<string, RuleBillRow> = {
  'XX-HB-2-2025': { rung: 2, deciding_words: 'shall not sell any assault weapon', why: 'Bans a type of firearm (rung 2).' },
  'XX-HB-3-2025': { rung: 3, deciding_words: 'a background check on every buyer', why: 'Checks every buyer.' },
  'XX-HB-33-2023': { rung: 3, deciding_words: 'a waiting period of ten days' },
  'XX-HB-4-2025': { rung: 4, deciding_words: 'may carry on public transit' },
  'XX-HB-44-2021': { rung: 4, deciding_words: 'may carry on public transit' },
  'XX-HB-5-2025': { rung: 5, deciding_words: 'no permit is required' },
  'XX-HB-9-2025': { rung: null, why: 'A dealer rule.' },
  'XX-HB-7-2025': { rung: null, why: 'As finally voted, a storage rule.', per_vote: { rungs: [3, null] } },
  'XX-HB-8-2025': { rung: 3, deciding_words: 'x', flag: 'Rung 3 or direction only?' },
  'US-HR-8-2021': { rung: 3, deciding_words: 'x' },
};
const bills: Record<string, RuleBill> = Object.fromEntries(Object.keys(table).map((k) => [k, { inStore: true, multi: false, tallies: [{ yes: 60, no: 30 }] }]));
const input = (findings: CoderFinding[], over: Partial<RuleInput> = {}): RuleInput => ({
  findings, plainIds: new Set(findings.map((f) => f.id)), table, bill: (id) => bills[id], sides: [[1, 2, 3], [4, 5]], billPrefix: 'XX-',
  office: 'State Representative', named: false, ...over,
});

describe('decideRecord: what the script may decide', () => {
  it('seats at the furthest rung on one side', () => {
    const r = decideRecord(input([vote('XX-HB-3-2025', 'yea', '2025-03-01'), vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-4-2025', 'nay', '2025-05-01')]));
    expect(r.lanes).toEqual([]);
    expect(r.decision).toMatchObject({ outcome: 'seated', value: 2 });
    const hi = decideRecord(input([vote('XX-HB-4-2025', 'yea', '2025-03-01'), sponsor('XX-HB-5-2025')]));
    expect(hi.decision).toMatchObject({ outcome: 'seated', value: 5 });
  });
  it('does not count a gated vote, a No, an abstention or a Yes on a no-rung bill', () => {
    const r = decideRecord(input([vote('XX-HB-2-2025', 'yea', '2025-04-01', 'near-unanimous'), vote('XX-HB-9-2025', 'yea', '2025-04-02'), vote('XX-HB-5-2025', 'abstain', '2025-04-03'), vote('XX-HB-3-2025', 'yea', '2025-03-01')]));
    expect(r.decision).toMatchObject({ outcome: 'seated', value: 3, gatedYes: 1 });
  });
  it('writes a No-votes-only blank when every counted No is on one side and nothing else counts', () => {
    const r = decideRecord(input([vote('XX-HB-4-2025', 'nay', '2025-05-01'), vote('XX-HB-5-2025', 'nay', '2025-05-02'), vote('XX-HB-2-2025', 'yea', '2025-04-01', 'multi-subject')]));
    expect(r.lanes).toEqual([]);
    expect(r.decision).toMatchObject({ outcome: 'doesnt-fit', naySide: 1 });
  });
});

describe('decideRecord: what it hands to Opus', () => {
  const lanes = (fs: CoderFinding[], over: Partial<RuleInput> = {}) => decideRecord(input(fs, over));
  it('Yes acts on both sides (the licence rule is a judgment)', () => {
    const r = lanes([sponsor('XX-HB-3-2025'), vote('XX-HB-4-2025', 'yea', '2021-05-01')]);
    expect(r.lanes).toEqual(['both-sides']);
    expect(r.decision).toBeUndefined();
  });
  it('a later No on a bill at the seat rung, but not an earlier one or one answered by a newer Yes', () => {
    expect(lanes([vote('XX-HB-44-2021', 'yea', '2021-05-01'), vote('XX-HB-4-2025', 'nay', '2025-05-01')]).lanes).toEqual(['later-no']);
    expect(lanes([vote('XX-HB-44-2021', 'nay', '2021-05-01'), vote('XX-HB-4-2025', 'yea', '2025-05-01')]).lanes).toEqual([]);
    expect(lanes([vote('XX-HB-3-2025', 'yea', '2025-03-01'), vote('XX-HB-4-2025', 'nay', '2025-05-01')]).lanes).toEqual([]);
  });
  it('no usable rung act but a sponsorship on file', () => {
    expect(lanes([sponsor('XX-HB-9-2025'), vote('XX-HB-4-2025', 'nay', '2025-05-01')]).lanes).toEqual(['sponsor-no-rung']);
  });
  it('a person the rulings name, a seat outside the legislature, a bill of another legislature', () => {
    const fs = [vote('XX-HB-2-2025', 'yea', '2025-04-01')];
    expect(lanes(fs, { named: true }).lanes).toEqual(['named-in-rulings']);
    expect(lanes(fs, { office: 'State Auditor' }).lanes).toEqual(['other-office']);
    expect(lanes(fs, { office: '' }).lanes).toEqual(['other-office']);
    expect(lanes([...fs, vote('US-HR-8-2021', 'yea', '2021-03-11')]).lanes).toEqual(['other-jurisdiction']);
  });
  it('a bill missing from the table or the store, and a bill with an open flag', () => {
    expect(lanes([vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-99-2025', 'nay', '2025-04-02')]).lanes).toEqual(['missing-bill']);
    expect(lanes([vote('XX-HB-2-2025', 'yea', '2025-04-01')], { bill: () => undefined }).lanes).toContain('missing-bill');
    expect(lanes([vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-8-2025', 'abstain', '2025-04-02')]).lanes).toEqual(['flagged-bill']);
  });
  it('a record whose note says more than the plain facts, or an act it does not read', () => {
    const fs = [vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-3-2025', 'yea', '2025-03-01')];
    expect(lanes(fs, { plainIds: new Set([fs[0].id]) }).lanes).toEqual(['note-says-more']);
    expect(lanes([fs[0], { ...vote('XX-HB-3-2025', 'yea', '2025-03-02'), act: 'other' as CoderFinding['act'] }]).lanes).toEqual(['note-says-more']);
  });
  it('a per-vote note only when one of its rungs would change the result', () => {
    // rung 3 or none beside a type ban: the seat is 2 either way, so the script decides
    expect(lanes([vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-7-2025', 'yea', '2025-03-01')]).lanes).toEqual([]);
    // alone, the same vote decides between a seat at 3 and a blank: Opus
    expect(lanes([vote('XX-HB-7-2025', 'yea', '2025-03-01'), vote('XX-HB-4-2025', 'nay', '2025-05-01')]).lanes).toEqual(['per-vote-note']);
    // beside a carry easing it could make the record two-sided: Opus
    expect(lanes([vote('XX-HB-4-2025', 'yea', '2025-04-01'), vote('XX-HB-7-2025', 'yea', '2025-03-01')]).lanes).toEqual(['per-vote-note']);
  });
  it('any blank that is not plain No votes on one side', () => {
    expect(lanes([vote('XX-HB-2-2025', 'yea', '2025-04-01', 'near-unanimous')]).lanes).toEqual(['blank-not-plain']);
    expect(lanes([vote('XX-HB-3-2025', 'nay', '2025-04-01'), vote('XX-HB-4-2025', 'nay', '2025-04-02')]).lanes).toEqual(['blank-not-plain']);
    expect(lanes([vote('XX-HB-9-2025', 'nay', '2025-04-01')]).lanes).toEqual(['blank-not-plain']);
  });
});

describe('sponsorGate', () => {
  it('gates a sponsorship only when every floor vote is near-unanimous, or the bill is multi-subject', () => {
    expect(sponsorGate({ inStore: true, multi: false, tallies: [{ yes: 99, no: 0 }, { yes: 39, no: 0 }] })).toBe('near-unanimous');
    expect(sponsorGate({ inStore: true, multi: false, tallies: [{ yes: 99, no: 0 }, { yes: 29, no: 10 }] })).toBe('none');
    expect(sponsorGate({ inStore: true, multi: false, tallies: [] })).toBe('none');
    expect(sponsorGate({ inStore: true, multi: true, tallies: [] })).toBe('multi-subject');
  });
  it('keeps a gated sponsorship from making a record two-sided', () => {
    const gated = { ...bills, 'XX-HB-4-2025': { inStore: true, multi: false, tallies: [{ yes: 38, no: 0 }] } };
    const r = decideRecord(input([vote('XX-HB-2-2025', 'yea', '2025-04-01'), sponsor('XX-HB-4-2025')], { bill: (id) => gated[id] }));
    expect(r.decision).toMatchObject({ outcome: 'seated', value: 2, gatedYes: 1 });
  });
});

describe('wordsFor', () => {
  const rungText = (r: number) => ({ 2: 'Ban a type of firearm or magazine.', 3: 'Add limits on buying a gun.', 4: 'Make carrying a gun easier.', 5: 'Repeal permit laws.' } as Record<number, string>)[r];
  it('quotes the deciding words, names bills as voters would, and cites the deciding act', () => {
    const fs = [vote('XX-HB-2-2025', 'yea', '2025-04-01'), vote('XX-HB-3-2025', 'yea', '2025-03-01')];
    const w = wordsFor(decideRecord(input(fs)).decision!, table, rungText)!;
    expect(w.reasoning).toContain('Voted Yes on HB 2 (2025) on 2025-04-01 (60–30). The bill says "shall not sell any assault weapon".');
    expect(w.reasoning).toContain('"Ban a type of firearm or magazine"');
    expect(w.reasoning).toContain('HB 3 (2025)');
    expect(w.reasoning).not.toMatch(/XX-HB/);
    expect(w.finding_ids).toEqual([fs[0].id]);
    expect(wordsFor(decideRecord(input(fs)).decision!, table, rungText, false)!.reasoning).not.toContain('Bans a type of firearm (rung 2).');
  });
  it('writes the blank from the rung text, with the class and side a coder gives', () => {
    const w = wordsFor(decideRecord(input([vote('XX-HB-4-2025', 'nay', '2025-05-01')])).decision!, table, rungText)!;
    expect(w).toMatchObject({ blank_class: 'nay-only', tags: ['direction-only'], shows_side: true });
    expect(w.open_note).toContain('Voted No on HB 4 (2025)');
  });
  it('gives nothing when the deciding bill cannot be named or has no deciding words', () => {
    const odd = { ...table, 'XX-HB-16-SP1-2020': { rung: 5, deciding_words: 'x y' }, 'XX-HB-33-2023': { rung: 3 } };
    const b = (id: string) => bills[id] ?? { inStore: true, multi: false, tallies: [] };
    expect(wordsFor(decideRecord(input([vote('XX-HB-16-SP1-2020', 'yea', '2020-09-01')], { table: odd, bill: b })).decision!, odd, rungText)).toBeUndefined();
    expect(wordsFor(decideRecord(input([vote('XX-HB-33-2023', 'yea', '2023-09-01')], { table: odd, bill: b })).decision!, odd, rungText)).toBeUndefined();
    expect(billName('XX-HB-16-SP1-2020')).toBeUndefined();
  });
});

describe('the standing check', () => {
  const s = (o: string, v?: number) => ({ outcome: o, value: v });
  const scripts: Record<string, ReturnType<typeof s>> = { a: s('seated', 5), b: s('seated', 2), c: s('doesnt-fit') };
  it('passes only when every check person has a blind Opus code with the same outcome and rung', () => {
    const opus: Record<string, { outcome: string; value?: number; coded_by?: string }> = { a: s('seated', 5), b: s('seated', 2), c: s('doesnt-fit') };
    expect(standingCheckDifferences(['a', 'b', 'c'], (p) => scripts[p], (p) => opus[p])).toEqual([]);
    expect(standingCheckDifferences(['a', 'b'], (p) => scripts[p], (p) => ({ ...opus, b: s('seated', 3) })[p])).toEqual(['b: script seated 2 | Opus seated 3']);
    expect(standingCheckDifferences(['c'], (p) => scripts[p], () => s('seated', 3))).toHaveLength(1);
    expect(standingCheckDifferences(['a'], (p) => scripts[p], () => undefined)).toEqual(['a: no Opus code yet']);
    expect(standingCheckDifferences(['a'], (p) => scripts[p], () => ({ ...s('seated', 5), coded_by: SCRIPT_CODER }))[0]).toContain('not a blind Opus code');
  });
  it('draws the same sample for the same seed, half from the preferred seats', () => {
    const ids = Array.from({ length: 40 }, (_, i) => `p${i}`);
    const prefer = new Set(ids.slice(0, 20));
    const a = seededSample(ids, 10, 'xx-rec', prefer);
    expect(a).toEqual(seededSample([...ids].reverse(), 10, 'xx-rec', prefer));
    expect(a).toHaveLength(10);
    expect(a.filter((p) => prefer.has(p)).length).toBeGreaterThanOrEqual(5);
    expect(seededSample(ids, 10, 'other', prefer)).not.toEqual(a);
    expect(seededSample(ids.slice(0, 3), 10, 'x')).toHaveLength(3);
  });
  it('checkCode refuses a script-made code until it carries the check, and never a coder\'s', () => {
    const pid = '11111111-1111-4111-8111-111111111111';
    const pf: PersonFindings = { politician_id: pid, searches: [], findings: [{ id: 'f'.repeat(64), kind: 'record', url: 'u', date: '2025-04-01', date_precision: 'day', instrument_id: 'XX-HB-2-2025', act: 'yea', note: 'n', subjects: [], topic_keys: ['t'], provenance: { fetched_by: 'x', fetched_at: '2026-11-01T00:00:00Z', method: 'api' } }] } as PersonFindings;
    const code = { politician_id: pid, topic_key: 't', season: 3, season_id: 's', revision_id: 'r', outcome: 'seated', value: 2, reasoning: 'x', tags: [], finding_ids: ['f'.repeat(64)], evidence_basis: 'record', codebook: '0.6', coded_by: SCRIPT_CODER, coded_at: 'now' } as Stage5Code;
    expect(checkCode(code, pf)).toEqual([NEEDS_STANDING_CHECK]);
    expect(checkCode({ ...code, script_check: 'standing check passed 2026-11-13: 10 of 10' }, pf)).toEqual([]);
    expect(checkCode({ ...code, coded_by: 'stage5-coder' }, pf)).toEqual([]);
  });
});

describe('rulings helpers', () => {
  const md = '## Standing {all}\n- Ann Able is an example.\n## California notes {state:ca}\n- Both-sides: James C. Ramos voted Yes.\n## Missouri notes {state:mo}\n- Young people.\n## Two {state:in, ca}\n- Valencia.\n';
  it('reads only the unit\'s own sections', () => {
    const ca = unitSections(md, 'state:ca');
    expect(ca).toContain('Ramos');
    expect(ca).toContain('Valencia');
    expect(ca).not.toContain('Ann Able');
    expect(ca).not.toContain('Young people');
  });
  it('finds a person by full name or whole surname', () => {
    const ca = unitSections(md, 'state:ca');
    expect(namedInRulings('James C. Ramos', ca)).toBe(true);
    expect(namedInRulings('Avelino Valencia', ca)).toBe(true);
    expect(namedInRulings('Ana Ram', ca)).toBe(false);
    expect(namedInRulings('Bob Both', ca)).toBe(false);
  });
  it('drops a bill ruling\'s People list once the bill table carries the ruling, and nothing else', () => {
    const t: Record<string, RuleBillRow> = { 'XX-HB-2-2025': { rung: 2 }, 'XX-HB-3-2025': { rung: 3 }, 'XX-HB-9-2025': { rung: 4, flag: 'ask the runner' } };
    const text = (line: string) => rulingsNameText(line, t, 'XX-');
    // every bill named is in the table and answered: the list goes
    const settled = '- Q1: XX-HB-2-2025 and XX-HB-3-2025 are rung 3. People: Ann Able, Bob Both.';
    expect(namedInRulings('Ann Able', text(settled))).toBe(false);
    expect(text(settled)).toContain('XX-HB-2-2025');
    // a person named in the ruling itself stays named
    const about = '- Two-sided: Ann Able (XX-HB-2-2025) keeps a rung 2 sponsorship. People: Bob Both.';
    expect(namedInRulings('Ann Able', text(about))).toBe(true);
    expect(namedInRulings('Bob Both', text(about))).toBe(false);
    // a bill the table lacks, a bill still flagged, and a list with no bill before it: the list stays
    expect(namedInRulings('Ann Able', text('- Q2: XX-HB-2-2025 and XX-HB-77-2025 are rung 3. People: Ann Able.'))).toBe(true);
    expect(namedInRulings('Ann Able', text('- Q3: XX-HB-9-2025 is rung 4. People: Ann Able.'))).toBe(true);
    expect(namedInRulings('Ann Able', text('- Q4: read these records with care. People: Ann Able.'))).toBe(true);
    // another state's bill, cited as the precedent, is not this table's to hold
    expect(namedInRulings('Ann Able', text('- Q5: XX-HB-3-2025 is rung 3, as YY-HB-8-2024. People: Ann Able.'))).toBe(false);
    expect(namedInRulings('Ann Able', text('- Q6: as YY-HB-8-2024, such bills are rung 3. People: Ann Able.'))).toBe(true);
    // each line is judged on its own
    expect(namedInRulings('Ann Able', text(`${settled}\n- Q4: read these records with care. People: Ann Able.`))).toBe(true);
  });
});
