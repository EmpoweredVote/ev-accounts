import { describe, expect, it } from 'vitest';
import {
  congressStartYear, legiscanBillNumber, parseSenateVoteUrl, pickLegiscanRollCall, voteviewRow,
} from './senateRollCall.js';
import { createLegiscanRecordFetcher, legiscanLinesFor, verifyLegiscanLine, type LegiscanQuery } from './legiscanEvidence.js';
import { namesParty } from './partyLabels.js';

describe('parseSenateVoteUrl', () => {
  it('reads congress, session and vote from the page and the XML file', () => {
    expect(parseSenateVoteUrl('https://www.senate.gov/legislative/LIS/roll_call_votes/vote1192/vote_119_2_00057.htm'))
      .toEqual({ congress: 119, session: 2, vote: 57 });
    expect(parseSenateVoteUrl('https://www.senate.gov/legislative/LIS/roll_call_votes/vote1171/vote_117_1_00420.xml'))
      .toEqual({ congress: 117, session: 1, vote: 420 });
    expect(parseSenateVoteUrl('https://senate.gov/legislative/LIS/roll_call_lists/vote1101/vote_110_1_00007.htm?x=1'))
      .toEqual({ congress: 110, session: 1, vote: 7 });
  });
  it('refuses every other senate.gov page', () => {
    expect(parseSenateVoteUrl('https://www.senate.gov/legislative/LIS/roll_call_lists/vote_menu_119_1.xml')).toBeNull();
    expect(parseSenateVoteUrl('https://www.vanhollen.senate.gov/news/press-releases/x')).toBeNull();
    expect(parseSenateVoteUrl('https://legiscan.com/US/rollcall/SB5/id/1472537')).toBeNull();
  });
});

describe('Voteview to LegiScan', () => {
  it('names the year a Congress began', () => {
    expect(congressStartYear(119)).toBe(2025);
    expect(congressStartYear(117)).toBe(2021);
  });
  it('maps Voteview bill numbers to LegiScan, and nothing else', () => {
    expect(legiscanBillNumber('S2747')).toBe('SB2747');
    expect(legiscanBillNumber('SCONRES33')).toBe('SCR33');
    expect(legiscanBillNumber('HR22')).toBe('HB22');
    expect(legiscanBillNumber('HRES12')).toBe('HR12');
    expect(legiscanBillNumber('SJRES7')).toBe('SJR7');
    expect(legiscanBillNumber('PN123')).toBeNull();
    expect(legiscanBillNumber('')).toBeNull();
  });
  it('finds the Voteview row by session and clerk roll number', () => {
    const rows = [
      { session: 1, clerk_rollnumber: 57, date: '2025-02-01', bill_number: 'S1' },
      { session: 2, clerk_rollnumber: 57, date: '2026-03-17', bill_number: 'S1383' },
    ];
    expect(voteviewRow(rows, { congress: 119, session: 2, vote: 57 })?.bill_number).toBe('S1383');
    expect(voteviewRow(rows, { congress: 119, session: 2, vote: 58 })).toBeNull();
  });
  it('picks the one Senate roll call with that date and RC number', () => {
    const bill = { votes: [
      { chamber: 'S', date: '2025-01-20', desc: 'On the Amendment S.Amdt. 8 to S. 5 RC# 6', url: 'six' },
      { chamber: 'S', date: '2025-01-20', desc: 'On Passage of the Bill S. 5 RC# 7', url: 'seven' },
      { chamber: 'H', date: '2025-01-22', desc: 'On Passage RC# 7', url: 'house' },
    ] };
    expect(pickLegiscanRollCall(bill, '2025-01-20', 7)?.url).toBe('seven');
    expect(pickLegiscanRollCall(bill, '2025-01-22', 7)).toBeNull(); // the House roll call is not a Senate vote
    expect(pickLegiscanRollCall(bill, '2025-01-21', 7)).toBeNull();
    expect(pickLegiscanRollCall({ votes: [bill.votes[1], bill.votes[1]] }, '2025-01-20', 7)).toBeNull();
    expect(pickLegiscanRollCall({}, '2025-01-20', 7)).toBeNull();
  });
});

describe('a US Senate roll call through the LegiScan lane', () => {
  // Shaped like LegiScan's US answers for S. 5 (119th), roll call 1472537, party fields included.
  const SESSION = { session_id: 2199, state_id: 52, year_start: 2025, year_end: 2026, special: 0, session_name: '119th Congress' };
  const URL = 'https://legiscan.com/US/rollcall/SB5/id/1472537';
  const senator = (people_id: number, first: string, last: string, party: string) => ({
    people_id, name: `${first} ${last}`, first_name: first, middle_name: '', last_name: last, suffix: '', nickname: '',
    party, party_id: party === 'R' ? '2' : '1', role: 'Sen', district: 'SD-PA',
  });
  const query: LegiscanQuery = async (op) => {
    switch (op) {
      case 'getRollCall': return { status: 'OK', roll_call: {
        roll_call_id: 1472537, bill_id: 1903351, date: '2025-01-20', desc: 'On Passage of the Bill S. 5 RC# 7',
        yea: 64, nay: 35, chamber: 'S', votes: [
          { people_id: 1, vote_text: 'Yea' }, { people_id: 2, vote_text: 'Yea' }, { people_id: 3, vote_text: 'Nay' }] } };
      case 'getBill': return { status: 'OK', bill: { bill_id: 1903351, state: 'US', bill_number: 'SB5', session: SESSION } };
      case 'getSessionPeople': return { status: 'OK', sessionpeople: { session: SESSION, people: [
        senator(1, 'John', 'Fetterman', 'D'), senator(2, 'Jerry', 'Moran', 'R'), senator(3, 'Elizabeth', 'Warren', 'D')] } };
      default: throw new Error(`unexpected op ${op}`);
    }
  };

  it('writes and verifies each senator\'s line, and no record or line names a party', async () => {
    const text = await createLegiscanRecordFetcher(query)(URL);
    expect(text).not.toMatch(/party/i);
    expect(namesParty(text)).toBe(false);
    const cases: Array<[string, string, string]> = [['John Fetterman', 'Fetterman', 'Yea'], ['Jerry Moran', 'Moran', 'Yea'],
      ['Elizabeth Warren', 'Warren', 'Nay']];
    for (const [fullName, lastName, vote] of cases) {
      const lines = legiscanLinesFor(URL, text, { fullName, lastName });
      expect(lines).toEqual([
        `LegiScan US 119th Congress SB5, roll call 1472537 (Senate, 2025-01-20, "On Passage of the Bill S. 5 RC# 7"): ${fullName} voted ${vote}.`]);
      expect(namesParty(lines[0])).toBe(false);
      expect(verifyLegiscanLine(lines[0], URL, text, { fullName, lastName }).verdict).toBe('verified');
    }
  });
});
