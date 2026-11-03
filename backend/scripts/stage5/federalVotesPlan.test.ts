import { describe, it, expect } from 'vitest';
import { findStoreVote, markActs, pageDecisions, planCitations, voteKey, type PageAct, type SeatedVote } from './federalVotesPlan.js';
import type { Vote } from '../lib/sourceStore.js';
import type { TableRollCall } from '../lib/federalTableVotes.js';

const PID = 'p-house-1';
const SEN = 'p-senate-1';

const roll = (over: Partial<TableRollCall>): TableRollCall => ({
  external_vote_id: 'house-252', bill_number: 'HJRES 44', congress: '118', date: '2023-06-13',
  question: 'On Passage RC# 252', rc: 252, yes: 219, no: 210, positions: new Map([[PID, 'nay']]), ...over,
});
const roll252 = roll({});
const senateRoll = roll({
  external_vote_id: 'legiscan-1343990', date: '2023-07-12', question: 'Joint Resolution Passage', rc: null,
  yes: 50, no: 49, positions: new Map([[SEN, 'yea']]),
});

const seatedHouse: SeatedVote = {
  politician_id: PID, full_name: 'Pat Example', last_name: 'Example', bioguide: 'E000001', topic_key: 'voting-rights',
  instrument_id: 'US-HJRES-44-2023', date: '2023-06-13', motion: 'final passage (On Passage)', act: 'nay', yes: 219, no: 210,
  cited_url: 'https://www.govinfo.gov/content/pkg/BILLS-118hjres44enr/html/BILLS-118hjres44enr.htm',
};
const seatedSenate: SeatedVote = {
  ...seatedHouse, politician_id: SEN, full_name: 'Sam Senator', last_name: 'Senator', bioguide: 'S000002',
  date: '2023-07-12', act: 'yea', yes: 50, no: 49,
};

describe('planCitations', () => {
  it('cites a House vote at its Clerk XML, from the table roll number', () => {
    expect(planCitations([seatedHouse], [roll252]).house[0].url).toBe('https://clerk.house.gov/evs/2023/roll252.xml');
  });
  it('carries the bill and roll number the Clerk XML must show', () => {
    expect(planCitations([seatedHouse], [roll252]).house[0]).toMatchObject({ bill_number: 'HJRES 44', rc: 252 });
  });
  it('cites a free-text motion whose roll number and tally are the table roll call\'s', () => {
    const s = { ...seatedHouse, motion: 'On Passage, H.J.Res. 44 (House roll call 252; passed 219-210)' };
    expect(planCitations([s], [roll252]).house).toHaveLength(1);
  });
  it('holds a motion that names another roll number', () => {
    const p = planCitations([{ ...seatedHouse, motion: 'On Passage, H.J.Res. 44 (House roll call 102)' }], [roll252]);
    expect(p.house).toHaveLength(0);
    expect(p.unmapped).toEqual([expect.objectContaining({ reason: 'motion names roll call 102; the table roll call is 252' })]);
    expect(planCitations([{ ...seatedHouse, motion: 'On Passage (roll #102)' }], [roll252]).house).toHaveLength(0);
  });
  it('holds a motion that names another tally', () => {
    const p = planCitations([{ ...seatedHouse, motion: 'On Passage, H.J.Res. 44 (passed 220-208)' }], [roll252]);
    expect(p.house).toHaveLength(0);
    expect(p.unmapped).toEqual([expect.objectContaining({ reason: 'motion names tally 220-208; the table roll call is 219-210' })]);
  });
  it('reads no roll number or tally from an amendment number or a date', () => {
    const s = { ...seatedHouse, motion: 'On the Amendment (Manchin Amdt. No. 715), 2023-06-13' };
    expect(planCitations([s], [roll252]).house).toHaveLength(1);
  });
  it('pads a short roll number to three digits', () => {
    const r = roll({ rc: 7, question: 'On Passage RC# 7' });
    expect(planCitations([seatedHouse], [r]).house[0].url).toBe('https://clerk.house.gov/evs/2023/roll007.xml');
  });
  it('makes a LegiScan pair for a Senate vote from the table id, with no senate.gov lookup', () => {
    const p = planCitations([seatedSenate], [senateRoll]);
    expect(p.senate[0].source_url).toBe('https://legiscan.com/US/rollcall/HJR44/id/1343990');
    expect(p.senate[0]).toMatchObject({ full_name: 'Sam Senator', last_name: 'Senator', topic_key: 'voting-rights' });
    expect(p.house).toHaveLength(0);
  });
  it("names the bill LegiScan's way in the pair URL", () => {
    const url = (bill_number: string, instrument_id: string) =>
      planCitations([{ ...seatedSenate, instrument_id }], [{ ...senateRoll, bill_number }]).senate[0]?.source_url;
    expect(url('S 1', 'US-S-1-2023')).toBe('https://legiscan.com/US/rollcall/SB1/id/1343990');
    expect(url('HR 22', 'US-HR-22-2023')).toBe('https://legiscan.com/US/rollcall/HB22/id/1343990');
    expect(url('SJRES 9', 'US-SJRES-9-2023')).toBe('https://legiscan.com/US/rollcall/SJR9/id/1343990');
  });
  it('holds a Senate vote on a bill type LegiScan has no prefix for', () => {
    const p = planCitations([{ ...seatedSenate, instrument_id: 'US-PN-12-2023' }], [{ ...senateRoll, bill_number: 'PN 12' }]);
    expect(p.senate).toHaveLength(0);
    expect(p.unmapped[0].reason).toMatch(/LegiScan bill number/);
  });
  it('stops on a seat whose act the table contradicts', () => {
    const p = planCitations([{ ...seatedHouse, act: 'yea' }], [roll252]) /* roll252 lists PID as nay */;
    expect(p.crosscheck.disagree).toHaveLength(1);
    expect(p.house).toHaveLength(0);
  });
  it('counts a table not_voting against a seated yea as a disagreement, not a skip', () => {
    const r = roll({ positions: new Map([[PID, 'not_voting']]) });
    expect(planCitations([{ ...seatedHouse, act: 'yea' }], [r]).crosscheck.disagree).toHaveLength(1);
  });
  it('agrees present with a seated abstain', () => {
    const r = roll({ positions: new Map([[PID, 'present']]) });
    const p = planCitations([{ ...seatedHouse, act: 'abstain' }], [r]);
    expect(p.crosscheck).toEqual({ agree: 1, disagree: [] });
    expect(p.house).toHaveLength(1);
  });
  it('holds, never guesses, a vote with no single table roll call', () => {
    expect(planCitations([seatedHouse], []).unmapped[0].reason).toMatch(/no roll call/);
    const twin = roll({ external_vote_id: 'house-252-twin', rc: 999, yes: 218, no: 211 });
    expect(planCitations([seatedHouse], [roll252, twin]).unmapped[0].reason).toMatch(/2 roll calls fit/);
  });
  it('holds a person the table roll call does not list', () => {
    const p = planCitations([seatedHouse], [roll({ positions: new Map() })]);
    expect(p.unmapped[0].reason).toMatch(/no table position/);
    expect(p.house).toHaveLength(0);
  });
  it('holds a person with no bioguide id, never falling back to a surname', () => {
    const p = planCitations([{ ...seatedHouse, bioguide: null }], [roll252]);
    expect(p.unmapped[0].reason).toMatch(/no bioguide id/);
    expect(p.house).toHaveLength(0);
  });
  it('holds a Senate roll call before the 115th Congress', () => {
    const old = roll({ ...senateRoll, congress: '114', external_vote_id: 'legiscan-555' });
    const p = planCitations([{ ...seatedSenate, instrument_id: 'US-HJRES-44-2015' }], [old]);
    expect(p.unmapped[0].reason).toMatch(/before the 115th Congress/);
    expect(p.senate).toHaveLength(0);
  });
  it('holds a House roll call the table gives no roll number', () => {
    const p = planCitations([seatedHouse], [roll({ rc: null, question: 'On Passage' })]);
    expect(p.unmapped[0].reason).toMatch(/no roll number/);
  });
  it('holds a Senate roll call whose table id is not a LegiScan id', () => {
    const p = planCitations([seatedSenate], [{ ...senateRoll, external_vote_id: 'voteview-123' }]);
    expect(p.unmapped[0].reason).toMatch(/not a LegiScan id/);
  });
  it("finds a senator's earlier House vote by the roll call, and cites it as House", () => {
    const r = roll({ positions: new Map([[SEN, 'nay']]) });
    const p = planCitations([{ ...seatedSenate, date: '2023-06-13', act: 'nay', yes: 219, no: 210 }], [r]);
    expect(p.house[0].url).toBe('https://clerk.house.gov/evs/2023/roll252.xml');
    expect(p.senate).toHaveLength(0);
  });
  it('lists one Senate pair once when two findings point to it', () => {
    const p = planCitations([seatedSenate, { ...seatedSenate, motion: 'passage' }], [senateRoll]);
    expect(p.senate).toHaveLength(1);
  });
});

const GOV = 'https://www.govinfo.gov/content/pkg/BILLS-118hjres44enr/html/BILLS-118hjres44enr.htm';
const act = (over: Partial<PageAct>): PageAct => ({
  full_name: 'Pat Example', page: GOV, act: 'nay', instrument_id: 'US-HJRES-44-2023', lined: true, senate: false, ...over,
});

describe('pageDecisions', () => {
  it('uncites a page whose House votes are all lined', () => {
    const d = pageDecisions([act({}), act({ act: 'yea', instrument_id: 'US-HR-2-2023' })], new Set());
    expect(d.uncite).toEqual([{ full_name: 'Pat Example', page: GOV }]);
    expect(d.blocking).toEqual([]);
  });
  it('keeps the page when a cosponsorship on it has no line', () => {
    const d = pageDecisions([act({}), act({ act: 'cosponsor', lined: false })], new Set());
    expect(d.uncite).toEqual([]);
  });
  it('blocks the LegiScan merge on a page with a Senate pair and a held House vote', () => {
    const d = pageDecisions([act({ act: 'yea', lined: false, senate: true }), act({ lined: false })], new Set());
    expect(d.uncite).toEqual([]);
    expect(d.blocking).toEqual([{ full_name: 'Pat Example', entry: { url: GOV, official: GOV, act: 'nay', instrument: 'US-HJRES-44-2023' } }]);
    expect(d.blocking[0].entry.url).not.toMatch(/\/rollcall\//);
    expect(d.warn).toHaveLength(1);
  });
  it('emits no blocking entry when every act on a Senate page is a pair or a line', () => {
    const d = pageDecisions([act({ act: 'yea', lined: false, senate: true }), act({})], new Set());
    expect(d).toEqual({ uncite: [], blocking: [], warn: [], hold: [] });
  });
  it('keeps a page with only lined House votes when evidence.csv holds another snippet for it', () => {
    const d = pageDecisions([act({})], new Set([`Pat Example\u0000${GOV}`]));
    expect(d.uncite).toEqual([]);
  });
});

describe('markActs and the blocking entries', () => {
  const held = { ...seatedHouse, motion: 'motion to recommit' }; // held before planning: no single store roll call
  it('lists the seated votes that became Senate pairs, before the pairs are deduped', () => {
    const p = planCitations([seatedSenate, { ...seatedSenate, motion: 'passage' }], [senateRoll]);
    expect(p.senateVotes.map(voteKey)).toEqual([voteKey(seatedSenate), voteKey({ ...seatedSenate, motion: 'passage' })]);
  });
  it('marks senate only for a vote that became a pair; a vote held before planning is open', () => {
    const onPage = [
      { full_name: 'Pat Example', page: GOV, act: 'yea', instrument_id: seatedSenate.instrument_id, key: voteKey(seatedSenate) },
      { full_name: 'Pat Example', page: GOV, act: 'nay', instrument_id: held.instrument_id, key: voteKey(held) },
    ];
    const acts = markActs(onPage, new Set(), new Set([voteKey(seatedSenate)]));
    expect(acts.map((a) => [a.lined, a.senate])).toEqual([[false, true], [false, false]]);
    expect(pageDecisions(acts, new Set()).blocking).toEqual([
      { full_name: 'Pat Example', entry: { url: GOV, official: GOV, act: 'nay', instrument: held.instrument_id } },
    ]);
  });
  it('marks a lined House vote lined, and an authorship (no key) open', () => {
    const acts = markActs([
      { full_name: 'Pat Example', page: GOV, act: 'nay', instrument_id: seatedHouse.instrument_id, key: voteKey(seatedHouse) },
      { full_name: 'Pat Example', page: GOV, act: 'author', instrument_id: 'US-HR-9-2023', key: null },
    ], new Set([voteKey(seatedHouse)]), new Set());
    expect(acts.map((a) => [a.lined, a.senate])).toEqual([[true, false], [false, false]]);
  });
  it('holds a cited LegiScan roll-call page that needs blocking, instead of a blocking entry', () => {
    const LS = 'https://legiscan.com/US/rollcall/HJRES44/id/1343990';
    const d = pageDecisions([act({ page: LS, act: 'yea', lined: false, senate: true }), act({ page: LS, lined: false })], new Set());
    expect(d.blocking).toEqual([]);
    expect(d.hold).toEqual([{ full_name: 'Pat Example', page: LS, why: expect.stringMatching(/LegiScan roll call/) }]);
    expect(d.uncite).toEqual([]);
  });
});

describe('findStoreVote', () => {
  const v = (over: Partial<Vote>): Vote => ({
    date: '2025-04-10', body: 'US House', motion: 'final passage (On Passage)', kind: 'roll-call', yes: 220, no: 208, members: [], ...over,
  });
  const free = { date: '2025-04-10', motion: 'On Passage, H.R. 22, SAVE Act (House roll call 102; passed 220-208)', note: '' };
  it('takes the vote whose motion matches exactly', () => {
    const votes = [v({}), v({ motion: 'motion to recommit', yes: 200, no: 228 })];
    expect(findStoreVote(votes, { date: '2025-04-10', motion: 'motion to recommit' })?.yes).toBe(200);
  });
  it('takes the one store vote of that date when a free-text motion matches none', () => {
    expect(findStoreVote([v({}), v({ date: '2025-04-11', motion: 'other' })], free)?.yes).toBe(220);
  });
  it('holds a free-text motion when that date has several store votes, or none', () => {
    expect(findStoreVote([v({}), v({ motion: 'motion to recommit' })], free)).toBeNull();
    expect(findStoreVote([v({ date: '2025-04-11' })], free)).toBeNull();
  });
  it('does not fall back to a date whose one store vote is not a roll call', () => {
    expect(findStoreVote([v({ kind: 'action-item' })], free)).toBeNull();
  });
  it('narrows two exact-motion votes by the body the note names', () => {
    const votes = [v({}), v({ body: 'US Senate', yes: 51, no: 49 })];
    expect(findStoreVote(votes, { date: '2025-04-10', motion: 'final passage (On Passage)', note: 'US Senate, final passage …' })?.yes).toBe(51);
  });
});
