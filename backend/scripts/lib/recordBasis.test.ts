import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { parseTally, isNearUnanimous, instrumentKey, checkRecordGroup, seatChamber, GENERIC_RULES, type SourceRules } from './recordBasis.js';
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

describe('fail closed on a zero tally (final review fix 3)', () => {
  it('ayes + noes = 0 is tally-unreadable, not "not near-unanimous"', () => {
    const z = new Map([...text, ['z', 'SB 1174 (2023-2024) Senate Floor Ayes Count 0 Noes Count 0 Ayes Durazo']]);
    const p = P({ snapshot_id: 'z', actor_quote: 'Ayes Durazo', tally_quote: 'Ayes Count 0 Noes Count 0' });
    const f = checkRecordGroup({ passages: [p, billPage], snapshotText: z, fullName: 'Maria Elena Durazo', chamber: 'upper' }).findings;
    expect(f).toEqual(['tally-unreadable']);
  });
});

describe('seatChamber', () => {
  it.each([
    ['Senator', 'upper'], ['State Senator', 'upper'], ['U.S. Senator', 'upper'],
    ['State Representative', 'lower'], ['Representative', 'lower'], ['Assembly Member', 'lower'],
    ['Assemblymember', 'lower'], ['Delegate', 'lower'],
    ['Mayor', null], ['County Commissioner', null], ['', null],
  ] as const)('%s -> %s', (t, c) => expect(seatChamber(t)).toBe(c));
});

describe('namesake guard on the actor page (final review fix 2)', () => {
  const HOUSE = 'H.B. 11 (2022). Utah House of Representatives roll call. Yeas 50 Nays 20 Yeas Adams, Barlow, Christofferson. The bill requires students to compete on teams matching their sex at birth.';
  const SENATE = 'H.B. 11 (2022). Utah State Senate roll call. Yeas 21 Nays 8 Yeas Adams J. S., Bramble, Cullimore. The bill requires students to compete on teams matching their sex at birth.';
  const NEITHER = 'H.B. 11 (2022). Roll call. Yeas 21 Nays 8 Yeas Adams J. S., Bramble, Cullimore. The bill requires students to compete on teams matching their sex at birth.';
  const m = new Map([['house', HOUSE], ['senate', SENATE], ['neither', NEITHER]]);
  const A = (id: string, actor: string) => P({ snapshot_id: id, instrument: 'H.B. 11 (2022)', actor_quote: actor,
    provision_quote: 'requires students to compete on teams matching their sex at birth' });
  const run = (p: Passage, chamber: 'upper' | 'lower' | null) =>
    checkRecordGroup({ passages: [p], snapshotText: m, fullName: 'J. Stuart Adams', chamber }).findings;

  it('a Senate page passes for a Senator', () =>
    expect(run({ ...A('senate', 'Yeas Adams J. S., Bramble'), tally_quote: 'Yeas 21 Nays 8' }, 'upper')).toEqual([]));
  it('a House-only page listing another Adams is chamber-not-evidenced for a Senator', () =>
    expect(run({ ...A('house', 'Yeas Adams, Barlow'), tally_quote: 'Yeas 50 Nays 20' }, 'upper')).toContain('chamber-not-evidenced'));
  it('a page that names no chamber is chamber-not-evidenced', () =>
    expect(run({ ...A('neither', 'Yeas Adams J. S., Bramble'), tally_quote: 'Yeas 21 Nays 8' }, 'upper')).toEqual(['chamber-not-evidenced']));
  it('the same House page passes the chamber test for a Representative', () =>
    expect(run({ ...A('house', 'Yeas Adams, Barlow'), tally_quote: 'Yeas 50 Nays 20' }, 'lower')).not.toContain('chamber-not-evidenced'));
  it('an unknown chamber (not a legislator title) skips the chamber test', () =>
    expect(run({ ...A('neither', 'Yeas Adams J. S., Bramble'), tally_quote: 'Yeas 21 Nays 8' }, null)).toEqual([]));
  it('a common surname with no first name or initial is name-collision, even printed once', () =>
    expect(run({ ...A('senate', 'Yeas Adams'), record_kind: 'sponsor', tally_quote: null }, 'upper')).toEqual(['name-collision']));
  it('a common surname qualified by an initial after it passes', () =>
    expect(run({ ...A('senate', 'Yeas Adams J. S.'), record_kind: 'sponsor', tally_quote: null }, 'upper')).toEqual([]));
  it('a common surname qualified by a full given name before it passes (middle name counts)', () => {
    const mm = new Map([['s2', 'H.B. 11 (2022). Utah Senate. Senate President Stuart Adams led the override. The bill requires students to compete on teams matching their sex at birth.']]);
    const p = P({ snapshot_id: 's2', instrument: 'H.B. 11 (2022)', record_kind: 'other-act', tally_quote: null, actor_quote: 'Stuart Adams led the override',
      provision_quote: 'requires students to compete on teams matching their sex at birth' });
    expect(checkRecordGroup({ passages: [p], snapshotText: mm, fullName: 'J. Stuart Adams', chamber: 'upper' }).findings).toEqual([]);
  });
  it('a middle name counts only when the first given name is a bare initial', () => {
    const mm = new Map([['s3', 'H.B. 11 (2022). Utah Senate. Senator Lee Smith led the override. The bill requires students to compete on teams matching their sex at birth.']]);
    const p = P({ snapshot_id: 's3', instrument: 'H.B. 11 (2022)', record_kind: 'other-act', tally_quote: null, actor_quote: 'Lee Smith led the override',
      provision_quote: 'requires students to compete on teams matching their sex at birth' });
    expect(checkRecordGroup({ passages: [p], snapshotText: mm, fullName: 'John Lee Smith', chamber: 'upper' }).findings).toContain('name-collision');
  });
  it('an uncommon surname printed once needs no qualifier', () =>
    expect(checkRecordGroup({ passages: [P({}), billPage], snapshotText: text, fullName: 'Maria Elena Durazo', chamber: 'upper' }).findings).toEqual([]));
});

// POSITIVE CONTROL (final review fix 2): the chamber + common-surname guard must pass the real,
// correct vote pages it will meet. A check that fails every real page is not a guard.
describe('positive control: real shadow-batch vote pages', () => {
  const load = (batch: string) => {
    const f = fileURLToPath(new URL(`../../data/stance-research/${batch}/snapshots.json`, import.meta.url));
    const rows = JSON.parse(readFileSync(f, 'utf8')) as { snapshot_id: string; snapshot_text: string | null }[];
    return new Map(rows.map((r) => [r.snapshot_id, r.snapshot_text ?? '']));
  };
  it('CA SB 1174 vote page (aa219c5b) passes for Senator Durazo', () => {
    const st = load('2026-09-25-shadow-durazo');
    const id = [...st.keys()].find((k) => k.startsWith('aa219c5b'))!;
    const p = P({ snapshot_id: id, actor_quote: 'Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo',
      tally_quote: 'Ayes Count 30 Noes Count 8', provision_quote: null });
    const f = checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Maria Elena Durazo', chamber: seatChamber('Senator') }).findings;
    expect(f).not.toContain('chamber-not-evidenced');
    expect(f).not.toContain('name-collision');
    expect(f).not.toContain('person-not-in-snapshot');
  });
  it('IN Senate roll call 334 (6024804d) passes for Senator Yoder', () => {
    const st = load('2026-09-25-shadow-yoder');
    const id = [...st.keys()].find((k) => k.startsWith('6024804d'))!;
    const p = P({ snapshot_id: id, instrument: 'HB 1041 (2025)', actor_quote: 'N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder',
      tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: 'Student eligibility in interscholastic sports' });
    const f = checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Shelli Yoder', chamber: seatChamber('Senator') }).findings;
    expect(f).toEqual([]);
  });
  it('the same IN Senate roll call does NOT pass for a House seat ("General Assembly" / "House Bill" are not the chamber)', () => {
    const st = load('2026-09-25-shadow-yoder');
    const id = [...st.keys()].find((k) => k.startsWith('6024804d'))!;
    const p = P({ snapshot_id: id, instrument: 'HB 1041 (2025)', actor_quote: 'N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder',
      tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: 'Student eligibility in interscholastic sports' });
    const f = checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Shelli Yoder', chamber: seatChamber('State Representative') }).findings;
    expect(f).toContain('chamber-not-evidenced');
  });
  it('CA SB 57 page (f3a91fb1) prints two Senate votes: Durazo in each is ONE member, not a collision', () => {
    const st = load('2026-09-25-shadow-durazo');
    const id = [...st.keys()].find((k) => k.startsWith('f3a91fb1'))!;
    const p = P({ snapshot_id: id, instrument: 'SB 57 (2025-2026)', actor_quote: 'Cervantes, Cortese, Durazo, Grayson',
      tally_quote: 'Ayes Count 29 Noes Count 8 NVR Count 3', provision_quote: null });
    const f = checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Maria Elena Durazo', chamber: seatChamber('Senator') }).findings;
    expect(f).not.toContain('name-collision');
    expect(f).not.toContain('chamber-not-evidenced');
    expect(f).not.toContain('tally-other-vote');
  });
  it('the SB 57 actor from the 09/13 vote with the 05/28 tally is tally-other-vote', () => {
    const st = load('2026-09-25-shadow-durazo');
    const id = [...st.keys()].find((k) => k.startsWith('f3a91fb1'))!;
    const p = P({ snapshot_id: id, instrument: 'SB 57 (2025-2026)', actor_quote: 'Cervantes, Cortese, Durazo, Grayson',
      tally_quote: 'Ayes Count 25 Noes Count 9 NVR Count 6', provision_quote: null });
    expect(checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Maria Elena Durazo', chamber: 'upper' }).findings).toContain('tally-other-vote');
  });
});

describe('positive control: chamber layouts on real pages', () => {
  const load = (batch: string) => {
    const f = fileURLToPath(new URL(`../../data/stance-research/${batch}/snapshots.json`, import.meta.url));
    const rows = JSON.parse(readFileSync(f, 'utf8')) as { snapshot_id: string; snapshot_text: string | null }[];
    return new Map(rows.map((r) => [r.snapshot_id, r.snapshot_text ?? '']));
  };
  it('IN author line: the title inside the actor_quote ("Sen. Shelli Yoder") is the chamber', () => {
    const st = load('2026-09-25-shadow-yoder');
    const p = P({ snapshot_id: 'd9257546-cef1-5033-b8a5-e8f37e1fa389', instrument: 'SB 208 (2024)', record_kind: 'author', tally_quote: null,
      actor_quote: 'Authored by: Sen. Shelli Yoder', provision_quote: null });
    expect(checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Shelli Yoder', chamber: 'upper' }).findings).not.toContain('chamber-not-evidenced');
  });
  it('CA AB 1955 Senate floor vote: "Motion Assembly 3rd Reading" is the bill stage, not the chamber', () => {
    const st = load('2026-09-25-shadow-durazo');
    const id = [...st.keys()].find((k) => k.startsWith('8666d0a3'))!;
    const p = P({ snapshot_id: id, instrument: 'AB 1955 (2023-2024)', actor_quote: 'Dodd, Durazo, Eggman',
      tally_quote: 'Ayes Count 29 Noes Count 8 NVR Count 3', provision_quote: null });
    const f = checkRecordGroup({ passages: [p], snapshotText: st, fullName: 'Maria Elena Durazo', chamber: 'upper' }).findings;
    expect(f).not.toContain('chamber-not-evidenced');
    expect(f).not.toContain('tally-other-vote');
  });
});

describe('vote blocks on a page with two chambers', () => {
  const page = 'SB 9 (2024). Location Assembly Floor Ayes Count 60 Noes Count 15 Ayes Baker, Lee, Ortiz Noes Diaz ' +
    '|| Location Senate Floor Ayes Count 30 Noes Count 9 Ayes Lee, Ortiz, Wong Noes Diaz. The bill requires a thing.';
  const m = new Map([['cp', page]]);
  const V = (actor: string, tally: string) => P({ snapshot_id: 'cp', instrument: 'SB 9 (2024)', actor_quote: actor, tally_quote: tally,
    provision_quote: 'requires a thing' });
  it('a Senator listed in the Senate vote passes', () =>
    expect(checkRecordGroup({ passages: [V('Ortiz, Wong', 'Ayes Count 30 Noes Count 9')], snapshotText: m, fullName: 'Ana Wong', chamber: 'upper' }).findings).toEqual([]));
  it('an Assembly vote cannot carry a Senator, even though the page names the Senate', () =>
    expect(checkRecordGroup({ passages: [V('Baker, Lee, Ortiz', 'Ayes Count 60 Noes Count 15')], snapshotText: m, fullName: 'Rosa Ortiz', chamber: 'upper' }).findings).toContain('chamber-not-evidenced'));
  it('a short name run printed in both votes is tied to the vote its tally names', () =>
    expect(checkRecordGroup({ passages: [V('Lee, Ortiz', 'Ayes Count 30 Noes Count 9')], snapshotText: m, fullName: 'Rosa Ortiz', chamber: 'upper' }).findings).toEqual([]));
});

describe('source rules', () => {
  const R = (over: Partial<SourceRules>): SourceRules => ({ ...GENERIC_RULES, ...over });
  const run = (page: string, over: Partial<Passage>, rules: SourceRules, chamber: 'upper' | 'lower' | null, fullName = 'Ana Wong') =>
    checkRecordGroup({ passages: [P({ snapshot_id: 'x', instrument: 'SB 9 (2024)', provision_quote: 'requires a thing', ...over })],
      snapshotText: new Map([['x', page]]), fullName, chamber: null, profileOf: () => ({ rules, chamber }) }).findings;

  const floorPage = 'SB 9 (2024). Location Senate Floor Ayes Count 30 Noes Count 9 Motion Assembly 3rd Reading Ayes Lee, Wong Noes Diaz. The bill requires a thing.';
  it('word-before-floor: the chamber is the word before "Floor", not the motion', () => {
    expect(run(floorPage, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9' }, R({ chamber: 'word-before-floor' }), 'upper')).toEqual([]);
    expect(run(floorPage, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9' }, R({ chamber: 'word-before-floor' }), 'lower')).toContain('chamber-not-evidenced');
  });
  it('page-header: the first chamber word on the page', () => {
    const page = 'Senate FIRST REGULAR SESSION SB 9 (2024) Yea 30 Nay 9 House members present Wong. The bill requires a thing.';
    expect(run(page, { actor_quote: 'present Wong', tally_quote: 'Yea 30 Nay 9' }, R({ chamber: 'page-header' }), 'upper')).toEqual([]);
  });
  it('bill-origin: SB is the Senate, AB/HB the lower chamber', () => {
    const page = 'SB 9 (2024), Wong. The bill requires a thing.';
    const author = { record_kind: 'author' as const, tally_quote: null, actor_quote: 'SB 9 (2024), Wong' };
    expect(run(page, author, R({ chamber: 'bill-origin' }), 'upper')).toEqual([]);
    expect(run(page, author, R({ chamber: 'bill-origin' }), 'lower')).toContain('chamber-not-evidenced');
  });
  it('none: the chamber test is skipped', () => {
    const page = 'SB 9 (2024). Council roll call Ayes 5 Noes 2 Ayes Lee, Wong. The bill requires a thing.';
    expect(run(page, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes 5 Noes 2' }, R({ chamber: 'none' }), 'upper')).toEqual([]);
  });
  it('not_chamber_after: an extra word makes a chamber word a stage', () => {
    const page = 'SB 9 (2024). Senate Floor Ayes 30 Noes 9 Assembly Concurrence Ayes Lee, Wong. The bill requires a thing.';
    const over = { actor_quote: 'Lee, Wong', tally_quote: 'Ayes 30 Noes 9' };
    expect(run(page, over, R({}), 'upper')).toContain('chamber-not-evidenced');
    expect(run(page, over, R({ not_chamber_after: ['concurrence'] }), 'upper')).toEqual([]);
  });
  it('whole-page: two aye counts are one vote, so the surname counts across both', () => {
    const page = 'SB 9 (2024). Senate Ayes 30 Noes 9 Ayes Wong Ayes 29 Noes 9 Ayes Wong. The bill requires a thing.';
    const over = { actor_quote: 'Ayes Wong', tally_quote: 'Ayes 30 Noes 9' };
    expect(run(page, over, R({}), 'upper')).not.toContain('name-collision');
    expect(run(page, over, R({ vote_block: 'whole-page' }), 'upper')).toContain('name-collision');
  });
  it('full-name: the given name is always required', () => {
    const page = 'SB 9 (2024). Senate Ayes 5 Noes 2 Councilmember Wong aye. The bill requires a thing.';
    const over = { actor_quote: 'Councilmember Wong aye', tally_quote: 'Ayes 5 Noes 2' };
    expect(run(page, over, R({}), 'upper')).toEqual([]);
    expect(run(page, over, R({ name_format: 'full-name' }), 'upper')).toContain('name-collision');
  });
  it('profileOf returning null keeps the generic rules and i.chamber', () => {
    const f = checkRecordGroup({ passages: [P({ snapshot_id: 'x', instrument: 'SB 9 (2024)', actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9', provision_quote: 'requires a thing' })],
      snapshotText: new Map([['x', floorPage]]), fullName: 'Ana Wong', chamber: 'upper', profileOf: () => null }).findings;
    // generic nearest-before reads "Assembly 3rd Reading" as a stage, then finds "Senate": passes
    expect(f).toEqual([]);
  });
});
