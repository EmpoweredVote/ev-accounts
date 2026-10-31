import { describe, expect, it } from 'vitest';
import {
  createLegiscanRecordFetcher, formatLegiscanLine, isLegiscanUrl, legiscanLinesFor, parseLegiscanLine, verifyLegiscanLine,
  withLegiscanRecords, type LegiscanQuery,
} from './legiscanEvidence.js';
import { verifyEvidence, type EvidenceRow, type PageFetcher, type StanceRow } from './researchVerifier.js';

const BILL_URL = 'https://legiscan.com/TX/bill/HB5337/2025';
const RC_URL = 'https://legiscan.com/TX/rollcall/SB16/id/1532789';
const SPECIAL_URL = 'https://legiscan.com/TX/bill/HB5337/2025/X1';
const SESSION = { session_id: 2160, state_id: 43, year_start: 2025, year_end: 2026, special: 0, session_name: '89th Legislature Regular Session' };
const person = (people_id: number, first: string, last: string, extra: Record<string, unknown> = {}) => ({
  people_id, name: `${first} ${last}`, first_name: first, middle_name: '', last_name: last, suffix: '', nickname: '',
  // Shaped like LegiScan's records, party fields included: they must never survive the fetcher.
  party: 'R', party_id: '2', role: 'Rep', district: 'HD-001', ...extra,
});

// Answers for a fake LegiScan API, shaped like getSessionList / getMasterListRaw / getBill /
// getRollCall / getSessionPeople responses.
function fakeApi(): { query: LegiscanQuery; calls: string[] } {
  const calls: string[] = [];
  const special = { ...SESSION, session_id: 2221, special: 1, year_end: 2025, session_name: '89th Legislature 1st Special Session' };
  const bills: Record<number, unknown> = {
    1916334: { bill_id: 1916334, state: 'TX', bill_number: 'HB5337', session: SESSION, url: BILL_URL,
      state_link: 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB5337',
      sponsors: [
        { ...person(24086, 'Carrie', 'Isaac'), sponsor_type_id: 1, sponsor_order: 1, committee_sponsor: 0 },
        { ...person(5848, 'Gary', 'Gates'), sponsor_type_id: 2, sponsor_order: 2, committee_sponsor: 0 },
        { ...person(9001, 'Terri', 'Leo-Wilson'), sponsor_type_id: 2, sponsor_order: 3, committee_sponsor: 0 },
        { ...person(9002, 'John', 'Bucy', { suffix: 'III' }), sponsor_type_id: 2, sponsor_order: 4, committee_sponsor: 0 },
        // NC records, 2026-10-30: a two-word last_name printed as one ("Jennifer Balkcom"), and a member
        // listed under the given name he goes by ("A. Reece Pyrtle, Jr." in our roster).
        { ...person(24196, 'Jennifer', 'Capps Balkcom', { name: 'Jennifer Balkcom' }), sponsor_type_id: 2, sponsor_order: 5, committee_sponsor: 0 },
        { ...person(22946, 'Reece', 'Pyrtle'), sponsor_type_id: 2, sponsor_order: 6, committee_sponsor: 0 },
      ] },
    2000102: { bill_id: 2000102, state: 'TX', bill_number: 'SB16', session: SESSION, url: 'https://legiscan.com/TX/bill/SB16/2025', sponsors: [] },
    2100001: { bill_id: 2100001, state: 'TX', bill_number: 'HB5337', session: special, url: SPECIAL_URL, sponsors: [
      { ...person(5848, 'Gary', 'Gates'), sponsor_type_id: 1, sponsor_order: 1, committee_sponsor: 0 }] },
  };
  const query: LegiscanQuery = async (op, params) => {
    calls.push(`${op}:${JSON.stringify(params)}`);
    switch (op) {
      case 'getSessionList': return { status: 'OK', sessions: [SESSION, special, { ...SESSION, session_id: 2003, year_start: 2023 }] };
      case 'getMasterListRaw':
        return { status: 'OK', masterlist: params.id === '2160'
          ? { session: SESSION, 0: { bill_id: 1916334, number: 'HB5337' }, 1: { bill_id: 2000102, number: 'SB16' } }
          : { session: special, 0: { bill_id: 2100001, number: 'HB5337' } } };
      case 'getBill': return { status: 'OK', bill: bills[Number(params.id)] };
      case 'getRollCall': return { status: 'OK', roll_call: {
        roll_call_id: 1532789, bill_id: 2000102, date: '2025-04-01', desc: 'Read 3rd time', yea: 20, nay: 11, nv: 0,
        absent: 0, total: 31, passed: 1, chamber: 'S', chamber_id: 92,
        votes: [{ people_id: 11013, vote_id: 1, vote_text: 'Yea' }, { people_id: 11020, vote_id: 2, vote_text: 'Nay' }] } };
      case 'getSessionPeople': return { status: 'OK', sessionpeople: { session: SESSION, people: [
        person(11013, 'Charles', 'Perry', { role: 'Sen' }), person(11020, 'Sarah', 'Eckhardt', { role: 'Sen' })] } };
      default: throw new Error(`unexpected op ${op}`);
    }
  };
  return { query, calls };
}

const SPONSOR_LINE = 'LegiScan TX 89th Legislature Regular Session HB5337: Gary Gates is listed as a cosponsor.';
const VOTE_LINE = 'LegiScan TX 89th Legislature Regular Session SB16, roll call 1532789 (Senate, 2025-04-01, "Read 3rd time"): Sarah Eckhardt voted Nay.';

describe('legiscanEvidence lines', () => {
  it('formats and parses both line kinds, which print no party', () => {
    const s = parseLegiscanLine(SPONSOR_LINE)!;
    expect(s).toEqual({ kind: 'sponsor', state: 'TX', session: '89th Legislature Regular Session', bill: 'HB5337',
      name: 'Gary Gates', role: 'cosponsor' });
    expect(formatLegiscanLine(s)).toBe(SPONSOR_LINE);
    const v = parseLegiscanLine(VOTE_LINE)!;
    expect(v).toEqual({ kind: 'vote', state: 'TX', session: '89th Legislature Regular Session', bill: 'SB16',
      rollCallId: 1532789, chamber: 'Senate', date: '2025-04-01', motion: 'Read 3rd time', name: 'Sarah Eckhardt', vote: 'Nay' });
    expect(formatLegiscanLine(v)).toBe(VOTE_LINE);
    for (const l of [SPONSOR_LINE, VOTE_LINE]) expect(l).not.toMatch(/\b(Republican|Democrat\w*|Independent)\b|\((R|D|I)\)|\bparty\b/i);
  });
  it('parses lines on a letter-named joint resolution (MI HJRB, 2026-10-30)', () => {
    const l = 'LegiScan MI 103rd Legislature HJRB, roll call 1602971 (House, 2025-05-01, "House Third Reading: Not Adopted Roll Call #79"): Mike Harris voted Yea.';
    expect(parseLegiscanLine(l)).toMatchObject({ kind: 'vote', bill: 'HJRB', rollCallId: 1602971, name: 'Mike Harris', vote: 'Yea' });
    expect(parseLegiscanLine('LegiScan MI 103rd Legislature HJRB: Karl Bohnak is listed as a cosponsor.')).toMatchObject({ kind: 'sponsor', bill: 'HJRB' });
  });
  it('parses a motion that itself holds parentheses', () => {
    const l = VOTE_LINE.replace('"Read 3rd time"', '"Senate concurs in House amendment(s)"');
    expect(parseLegiscanLine(l)).toMatchObject({ motion: 'Senate concurs in House amendment(s)', vote: 'Nay' });
  });
  it('recognises LegiScan bill and roll-call URLs only, never the API', () => {
    expect(isLegiscanUrl(BILL_URL)).toBe(true);
    expect(isLegiscanUrl(RC_URL)).toBe(true);
    expect(isLegiscanUrl('https://legiscan.com/MI/rollcall/HJRB/id/1602971')).toBe(true);
    expect(isLegiscanUrl('https://legiscan.com/MI/bill/HJRB/2025')).toBe(true);
    expect(isLegiscanUrl('https://api.legiscan.com/?key=x&op=getBill&id=1')).toBe(false);
    expect(isLegiscanUrl('https://legiscan.com/TX/text/HB5337/id/3180471')).toBe(false);
    expect(isLegiscanUrl('https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB5337')).toBe(false);
  });
});

describe('createLegiscanRecordFetcher', () => {
  it('resolves a bill URL through the session list and master list, and drops every party field', async () => {
    const { query, calls } = fakeApi();
    const text = await createLegiscanRecordFetcher(query)(BILL_URL);
    expect(text).not.toMatch(/party/i);
    const rec = JSON.parse(text);
    expect(rec.kind).toBe('bill');
    expect(rec.bills.map((b: { session_name: string }) => b.session_name)).toEqual(['89th Legislature Regular Session']);
    expect(calls.filter((c) => c.startsWith('getSessionList'))).toHaveLength(1);
  });
  it('never mixes a regular-session bill with a special-session bill of the same number', async () => {
    // Texas 2025 has an HB5337 in the regular session and another in the 1st special session.
    const f = createLegiscanRecordFetcher(fakeApi().query);
    expect(JSON.parse(await f(SPECIAL_URL)).bills.map((b: { session_name: string }) => b.session_name))
      .toEqual(['89th Legislature 1st Special Session']);
    await expect(f('https://legiscan.com/TX/bill/HB5337/2025/X9')).rejects.toThrow(/not found/);
  });
  it('caches the session list and master lists across URLs', async () => {
    const { query, calls } = fakeApi();
    const f = createLegiscanRecordFetcher(query);
    await f(BILL_URL);
    await f('https://legiscan.com/TX/bill/SB16/2025');
    expect(calls.filter((c) => c.startsWith('getSessionList'))).toHaveLength(1);
    // One master list: both URLs are regular-session pages, so the special session is never read.
    expect(calls.filter((c) => c.startsWith('getMasterListRaw'))).toHaveLength(1);
  });
  it('resolves a roll-call URL with the voters named from the session people list, no party', async () => {
    const { query } = fakeApi();
    const text = await createLegiscanRecordFetcher(query)(RC_URL);
    expect(text).not.toMatch(/party/i);
    const rec = JSON.parse(text);
    expect(rec).toMatchObject({ kind: 'rollcall', state: 'TX', bill_number: 'SB16', session_name: '89th Legislature Regular Session',
      roll_call_id: 1532789, chamber: 'S', date: '2025-04-01', desc: 'Read 3rd time' });
    expect(rec.votes).toContainEqual({ vote_text: 'Nay', person: expect.objectContaining({ name: 'Sarah Eckhardt' }) });
  });
  it('fails when the bill is not in any session that began that year', async () => {
    const { query } = fakeApi();
    await expect(createLegiscanRecordFetcher(query)('https://legiscan.com/TX/bill/HB9999/2025')).rejects.toThrow(/not found/);
  });
});

describe('verifyLegiscanLine', () => {
  const names = { fullName: 'Gary Gates', lastName: 'Gates' };
  async function record(url: string) { return createLegiscanRecordFetcher(fakeApi().query)(url); }

  it('verifies a sponsor line that matches the record', async () => {
    expect(verifyLegiscanLine(SPONSOR_LINE, BILL_URL, await record(BILL_URL), names).verdict).toBe('verified');
  });
  it('checks the session named in the line against the bill the URL names', async () => {
    const special = SPONSOR_LINE.replace('Regular Session', '1st Special Session').replace('a cosponsor', 'a primary sponsor');
    expect(verifyLegiscanLine(special, SPECIAL_URL, await record(SPECIAL_URL), names).verdict).toBe('verified');
    // The regular-session page does not hold the special-session bill.
    expect(verifyLegiscanLine(special, BILL_URL, await record(BILL_URL), names).verdict).toBe('snippet_not_found');
  });
  it('refuses a wrong role, bill, state or session', async () => {
    const rec = await record(BILL_URL);
    for (const bad of [
      SPONSOR_LINE.replace('a cosponsor', 'a primary sponsor'),
      SPONSOR_LINE.replace('HB5337', 'HB5338'),
      SPONSOR_LINE.replace('LegiScan TX', 'LegiScan OK'),
      SPONSOR_LINE.replace('89th', '88th'),
    ]) expect(verifyLegiscanLine(bad, BILL_URL, rec, names).verdict).toBe('snippet_not_found');
  });
  it("refuses a line about someone else, and a line whose name is not the politician's", async () => {
    const rec = await record(BILL_URL);
    expect(verifyLegiscanLine(SPONSOR_LINE, BILL_URL, rec, { fullName: 'Gary Gate', lastName: 'Gate' }).verdict).toBe('name_not_present');
    const isaac = 'LegiScan TX 89th Legislature Regular Session HB5337: Carrie Isaac is listed as a primary sponsor.';
    expect(verifyLegiscanLine(isaac, BILL_URL, rec, names).verdict).toBe('name_not_present');
  });
  it('accepts a hyphen, a suffix and a nickname the record spells differently', async () => {
    const rec = await record(BILL_URL);
    const leo = 'LegiScan TX 89th Legislature Regular Session HB5337: Terri Leo-Wilson is listed as a cosponsor.';
    expect(verifyLegiscanLine(leo, BILL_URL, rec, { fullName: 'Terri Leo Wilson', lastName: 'Leo Wilson' }).verdict).toBe('verified');
    const bucy = 'LegiScan TX 89th Legislature Regular Session HB5337: John Bucy is listed as a cosponsor.';
    expect(verifyLegiscanLine(bucy, BILL_URL, rec, { fullName: 'John Bucy III', lastName: 'Bucy' }).verdict).toBe('verified');
    expect(verifyLegiscanLine(bucy, BILL_URL, rec, { fullName: 'Jack Bucy III', lastName: 'Bucy' }).verdict).toBe('verified');
    expect(verifyLegiscanLine(bucy, BILL_URL, rec, { fullName: 'Mark Bucy', lastName: 'Bucy' }).verdict).toBe('name_not_present');
  });
  it('accepts the surname the record prints when its last_name holds two words', async () => {
    const rec = await record(BILL_URL);
    const line = 'LegiScan TX 89th Legislature Regular Session HB5337: Jennifer Balkcom is listed as a cosponsor.';
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'Jennifer Balkcom', lastName: 'Balkcom' }).verdict).toBe('verified');
    // The other word of the two is not her printed surname, and another first name still fails.
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'Jennifer Capps', lastName: 'Capps' }).verdict).toBe('name_not_present');
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'Janet Balkcom', lastName: 'Balkcom' }).verdict).toBe('name_not_present');
  });
  it('reads past a leading initial to the given name the person goes by', async () => {
    const rec = await record(BILL_URL);
    const line = 'LegiScan TX 89th Legislature Regular Session HB5337: Reece Pyrtle is listed as a cosponsor.';
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'A. Reece Pyrtle, Jr.', lastName: 'Pyrtle' }).verdict).toBe('verified');
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'A. Pyrtle', lastName: 'Pyrtle' }).verdict).toBe('name_not_present');
    expect(verifyLegiscanLine(line, BILL_URL, rec, { fullName: 'B. Ross Pyrtle', lastName: 'Pyrtle' }).verdict).toBe('name_not_present');
  });
  it('verifies a vote line field by field', async () => {
    const rec = await record(RC_URL);
    const sarah = { fullName: 'Sarah Eckhardt', lastName: 'Eckhardt' };
    expect(verifyLegiscanLine(VOTE_LINE, RC_URL, rec, sarah).verdict).toBe('verified');
    for (const bad of [
      VOTE_LINE.replace('voted Nay', 'voted Yea'),
      VOTE_LINE.replace('roll call 1532789', 'roll call 1532790'),
      VOTE_LINE.replace('Senate,', 'House,'),
      VOTE_LINE.replace('2025-04-01', '2025-04-02'),
      VOTE_LINE.replace('Read 3rd time', 'Read 2nd time'),
      VOTE_LINE.replace('SB16', 'SB17'),
    ]) expect(verifyLegiscanLine(bad, RC_URL, rec, sarah).verdict).toBe('snippet_not_found');
  });
  it('refuses a sponsor line on a roll-call URL and a vote line on a bill URL', async () => {
    expect(verifyLegiscanLine(SPONSOR_LINE, RC_URL, await record(RC_URL), names).verdict).toBe('snippet_not_found');
    expect(verifyLegiscanLine(VOTE_LINE, BILL_URL, await record(BILL_URL), { fullName: 'Sarah Eckhardt', lastName: 'Eckhardt' }).verdict)
      .toBe('snippet_not_found');
  });
});

describe('legiscanLinesFor', () => {
  it("writes the politician's line on the bill the URL names, and nothing for anyone else", async () => {
    const rec = await createLegiscanRecordFetcher(fakeApi().query)(BILL_URL);
    expect(legiscanLinesFor(BILL_URL, rec, { fullName: 'Gary Gates', lastName: 'Gates' })).toEqual([SPONSOR_LINE]);
    expect(legiscanLinesFor(BILL_URL, rec, { fullName: 'Ada Lovelace', lastName: 'Lovelace' })).toEqual([]);
  });
  it('writes the vote line on a roll call', async () => {
    const rec = await createLegiscanRecordFetcher(fakeApi().query)(RC_URL);
    expect(legiscanLinesFor(RC_URL, rec, { fullName: 'Sarah Eckhardt', lastName: 'Eckhardt' })).toEqual([VOTE_LINE]);
  });
});

describe('verifyEvidence with the LegiScan lane', () => {
  it('verifies the line through withLegiscanRecords and publishes the line itself', async () => {
    const base: PageFetcher = async () => ({ ok: false, reason: 'legiscan.com is behind a bot challenge' });
    const fetcher = withLegiscanRecords(base, createLegiscanRecordFetcher(fakeApi().query));
    const stance: StanceRow = { full_name: 'Gary Gates', politician_id: 'p1', topic_key: 'voting-rights', value: 5,
      reasoning: 'Cosponsor of HB 5337 (2025).', source_urls: [BILL_URL], evidence_type: 'record' };
    const ev: EvidenceRow = { full_name: 'Gary Gates', topic_key: 'voting-rights', source_url: BILL_URL, snippet: SPONSOR_LINE, snippet_index: 1 };
    const res = await verifyEvidence({ stanceRows: [stance], evidenceRows: [ev], fetcher, threshold: 1,
      politicianNames: { 'Gary Gates': { fullName: 'Gary Gates', lastName: 'Gates' } } });
    expect(res.pushable).toHaveLength(1);
    expect(res.pushable[0].verifiedSources[0].snippets[0].matchedSpan).toBe(SPONSOR_LINE);
  });
  it('leaves every other URL to the base fetcher', async () => {
    const base: PageFetcher = async (u) => ({ ok: true, text: `base:${u}` });
    const fetcher = withLegiscanRecords(base, async () => { throw new Error('not called'); });
    expect(await fetcher('https://example.org/a')).toEqual({ ok: true, text: 'base:https://example.org/a' });
  });
});
