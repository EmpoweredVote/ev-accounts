import { describe, it, expect } from 'vitest';
import {
  isRevisorBillUrl,
  parseRevisorAuthorLinks,
  lrlNameFromHtml,
  lrlNameForms,
  lrlNameMatches,
  createRevisorAuthorCheck,
} from './mnRevisorAuthors.js';
import { verifyEvidence } from './researchVerifier.js';

const BILL = 'https://www.revisor.mn.gov/bills/94/2026/0/HF/3402?body=House';
const SENATE_BILL = 'https://www.revisor.mn.gov/bills/bill.php?b=Senate&f=SF0180&ssn=0&y=2023';

// The shape of a real Revisor page (2026 HF 3402), cut down. Names in the actions table must not count.
const billHtml = `<html><body>
<h2>Authors <span class="author_count">(5)</span></h2>
<div class="author"><ul>
  <li><a href="https://www.house.mn.gov/members/profile/15576">Lee, K.</a>; </li>
  <li><a href="https://www.house.mn.gov/members/profile/15636">Johnson, P.</a>; </li>
  <li><a href="https://www.house.mn.gov/members/profile/15606">Smith</a>; </li>
  <li><a href="https://www.house.mn.gov/members/profile/15611">Hill</a>; </li>
  <li><a href="https://www.house.mn.gov/members/profile/15652">Lee, X.</a></li>
</ul></div>
<h2>Actions</h2><ul><li><a href="https://www.house.mn.gov/members/profile/15999">Jones</a> added as author</li></ul>
</body></html>`;

const senateHtml = `<h2>Authors (2)</h2><ul>
  <li><a href="https://www.mnsenate.gov/members/member_bio.html?leg_id=15395">Green</a>; </li>
  <li><a href="https://www.mnsenate.gov/members/member_bio.html?leg_id=15485">Johnson</a></li></ul>`;

const lrl: Record<string, string> = {
  '15576': 'Liz Lee', '15636': 'Peter "Pete" Johnson', '15606': 'Andrew "Andy" Smith', '15611': 'Josiah Hill',
  '15652': 'Xp Lee', '15999': 'Katie Jones', '15395': 'Steve Green', '15485': 'Mark T. Johnson',
  '15301': 'Paul H. Anderson', '14999': 'Paul T. Anderson',
};
const lrlPage = (name: string) => `<html><head><title>${name.replace(/"/g, '&quot;')} - Legislator Record - Minnesota Legislators Past &amp; Present</title></head></html>`;

function fakeFetch(pages: Record<string, string>) {
  const calls: string[] = [];
  const fn = async (url: string) => {
    calls.push(url);
    const id = /fulldetail\?ID=(\d+)/.exec(url)?.[1];
    if (id && lrl[id]) return lrlPage(lrl[id]);
    if (pages[url]) return pages[url];
    throw new Error('HTTP 404');
  };
  return { fn, calls };
}

describe('mnRevisorAuthors', () => {
  it('knows a Revisor bill page', () => {
    expect(isRevisorBillUrl(BILL)).toBe(true);
    expect(isRevisorBillUrl(SENATE_BILL)).toBe(true);
    expect(isRevisorBillUrl('https://www.revisor.mn.gov/statutes/cite/624.714')).toBe(false);
    expect(isRevisorBillUrl('https://example.com/bills/1')).toBe(false);
  });

  it('reads only the Authors block', () => {
    const links = parseRevisorAuthorLinks(billHtml);
    expect(links.map((l) => l.label)).toEqual(['Lee, K.', 'Johnson, P.', 'Smith', 'Hill', 'Lee, X.']);
    expect(links[0]).toEqual({ label: 'Lee, K.', chamber: 'house', id: '15576' });
    expect(parseRevisorAuthorLinks(senateHtml).map((l) => [l.chamber, l.id])).toEqual([['senate', '15395'], ['senate', '15485']]);
  });

  it('reads the LRL record title and its nickname forms', () => {
    expect(lrlNameFromHtml(lrlPage('Andrew "Andy" Smith'))).toBe('Andrew "Andy" Smith');
    expect(lrlNameForms('Patricia "Patti, Pat" Anderson')).toEqual(['Patricia Anderson', 'Patti Anderson', 'Pat Anderson']);
    expect(lrlNameFromHtml('<title>Minnesota Senate</title>')).toBeNull();
  });

  it('never drops a middle initial', () => {
    expect(lrlNameMatches('Mark T. Johnson', { fullName: 'Mark T. Johnson', lastName: 'Johnson' })).toBe(true);
    expect(lrlNameMatches('Paul H. Anderson', { fullName: 'Paul Anderson', lastName: 'Anderson' })).toBe(false);
    expect(lrlNameMatches('Paul T. Anderson', { fullName: 'Paul Anderson', lastName: 'Anderson' })).toBe(false);
    expect(lrlNameMatches('Paul H. Anderson', { fullName: 'Paul Anderson', lastName: 'Anderson', aliases: ['Paul H. Anderson'] })).toBe(true);
  });

  it('accepts the linked author and refuses a namesake', async () => {
    const { fn } = fakeFetch({ [BILL]: billHtml, [SENATE_BILL]: senateHtml });
    const check = createRevisorAuthorCheck(fn);
    expect(await check(BILL, { fullName: 'Liz Lee', lastName: 'Lee' })).toBe(true); // printed "Lee, K."
    expect(await check(BILL, { fullName: 'Xp Lee', lastName: 'Lee' })).toBe(true);
    expect(await check(BILL, { fullName: 'Fue Lee', lastName: 'Lee' })).toBe(false); // not an author here
    expect(await check(BILL, { fullName: 'Pete Johnson', lastName: 'Johnson' })).toBe(true);
    expect(await check(BILL, { fullName: 'Andy Smith', lastName: 'Smith' })).toBe(true);
    expect(await check(BILL, { fullName: 'Katie Jones', lastName: 'Jones' })).toBe(false); // actions table only
    expect(await check(SENATE_BILL, { fullName: 'Mark T. Johnson', lastName: 'Johnson' })).toBe(true);
    expect(await check(SENATE_BILL, { fullName: 'Pete Johnson', lastName: 'Johnson' })).toBe(false);
  });

  it('caches pages and member records, and answers false on a fetch failure', async () => {
    const { fn, calls } = fakeFetch({ [BILL]: billHtml });
    const check = createRevisorAuthorCheck(fn);
    await check(BILL, { fullName: 'Liz Lee', lastName: 'Lee' });
    await check(BILL, { fullName: 'Liz Lee', lastName: 'Lee' });
    expect(calls.filter((u) => u === BILL)).toHaveLength(1);
    expect(await check('https://www.revisor.mn.gov/bills/94/2025/0/HF/1?body=House', { fullName: 'Liz Lee', lastName: 'Lee' })).toBe(false);
    expect(await check('https://example.com/x', { fullName: 'Liz Lee', lastName: 'Lee' })).toBe(false);
  });

  it('with a stored LRL id, compares ids and reads no name or LRL record (CA_0401)', async () => {
    const { fn, calls } = fakeFetch({ [BILL]: billHtml, [SENATE_BILL]: senateHtml });
    const check = createRevisorAuthorCheck(fn);
    // A wrong family name on our record does not matter: the id decides.
    expect(await check(BILL, { fullName: 'Liz Lee', lastName: 'Nobody', memberIds: { 'mn-lrl': ['15576'] } })).toBe(true);
    expect(await check(SENATE_BILL, { fullName: 'Mark T. Johnson', lastName: 'Johnson', memberIds: { 'mn-lrl': ['15485'] } })).toBe(true);
    expect(calls.some((u) => u.includes('fulldetail'))).toBe(false);
  });

  it('a stored id not on the page is a firm no, even when the name path would say yes', async () => {
    const { fn } = fakeFetch({ [BILL]: billHtml });
    const check = createRevisorAuthorCheck(fn);
    // Name path accepts Liz Lee (LRL 15576 is titled "Liz Lee"); a different stored id must not fall through.
    expect(await check(BILL, { fullName: 'Liz Lee', lastName: 'Lee', memberIds: { 'mn-lrl': ['15999'] } })).toBe(false);
    // Rep. Paul H. Anderson (15301) is not credited with a bill authored by former Sen. Paul T. Anderson (14999).
    const ptaBill = 'https://www.revisor.mn.gov/bills/bill.php?b=Senate&f=SF0001&ssn=0&y=2009';
    const { fn: fn2 } = fakeFetch({ [ptaBill]: `<h2>Authors (1)</h2><ul><li><a href="https://www.mnsenate.gov/members/member_bio.html?leg_id=14999">Anderson</a></li></ul>` });
    expect(await createRevisorAuthorCheck(fn2)(ptaBill, { fullName: 'Paul Anderson', lastName: 'Anderson', memberIds: { 'mn-lrl': ['15301'] } })).toBe(false);
  });

  it('other id types do not switch the check to the id path', async () => {
    const { fn } = fakeFetch({ [BILL]: billHtml });
    const check = createRevisorAuthorCheck(fn);
    expect(await check(BILL, { fullName: 'Liz Lee', lastName: 'Lee', memberIds: { legiscan: ['1'] } })).toBe(true);
  });
});

describe('verifyEvidence memberLinkCheck', () => {
  const authorList = 'Jordan ; Moller ; Greenman ; Lee, K. ; Bahner ; Curran ; Hollins ; Johnson, P. ; Pinto ; Rehm ; Finke ; '
    + 'Feist ; Clardy ; Berg ; Klevorn ; Greene ; Acomb ; Pursell ; Coulter ; Smith ; Hicks ; Kozlowski ; Keeler ; Falconer ; '
    + 'Frazier ; Bierman ; Howard ; Hill ; Liebling ; Noor ; Luger-Nikolai ; Lee, X. ; Youakim';
  const pageText = `Authors (33) ${authorList} Actions Separated Chronological House 02/17/2026 Introduction and first reading`;
  const run = (memberLinkCheck?: (u: string, n: { fullName: string }) => Promise<boolean>) => verifyEvidence({
    stanceRows: [{ full_name: 'Liz Lee', topic_key: 'gun-policy', value: 2, source_urls: [BILL] } as never],
    evidenceRows: [{ full_name: 'Liz Lee', topic_key: 'gun-policy', source_url: BILL, snippet: authorList, snippet_index: 1 } as never],
    fetcher: async () => ({ ok: true, text: pageText }),
    threshold: 1,
    politicianNames: { 'Liz Lee': { fullName: 'Liz Lee', lastName: 'Lee' } },
    memberLinkCheck,
  });

  it('without the check, a common family name with no title verifies nothing', async () => {
    const r = await run();
    expect(r.pushable).toHaveLength(0);
    expect(r.needsReResearch[0].failedSources[0].snippets[0].verdict.verdict).toBe('name_not_present');
  });

  it('with the check, the linked author verifies', async () => {
    const r = await run(async (u, n) => u === BILL && n.fullName === 'Liz Lee');
    expect(r.pushable).toHaveLength(1);
    expect(r.pushable[0].verifiedSources[0].snippets[0].verdict.verdict).toBe('verified');
  });

  it('a check that says no leaves the source failed', async () => {
    const r = await run(async () => false);
    expect(r.pushable).toHaveLength(0);
  });
});
