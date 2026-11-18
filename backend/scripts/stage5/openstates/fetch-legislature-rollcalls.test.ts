import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { buildRollCall, INDEX, sdIntroducedText, sdNamedOnText, sdRecordSponsors, sdSameMember, sdSessionMembers, sdSponsorsOnText, type IndexedVote } from './fetch-legislature-rollcalls.js';

// The saved Utah House page: roll call 100 of the 2025 General Session, HB 237, 71 yeas, 0 nays, 4 absent.
const HOUSE = readFileSync(fileURLToPath(new URL('../../../src/lib/__fixtures__/stateRollCall/ut-2025GS-100-H.html', import.meta.url)), 'latin1');
const URL_H = 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=H';
const vote = (over: Partial<IndexedVote> = {}): IndexedVote => ({ url: URL_H, motion: 'House/ passed 3rd reading', tally: [71, 0, 4], ...over });
/** A bill's vote list as le.utah.gov publishes it, cut down to the fields the tool reads. */
const action = (over: Record<string, string>): Record<string, string> =>
  ({ description: 'House/ passed 3rd reading', actionClass: 'H', voteID: '100', voiceVote: '0', voteHouse: 'H', voteStr: '71-0-4', ...over });
const file = (actions: Record<string, string>[], over: Record<string, string> = {}): string =>
  JSON.stringify({ sessionID: '2025GS', billNumber: 'HB0237', actionHistoryList: actions, ...over });

describe('the legislature\'s own vote list — Utah', () => {
  it('names the data file by the site\'s session and bill numbers', () => {
    expect(INDEX.UT.billUrl('2025', 'HB 237')).toBe('https://le.utah.gov/data/2025GS/HB0237.json');
    expect(INDEX.UT.billUrl('2025S1', 'S.J.R. 2')).toBe('https://le.utah.gov/data/2025S1/SJR0002.json');
    expect(INDEX.UT.billUrl('2025-2026', 'HB 237')).toBeNull();
    expect(INDEX.UT.billUrl('2025', 'Bill 237')).toBeNull();
  });

  it('keeps floor roll calls and counts, but does not read, committee and voice votes', () => {
    const bi = INDEX.UT.read(file([
      action({}),
      action({ actionClass: 'A', voteID: '34263', voteHouse: '', voteStr: '9-0-2', voiceVote: '' }),
      action({ voteID: '302', voiceVote: '1', voteStr: '0-0-75' }),
      action({ voteID: '' }),
      action({ actionClass: 'S', voteID: '734', voteHouse: 'S', voteStr: ' 19-0-10 ', description: 'Senate/ passed 2nd reading' }),
    ]), '2025', 'HB 237');
    expect(bi.committee).toBe(1);
    expect(bi.voice).toBe(1);
    expect(bi.floor).toEqual([
      { url: URL_H, motion: 'House/ passed 3rd reading', tally: [71, 0, 4] },
      { url: 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=734&house=S', motion: 'Senate/ passed 2nd reading', tally: [19, 0, 10] },
    ]);
  });

  it('refuses a data file that is for another bill or another session', () => {
    expect(() => INDEX.UT.read(file([action({})]), '2025', 'HB 238')).toThrow(/not 2025 HB 238/);
    expect(() => INDEX.UT.read(file([action({})], { sessionID: '2024GS' }), '2025', 'HB 237')).toThrow(/2024GS/);
  });

  it('refuses a floor vote it cannot read, rather than dropping it', () => {
    expect(() => INDEX.UT.read(file([action({ voteStr: 'passed' })]), '2025', 'HB 237')).toThrow(/cannot read/);
    expect(() => INDEX.UT.read(file([action({ voteHouse: '' })]), '2025', 'HB 237')).toThrow(/cannot read/);
  });
});

describe('one roll call for the supplement', () => {
  it('takes the members from the page when the page and the bill file agree', () => {
    const rc = buildRollCall('HB 237', vote(), HOUSE);
    expect(rc).toMatchObject({ url: URL_H, date: '2025-01-30', chamber: 'H', yea: 71, nay: 0, absent: 4, passed: 1,
      motion: 'House/ passed 3rd reading', question: '3rd Reading Final Passage' });
    if ('refused' in rc) throw new Error(rc.refused);
    expect(rc.groups['Absent or not voting']).toEqual(['Bolinder, B.', 'Matthews, A.', 'Schultz, M.', 'Teuscher, J.']);
    expect(rc.groups.Yea).toContain('Maloy, A. Cory');
  });

  it('refuses a page that is for another bill', () => {
    expect(buildRollCall('HB 238', vote(), HOUSE)).toEqual({ refused: 'the page is for HB 237, not HB 238' });
  });

  it('refuses a page whose tally is not the bill file\'s', () => {
    expect(buildRollCall('HB 237', vote({ tally: [70, 1, 4] }), HOUSE)).toEqual({ refused: 'the page\'s tally 71-0-4 is not the bill file\'s 70-1-4' });
  });

  it('refuses a page the reader refuses, and an address no reader knows', () => {
    expect(HOUSE.includes('Yeas - 71')).toBe(true);
    expect(buildRollCall('HB 237', vote(), HOUSE.replace('Yeas - 71', 'Yeas - 70'))).toEqual({ refused: 'the page did not read as a roll call' });
    expect(buildRollCall('HB 237', vote({ url: 'https://le.utah.gov/mtgvotes.jsp?voteid=9' }), HOUSE)).toEqual({ refused: 'no reader knows this address' });
  });

  it('takes pass or fail from the motion\'s own word, and from the count only when it has none', () => {
    const p = (motion: string): unknown => { const rc = buildRollCall('HB 237', vote({ motion }), HOUSE); return 'refused' in rc ? rc : rc.passed; };
    expect(p('House/ failed')).toBe(0);
    expect(p('House/ concurs with Senate amendment')).toBe(1);
    expect(p('House/ substituted')).toBe(1); // 71 yeas to 0
  });
});

// Ohio: saved 2026-11-16. 132 HB 228: two committee reports, a House passage, a Senate passage (amended), the House
// concurrence, and both chambers' veto overrides.
const oh = (name: string): string => readFileSync(fileURLToPath(new URL(`../../../src/lib/__fixtures__/stateRollCall/${name}`, import.meta.url)), 'utf8');
const OH_DOCS = [oh('oh-132-hb228-votes.html'), oh('oh-132-hb228-actions.json'), oh('oh-132-legislators.json')];
const OH_PAGE = 'https://www.legislature.ohio.gov/legislation/132/hb228/votes#';

describe('the legislature\'s own vote list — Ohio', () => {
  it('names the bill\'s action list, and no list for a special session', () => {
    expect(INDEX.OH.billUrl('132', 'HB 228')).toBe('https://search-prod.lis.state.oh.us/api/v2/general_assembly_132/legislation/hb228/actions/');
    expect(INDEX.OH.billUrl('135', 'S.J.R. 2')).toBe('https://search-prod.lis.state.oh.us/api/v2/general_assembly_135/legislation/sjr2/actions/');
    expect(INDEX.OH.billUrl('135S1', 'HB 2')).toBeNull();
    expect(INDEX.OH.billUrl('2025', 'HB 2')).toBeNull();
  });

  it('reads no vote on a motion (action_code motion_), and counts it (runner, 2026-11-16)', () => {
    const data = OH_DOCS[1].replace(/"action_code": ?"msg_507"/, '"action_code": "motion_920"');
    expect(data).not.toBe(OH_DOCS[1]);
    const bi = INDEX.OH.read(data, '132', 'HB 228');
    expect(bi.floor.map((v) => v.url)).not.toContain(`${OH_PAGE}2018-12-06-House-59-22`);
    expect(bi.floor).toHaveLength(4);
    expect(bi.motion).toBe(1);
  });

  it('keeps the floor votes, each named on the bill\'s Votes page, and counts the committee reports', () => {
    const bi = INDEX.OH.read(OH_DOCS[1], '132', 'HB 228');
    expect(bi.committee).toBe(2);
    expect(bi.floor.map((v) => v.url)).toEqual([
      `${OH_PAGE}2018-12-27-Senate-21-11`, `${OH_PAGE}2018-12-27-House-67-22`, `${OH_PAGE}2018-12-06-House-59-22`,
      `${OH_PAGE}2018-12-06-Senate-19-10`, `${OH_PAGE}2018-11-14-House-65-32`,
    ]);
    expect(bi.floor[1]).toMatchObject({ motion: 'Passed notwithstanding objections of the Governor', tally: [67, 22, 0] });
  });

  it('reads each floor vote from the page, the data and the member list together', () => {
    const v = INDEX.OH.read(OH_DOCS[1], '132', 'HB 228').floor[1];
    const rc = buildRollCall('HB 228', v, OH_DOCS);
    expect(rc).toMatchObject({ url: v.url, date: '2018-12-27', chamber: 'H', yea: 67, nay: 22, absent: 0, passed: 1, question: 'Passed notwithstanding objections of the Governor' });
    if ('groups' in rc) expect(rc.groups.Yea).toHaveLength(67);
  });

  it('refuses a vote the page does not hold as the data does, and a vote of another bill', () => {
    const v = INDEX.OH.read(OH_DOCS[1], '132', 'HB 228').floor[1];
    expect(buildRollCall('HB 228', v, [OH_DOCS[0].replace('Yeas: 67', 'Yeas: 66'), OH_DOCS[1], OH_DOCS[2]])).toHaveProperty('refused');
    expect(buildRollCall('HB 229', v, OH_DOCS)).toHaveProperty('refused');
  });
});

// South Dakota (saved 2026-11-17 from sdlegislature.gov): 2018 HB 1209's action log (two committee votes, the House
// and Senate floor votes and the House concurrence), 2018 SB 115's (a floor vote, then a vote to reconsider), and the
// concurrence's own record, /api/Votes/26828.
const SD_HB1209 = oh('sd-2018-hb1209-actionlog.json');
const SD_SB115 = oh('sd-2018-sb115-actionlog.json');
const SD_26828 = oh('sd-vote-26828.json');
const sdList = (rows: { BillId: number; BillType: string; BillNumberOnly: number }[]): string => JSON.stringify(rows);

describe('the legislature\'s own vote list — South Dakota', () => {
  it('finds the bill in the session\'s bill list, by the site\'s own id, and knows no session it was not told', () => {
    expect(INDEX.SD.billUrl('2018', 'HB 1209')).toBeNull();
    expect(INDEX.SD.listUrl!('2018')).toBe('https://sdlegislature.gov/api/Bills/Session/Light/32');
    expect(INDEX.SD.listUrl!('2021r')).toBe('https://sdlegislature.gov/api/Bills/Session/Light/65');
    expect(INDEX.SD.listUrl!('2027')).toBeNull();
    const list = sdList([{ BillId: 9112, BillType: 'HB', BillNumberOnly: 1209 }, { BillId: 9113, BillType: 'SB', BillNumberOnly: 1209 }]);
    expect(INDEX.SD.billUrlFromList!(list, '2018', 'HB 1209')).toBe('https://sdlegislature.gov/api/Bills/ActionLog/9112');
    expect(INDEX.SD.billUrlFromList!(list, '2018', 'H.B. 1209')).toBe('https://sdlegislature.gov/api/Bills/ActionLog/9112');
  });

  it('refuses a bill the list holds no times, or twice', () => {
    const one = { BillId: 9112, BillType: 'HB', BillNumberOnly: 1209 };
    expect(() => INDEX.SD.billUrlFromList!(sdList([]), '2018', 'HB 1209')).toThrow(/0 times/);
    expect(() => INDEX.SD.billUrlFromList!(sdList([one, { ...one, BillId: 9999 }]), '2018', 'HB 1209')).toThrow(/2 times/);
    expect(() => INDEX.SD.billUrlFromList!(sdList([one]), '2018', 'Bill 1209')).toThrow(/not a South Dakota bill/);
  });

  it('keeps the floor votes, and counts and lists the committee votes, each cited on its own page', () => {
    const bi = INDEX.SD.read(SD_HB1209, '2018', 'HB 1209');
    expect(bi.floor).toEqual([
      { url: 'https://sdlegislature.gov/Session/Vote/25955', motion: 'Do Pass', tally: [55, 0, 15] },
      { url: 'https://sdlegislature.gov/Session/Vote/26737', motion: 'Do Pass Amended', tally: [31, 1, 3] },
      { url: 'https://sdlegislature.gov/Session/Vote/26828', motion: 'Concurred in amendments', tally: [62, 4, 0] },
    ]);
    expect(bi.committee).toBe(2);
    expect(bi.committeeUrls).toEqual(['https://sdlegislature.gov/Session/Vote/25823', 'https://sdlegislature.gov/Session/Vote/26522']);
    expect(bi.motion).toBe(0);
  });

  it('reads no vote on a motion: SB 115\'s vote to reconsider is counted and listed, not kept (runner, 2026-11-16)', () => {
    const bi = INDEX.SD.read(SD_SB115, '2018', 'SB 115');
    expect(bi.floor.map((v) => v.url)).toEqual(['https://sdlegislature.gov/Session/Vote/26041']);
    expect(bi.motion).toBe(1);
    expect(bi.motions).toEqual(['https://sdlegislature.gov/Session/Vote/26132 Reconsidered']);
  });

  it('keeps a vote the action log lists twice once (the 2020 consent calendars)', () => {
    const j = JSON.parse(SD_HB1209) as unknown[];
    const twice = JSON.stringify([...j, ...j]);
    expect(INDEX.SD.read(twice, '2018', 'HB 1209').floor).toHaveLength(3);
    expect(INDEX.SD.read(twice, '2018', 'HB 1209').committee).toBe(2);
  });

  it('builds the roll call from the record, comparing yeas and nays only: the action log counts 0 excused where the record lists 4', () => {
    const v = INDEX.SD.read(SD_HB1209, '2018', 'HB 1209').floor[2];
    expect(v.tally).toEqual([62, 4, 0]);
    const rc = buildRollCall('HB 1209', v, SD_26828, '2018');
    expect(rc).toMatchObject({ url: v.url, date: '2018-03-07', chamber: 'H', yea: 62, nay: 4, absent: 4, passed: 1, question: 'Concurred in amendments' });
    expect(buildRollCall('HB 1209', { ...v, tally: [61, 5, 0] }, SD_26828, '2018')).toHaveProperty('refused');
  });

  it('refuses the record of another session, or of another bill', () => {
    const v = INDEX.SD.read(SD_HB1209, '2018', 'HB 1209').floor[2];
    expect(buildRollCall('HB 1209', v, SD_26828, '2019')).toEqual({ refused: 'the vote is of session 2018, not 2019' });
    expect(buildRollCall('HB 1210', v, SD_26828, '2018')).toHaveProperty('refused');
  });
});

// South Dakota sponsorships (runner, 2026-11-17: cite the introduced text). 2018 HB 1209's record (/api/Bills/9112,
// saved without the party field) and versions (/api/Bills/Versions/9112); the "Introduced by" passages are the text
// extractPdfText gives for the 2018 HB 1209, 2020 HB 1093 and 2026 SB 179 introduced PDFs.
const SD_BILL = oh('sd-2018-hb1209-bill.json');
const SD_VERSIONS = oh('sd-2018-hb1209-versions.json');
const TEXT_2018 = 'HOUSE BILL NO. 1209 Introduced by: Representatives Peterson (Sue), Bordeaux, Haugaard, Howard, Marty, May, Qualm, and Rasmussen and Senators Langer, Curd, Greenfield (Brock), Klumb, Maher, Monroe, and Netherton FOR AN ACT ENTITLED, An Act to require';
const TEXT_2020 = 'House Bill 1093 Introduced by: Representative Bordeaux at the request of the Committee on State-Tribal Relations Catchlines are not law.';
const TEXT_2026 = 'Senate Bill 179 Introduced by: Senator Hohn Underscores indicate new language. Overstrikes indicate deleted language. An Act to permit';

describe('South Dakota sponsorships, cited on the introduced text', () => {
  it('finds the one introduced text, and refuses a version list with none or two', () => {
    expect(sdIntroducedText(SD_VERSIONS, 'HB 1209')).toBe('https://mylrc.sdlegislature.gov/api/Documents/47915.pdf');
    const v = JSON.parse(SD_VERSIONS) as { BillVersion: string }[];
    expect(() => sdIntroducedText(JSON.stringify(v.slice(1)), 'HB 1209')).toThrow(/0 introduced/);
    expect(() => sdIntroducedText(JSON.stringify([v[0], v[0]]), 'HB 1209')).toThrow(/2 introduced/);
  });

  it('reads the record\'s sponsors, prime or co-sponsor, and nothing else about them', () => {
    const r = sdRecordSponsors(SD_BILL, 9112, 'HB 1209');
    expect(r).toHaveLength(15);
    expect(r.slice(0, 3)).toEqual([
      { name: 'Kris Langer', label: 'Langer', chamber: 'S', type: 'P' },
      { name: 'Sue Peterson', label: 'Peterson (Sue)', chamber: 'H', type: 'P' },
      { name: 'Shawn Bordeaux', label: 'Bordeaux', chamber: 'H', type: 'C' },
    ]);
    expect(() => sdRecordSponsors(SD_BILL, 9113, 'HB 1209')).toThrow(/not bill 9113/);
  });

  it('reads every member the 2018 text names, by chamber; the later texts name the lead sponsor only, and a committee is no member', () => {
    const n18 = sdNamedOnText(TEXT_2018)!;
    expect(n18.names).toHaveLength(15);
    expect(n18.names.slice(0, 2)).toEqual([{ chamber: 'H', label: 'Peterson (Sue)' }, { chamber: 'H', label: 'Bordeaux' }]);
    expect(n18.names.slice(7, 9)).toEqual([{ chamber: 'H', label: 'Rasmussen' }, { chamber: 'S', label: 'Langer' }]);
    expect(n18.names.at(-1)).toEqual({ chamber: 'S', label: 'Netherton' });
    expect(sdNamedOnText(TEXT_2020)!.names).toEqual([{ chamber: 'H', label: 'Bordeaux' }]);
    expect(sdNamedOnText(TEXT_2026)!.names).toEqual([{ chamber: 'S', label: 'Hohn' }]);
    expect(sdNamedOnText('An Act to revise')).toBeNull();
  });

  // the 2018 member list's people the tests need: two Petersons in the House, one Kolbeck and one Otten in the Senate
  const MEMBERS = (rec: { name: string; label: string; chamber: 'H' | 'S' }[]) => [
    ...rec, { name: 'Kent Peterson', label: 'Peterson (Kent)', chamber: 'H' as const },
    { name: 'Jack Kolbeck', label: 'Kolbeck (Jack)', chamber: 'S' as const }, { name: 'Ernie Otten', label: 'Otten', chamber: 'S' as const },
    { name: 'Herman Otten', label: 'Otten (Herman)', chamber: 'H' as const }, { name: 'Kevin Jensen', label: 'Jensen (Kevin)', chamber: 'H' as const },
  ];

  it('reads a session member list, name, label and chamber only', () => {
    const body = JSON.stringify([{ SessionId: 32, MemberType: 'S', FirstName: 'Jack', LastName: 'Kolbeck', UniqueName: 'Kolbeck (Jack)', PersonId: 1 }]);
    expect(sdSessionMembers(body, 32)).toEqual([{ name: 'Jack Kolbeck', label: 'Kolbeck (Jack)', chamber: 'S' }]);
    expect(() => sdSessionMembers(body, 36)).toThrow(/cannot read/);
    expect(() => sdSessionMembers('[]', 32)).toThrow(/empty/);
  });

  it('knows a member however the text prints the name', () => {
    expect(sdSameMember('Kolbeck', { name: 'Jack Kolbeck', label: 'Kolbeck (Jack)' })).toBe(true);
    expect(sdSameMember('Otten (Ernie)', { name: 'Ernie Otten', label: 'Otten' })).toBe(true);
    expect(sdSameMember('Kevin Jensen', { name: 'Kevin Jensen', label: 'Jensen (Kevin)' })).toBe(true);
    expect(sdSameMember('Otten (Herman)', { name: 'Ernie Otten', label: 'Otten' })).toBe(false);
    expect(sdSameMember('Jensen', { name: 'Kevin Jensen', label: 'Jensen (Kevin)' })).toBe(true);
    expect(sdSameMember('Jenson', { name: 'Kevin Jensen', label: 'Jensen (Kevin)' })).toBe(false);
  });

  it('marks each sponsor the text names, and only those', () => {
    const rec = sdRecordSponsors(SD_BILL, 9112, 'HB 1209');
    expect(sdSponsorsOnText(rec, sdNamedOnText(TEXT_2018)!.names, MEMBERS(rec), 'HB 1209').every((m) => m.on_text)).toBe(true);
    const lead = sdSponsorsOnText(rec, [{ chamber: 'H', label: 'Peterson (Sue)' }], MEMBERS(rec), 'HB 1209');
    expect(lead.filter((m) => m.on_text).map((m) => m.name)).toEqual(['Sue Peterson']);
    // the text prints a member another way than the record: still that one sponsor
    const kol = [...rec, { name: 'Jack Kolbeck', label: 'Kolbeck (Jack)', chamber: 'S' as const, type: 'C' as const }];
    expect(sdSponsorsOnText(kol, [{ chamber: 'S', label: 'Kolbeck' }], MEMBERS(rec), 'HB 1209').filter((m) => m.on_text).map((m) => m.name)).toEqual(['Jack Kolbeck']);
  });

  it('refuses a text that names someone who is not one member of the chamber and one sponsor of the record', () => {
    const rec = sdRecordSponsors(SD_BILL, 9112, 'HB 1209');
    expect(() => sdSponsorsOnText(rec, [{ chamber: 'H', label: 'Hohn' }], MEMBERS(rec), 'HB 1209')).toThrow(/0 members of the session/);
    expect(() => sdSponsorsOnText(rec, [{ chamber: 'S', label: 'Bordeaux' }], MEMBERS(rec), 'HB 1209')).toThrow(/0 members of the session/);
    // two Petersons sit in the House: a bare surname is refused, though only Sue sponsors the bill
    expect(() => sdSponsorsOnText(rec, [{ chamber: 'H', label: 'Peterson' }], MEMBERS(rec), 'HB 1209')).toThrow(/2 members of the session/);
    // a bare surname that is one member's own label is that member: "Sutton" is Maggie, "Sutton (Billie)" Billie
    const sut = [...rec, { name: 'Maggie Sutton', label: 'Sutton', chamber: 'S' as const, type: 'C' as const }];
    const both = [...MEMBERS(rec), { name: 'Maggie Sutton', label: 'Sutton', chamber: 'S' as const }, { name: 'Billie Sutton', label: 'Sutton (Billie)', chamber: 'S' as const }];
    expect(sdSponsorsOnText(sut, [{ chamber: 'S', label: 'Sutton' }], both, 'HB 1209').filter((m) => m.on_text).map((m) => m.name)).toEqual(['Maggie Sutton']);
    // a member of the session who is no sponsor of the bill
    expect(() => sdSponsorsOnText(rec, [{ chamber: 'S', label: 'Kolbeck' }], MEMBERS(rec), 'HB 1209')).toThrow(/0 sponsors of the record/);
  });

  it('ends the line of a commemoration and a resolution at its own heading', () => {
    expect(sdNamedOnText('HOUSE COMMEMORATION NO. 1015 Introduced by: Representatives Duvall and Peterson (Kent) and Senators Kolbeck and Smith (VJ) A LEGISLATIVE COMMEMORATION, Honoring')!.names)
      .toEqual([{ chamber: 'H', label: 'Duvall' }, { chamber: 'H', label: 'Peterson (Kent)' }, { chamber: 'S', label: 'Kolbeck' }, { chamber: 'S', label: 'Smith (VJ)' }]);
    expect(sdNamedOnText('SENATE RESOLUTION NO. 6 Introduced by: Senator Nelson A RESOLUTION, Supporting')!.names).toEqual([{ chamber: 'S', label: 'Nelson' }]);
  });
});

// Mississippi (saved 2026-11-17 from billstatus.ls.state.ms.us): 2026 HB 1793's history (four recorded votes, each
// linking its PDF), and the documents of its House conference-report vote, 0830060 (the PDF as its lines).
const MS_FIX = (f: string): string => readFileSync(fileURLToPath(new URL(`../../../src/lib/__fixtures__/stateRollCall/${f}`, import.meta.url)), 'latin1');
const MS_HB1793 = MS_FIX('ms-2026-HB1793.xml');
const MS_0830060 = ['ms-2026-house-0830060.txt', 'ms-2026-HB1793.xml', 'ms-2026-h_auth.xml', 'ms-members-hr_membs.xml'].map(MS_FIX);
const MS_V = 'https://billstatus.ls.state.ms.us/2026/pdf/votes/';

describe('the legislature\'s own vote list — Mississippi', () => {
  it('names the bill\'s history, its number padded to four, for a regular or an extraordinary session', () => {
    expect(INDEX.MS.billUrl('2026', 'HB 1793')).toBe('https://billstatus.ls.state.ms.us/2026/pdf/history/HB/HB1793.xml');
    expect(INDEX.MS.billUrl('2023', 'HB 912')).toBe('https://billstatus.ls.state.ms.us/2023/pdf/history/HB/HB0912.xml');
    expect(INDEX.MS.billUrl('20241E', 'SB 2001')).toBe('https://billstatus.ls.state.ms.us/20241E/pdf/history/SB/SB2001.xml');
    expect(INDEX.MS.billUrl('2026 Regular', 'HB 1793')).toBeNull();
  });

  it('keeps every vote the history links, each cited on its PDF with the bill; the history prints no tally', () => {
    const bi = INDEX.MS.read(MS_HB1793, '2026', 'HB 1793');
    expect(bi.floor.map((v) => v.url)).toEqual([`${MS_V}house/0510008.pdf#HB1793`, `${MS_V}senate/0710008.pdf#HB1793`,
      `${MS_V}house/0830060.pdf#HB1793`, `${MS_V}senate/0830093.pdf#HB1793`]);
    expect(bi.floor[2]).toEqual({ url: `${MS_V}house/0830060.pdf#HB1793`, motion: 'Conference Report Adopted', tally: null });
    expect(bi.motion).toBe(0);
  });

  it('reads no vote on a motion, and counts it (runner, 2026-11-16)', () => {
    const body = MS_HB1793.replace('03/17 (S) Passed As Amended', '03/17 (S) Motion to Reconsider Tabled');
    expect(body).not.toBe(MS_HB1793);
    const bi = INDEX.MS.read(body, '2026', 'HB 1793');
    expect(bi.floor).toHaveLength(3);
    expect(bi.motion).toBe(1);
  });

  it('refuses the history of another bill or year, and a vote link to another session', () => {
    expect(() => INDEX.MS.read(MS_HB1793, '2026', 'HB 1794')).toThrow();
    expect(() => INDEX.MS.read(MS_HB1793, '2025', 'HB 1793')).toThrow();
    const other = MS_HB1793.replace('../../../../2026/pdf/votes/house/0830060.pdf', '../../../../2025/pdf/votes/house/0830060.pdf');
    expect(other).not.toBe(MS_HB1793);
    expect(() => INDEX.MS.read(other, '2026', 'HB 1793')).toThrow();
  });

  it('builds the roll call from the PDF\'s own totals, and says why it refused one', () => {
    const v = INDEX.MS.read(MS_HB1793, '2026', 'HB 1793').floor[2];
    const rc = buildRollCall('HB 1793', v, MS_0830060);
    // Present is not a Yea or a Nay: it joins the not-voting group the supplement keeps
    expect(rc).toMatchObject({ url: v.url, date: '2026-03-29', chamber: 'H', yea: 106, nay: 6, absent: 10, passed: 1, question: 'Conference Report Adopted' });
    const bad = buildRollCall('HB 1793', v, [MS_0830060[0].replace('Total--106.', 'Total--105.'), ...MS_0830060.slice(1)]);
    expect(bad).toHaveProperty('refused');
    expect((bad as { refused: string }).refused).toMatch(/^the page did not read as a roll call: /);
  });
});
