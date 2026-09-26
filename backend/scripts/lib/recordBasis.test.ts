import { describe, it, expect } from 'vitest';
import { parseTally, isNearUnanimous, instrumentKey, checkRecordGroup } from './recordBasis.js';
import type { Passage } from './coderLabel.js';

// CA leginfo votes page for SB 1174 (Senate floor block) and the bill text — shadow-durazo batch.
const VOTES = 'Bill Votes - SB-1174 Elections: voter identification. (2023-2024) California Legislative Information || Date 05/21/24 Result (PASS) Location Senate Floor Ayes Count 30 Noes Count 8 NVR Count 2 Motion Senate 3rd Reading SB1174 Min et al. Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer Noes Dahle, Grove, Jones NVR Allen, Alvarado-Gil';
const BILL = 'SB-1174 Elections: voter identification. (2023-2024) A local government shall not enact or enforce any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting or submitting a ballot at any polling place, vote center, or other location where ballots are cast or submitted, unless required by state or federal law.';
// IN Senate roll call 334 (HB 1041) — shadow-yoder batch.
const RC334 = 'Roll Call 334: Bill Passed HB 1041 - Donato - 3rd Reading Yea 42 Student eligibility in interscholastic sports. Nay 6 Excused 2 Not Voting 0 Y EA - 42 Alting Walker G Walker K Young N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder';
const text = new Map([['v', VOTES], ['b', BILL], ['r', RC334]]);

const P = (over: Partial<Passage>): Passage => ({ snapshot_id: 'v', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2024-05-21', instrument: 'SB 1174 (2023-2024)', provision_quote: null,
  record_kind: 'vote', actor_quote: 'Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo', tally_quote: 'Ayes Count 30 Noes Count 8', ...over });
const billPage = P({ snapshot_id: 'b', record_kind: 'vote', actor_quote: null, tally_quote: null,
  provision_quote: 'A local government shall not enact or enforce any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting' });

describe('parseTally', () => {
  it.each([
    ['Ayes Count 30 Noes Count 8', { ayes: 30, noes: 8 }],
    ['Yea 42 Student eligibility in interscholastic sports. Nay 6', { ayes: 42, noes: 6 }],
    ['Yeas: 96 Nays: 41', { ayes: 96, noes: 41 }],
  ])('%s', (q, t) => expect(parseTally(q)).toEqual(t));
  it('returns null when a count is missing (fail closed)', () => expect(parseTally('Bill Passed')).toBeNull());
  it('does not read "Not Voting" as No', () => expect(parseTally('Yea 42 Not Voting 0')).toBeNull());
  it('prefers the plural/labelled form over a stray "No <n>" (fix round 1)', () =>
    expect(parseTally('Amendment No 12 Ayes 40 Noes 2')).toEqual({ ayes: 40, noes: 2 }));
  it('fails closed when the No side is ambiguous between a "No:" label and a real "Nay" (fix round 1)', () =>
    expect(parseTally('Roll Call No: 334 Yea 46 Nay 5')).toBeNull());
});

describe('isNearUnanimous', () => {
  it('40-0 is near-unanimous', () => expect(isNearUnanimous({ ayes: 40, noes: 0 })).toBe(true));
  it('30-8 is divided', () => expect(isNearUnanimous({ ayes: 30, noes: 8 })).toBe(false));
  it('42-6 is divided (12.5% No)', () => expect(isNearUnanimous({ ayes: 42, noes: 6 })).toBe(false));
  it('46-5 is near-unanimous (9.8% No)', () => expect(isNearUnanimous({ ayes: 46, noes: 5 })).toBe(true));
});

describe('instrumentKey', () => {
  it('normalises spacing, case and punctuation', () => {
    expect(instrumentKey('SB 1174 (2023-2024)')).toBe(instrumentKey('sb1174 (2023-2024)'));
    expect(instrumentKey('H.B. 11 (2022)')).toBe('hb11(2022)');
  });
  it('null for an empty instrument', () => expect(instrumentKey(null)).toBeNull());
  it('treats a hyphen between the bill prefix and its number as nothing (fix round 1)', () =>
    expect(instrumentKey('SB-1174')).toBe(instrumentKey('SB 1174')));
  it('keeps a hyphen between two digits (a session range)', () =>
    expect(instrumentKey('SB 1 (2023-2024)')).not.toBe(instrumentKey('SB 1 (2025-2026)')));
});

describe('checkRecordGroup (D1: one basis across pages)', () => {
  it('passes a vote page + bill text pair on one instrument', () => {
    const r = checkRecordGroup({ passages: [P({}), billPage], snapshotText: text, fullName: 'Maria Elena Durazo' });
    expect(r.findings).toEqual([]);
    expect(r.actorPassages.map((p) => p.snapshot_id)).toEqual(['v']);
  });
  it('a claimed vote with only the bill text is not a vote (dead-bill case)', () =>
    expect(checkRecordGroup({ passages: [billPage], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toEqual(expect.arrayContaining(['vote-not-evidenced', 'person-not-in-snapshot'])));
  it('requires the provision somewhere in the group', () =>
    expect(checkRecordGroup({ passages: [P({})], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings).toEqual(['provision-missing']));
  it('flags pages about different instruments', () =>
    expect(checkRecordGroup({ passages: [P({}), { ...billPage, instrument: 'SB 57 (2025-2026)' }], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toContain('instrument-mismatch'));
  it('flags an actor_quote that does not name the person', () =>
    expect(checkRecordGroup({ passages: [P({ actor_quote: 'Noes Dahle, Grove, Jones' }), billPage], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toContain('person-not-in-snapshot'));
  it('flags a near-unanimous vote', () => {
    const t40 = new Map([...text, ['u', 'SB 1174 (2023-2024) Ayes Count 40 Noes Count 0 Ayes Allen, Durazo, Wiener']]);
    const u = P({ snapshot_id: 'u', actor_quote: 'Ayes Allen, Durazo, Wiener', tally_quote: 'Ayes Count 40 Noes Count 0' });
    expect(checkRecordGroup({ passages: [u, billPage], snapshotText: t40, fullName: 'Maria Elena Durazo' }).findings).toEqual(['near-unanimous-vote']);
  });
  it('flags an unreadable tally', () =>
    expect(checkRecordGroup({ passages: [P({ tally_quote: 'Result (PASS)' }), billPage], snapshotText: new Map([...text, ['v', VOTES + ' Result (PASS)']]), fullName: 'Maria Elena Durazo' }).findings)
      .toContain('tally-unreadable'));
  it('IN roll call: Yoder is the actor and the 42-6 tally is divided', () => {
    const rc = P({ snapshot_id: 'r', instrument: 'HB 1041 (2025)', actor_quote: 'N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder',
      tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: null });
    const bill = { ...rc, snapshot_id: 'r', actor_quote: null, tally_quote: null, provision_quote: 'Student eligibility in interscholastic sports' };
    expect(checkRecordGroup({ passages: [rc, bill], snapshotText: text, fullName: 'Shelli Yoder' }).findings).toEqual([]);
  });
  it('flags a surname shared on the page unless the actor_quote carries the initial', () => {
    const w = P({ snapshot_id: 'r', instrument: 'HB 1041 (2025)', actor_quote: 'Walker', tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: 'Student eligibility in interscholastic sports' });
    expect(checkRecordGroup({ passages: [w], snapshotText: text, fullName: 'Greg Walker' }).findings).toContain('name-collision');
    expect(checkRecordGroup({ passages: [{ ...w, actor_quote: 'Walker G' }], snapshotText: text, fullName: 'Greg Walker' }).findings).not.toContain('name-collision');
  });

  // --- Fix round 1 ---

  it('does not let actor_quote match mid-word ("Lee" inside "Leeds")', () => {
    const page = 'HB 5 (2024) Ayes Leeds, Smith Noes None';
    const m = new Map([['x', page]]);
    const p = P({ snapshot_id: 'x', instrument: 'HB 5 (2024)', record_kind: 'sponsor', tally_quote: null, provision_quote: null, actor_quote: 'Ayes Lee' });
    expect(checkRecordGroup({ passages: [p], snapshotText: m, fullName: 'Barbara Lee' }).findings).toContain('person-not-in-snapshot');
  });

  it('does not let tally_quote match mid-number ("Yeas 4" inside "Yeas 46")', () => {
    const page = 'HB 6 (2024) Nays 5 Yeas 46 Ayes Roe';
    const m = new Map([['y', page]]);
    const p = P({ snapshot_id: 'y', instrument: 'HB 6 (2024)', actor_quote: 'Ayes Roe', tally_quote: 'Nays 5 Yeas 4', provision_quote: null });
    expect(checkRecordGroup({ passages: [p], snapshotText: m, fullName: 'Jane Roe' }).findings).toContain('tally-unreadable');
  });

  it('flags a page that never shows its own bill number', () => {
    const p = P({ instrument: 'SB 99 (2023-2024)' }); // snapshot_id 'v' (VOTES) never mentions SB 99
    expect(checkRecordGroup({ passages: [p], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings).toContain('instrument-mismatch');
  });

  it('flags a group with no record-class passage', () => {
    const s = P({ v3_class: 'statement-answer' });
    expect(checkRecordGroup({ passages: [s], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings).toContain('no-record-passage');
  });

  it('does not let a single initial before the surname stand in for a full first name', () => {
    const p = P({ snapshot_id: 'r', instrument: 'HB 1041 (2025)', record_kind: 'sponsor', tally_quote: null, provision_quote: null, actor_quote: 'G Walker K' });
    expect(checkRecordGroup({ passages: [p], snapshotText: text, fullName: 'Greg Walker' }).findings).toContain('name-collision');
  });

  it("recognises Sean O'Brien through consistent word tokenisation", () => {
    const page = "HB 20 (2024) A bill about parks. Ayes O'Brien, Peña Noes Smith";
    const m = new Map([['n', page]]);
    const p = P({ snapshot_id: 'n', instrument: 'HB 20 (2024)', record_kind: 'sponsor', tally_quote: null, provision_quote: 'A bill about parks', actor_quote: "Ayes O'Brien" });
    expect(checkRecordGroup({ passages: [p], snapshotText: m, fullName: "Sean O'Brien" }).findings).not.toContain('person-not-in-snapshot');
  });

  it('recognises Ana Peña through consistent word tokenisation', () => {
    const page = "HB 20 (2024) A bill about parks. Ayes O'Brien, Peña Noes Smith";
    const m = new Map([['n', page]]);
    const p = P({ snapshot_id: 'n', instrument: 'HB 20 (2024)', record_kind: 'sponsor', tally_quote: null, provision_quote: 'A bill about parks', actor_quote: 'Peña Noes Smith' });
    expect(checkRecordGroup({ passages: [p], snapshotText: m, fullName: 'Ana Peña' }).findings).not.toContain('person-not-in-snapshot');
  });
});
