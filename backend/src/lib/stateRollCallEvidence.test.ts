import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  isStateRollCallUrl, parseStateRollCallUrl, readStateRollCallHtml, renderStateRollCall, parseStateRollCallRender,
  parseStateRollCallLine, stateLabelFits, stateRollCallLinesFor, verifyStateRollCallLine, STATE_VOTES,
  readStateRollCallDocs, stateRollCallDocs, stateRollCallMinGapMs, fullNameLabelFits,
  explainMarylandVote, mdQuestionIsOnTheBill, pdfCellsBody, readStateRollCallRecord,
  explainKansasVote, ksQuestionIsOnTheBill, ksMemberName, parseKansasVoteUrl,
  explainColoradoVote, coQuestionIsOnTheBill, coMemberName, coMembers, coBillTag, parseColoradoVoteUrl,
  explainNorthDakotaVote, ndQuestionIsOnTheBill, ndMembers, ndMemberNames, parseNorthDakotaVoteUrl,
  explainNevadaVote, nvMemberName, nvVoteList, parseNevadaVoteUrl,
  explainCaliforniaVote, caQuestionIsOnTheBill, californiaVoteUrl, californiaBillId, isLocalStateRollCallUrl, parseCaliforniaVoteUrl,
  explainOregonVote, orQuestionIsOnTheBill, orTally, parseOregonVoteUrl, oregonVoteUrl, OR_DATA,
  explainMaineVote, meMajorityReport, meQuestionIsOnTheBill, meQuestionIsRead, parseMaineVoteUrl, pdfItemsBody, PDF_ITEMS_MARK,
  explainMinnesotaVote, mnQuestionIsOnTheBill, mnMembers, mnMemberNames, MN_LABEL_ALIASES, parseMinnesotaVoteUrl, pdfBodyFor,
  explainHawaiiVote, hawaiiFloorLine, hawaiiLabelMember, hawaiiMembers, hawaiiSeated, hawaiiVoteUrl, parseHawaiiVoteUrl, statePostbackOf, type HiMember,
} from './stateRollCallEvidence.js';
import { fetchStateRollCallText, renderStateRollCallHtml, resetStateRollCallPacing } from './adapters/stateRollCallAdapter.js';
import { ME_HOUSE_ROSTERS, ME_SENATE_LISTS, type MeHouseMember } from './maineLegislatureMembers.js';
import { verifyEvidence, type StanceRow } from './researchVerifier.js';

// Saved 2026-11-15 from le.utah.gov with the verifier's own user-agent. Neither page prints a party.
const page = (name: string): string =>
  readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}.html`, import.meta.url)), 'latin1');
const H_URL = 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=H';
const S_URL = 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=S';
const HOUSE = page('ut-2025GS-100-H');
const SENATE = page('ut-2025GS-100-S');
const render = (html: string, url: string): string => {
  const t = renderStateRollCallHtml(html, url);
  if (!t) throw new Error('the page did not read');
  return t;
};
/** Change one thing in a page, and fail the test when the change did not apply. */
const tamper = (html: string, from: string, to: string): string => {
  expect(html.includes(from)).toBe(true);
  const out = html.replace(from, to);
  expect(out).not.toBe(html);
  return out;
};
const SNIDER = 'Utah House roll call 100 (2025GS), HB 237 - 3rd Reading Final Passage (2025-01-30): Snider, C. voted Yea.';

describe('state roll-call pages — address', () => {
  it('knows a Utah floor roll-call page and nothing else', () => {
    expect(parseStateRollCallUrl(H_URL)).toEqual({ state: 'UT', stateName: 'Utah', chamber: 'House', session: '2025GS', rollNum: 100 });
    expect(parseStateRollCallUrl(S_URL)?.chamber).toBe('Senate');
    expect(isStateRollCallUrl('https://le.utah.gov/~2025/bills/static/HB0237.html')).toBe(false);
    expect(isStateRollCallUrl('https://le.utah.gov.example.com/DynaBill/svotes.jsp?sessionid=2025GS&voteid=100&house=H')).toBe(false);
    expect(isStateRollCallUrl('https://legiscan.com/UT/rollcall/HB0237/id/1')).toBe(false);
  });
});

describe('state roll-call pages — reading Utah', () => {
  it('reads the House page: bill, question, day and every member under the right heading', () => {
    const r = readStateRollCallHtml(HOUSE, H_URL);
    expect(r).toMatchObject({ bill: 'HB 237', question: '3rd Reading Final Passage', date: '2025-01-30', chamber: 'House' });
    expect([r?.groups.Yea.length, r?.groups.Nay.length, r?.groups['Absent or not voting'].length]).toEqual([71, 0, 4]);
    // Flattened text reads "Maloy, A. Cory Mauga, V.": only the table cells say where one name ends.
    expect(r?.groups.Yea).toContain('Maloy, A. Cory');
    expect(r?.groups.Yea).toContain('Mauga, V.');
    expect(r?.groups['Absent or not voting']).toEqual(['Bolinder, B.', 'Matthews, A.', 'Schultz, M.', 'Teuscher, J.']);
  });

  it('reads the Senate page, whose tally line says Ayes and Abs', () => {
    const r = readStateRollCallHtml(SENATE, S_URL);
    expect(r).toMatchObject({ bill: 'SB 1', date: '2025-01-29', chamber: 'Senate',
      question: '2nd Reading Passage on 2nd & 3rd Under suspension of the rules' });
    expect(r?.groups.Yea).toHaveLength(25);
    expect(r?.groups.Yea).toContain('Adams, J. Stuart');
  });

  it('reads a 2019 page that prints one member with no comma ("Strong M.A.")', () => {
    const url = 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2019GS&voteid=428&house=H';
    const r = readStateRollCallHtml(page('ut-2019GS-428-H'), url);
    expect(r).toMatchObject({ bill: 'HB 114', question: '3rd Reading Final Passage', date: '2019-02-22' });
    expect([r?.groups.Yea.length, r?.groups.Nay.length, r?.groups['Absent or not voting'].length]).toEqual([54, 16, 5]);
    expect(STATE_VOTES.flatMap((v) => r?.groups[v] ?? [])).toContain('Strong M.A.');
    const text = renderStateRollCall(r!);
    const [line] = stateRollCallLinesFor(url, text, 'Strong', 'Mark A. Strong');
    expect(line).toMatch(/Strong M\.A\. (voted Yea|voted Nay|was absent or not voting)\.$/);
    expect(verifyStateRollCallLine(line, url, text, 'Strong', 'Mark A. Strong').verdict).toBe('verified');
    expect(stateLabelFits('Strong M.A.', 'Strong', 'Mark A. Strong')).toBe(true);
    expect(stateLabelFits('Strong M.A.', 'Armstrong', 'Mary Armstrong')).toBe(false);
  });

  it('refuses a page with a cell that is not a member label', () => {
    expect(renderStateRollCallHtml(tamper(HOUSE, '>Bennion, G.<', '>Bennion<'), H_URL)).toBeNull();
  });

  it('render and parse are inverses, and the render prints no party', () => {
    for (const [html, url] of [[HOUSE, H_URL], [SENATE, S_URL]]) {
      const r = readStateRollCallHtml(html, url);
      expect(parseStateRollCallRender(renderStateRollCall(r!), url)).toEqual(r);
      expect(renderStateRollCall(r!)).not.toMatch(/republican|democrat|\([RD]\)/i);
    }
  });

  it('refuses a page whose heading count is not the number of members under it', () => {
    expect(renderStateRollCallHtml(tamper(HOUSE, 'Yeas - 71', 'Yeas - 70'), H_URL)).toBeNull();
  });
  it('refuses a page whose header tally is not the groups', () => {
    expect(renderStateRollCallHtml(tamper(HOUSE, '71 - 0 - 4,', '70 - 1 - 4,'), H_URL)).toBeNull();
  });
  it('refuses a page whose header and tally line agree with each other and not with the members listed', () => {
    // Both printed tallies are changed together, so only the comparison with the groups can catch it.
    const both = tamper(tamper(HOUSE, '71 - 0 - 4,', '70 - 1 - 4,'), 'Yeas 71 Nays 0 N/V 4', 'Yeas 70 Nays 1 N/V 4');
    expect(renderStateRollCallHtml(both, H_URL)).toBeNull();
  });
  it('refuses a page whose tally line is not the header', () => {
    expect(renderStateRollCallHtml(tamper(HOUSE, 'Yeas 71 Nays 0 N/V 4', 'Yeas 70 Nays 1 N/V 4'), H_URL)).toBeNull();
  });
  it('refuses a page with a member moved out of a group', () => {
    const cell = /<td><font face="Arial" size=-1>Bennion, G\.<\/font><\/td>/.exec(HOUSE)?.[0] ?? 'missing';
    expect(renderStateRollCallHtml(tamper(HOUSE, cell, ''), H_URL)).toBeNull();
  });
  it('refuses a House page fetched under a Senate address', () => {
    expect(renderStateRollCallHtml(HOUSE, H_URL.replace('house=H', 'house=S'))).toBeNull();
  });
  it('refuses a page whose calendar bill is not the header bill', () => {
    expect(renderStateRollCallHtml(tamper(HOUSE, '<center>1HB 237</center>', '<center>1HB 238</center>'), H_URL)).toBeNull();
  });
  it('refuses a voice vote, which lists no member', () => {
    const voice = '<body><b>HB0114 - - Passed on voice vote , 2/21/2019 3:41 PM</b><hr><center>HB 114</center><center>Self-defense Amendments</center><center>3rd Reading</center></body>';
    expect(renderStateRollCallHtml(voice, 'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2019GS&voteid=400&house=H')).toBeNull();
  });
});

describe('state roll-call pages — whose label', () => {
  it('fits a surname with an initial, a second given name, or a nickname', () => {
    expect(stateLabelFits('Snider, C.', 'Snider', 'Casey Snider')).toBe(true);
    expect(stateLabelFits('Adams, J. Stuart', 'Adams', 'Stuart Adams')).toBe(true);
    expect(stateLabelFits('Adams, J. Stuart', 'Adams', 'J. Stuart Adams')).toBe(true);
    expect(stateLabelFits('Maloy, A. Cory', 'Maloy', 'Cory Maloy')).toBe(true);
    expect(stateLabelFits('Shipp, R.P.', 'Shipp', 'Rex P. Shipp')).toBe(true);
    expect(stateLabelFits('Dailey-Provost, J.', 'Dailey-Provost', 'Jennifer Dailey-Provost')).toBe(true);
    expect(stateLabelFits('Ward, R.', 'Ward', 'Raymond "Ray" Ward')).toBe(true);
    // Maine 132nd House roll call 557 prints the family name without its apostrophe.
    expect(stateLabelFits('OHalloran, D.L.', "O'Halloran", "Dani O'Halloran")).toBe(true);
    expect(stateLabelFits("O'Halloran, D.L.", 'OHalloran', 'Dani OHalloran')).toBe(true);
    expect(stateLabelFits('OHalloran, D.L.', "O'Hara", "Dani O'Hara")).toBe(false);
    expect(stateLabelFits('Wilcox, R.', 'Wilcox', 'Ryan D. Wilcox, Jr.')).toBe(true);
    // An initial that is also a Roman numeral is an initial ("V" is not "the fifth").
    expect(stateLabelFits('Mauga, V.', 'Mauga', 'Verona Mauga')).toBe(true);
    expect(stateLabelFits('Peterson, V.', 'Peterson', 'Val L. Peterson')).toBe(true);
    expect(stateLabelFits('Ivory, I.', 'Ivory', 'Ida Ivory')).toBe(true);
    expect(stateLabelFits('Smith, J.', 'Smith', 'John Smith V')).toBe(true);
  });
  it('refuses another surname, another initial, and a printed given name that is not theirs', () => {
    expect(stateLabelFits('Snider, C.', 'Snyder', 'Casey Snyder')).toBe(false);
    expect(stateLabelFits('Miller, G.', 'Miller', 'Tracy Miller')).toBe(false);
    expect(stateLabelFits('Maloy, A. Cory', 'Maloy', 'Angela Maloy')).toBe(false);
    expect(stateLabelFits('Mr. Speaker', 'Schultz', 'Mike Schultz')).toBe(false);
  });
});

describe('state roll-call pages — the line', () => {
  const text = render(HOUSE, H_URL);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(H_URL, text, 'Snider', 'Casey Snider')).toEqual([SNIDER]);
    expect(verifyStateRollCallLine(SNIDER, H_URL, text, 'Snider', 'Casey Snider')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(stateRollCallLinesFor(H_URL, text, 'Bolinder', 'Bridger Bolinder')[0]).toMatch(/Bolinder, B\. was absent or not voting\.$/);
    expect(parseStateRollCallLine(SNIDER)).toMatchObject({ state: 'UT', vote: 'Yea', name: 'Snider, C.' });
  });

  it('refuses the line when the page lists the member under the other vote', () => {
    const cell = /<td><font face="Arial" size=-1><a [^>]*>Snider, C\.<\/a><\/font><\/td>/.exec(HOUSE)?.[0] ?? 'missing';
    let flipped = tamper(HOUSE, cell, '');
    flipped = tamper(flipped, 'Nays - 0</font></b><br><center><table><tr>', `Nays - 1</font></b><br><center><table><tr>${cell}`);
    flipped = tamper(tamper(tamper(flipped, 'Yeas - 71', 'Yeas - 70'), '71 - 0 - 4,', '70 - 1 - 4,'), 'Yeas 71 Nays 0 N/V 4', 'Yeas 70 Nays 1 N/V 4');
    const moved = render(flipped, H_URL);
    expect(moved).toContain('Nay (1): Snider, C.');
    expect(verifyStateRollCallLine(SNIDER, H_URL, moved, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
  });

  it('refuses a line whose vote, bill, day, question or roll-call number is not the page', () => {
    const bad = (line: string) => verifyStateRollCallLine(line, H_URL, text, 'Snider', 'Casey Snider').verdict;
    expect(bad(SNIDER.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(bad(SNIDER.replace('HB 237', 'HB 238'))).toBe('snippet_not_found');
    expect(bad(SNIDER.replace('2025-01-30', '2025-01-31'))).toBe('snippet_not_found');
    expect(bad(SNIDER.replace('Final Passage', 'Motion to Circle'))).toBe('snippet_not_found');
    expect(bad(SNIDER.replace('roll call 100', 'roll call 101'))).toBe('snippet_not_found');
    expect(bad(SNIDER.replace('Utah House', 'Utah Senate'))).toBe('snippet_not_found');
  });

  it('refuses the line on another roll call\'s address', () => {
    expect(verifyStateRollCallLine(SNIDER, H_URL.replace('voteid=100', 'voteid=101'), text, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
  });

  it('refuses a render that is not the roll call the address names, even when the line names that address', () => {
    // The line and the address agree (roll call 101; the Senate), so only the render's own heading can catch it.
    const url101 = H_URL.replace('voteid=100', 'voteid=101');
    expect(verifyStateRollCallLine(SNIDER.replace('roll call 100', 'roll call 101'), url101, text, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(SNIDER.replace('Utah House', 'Utah Senate'), S_URL, text, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(SNIDER.replace('(2025GS)', '(2024GS)'), H_URL.replace('2025GS', '2024GS'), text, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
  });

  it('refuses another member\'s vote as this person\'s', () => {
    expect(verifyStateRollCallLine(SNIDER, H_URL, text, 'Miller', 'Tracy Miller').verdict).toBe('name_not_present');
    expect(stateRollCallLinesFor(H_URL, text, 'Nobody', 'Nora Nobody')).toEqual([]);
  });

  it('gives no line, and verifies none, when two labels fit the person', () => {
    // "Peterson, K.", "Peterson, T." and "Peterson, V." are all on the page; a name with K and T given names fits two.
    expect(stateRollCallLinesFor(H_URL, text, 'Peterson', 'Karen Peterson')).toHaveLength(1);
    const twoFit = text.replace('Peterson, T.;', 'Peterson, K. Ann;');
    expect(twoFit).not.toBe(text);
    expect(stateRollCallLinesFor(H_URL, twoFit, 'Peterson', 'Karen Ann Peterson')).toEqual([]);
    const line = SNIDER.replace('Snider, C.', 'Peterson, K.');
    expect(verifyStateRollCallLine(line, H_URL, text, 'Peterson', 'Karen Ann Peterson').verdict).toBe('verified');
    expect(verifyStateRollCallLine(line, H_URL, twoFit, 'Peterson', 'Karen Ann Peterson').verdict).toBe('name_not_present');
  });

  it('never verifies against the page\'s plain text, where names run together', () => {
    const plain = 'Vote Status HB0237 Substitute 1 - - Passed 71 - 0 - 4, 1/30/2025 11:50 AM Yeas - 71 Abbott, N. Snider, C. Nays - 0';
    expect(verifyStateRollCallLine(SNIDER, H_URL, plain, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
  });
});

describe('state roll-call pages — the adapter and the verifier', () => {
  const html = (body: string) => async () => new Response(body, { status: 200, headers: { 'content-type': 'text/html;charset=ISO-8859-1' } });

  it('fetches with the caller\'s user-agent and renders the page', async () => {
    resetStateRollCallPacing();
    let ua = '';
    const t = await fetchStateRollCallText(H_URL, {
      userAgent: 'TestBot/1.0',
      fetchImpl: async (_u, init) => { ua = String((init?.headers as Record<string, string>)['user-agent']); return html(HOUSE)(); },
    });
    expect(ua).toBe('TestBot/1.0');
    expect(t).toBe(render(HOUSE, H_URL));
  });

  it('leaves the site\'s Crawl-delay between two requests, and waits out a 429 before asking again', async () => {
    resetStateRollCallPacing();
    let clock = 1_000_000;
    const waits: number[] = [];
    const deps = { now: () => clock, sleep: async (ms: number) => { waits.push(ms); clock += ms; } };
    await fetchStateRollCallText(H_URL, { ...deps, fetchImpl: html(HOUSE) });
    expect(waits).toEqual([]); // the first request of a run does not wait
    clock += 3_000;
    await fetchStateRollCallText(S_URL, { ...deps, fetchImpl: html(SENATE) });
    expect(waits).toEqual([7_000]); // 10 s after the last one, not sooner
    // Refused twice with 429, then served: the page is read, after a wait each time.
    clock += 60_000; waits.length = 0;
    let n = 0;
    const flaky = async () => (++n <= 2 ? new Response('<h1>429 Too Many Requests</h1>', { status: 429 }) : html(HOUSE)());
    expect(await fetchStateRollCallText(H_URL, { ...deps, fetchImpl: flaky })).toBe(render(HOUSE, H_URL));
    expect(n).toBe(3);
    expect(waits.length).toBeGreaterThanOrEqual(2);
    expect(Math.min(...waits)).toBeGreaterThanOrEqual(10_000);
    // Refused every time: null after three requests, never a loop.
    n = -100; clock += 60_000;
    let asked = 0;
    expect(await fetchStateRollCallText(H_URL, { ...deps, fetchImpl: async () => { asked++; return new Response('', { status: 429 }); } })).toBeNull();
    expect(asked).toBe(3);
    resetStateRollCallPacing();
  });

  it('is null for another address, a failed fetch and an unreadable page', async () => {
    resetStateRollCallPacing();
    expect(await fetchStateRollCallText('https://le.utah.gov/', { fetchImpl: html(HOUSE) })).toBeNull();
    const quick = { sleep: async () => {} };
    expect(await fetchStateRollCallText(H_URL, { ...quick, fetchImpl: async () => new Response('', { status: 404 }) })).toBeNull();
    expect(await fetchStateRollCallText(H_URL, { ...quick, fetchImpl: html('<html><body>Maintenance</body></html>') })).toBeNull();
    // With a text function, an unreadable page comes back as plain text, so the caller does not fetch it again.
    resetStateRollCallPacing();
    const plain = await fetchStateRollCallText(H_URL, { ...quick, fetchImpl: html('<html><body>Maintenance</body></html>'), toText: (h) => h.replace(/<[^>]+>/g, ' ') });
    expect(plain).toBe('Maintenance');
    expect(verifyStateRollCallLine(SNIDER, H_URL, plain!, 'Snider', 'Casey Snider').verdict).toBe('snippet_not_found');
  });

  it('verifyEvidence accepts the line on the render and publishes the line itself', async () => {
    const run = (text: string, snippet = SNIDER) => verifyEvidence({
      stanceRows: [{ full_name: 'Casey Snider', topic_key: 'a-topic', value: 2, source_urls: [H_URL] } as StanceRow],
      evidenceRows: [{ full_name: 'Casey Snider', topic_key: 'a-topic', source_url: H_URL, snippet, snippet_index: 1 }],
      fetcher: async () => ({ ok: true as const, text }),
      threshold: 1,
      politicianNames: { 'Casey Snider': { fullName: 'Casey Snider', lastName: 'Snider' } },
    });
    const ok = await run(render(HOUSE, H_URL));
    expect(ok.pushable).toHaveLength(1);
    expect(ok.pushable[0].verifiedSources[0].snippets[0].matchedSpan).toBe(SNIDER);
    const flipped = await run(render(HOUSE, H_URL), SNIDER.replace('voted Yea', 'voted Nay'));
    expect(flipped.pushable).toHaveLength(0);
    // The page's plain text (what the generic tier serves when the reader refuses the page) verifies nothing.
    expect((await run('Vote Status HB0237 Yeas - 71 Abbott, N. Snider, C. Nays - 0')).pushable).toHaveLength(0);
  });
});

// ── Ohio ─────────────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-16 with the verifier's own user-agent: the bill's Votes page at www.legislature.ohio.gov (the
// citation), the bill's action list at search-prod.lis.state.oh.us (the data), and the General Assembly's member
// list there. The Votes page prints a party letter after each name; the render never does.
const ohFile = (name: string): string =>
  readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}`, import.meta.url)), 'utf8');
const OH135 = { page: ohFile('oh-135-hb327-votes.html'), data: ohFile('oh-135-hb327-actions.json'), members: ohFile('oh-135-legislators.json') };
const OH132 = { page: ohFile('oh-132-hb228-votes.html'), data: ohFile('oh-132-hb228-actions.json'), members: ohFile('oh-132-legislators.json') };
const OH_URL = 'https://www.legislature.ohio.gov/legislation/135/hb327/votes#2024-06-12-House-85-6';
const OH_VETO = 'https://www.legislature.ohio.gov/legislation/132/hb228/votes#2018-12-27-House-67-22';
const ohRender = (d: { page: string; data: string; members: string }, url: string): string | null =>
  readStateRollCallDocs([d.page, d.data, d.members], url);
const ABRAMS = 'Ohio House vote of 2024-06-12 (135th General Assembly), HB 327 - Passed, 85-6: Cindy Abrams voted Yea.';

describe('state roll-call pages — Ohio address', () => {
  it('knows a vote on a bill\'s Votes page, and names the three documents that prove it', () => {
    expect(isStateRollCallUrl(OH_URL)).toBe(true);
    expect(stateRollCallDocs(OH_URL)).toEqual([
      'https://www.legislature.ohio.gov/legislation/135/hb327/votes',
      'https://search-prod.lis.state.oh.us/api/v2/general_assembly_135/legislation/hb327/actions/',
      'https://search-prod.lis.state.oh.us/api/v2/general_assembly_135/legislators/',
    ]);
    expect(stateRollCallMinGapMs(OH_URL)).toBe(1_000);
    // the page without a vote named, an old data address, and a look-alike host are not votes
    expect(isStateRollCallUrl('https://www.legislature.ohio.gov/legislation/135/hb327/votes')).toBe(false);
    expect(isStateRollCallUrl('https://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135/bills/hb327/votes')).toBe(false);
    expect(isStateRollCallUrl('https://www.legislature.ohio.gov.example.com/legislation/135/hb327/votes#2024-06-12-House-85-6')).toBe(false);
    expect(stateRollCallDocs(H_URL)).toEqual([H_URL]);
  });
});

describe('state roll-call pages — reading Ohio', () => {
  it('reads the vote from the page and the data together, with the motion from the data and no party', () => {
    const t = ohRender(OH135, OH_URL);
    expect(t).not.toBeNull();
    const rows = t!.split('\n');
    expect(rows[0]).toBe('Ohio House vote of 2024-06-12 (135th General Assembly), HB 327, 85-6.');
    expect(rows[1]).toBe('Question: Passed');
    expect(rows[2]).toMatch(/^Yea \(85\): Munira Abdullahi; Cindy Abrams; /);
    expect(rows[3]).toMatch(/^Nay \(6\): /);
    expect(rows).toHaveLength(4);
    expect(t).not.toMatch(/\((R|D)\)|republican|democrat/i);
    expect(parseStateRollCallRender(t!, OH_URL)).not.toBeNull();
  });

  it('reads a veto override two years earlier, and gives its motion', () => {
    const t = ohRender(OH132, OH_VETO);
    expect(t?.split('\n').slice(0, 2)).toEqual([
      'Ohio House vote of 2018-12-27 (132nd General Assembly), HB 228, 67-22.',
      'Question: Passed notwithstanding objections of the Governor',
    ]);
  });

  it('reads a 2026 page, which prints each sitting member as a link', () => {
    const d = { page: ohFile('oh-136-sb278-votes.html'), data: ohFile('oh-136-sb278-actions.json'), members: ohFile('oh-136-legislators.json') };
    const url = 'https://www.legislature.ohio.gov/legislation/136/sb278/votes#2026-04-15-Senate-24-9';
    const t = ohRender(d, url);
    expect(t?.split('\n')[0]).toBe('Ohio Senate vote of 2026-04-15 (136th General Assembly), SB 278, 24-9.');
    expect(t).toContain('Louis W. Blessing, III');
    expect(t).not.toMatch(/\((R|D)\)|href|ohiosenate/);
  });

  it('takes the session day the page prints, not the clock time the data stores', () => {
    // The House vote of 11-14-2018 is stored as occurring after midnight (2018-11-15T...); the page and the
    // session day say 11-14.
    const url = 'https://www.legislature.ohio.gov/legislation/132/hb228/votes#2018-11-14-House-65-32';
    expect(ohRender(OH132, url)?.split('\n')[0]).toBe('Ohio House vote of 2018-11-14 (132nd General Assembly), HB 228, 65-32.');
    expect(ohRender(OH132, url.replace('2018-11-14', '2018-11-15'))).toBeNull();
  });

  it('tells a floor vote from a committee vote of the same day and chamber, and reads no committee vote', () => {
    // 12-6-2018, Senate: the committee reported the bill 7-3 and the Senate passed it 19-10.
    expect(ohRender(OH132, 'https://www.legislature.ohio.gov/legislation/132/hb228/votes#2018-12-06-Senate-19-10')?.split('\n')[1]).toBe('Question: Passed - Amended');
    expect(ohRender(OH132, 'https://www.legislature.ohio.gov/legislation/132/hb228/votes#2018-12-06-Senate-7-3')).toBeNull();
    expect(ohRender(OH135, 'https://www.legislature.ohio.gov/legislation/135/hb327/votes#2024-05-22-House-11-2')).toBeNull();
  });

  it('reads no vote on a motion: "Informally passed" sets the bill aside, it is not a vote on the bill (runner, 2026-11-16)', () => {
    // 133 HB 425, 2020-06-04: action_code motion_920, "Informally passed", 85-9. Here the passage vote of HB 327
    // is given a motion's code: the same page row, the same members, and no line.
    const data = OH135.data.replace('"action_code": "pass_300"', '"action_code": "motion_920"').replace('"action_code":"pass_300"', '"action_code":"motion_920"');
    expect(data).not.toBe(OH135.data);
    expect(ohRender({ ...OH135, data }, OH_URL)).toBeNull();
  });

  it('refuses a vote the address does not name exactly: tally, chamber, day', () => {
    expect(ohRender(OH135, OH_URL.replace('85-6', '84-6'))).toBeNull();
    expect(ohRender(OH135, OH_URL.replace('House', 'Senate'))).toBeNull();
    expect(ohRender(OH135, OH_URL.replace('2024-06-12', '2024-06-13'))).toBeNull();
  });

  it('refuses documents that are not this bill and General Assembly', () => {
    expect(ohRender(OH132, OH_URL)).toBeNull();
    expect(ohRender({ ...OH135, page: OH132.page }, OH_URL)).toBeNull();
    expect(ohRender(OH135, OH_URL.replace('hb327', 'hb328'))).toBeNull();
  });

  it('refuses when the page and the data disagree on a member', () => {
    // The data moves one member from Yea to Nay and the page does not: the counts no longer match the address.
    const d = JSON.parse(OH135.data) as { yeas?: string[]; nays?: string[] }[];
    const floor = d.find((a) => a.yeas?.length === 85)!;
    const moved = floor.yeas!.shift()!; floor.nays!.push(moved);
    expect(ohRender({ ...OH135, data: JSON.stringify(d) }, OH_URL)).toBeNull();
    // Same counts, another member: swap one Yea member for one not on the page at all.
    const d2 = JSON.parse(OH135.data) as { yeas?: string[]; nays?: string[] }[];
    const f2 = d2.find((a) => a.yeas?.length === 85)!;
    const outside = (JSON.parse(OH135.members) as { lpid: string; displayname: string }[])
      .find((m) => m.lpid.startsWith('rep_') && m.displayname && !f2.yeas!.includes(m.lpid) && !f2.nays!.includes(m.lpid))!;
    f2.yeas![0] = outside.lpid;
    expect(ohRender({ ...OH135, data: JSON.stringify(d2) }, OH_URL)).toBeNull();
    // The page loses one name under Yeas.
    expect(ohRender({ ...OH135, page: tamper(OH135.page, '<span>Cindy Abrams (R)</span>', '') }, OH_URL)).toBeNull();
    // The page's printed count is not the names under it.
    expect(ohRender({ ...OH135, page: tamper(OH135.page, 'Yeas: 85', 'Yeas: 84') }, OH_URL)).toBeNull();
  });

  it('refuses a member id the member list does not hold, or holds with no name', () => {
    const m = (JSON.parse(OH135.members) as { lpid: string }[]).filter((x) => x.lpid !== 'rep_abrams_cindy_1');
    expect(ohRender({ ...OH135, members: JSON.stringify(m) }, OH_URL)).toBeNull();
    const blank = (JSON.parse(OH135.members) as { lpid: string; displayname: string }[]).map((x) => (x.lpid === 'rep_abrams_cindy_1' ? { ...x, displayname: '' } : x));
    expect(ohRender({ ...OH135, members: JSON.stringify(blank) }, OH_URL)).toBeNull();
  });

  it('refuses a vote whose members are of the other chamber', () => {
    const d = JSON.parse(OH135.data) as { yeas?: string[] }[];
    const f = d.find((a) => a.yeas?.length === 85)!;
    const i = f.yeas!.indexOf('rep_abrams_cindy_1');
    f.yeas![i] = 'sen_abrams_cindy_1';
    const m = [...(JSON.parse(OH135.members) as object[]), { lpid: 'sen_abrams_cindy_1', displayname: 'Cindy Abrams', chamber: 'Senate' }];
    expect(ohRender({ ...OH135, data: JSON.stringify(d), members: JSON.stringify(m) }, OH_URL)).toBeNull();
  });

  it('refuses a page or data that does not read', () => {
    expect(ohRender({ ...OH135, page: '<html><body>Maintenance</body></html>' }, OH_URL)).toBeNull();
    expect(ohRender({ ...OH135, data: 'not json' }, OH_URL)).toBeNull();
    expect(ohRender({ ...OH135, members: '{}' }, OH_URL)).toBeNull();
  });
});

describe('state roll-call pages — Ohio labels and lines', () => {
  const text = ohRender(OH135, OH_URL)!;

  it('fits a full printed name: surname, and a given name, nickname or middle name the page prints', () => {
    expect(fullNameLabelFits('Cindy Abrams', 'Abrams', 'Cindy Abrams')).toBe(true);
    expect(fullNameLabelFits('P. Scott Lipps', 'Lipps', 'Scott Lipps')).toBe(true);
    expect(fullNameLabelFits('Joseph A. Miller, III', 'Miller', 'Joe Miller')).toBe(true);
    expect(fullNameLabelFits('Monica Robb Blasdel', 'Robb Blasdel', 'Monica Robb Blasdel')).toBe(true);
    expect(fullNameLabelFits('Monica Robb Blasdel', 'Blasdel', 'Monica Blasdel')).toBe(true);
    expect(fullNameLabelFits("Richard Dell'Aquila", "Dell'Aquila", "Richard Dell'Aquila")).toBe(true);
    expect(fullNameLabelFits('Kevin D. Miller', 'Miller', 'Melanie Miller')).toBe(false);
    expect(fullNameLabelFits('Melanie Miller', 'Miller', 'Kevin Miller')).toBe(false);
    expect(fullNameLabelFits('Cindy Abrams', 'Abram', 'Cindy Abram')).toBe(false);
  });

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(OH_URL, text, 'Abrams', 'Cindy Abrams')).toEqual([ABRAMS]);
    expect(verifyStateRollCallLine(ABRAMS, OH_URL, text, 'Abrams', 'Cindy Abrams')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(ABRAMS)).toMatchObject({ state: 'OH', chamber: 'House', vote: 'Yea', name: 'Cindy Abrams', bill: 'HB 327', date: '2024-06-12' });
  });

  it('gives no line to a member of the chamber who is on neither list (absent is no finding)', () => {
    const listed = text.split('\n').slice(2).join(';');
    const m = (JSON.parse(OH135.members) as { lpid: string; displayname: string; lastname: string; firstname: string }[])
      .find((x) => x.lpid.startsWith('rep_') && x.displayname && !listed.includes(x.displayname))!;
    expect(m).toBeTruthy();
    expect(stateRollCallLinesFor(OH_URL, text, m.lastname, `${m.firstname} ${m.lastname}`)).toEqual([]);
  });

  it('refuses the line with the vote flipped, or given to another member', () => {
    expect(verifyStateRollCallLine(ABRAMS.replace('voted Yea', 'voted Nay'), OH_URL, text, 'Abrams', 'Cindy Abrams').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(ABRAMS, OH_URL, text, 'Miller', 'Melanie Miller').verdict).toBe('name_not_present');
    expect(verifyStateRollCallLine(ABRAMS.replace('85-6', '84-7'), OH_URL, text, 'Abrams', 'Cindy Abrams').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(ABRAMS.replace(' - Passed,', ' - Concurred in Senate amendments,'), OH_URL, text, 'Abrams', 'Cindy Abrams').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(ABRAMS.replace('2024-06-12', '2024-06-11'), OH_URL, text, 'Abrams', 'Cindy Abrams').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(ABRAMS, OH_URL.replace('85-6', '85-7'), text, 'Abrams', 'Cindy Abrams').verdict).toBe('snippet_not_found');
  });

  it('gives no line when two printed names fit the person', () => {
    // Three Millers sit in this House; "Miller" with only a surname known fits none uniquely.
    expect(stateRollCallLinesFor(OH_URL, text.replace('Melanie Miller', 'Kevin Miller'), 'Miller', 'Kevin D. Miller')).toEqual([]);
  });

  it('verifyEvidence accepts the Ohio line on the render and refuses it on the page\'s plain text', async () => {
    const run = (t: string, snippet = ABRAMS) => verifyEvidence({
      stanceRows: [{ full_name: 'Cindy Abrams', topic_key: 'a-topic', value: 2, source_urls: [OH_URL] } as StanceRow],
      evidenceRows: [{ full_name: 'Cindy Abrams', topic_key: 'a-topic', source_url: OH_URL, snippet, snippet_index: 1 }],
      fetcher: async () => ({ ok: true as const, text: t }),
      threshold: 1,
      politicianNames: { 'Cindy Abrams': { fullName: 'Cindy Abrams', lastName: 'Abrams' } },
    });
    expect((await run(text)).pushable).toHaveLength(1);
    expect((await run(text, ABRAMS.replace('voted Yea', 'voted Nay'))).pushable).toHaveLength(0);
    expect((await run('House Bill 327 Votes Yeas: 85 Nays: 6 Cindy Abrams (R)')).pushable).toHaveLength(0);
  });
});

describe('state roll-call pages — the Ohio adapter', () => {
  it('fetches the page, the data and the member list, a second apart per site, and asks for none of them again for the same bill', async () => {
    resetStateRollCallPacing();
    let clock = 5_000_000;
    const asked: string[] = [];
    const waits: number[] = [];
    const body: Record<string, string> = Object.fromEntries(stateRollCallDocs(OH_URL)!.map((u, i) => [u, [OH135.page, OH135.data, OH135.members][i]]));
    const deps = {
      now: () => clock, sleep: async (ms: number) => { waits.push(ms); clock += ms; },
      fetchImpl: async (u: string) => { asked.push(u); clock += 100; return new Response(body[u] ?? '', { status: body[u] ? 200 : 404 }); },
    };
    expect(await fetchStateRollCallText(OH_URL, deps)).toBe(ohRender(OH135, OH_URL));
    expect(asked).toHaveLength(3);
    // Another vote of the same bill shares all three documents: nothing is asked again.
    const committee = OH_URL.replace('2024-06-12-House-85-6', '2024-05-22-House-11-2');
    expect(await fetchStateRollCallText(committee, { ...deps, toText: (h: string) => h.slice(0, 20) })).toBe(OH135.page.slice(0, 20).trim());
    expect(asked).toHaveLength(3);
    expect(waits.every((w) => w <= 1_000) && waits.length > 0).toBe(true);
    resetStateRollCallPacing();
  });
});

// ── South Dakota ─────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-17 from sdlegislature.gov/api/Votes/<id> with the verifier's own user-agent. The cited page
// (/Session/Vote/<id>) is a script shell with no vote in it; the data is the one document. No party in either.
const sdFile = (id: number): string => ohFile(`sd-vote-${id}.json`);
const SD_URL = (id: number): string => `https://sdlegislature.gov/Session/Vote/${id}`;
const sdRender = (id: number, body = sdFile(id)): string | null => readStateRollCallDocs([body], SD_URL(id));
/** Change one thing in the data and fail when the change did not apply. */
const sdTamper = (id: number, edit: (d: Record<string, any>) => void): string => {
  const d = JSON.parse(sdFile(id));
  const before = JSON.stringify(d);
  edit(d);
  expect(JSON.stringify(d)).not.toBe(before);
  return JSON.stringify(d);
};
const MORTENSON = 'South Dakota House vote 84688 (2026), SB 179 - Do Pass (2026-03-05): Will Mortenson voted Yea.';

describe('state roll-call pages — South Dakota address', () => {
  it('knows a vote page, and reads it from the vote\'s data, a second apart', () => {
    expect(isStateRollCallUrl(SD_URL(84688))).toBe(true);
    expect(stateRollCallDocs(SD_URL(84688))).toEqual(['https://sdlegislature.gov/api/Votes/84688']);
    expect(stateRollCallMinGapMs(SD_URL(84688))).toBe(1_000);
    // the data address itself, the old address the dump stores, a look-alike host and a zero id are not cited votes
    for (const u of ['https://sdlegislature.gov/api/Votes/84688', 'https://sdlegislature.gov/Legislative_Session/Bills/RollCall.aspx?Vote=25365&Session=2018',
      'https://sdlegislature.gov.example.com/Session/Vote/84688', 'http://sdlegislature.gov/Session/Vote/84688', 'https://sdlegislature.gov/Session/Vote/0']) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });
});

describe('state roll-call pages — reading South Dakota', () => {
  it('reads a 2026 floor vote: chamber, session, bill, question, day and every member, with no party', () => {
    const t = sdRender(84688)!;
    expect(t.split('\n').slice(0, 3)).toEqual([
      'South Dakota House vote 84688 (2026), SB 179, 2026-03-05.', 'Question: Do Pass',
      'Yea 42; Nay 25; Excused 3; Absent 0; Not voting 0; Present 0; Suspended 0.',
    ]);
    expect(t).toContain('Excused (3): Jeff Bathke; Tim Czmowski; Bethany Soye');
    expect(t).not.toMatch(/\([A-Z]\)/); // no letter after a name
    expect(parseStateRollCallRender(t, SD_URL(84688))).toMatchObject({ state: 'SD', chamber: 'House', session: '2026', bill: 'SB 179' });
  });

  it('reads a consent calendar as one vote on every bill it carried, once each, though 2020 lists each bill twice', () => {
    expect(sdRender(34573)!.split('\n')[0]).toBe(
      'South Dakota House vote 34573 (2020), SB 45, SB 98, SB 120, SB 124, SB 25, SB 27, SB 44, SB 89, SB 81, SB 91, SB 149, 2020-03-09.');
    // one bill number under two ids is two bills that cannot both be that number: refused
    expect(sdRender(34573, sdTamper(34573, (d) => { d.Bill[1].BillId = 99999; }))).toBeNull();
  });

  it('reads a 2018 concurrence, a vote on the bill', () => {
    expect(sdRender(26828)!.split('\n').slice(0, 2)).toEqual(['South Dakota House vote 26828 (2018), HB 1209, 2018-03-07.', 'Question: Concurred in amendments']);
  });

  it('lists a suspended member as the record does, never as a Yea or a Nay', () => {
    const t = sdRender(76497)!;
    expect(t).toContain('Suspended (1): Julie Frye-Mueller');
    expect(stateRollCallLinesFor(SD_URL(76497), t, 'Frye-Mueller', 'Julie Frye-Mueller')).toEqual([
      'South Dakota Senate vote 76497 (2023), SB 50, SB 64, SB 61, SB 37, SB 84, SB 72, SB 81, SB 85, HB 1010, HB 1015, HB 1033, HB 1062, HB 1004, HB 1018, HB 1019, HB 1005 - Do Pass (2023-01-30): Julie Frye-Mueller was suspended.',
    ]);
  });

  it('reads no committee vote, though the data files it under the House with "Do Pass" (runner, 2026-11-16)', () => {
    expect(sdRender(83164)).toBeNull();
  });

  it('reads no vote on a motion: "Reconsidered" is not a vote on the bill (runner, 2026-11-16)', () => {
    expect(sdRender(26132)).toBeNull();
    // the same vote with a question on the bill reads, so the motion is what refused it
    expect(sdRender(26132, sdTamper(26132, (d) => { d.actionLog.StatusText = 'Do Pass'; }))).not.toBeNull();
  });

  it('refuses data whose counts are not the members listed, or whose member votes twice', () => {
    expect(sdRender(84688, sdTamper(84688, (d) => { d.Yeas = 41; }))).toBeNull();
    expect(sdRender(84688, sdTamper(84688, (d) => { d.RollCalls[0].Vote1 = 'Nay'; }))).toBeNull();
    expect(sdRender(84688, sdTamper(84688, (d) => { d.RollCalls[1].SessionMemberId = d.RollCalls[0].SessionMemberId; }))).toBeNull();
    expect(sdRender(84688, sdTamper(84688, (d) => { d.RollCalls.push({ ...d.RollCalls[0], SessionMemberId: 1 }); d.Yeas += 1; }))).toBeNull();
  });

  it('refuses a session it does not know, a vote it cannot place, another vote\'s data, and a vote word it does not know', () => {
    expect(sdRender(84688, sdTamper(84688, (d) => { d.SessionId = 174; }))).toBeNull();
    expect(sdRender(84688, sdTamper(84688, (d) => { d.actionLog.FullName = 'Joint Committee on Appropriations'; }))).toBeNull();
    expect(readStateRollCallDocs([sdFile(84688)], SD_URL(84689))).toBeNull();
    expect(sdRender(84688, sdTamper(84688, (d) => { d.RollCalls[0].Vote1 = 'Paired'; }))).toBeNull();
    expect(sdRender(84688, '<html>not data</html>')).toBeNull();
  });
});

describe('state roll-call pages — South Dakota lines', () => {
  const text = sdRender(84688)!;

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(SD_URL(84688), text, 'Mortenson', 'Will Mortenson')).toEqual([MORTENSON]);
    expect(verifyStateRollCallLine(MORTENSON, SD_URL(84688), text, 'Mortenson', 'Will Mortenson')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(MORTENSON)).toMatchObject({ state: 'SD', voteId: 84688, chamber: 'House', vote: 'Yea', name: 'Will Mortenson', bill: 'SB 179' });
  });

  it('gives an excused member the line "was excused", never a Yea or a Nay', () => {
    const [l] = stateRollCallLinesFor(SD_URL(84688), text, 'Soye', 'Bethany Soye');
    expect(l).toBe('South Dakota House vote 84688 (2026), SB 179 - Do Pass (2026-03-05): Bethany Soye was excused.');
    expect(verifyStateRollCallLine(l.replace('was excused', 'voted Yea'), SD_URL(84688), text, 'Soye', 'Bethany Soye').verdict).toBe('snippet_not_found');
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Mortenson', full = 'Will Mortenson', url = SD_URL(84688)) => verifyStateRollCallLine(line, url, text, last, full).verdict;
    expect(v(MORTENSON.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(MORTENSON.replace('Will Mortenson', 'Erin Healy'))).toBe('snippet_not_found');
    expect(v(MORTENSON, 'Healy', 'Erin Healy')).toBe('name_not_present');
    expect(v(MORTENSON.replace('SB 179', 'SB 178'))).toBe('snippet_not_found');
    expect(v(MORTENSON.replace('2026-03-05', '2026-03-04'))).toBe('snippet_not_found');
    expect(v(MORTENSON.replace('Do Pass', 'Do Pass Amended'))).toBe('snippet_not_found');
    expect(v(MORTENSON, 'Mortenson', 'Will Mortenson', SD_URL(84689))).toBe('snippet_not_found');
  });

  it('refuses a consent calendar\'s line that names one of its bills and not all of them', () => {
    const t = sdRender(34573)!;
    const [l] = stateRollCallLinesFor(SD_URL(34573), t, 'Randolph', 'Tony Randolph');
    expect(verifyStateRollCallLine(l, SD_URL(34573), t, 'Randolph', 'Tony Randolph').verdict).toBe('verified');
    expect(verifyStateRollCallLine(l.replace(/\), SB 45, .* - Do Pass/, '), SB 45 - Do Pass'), SD_URL(34573), t, 'Randolph', 'Tony Randolph').verdict).toBe('snippet_not_found');
  });

  it('gives no line when two members fit the person', () => {
    expect(stateRollCallLinesFor(SD_URL(84688), text.replace('Erin Healy', 'Will Mortenson'), 'Mortenson', 'Will Mortenson')).toEqual([]);
  });

  it('verifyEvidence accepts the line on the render and refuses it on the page\'s script shell', async () => {
    const run = (t: string, snippet = MORTENSON) => verifyEvidence({
      stanceRows: [{ full_name: 'Will Mortenson', topic_key: 'a-topic', value: 2, source_urls: [SD_URL(84688)] } as StanceRow],
      evidenceRows: [{ full_name: 'Will Mortenson', topic_key: 'a-topic', source_url: SD_URL(84688), snippet, snippet_index: 1 }],
      fetcher: async () => ({ ok: true as const, text: t }),
      threshold: 1,
      politicianNames: { 'Will Mortenson': { fullName: 'Will Mortenson', lastName: 'Mortenson' } },
    });
    expect((await run(text)).pushable).toHaveLength(1);
    expect((await run(text, MORTENSON.replace('voted Yea', 'voted Nay'))).pushable).toHaveLength(0);
    expect((await run('South Dakota Legislature You need to enable JavaScript to run this app.')).pushable).toHaveLength(0);
  });

  it('the adapter reads the vote from its data address, with the caller\'s user-agent', async () => {
    resetStateRollCallPacing();
    const asked: { u: string; ua: string | null }[] = [];
    const fetchImpl = async (u: string, init?: RequestInit) => {
      asked.push({ u, ua: new Headers(init?.headers).get('user-agent') });
      return new Response(sdFile(84688), { status: 200, headers: { 'content-type': 'application/json' } });
    };
    expect(await fetchStateRollCallText(SD_URL(84688), { fetchImpl, userAgent: 'EmpoweredVoteBot/test', now: () => 0, sleep: async () => {} })).toBe(text);
    expect(asked).toEqual([{ u: 'https://sdlegislature.gov/api/Votes/84688', ua: 'EmpoweredVoteBot/test' }]);
    resetStateRollCallPacing();
  });
});

// ── Mississippi ──────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-17 from billstatus.ls.state.ms.us: each vote's PDF (as the adapter hands it on, its lines paired by
// position: pdfLinesBody), the bill's history, the session's author list and the current member list. No party in
// any of them.
const MS = 'https://billstatus.ls.state.ms.us/';
const MS_SEN_2018 = `${MS}2018/pdf/votes/senate/0650030.pdf#HB1083`; // pairs, "Voting Present"
const MS_HOU_2026 = `${MS}2026/pdf/votes/house/0830060.pdf#HB1793`; // "Present", the Speaker, "Total-" / "-6"
const MS_HOU_2023 = `${MS}2023/pdf/votes/house/0850026.pdf#HB912`; // two Baileys, one not on the 2023 lists
const msDocs: Record<string, string[]> = {
  [MS_SEN_2018]: ['ms-2018-senate-0650030.txt', 'ms-2018-HB1083.xml', 'ms-2018-s_auth.xml', 'ms-members-ss_membs.xml'],
  [MS_HOU_2026]: ['ms-2026-house-0830060.txt', 'ms-2026-HB1793.xml', 'ms-2026-h_auth.xml', 'ms-members-hr_membs.xml'],
  [MS_HOU_2023]: ['ms-2023-house-0850026.txt', 'ms-2023-HB0912.xml', 'ms-2023-h_auth.xml', 'ms-members-hr_membs.xml'],
};
const msBodies = (url: string): string[] => msDocs[url].map((f) => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${f}`, import.meta.url)), 'latin1'));
/** The render, after one change to one document; the test fails when the change did not apply. */
const msRender = (url: string, doc = -1, from = '', to = ''): string | null => {
  const b = msBodies(url);
  if (doc >= 0) b[doc] = tamper(b[doc], from, to);
  return readStateRollCallDocs(b, url);
};
const EURE = 'Mississippi House vote 0830060 (2026), HB 1793 - Conference Report Adopted (2026-03-29): Casey Eure voted Yea.';

describe('state roll-call pages — Mississippi address', () => {
  it('knows a vote PDF cited with its bill, and reads it from four documents, a second apart', () => {
    expect(isStateRollCallUrl(MS_HOU_2023)).toBe(true);
    expect(stateRollCallDocs(MS_HOU_2023)).toEqual([`${MS}2023/pdf/votes/house/0850026.pdf`, `${MS}2023/pdf/history/HB/HB0912.xml`,
      `${MS}2023/pdf/h_auth.xml`, `${MS}members/hr_membs.xml`]);
    expect(stateRollCallMinGapMs(MS_HOU_2023)).toBe(1_000);
    // no bill (one PDF may carry several), plain http, a short vote number, a look-alike host, an unknown chamber
    for (const u of [`${MS}2023/pdf/votes/house/0850026.pdf`, MS_HOU_2023.replace('https', 'http'), `${MS}2023/pdf/votes/house/085002.pdf#HB912`,
      MS_HOU_2023.replace('ms.us/', 'ms.us.example.com/'), `${MS}2023/pdf/votes/joint/0850026.pdf#HB912`]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });
});

describe('state roll-call pages — reading Mississippi', () => {
  it('reads a 2018 Senate vote: bill, question and day from the history, every member by full name, the pairs apart', () => {
    const t = msRender(MS_SEN_2018)!;
    expect(t.split('\n').slice(0, 3)).toEqual([
      'Mississippi Senate vote 0650030 (2018), HB 1083, 2018-03-07.', 'Question: Passed As Amended',
      'Yea 27; Nay 18; Absent or not voting 4; Present 1; Paired 2.',
    ]);
    expect(t).toMatch(/^Paired \(2\): .*Juan Barnett/m);
    expect(t).not.toMatch(/^(Yea|Nay) .*Juan Barnett/m); // a pair is never a Yea or a Nay
    expect(parseStateRollCallRender(t, MS_SEN_2018)).toMatchObject({ state: 'MS', chamber: 'Senate', session: '2018', bill: 'HB 1083' });
  });

  it('reads a 2026 House vote: "Present", the Speaker by name, and a total the PDF breaks over two lines', () => {
    const t = msRender(MS_HOU_2026)!;
    expect(t.split('\n')[2]).toBe('Yea 106; Nay 6; Absent or not voting 3; Present 7; Paired 0.');
    expect(t).toMatch(/^Yea \(106\): .*Jason White/m);
    expect(t).not.toContain('Speaker');
  });

  it('keeps a label the lists do not name as printed, and gives it no line; the other Bailey is still read', () => {
    const t = msRender(MS_HOU_2023)!;
    expect(t).toMatch(/^Yea \(87\): .*Bailey \(23rd\);/m);
    expect(t).toMatch(/^Nay \(26\): .*Willie Bailey/m);
    expect(stateRollCallLinesFor(MS_HOU_2023, t, 'Bailey', 'Perry Bailey')).toEqual([]);
    // the 2023 author list has empty name slots with no link: none may run on into the next member's name
    expect(t).not.toMatch(/[<>]/);
  });

  it('refuses a total that is not the names listed, a name listed twice, or another chamber or session', () => {
    expect(msRender(MS_HOU_2023, 0, 'Total--87.', 'Total--88.')).toBeNull();
    expect(msRender(MS_HOU_2023, 0, 'Yeas--Aguirre,', 'Yeas--Young,')).toBeNull();
    expect(msRender(MS_HOU_2023, 0, 'Mississippi House of Representatives', 'Mississippi State Senate')).toBeNull();
    expect(msRender(MS_HOU_2023, 0, '2023 Regular Session', '2023 First Extraordinary Session')).toBeNull();
  });

  it('refuses a PDF that names another bill, and a history that does not link this vote to this bill', () => {
    expect(msRender(MS_HOU_2023, 0, 'H. B. No. 912', 'H. B. No. 913')).toBeNull();
    expect(msRender(MS_HOU_2026, 1, 'votes/house/0830060.pdf', 'votes/house/0830061.pdf')).toBeNull();
    expect(readStateRollCallDocs(msBodies(MS_HOU_2023), MS_HOU_2023.replace('#HB912', '#HB913'))).toBeNull();
  });

  it('reads no vote on a motion: the question must be on the bill (runner, 2026-11-16)', () => {
    expect(msRender(MS_HOU_2026, 1, '03/29 (H) Conference Report Adopted', '03/29 (H) Motion to Reconsider Tabled')).toBeNull();
  });

  it('names no Speaker it cannot place: the member list must name the same Speaker in the years of its term', () => {
    expect(msRender(MS_HOU_2026, 3, '<CHAIR_LINK>house/White.xml', '<CHAIR_LINK>house/Someone.xml')).toBeNull();
  });
});

describe('state roll-call pages — Mississippi lines', () => {
  const t = msRender(MS_HOU_2026)!;

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(MS_HOU_2026, t, 'Eure', 'Casey Eure')).toEqual([EURE]);
    expect(verifyStateRollCallLine(EURE, MS_HOU_2026, t, 'Eure', 'Casey Eure')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(EURE)).toMatchObject({ state: 'MS', chamber: 'House', vote: 'Yea', name: 'Casey Eure', bill: 'HB 1793' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Eure', full = 'Casey Eure', url = MS_HOU_2026) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(EURE.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(EURE.replace('Casey Eure', 'Jody Steverson'))).not.toBe('verified');
    expect(v(EURE, 'Steverson', 'Jody Steverson')).toBe('name_not_present');
    expect(v(EURE.replace('HB 1793', 'HB 1794'))).toBe('snippet_not_found');
    expect(v(EURE.replace('2026-03-29', '2026-03-28'))).toBe('snippet_not_found');
    expect(v(EURE, 'Eure', 'Casey Eure', MS_HOU_2026.replace('0830060', '0830061'))).toBe('snippet_not_found');
  });

  it('gives a paired member "was paired", and a member present "voted present", never a Yea or a Nay', () => {
    const s = msRender(MS_SEN_2018)!;
    const [l] = stateRollCallLinesFor(MS_SEN_2018, s, 'Barnett', 'Juan Barnett');
    expect(l).toBe('Mississippi Senate vote 0650030 (2018), HB 1083 - Passed As Amended (2018-03-07): Juan Barnett was paired.');
    expect(verifyStateRollCallLine(l.replace('was paired', 'voted Nay'), MS_SEN_2018, s, 'Barnett', 'Juan Barnett').verdict).toBe('snippet_not_found');
    expect(stateRollCallLinesFor(MS_SEN_2018, s, 'Branning', 'Jenifer B. Branning')[0]).toMatch(/Jenifer B\. Branning voted present\.$/);
  });

  it('fits a printed name that carries a nickname in quotes to the person\'s own name (W.I. "Doc" Harris, 2026)', () => {
    expect(fullNameLabelFits('W.I. "Doc" Harris', 'Harris', 'W. I. Harris')).toBe(true);
    expect(fullNameLabelFits('W.I. "Doc" Harris', 'Harris', 'Doc Harris')).toBe(true);
    expect(fullNameLabelFits('W.I. "Doc" Harris', 'Harris', 'Kevin Harris')).toBe(false);
    expect(stateRollCallLinesFor(MS_HOU_2026, t, 'Harris', 'W. I. Harris')).toHaveLength(1);
  });

  it('the adapter asks for XML as text/xml, which the site requires (406 otherwise), and reads the vote', async () => {
    resetStateRollCallPacing();
    const [, ...xml] = msBodies(MS_HOU_2026);
    // the PDF itself, as the site serves it: the adapter reads its lines (pdfLinesBody)
    const pdf = readFileSync(fileURLToPath(new URL('./__fixtures__/stateRollCall/ms-2026-house-0830060.pdf', import.meta.url)));
    const docs = stateRollCallDocs(MS_HOU_2026)!;
    const fetchImpl = async (u: string, init?: RequestInit) => {
      const i = docs.indexOf(u);
      if (i > 0 && !/\btext\/xml\b/.test(new Headers(init?.headers).get('accept') ?? '')) return new Response('Not Acceptable', { status: 406 });
      return new Response(i === 0 ? pdf : xml[i - 1], { status: 200 });
    };
    expect(await fetchStateRollCallText(MS_HOU_2026, { fetchImpl, now: () => 0, sleep: async () => {} })).toBe(t);
    resetStateRollCallPacing();
  });
});

// ── Maryland ─────────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-18 from mgaleg.maryland.gov: three votes (2026 House, a PDF, kept as the cells the adapter hands on:
// pdfCellsBody; 2019 Senate, a consent calendar printed sideways, kept as the PDF; 2017 Senate, a page, trimmed to its
// table cells) and each chamber's committee pages for that session, trimmed to the session and the member links (the
// pages print each member's party; the trim leaves it out).
const MD = 'https://mgaleg.maryland.gov/';
const MD_HOU_2026 = `${MD}2026RS/votes/house/1104.pdf#SB128`;
const MD_SEN_2019 = `${MD}2019RS/votes/senate/0777.pdf#HB243`;
const MD_SEN_2017 = `${MD}2017RS/votes/senate/1361.htm#2016-SB907`; // "Special Order Calendar 2016 Vetoed Senate Bill"
const mdFile = (f: string, enc: BufferEncoding = 'utf8'): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${f}`, import.meta.url)), enc);
const MD_CM: Record<string, string[]> = {
  'H-2026': ['app', 'ecm', 'ent', 'jud', 'wm', 'hru', 'hlt', 'gvc'],
  'S-2019': ['bt', 'ehe', 'fin', 'jpr', 'sru', 'exn'],
  'S-2017': ['bt', 'ehe', 'fin', 'jpr', 'sru', 'exn'],
};
const mdCm = (k: string): string[] => MD_CM[k].map((c) => mdFile(`md-cm-${k}-${c}.html`));
const mdHou2026 = (): string[] => [mdFile('md-2026-house-1104.txt'), ...mdCm('H-2026')];
const mdSen2017 = (): string[] => [mdFile('md-2017-senate-1361.htm'), ...mdCm('S-2017')];
// 2013: the House page for SB 281 (Firearm Safety Act of 2013), trimmed like 2017's, and that session's House committee pages.
const MD_HOU_2013 = `${MD}2013RS/votes/house/0895.htm#SB281`;
const mdHou2013 = (): string[] => [mdFile('md-2013-house-0895.htm'),
  ...['app', 'ecm', 'env', 'jud', 'wm', 'hru', 'hgo'].map((c) => mdFile(`md-cm-H-2013-${c}.html`))];
/** The render, after one change to one document; the test fails when the change did not apply. */
const mdRender = (bodies: string[], url: string, doc = -1, from = '', to = ''): string | null => {
  const b = [...bodies];
  if (doc >= 0) b[doc] = tamper(b[doc], from, to);
  return readStateRollCallDocs(b, url);
};
const mdWhy = (bodies: string[], url: string, doc: number, from: string, to: string): string => {
  const b = [...bodies];
  b[doc] = tamper(b[doc], from, to);
  const v = explainMarylandVote(b, url);
  return 'refused' in v ? v.refused : 'read';
};
const ACEVERO = 'Maryland House vote 1104 (2026RS), SB 128 - On Third Reading (2026-04-08): Gabriel Acevero voted Yea.';

describe('state roll-call pages — Maryland address', () => {
  it('knows a vote cited with its bill, and reads it with the chamber\'s committee pages, a second apart', () => {
    expect(isStateRollCallUrl(MD_HOU_2026)).toBe(true);
    expect(stateRollCallDocs(MD_HOU_2026)).toEqual([`${MD}2026RS/votes/house/1104.pdf`,
      ...['app', 'ecm', 'ent', 'jud', 'w%26m', 'hru', 'hlt', 'gvc'].map((c) => `${MD}mgawebsite/Committees/Details?cmte=${c}&ys=2026RS`)]);
    expect(stateRollCallDocs(MD_SEN_2017)!.slice(0, 2)).toEqual([`${MD}2017RS/votes/senate/1361.htm`, `${MD}mgawebsite/Committees/Details?cmte=b%26t&ys=2017RS`]);
    expect(stateRollCallMinGapMs(MD_HOU_2026)).toBe(1_000);
    // no bill, plain http, a 2017 PDF and a later page (2017's votes are pages, every later session's PDFs), a short
    // vote number, a look-alike host, an unknown chamber
    for (const u of [`${MD}2026RS/votes/house/1104.pdf`, MD_HOU_2026.replace('https', 'http'), MD_SEN_2017.replace('.htm', '.pdf'),
      MD_HOU_2026.replace('.pdf', '.htm'), MD_HOU_2026.replace('1104', '104'), MD_HOU_2026.replace('.gov/', '.gov.example.com/'),
      MD_HOU_2026.replace('/house/', '/joint/')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('keeps each run of a PDF row a cell of its own, and reads a page printed sideways along its text', () => {
    // "White Holland" is one member; "White" and "Holland" would be two. Joined with spaces they cannot be told apart.
    expect(pdfCellsBody([{ page: 1, x: 50, y: 500, str: 'White Holland' }, { page: 1, x: 150, y: 500.5, str: 'Wilson' }, { page: 1, x: 50, y: 520, str: 'Voting Yea - 2' }]))
      .toBe('%PDF-CELLS\nVoting Yea - 2\nWhite Holland\tWilson');
    // text running down the page (a quarter turn clockwise): a row is one x, read top to bottom
    expect(pdfCellsBody([{ page: 1, x: 540, y: 456, str: 'Elfreth', dir: -1 }, { page: 1, x: 540, y: 559, str: 'Augustine', dir: -1 }, { page: 1, x: 552, y: 565, str: 'Voting Yea - 2', dir: -1 }]))
      .toBe('%PDF-CELLS\nVoting Yea - 2\nAugustine\tElfreth');
  });
});

describe('state roll-call pages — reading Maryland', () => {
  it('reads the 2024 Senate\'s misprint "Regular Sessions", but only for its own year', () => {
    const read = mdRender(mdHou2026(), MD_HOU_2026);
    expect(mdRender(mdHou2026(), MD_HOU_2026, 0, '2026 Regular Session', '2026 Regular Sessions')).toBe(read);
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, '2026 Regular Session', '2025 Regular Sessions')).toBe('the vote does not name this session');
  });

  it('reads past each footer and copy stamp the site prints, and stops on a footer it does not know', () => {
    const foot = '* Indicates Vote Change';
    expect(mdHou2026()[0].endsWith(foot)).toBe(true);
    const read = mdRender(mdHou2026(), MD_HOU_2026);
    expect(read).not.toBeNull();
    for (const f of ['(COPY- * indicates vote change)', 'COPY - * Indicates Vote Change', '(COPY)\n* Indicates Vote Change', '- COPY -\n* Indicates Vote Change']) {
      expect(mdRender(mdHou2026(), MD_HOU_2026, 0, foot, f)).toBe(read);
    }
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, foot, 'DRAFT - * Indicates Vote Change')).toMatch(/cannot read: DRAFT/);
  });

  it('reads a 2026 House vote: day, question and tally; members by full name; the presiding officer as printed', () => {
    const t = mdRender(mdHou2026(), MD_HOU_2026)!;
    expect(t.split('\n').slice(0, 3)).toEqual([
      'Maryland House vote 1104 (2026RS), SB 128, 2026-04-08.', 'Question: On Third Reading',
      'Yea 132; Nay 0; Not voting 6; Excused 0; Absent 3.',
    ]);
    expect(t).toMatch(/^Yea \(132\): Speaker; .*Gabriel Acevero;/m);
    // two Johnsons and two Joneses, told apart by their initials
    expect(t).toMatch(/^Yea .*Andre V\. Johnson Jr\.; .*Steve Johnson;.*Dana Jones;/m);
    expect(t).toMatch(/^Absent \(3\): .*Adrienne A\. Jones/m);
    expect(parseStateRollCallRender(t, MD_HOU_2026)).toMatchObject({ state: 'MD', chamber: 'House', session: '2026RS', seq: 1104, bill: 'SB 128' });
    expect(readStateRollCallRecord(mdHou2026(), MD_HOU_2026)!.groups['Absent or not voting']).toHaveLength(9);
  });

  it('a bare label is the member no other label of the vote names ("Jones" beside "Jones, A.")', () => {
    expect(mdRender(mdHou2026(), MD_HOU_2026, 0, 'Jones, D.', 'Jones')).toMatch(/^Yea .*Dana Jones;/m);
    // with no other label to take Adrienne Jones out, a bare "Jones" is two members, and is kept as printed
    const b = mdHou2026();
    b[0] = tamper(tamper(b[0], 'Jones, D.', 'Jones'), 'Jones, A.', 'Jonas');
    expect(readStateRollCallDocs(b, MD_HOU_2026)).toMatch(/^Yea .*; Jones;/m);
  });

  it('reads a 2019 Senate consent calendar printed sideways, for each bill it carries, from the PDF itself', async () => {
    resetStateRollCallPacing();
    const pdf = readFileSync(fileURLToPath(new URL('./__fixtures__/stateRollCall/md-2019-senate-0777.pdf', import.meta.url)));
    for (const url of [MD_SEN_2019, MD_SEN_2019.replace('#HB243', '#HB685')]) {
      const docs = stateRollCallDocs(url)!;
      const cm = mdCm('S-2019');
      const fetchImpl = async (u: string) => new Response(u === docs[0] ? pdf : cm[docs.indexOf(u) - 1], { status: 200 });
      const t = (await fetchStateRollCallText(url, { fetchImpl, now: () => 0, sleep: async () => {} }))!;
      expect(t.split('\n').slice(0, 3)).toEqual([`Maryland Senate vote 777 (2019RS), ${url.endsWith('243') ? 'HB 243' : 'HB 685'}, 2019-03-25.`,
        'Question: Third Reading Consent Calendar', 'Yea 47; Nay 0; Not voting 0; Excused 0; Absent 0.']);
      expect(t).toMatch(/^Yea \(47\): Mr\. President; Sarah K\. Elfreth;/m);
      resetStateRollCallPacing();
    }
  });

  it('reads a 2017 page: a veto question over two cells, and a tally printed "Excused (Absent)" ... "Absent"', () => {
    const t = mdRender(mdSen2017(), MD_SEN_2017)!;
    expect(t.split('\n').slice(0, 3)).toEqual(['Maryland Senate vote 1361 (2017RS), SB 907 of 2016, 2017-04-10.',
      'Question: Shall the bill pass notwithstanding the objection of the Chief Executive?', 'Yea 0; Nay 45; Not voting 2; Excused 0; Absent 0.']);
    expect(t).toMatch(/^Not voting \(2\): Douglas J\. J\. Peters; Andrew A\. Serafini$/m);
  });

  it('reads a 2013 page (SB 281), and only the years it has been proved on', () => {
    expect(stateRollCallDocs(MD_HOU_2013)!.slice(0, 2)).toEqual([`${MD}2013RS/votes/house/0895.htm`, `${MD}mgawebsite/Committees/Details?cmte=app&ys=2013RS`]);
    // 2013 votes are pages, not PDFs; 2014-2016 have not been read, so they are not addresses at all
    for (const u of [MD_HOU_2013.replace('.htm', '.pdf'), MD_HOU_2013.replace('2013RS', '2014RS'), MD_HOU_2013.replace('2013RS', '2016RS')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
    const t = mdRender(mdHou2013(), MD_HOU_2013)!;
    expect(t.split('\n').slice(0, 3)).toEqual(['Maryland House vote 895 (2013RS), SB 281, 2013-04-03.',
      'Question: On Third Reading (Amend)', 'Yea 78; Nay 61; Not voting 0; Excused 0; Absent 2.']);
    expect(t).toMatch(/^Nay \(61\): .*; Mary-Dulany James;/m);
    expect(t).toMatch(/^Absent \(2\): Jill P\. Carter; Joseph J\. Minnick$/m);
    // a bare surname no 2013 House committee page lists (he had moved to the Senate) is left as printed, never guessed
    expect(t).toMatch(/; Feldman;/);
    expect(t).not.toMatch(/Brian J\. Feldman/);
  });

  it('refuses a 2013 page that does not add up, or whose committee pages are another session\'s', () => {
    expect(mdWhy(mdHou2013(), MD_HOU_2013, 0, '78&nbsp;Yeas', '77&nbsp;Yeas')).toBe('the Yea heading prints 78 and the tally 77');
    expect(mdWhy(mdHou2013(), MD_HOU_2013, 0, '2013&nbsp;Regular&nbsp;Session', '2014&nbsp;Regular&nbsp;Session')).toBe('the vote does not name this session');
    // the member's own committee page, moved to another session: James is no longer a known member, so her name is not read
    const t = mdRender(mdHou2013(), MD_HOU_2013, 1, '2013 Regular Session', '2012 Regular Session');
    expect(t ?? '').not.toMatch(/Mary-Dulany James/);
  });

  it('refuses a group that is not its heading\'s count, a heading that is not the tally\'s, or one out of order', () => {
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Voting Yea - 132', 'Voting Yea - 131')).toBe('the Yea group lists 132 names and prints 131');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, '132 Yeas', '131 Yeas')).toBe('the Yea heading prints 132 and the tally 131');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Bouchat', 'Bouchat\tBoafo')).toMatch(/^the Not voting group lists 7/);
    expect(mdWhy(mdSen2017(), MD_SEN_2017, 0, 'Not&nbsp;Voting&nbsp;-&nbsp;2', 'Excused from Voting - 2')).toBe('a cell the reader cannot read: Excused from Voting - 2');
  });

  it('refuses another number, chamber, session, day or bill, and a label printed twice', () => {
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'SEQ NO. 1104', 'SEQ NO. 1105')).toBe('the vote does not print this number');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Maryland House of Delegates', 'Senate of Maryland')).toBe('the vote does not name this chamber');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, '2026 Regular Session', '2025 Regular Session')).toBe('the vote does not name this session');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Apr 8, 2026', 'Apr 8, 2025')).toBe('the vote has no calendar date in its session year');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Apr 8, 2026', 'Apr 31, 2026')).toBe('the calendar date is not a real day');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, '\nSB 128\n', '\nSB 129\n')).toBe('the vote does not name the bill');
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'Stinnett', 'Stewart')).toBe('a label is printed twice');
  });

  it('reads no vote on a motion: the question must be on the bill (runner, 2026-11-16)', () => {
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 0, 'On Third Reading\t(Emerg)', 'Motion to Special Order')).toBe('the question is not a vote on the bill: Motion to Special Order');
    expect(mdQuestionIsOnTheBill('ON THIRD READING (Rules Suspended)')).toBe(true);
    expect(mdQuestionIsOnTheBill('On Third Reading and Final Passage (Hse concurred)')).toBe(true);
    expect(mdQuestionIsOnTheBill('Conference Committee Report - Adoption')).toBe(true);
    expect(mdQuestionIsOnTheBill('On third reading for final passage')).toBe(true); // 2021 Senate 855
    for (const q of ['Favorable with amendments adp - ON 2ND RDG', 'Motion To Recommit', 'Previous Question', 'Shall the Bill be Introduced?', 'FLA Del. Miller /263328/1']) {
      expect(mdQuestionIsOnTheBill(q)).toBe(false);
    }
  });

  it('refuses a committee page of another session or with no members, and a key that names two people', () => {
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 3, '2026 Regular Session', '2025 Regular Session')).toBe('the committee page ent is not this session\'s, or lists no members');
    const app = mdHou2026()[1];
    const empty = app.replace(/<a href="\/mgawebsite\/Members\/Details\/[^\n]*\n/g, '');
    expect(empty).not.toBe(app);
    const b = mdHou2026();
    b[1] = empty;
    expect(explainMarylandVote(b, MD_HOU_2026)).toEqual({ refused: 'the committee page app is not this session\'s, or lists no members' });
    const key = /Details\/([^"]+)">([^<]+)</.exec(app)!;
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 2, '</div>', `<a href="/mgawebsite/Members/Details/${key[1]}">Someone, Else</a>\n</div>`))
      .toBe(`the key ${key[1]} names both ${key[2].replace(/^([^,]+), (.+)$/, '$2 $1')} and Else Someone`);
    // the same, on one page: the page itself is refused
    expect(mdWhy(mdHou2026(), MD_HOU_2026, 1, '</div>', `<a href="/mgawebsite/Members/Details/${key[1]}">Someone, Else</a>\n</div>`))
      .toBe(`the key ${key[1]} names both ${key[2]} and Someone, Else`);
  });
});

describe('state roll-call pages — Maryland, a veto overridden in the next session', () => {
  // 2021 House vote 42 overrode the veto of 2020's HB 4 ("SPECIAL ORDER CALENDAR - 2020 VETOED HOUSE BILL"); 2021 had its
  // own HB 4. Here the 2026 vote is made into the override of a 2025 vetoed bill, one change at a time.
  const VETO = `${MD}2026RS/votes/house/1104.pdf#2025-SB128`;
  const veto = (cal = 'SPECIAL ORDER CALENDAR - 2025 VETOED SENATE BILL', q = 'Shall the Bill pass notwithstanding the objections\nof the Chief Executive?'): string[] => {
    const b = mdHou2026();
    b[0] = tamper(tamper(b[0], 'Third Reading (SB) Calendar No.17', cal), 'On Third Reading\t(Emerg)', q);
    return b;
  };
  const why = (b: string[], url: string): string => { const v = explainMarylandVote(b, url); return 'refused' in v ? v.refused : 'read'; };

  it('reads it cited with the bill\'s year, and names the bill so in its lines', () => {
    const t = readStateRollCallDocs(veto(), VETO)!;
    expect(t.split('\n')[0]).toBe('Maryland House vote 1104 (2026RS), SB 128 of 2025, 2026-04-08.');
    const [line] = stateRollCallLinesFor(VETO, t, 'Acevero', 'Gabriel Acevero');
    expect(line).toBe('Maryland House vote 1104 (2026RS), SB 128 of 2025 - Shall the Bill pass notwithstanding the objections of the Chief Executive? (2026-04-08): Gabriel Acevero voted Yea.');
    expect(verifyStateRollCallLine(line, VETO, t, 'Acevero', 'Gabriel Acevero').verdict).toBe('verified');
    expect(verifyStateRollCallLine(line.replace(' of 2025', ''), VETO, t, 'Acevero', 'Gabriel Acevero').verdict).not.toBe('verified');
  });

  it('refuses the file cited without the year, a year it does not print, the other chamber\'s bill, and a question that is no override', () => {
    expect(why(veto(), MD_HOU_2026)).toBe('the vote is on a vetoed bill of another session: cite it with the bill\'s year');
    expect(why(mdHou2026(), VETO)).toBe('the vote does not print this bill\'s session as vetoed');
    expect(why(veto('SPECIAL ORDER CALENDAR - 2025 VETOED HOUSE BILL'), VETO)).toBe('the vote does not print this bill\'s session as vetoed');
    expect(why(veto(undefined, 'On Third Reading'), VETO)).toBe('the question is not a veto override: On Third Reading');
    // only the previous session's bill
    expect(isStateRollCallUrl(`${MD}2026RS/votes/house/1104.pdf#2024-SB128`)).toBe(false);
    expect(isStateRollCallUrl(VETO)).toBe(true);
    // the 2021 Senate printed the sponsor without the dash: "HB 4 Delegate Atterbeary"; any other word after the bill is refused
    const read = readStateRollCallDocs(veto(), VETO);
    expect(readStateRollCallDocs(veto().map((d, i) => i ? d : tamper(d, '\nSB 128\n', '\nSB 128 Senator Hershey\n')), VETO)).toBe(read);
    expect(why(veto().map((d, i) => i ? d : tamper(d, '\nSB 128\n', '\nSB 128 Amended\n')), VETO)).toBe('the vote does not name the bill');
  });
});

describe('state roll-call pages — Maryland lines', () => {
  const t = mdRender(mdHou2026(), MD_HOU_2026)!;

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(MD_HOU_2026, t, 'Acevero', 'Gabriel Acevero')).toEqual([ACEVERO]);
    expect(verifyStateRollCallLine(ACEVERO, MD_HOU_2026, t, 'Acevero', 'Gabriel Acevero')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(ACEVERO)).toMatchObject({ state: 'MD', chamber: 'House', vote: 'Yea', name: 'Gabriel Acevero', bill: 'SB 128', seq: 1104 });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Acevero', full = 'Gabriel Acevero', url = MD_HOU_2026) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(ACEVERO.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(ACEVERO.replace('Gabriel Acevero', 'Vaughn Stewart'))).not.toBe('verified');
    expect(v(ACEVERO, 'Stewart', 'Vaughn Stewart')).toBe('name_not_present');
    expect(v(ACEVERO.replace('SB 128', 'SB 129'))).toBe('snippet_not_found');
    expect(v(ACEVERO.replace('2026-04-08', '2026-04-07'))).toBe('snippet_not_found');
    expect(v(ACEVERO, 'Acevero', 'Gabriel Acevero', MD_HOU_2026.replace('1104', '1105'))).toBe('snippet_not_found');
  });

  it('gives an absent member "was absent", never a Yea or a Nay, and the presiding officer no line', () => {
    const [l] = stateRollCallLinesFor(MD_HOU_2026, t, 'Metzgar', 'Ric Metzgar');
    expect(l).toBe('Maryland House vote 1104 (2026RS), SB 128 - On Third Reading (2026-04-08): Ric Metzgar was absent.');
    expect(verifyStateRollCallLine(l.replace('was absent', 'voted Nay'), MD_HOU_2026, t, 'Metzgar', 'Ric Metzgar').verdict).toBe('snippet_not_found');
    expect(stateRollCallLinesFor(MD_HOU_2026, t, 'Boafo', 'Adrian Boafo')[0]).toMatch(/Adrian Boafo did not vote\.$/);
    expect(stateRollCallLinesFor(MD_HOU_2026, t, 'Peña-Melnyk', 'Joseline A. Peña-Melnyk')).toEqual([]);
  });
});

// Saved 2026-11-18 from www.kslegislature.gov with the verifier's own user-agent. 2017-2022 and the special sessions are
// the archive's vote pages (li_YYYY); 2023 on, the current site's. The reader prints no party.
const KS = 'https://www.kslegislature.gov/';
const ksPage = (name: string): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}.html`, import.meta.url)), 'utf8');
const KS_H18 = `${KS}li_2018/b2017_18/measures/vote_view/je_20180329105013_233428/`;
const KS_S17 = `${KS}li_2018/b2017_18/measures/vote_view/je_20170222110146_941423/`;
const KS_S17_MOTION = `${KS}li_2018/b2017_18/measures/vote_view/je_20170601142214_051767/`;
const KS_H20S = `${KS}li_2020s/b2020s/measures/vote_view/je_20200603210950_181372/`;
const KS_H26 = `${KS}b2025_26/vote/?apn=b2025_26/year2/house/legislative_days/day054_20260410/vote_records/0426_HB2513.odt`;
const KS_S26 = `${KS}b2025_26/vote/?apn=b2025_26/year2/senate/legislative_days/day054_20260410/vote_records/vote_407_HB2535.odt`;
const KS_H23 = `${KS}b2023_24/vote/?apn=b2023_24/year1/house/legislative_days/day063_20230428/vote_records/0353_SB113.odt`;
const ksRender = (url: string, html: string): string => {
  const t = readStateRollCallDocs([html], url);
  if (!t) throw new Error('the page did not read');
  return t;
};
const ksWhy = (url: string, html: string): string => {
  const v = explainKansasVote([html], url);
  return 'refused' in v ? v.refused : 'read';
};
const KS_STEVE_ALFORD = 'Kansas House vote je_20180329105013_233428 (2017-2018), SB 328 - Final Action - Passed as amended (2018-03-29): Steve Alford voted Yea.';

describe('state roll-call pages — Kansas address', () => {
  it('knows an archive vote page and a current-site vote page, each read alone, a second apart', () => {
    expect(parseKansasVoteUrl(KS_H18)).toMatchObject({ session: '2017-2018', voteId: 'je_20180329105013_233428', chamber: null, day: '2018-03-29', layout: 'archive' });
    expect(parseKansasVoteUrl(KS_H20S)).toMatchObject({ session: '2020S1', layout: 'archive' });
    expect(parseKansasVoteUrl(KS_S26)).toMatchObject({ session: '2025-2026', voteId: 'vote_407_HB2535', chamber: 'Senate', day: '2026-04-10', layout: 'current' });
    expect(stateRollCallDocs(KS_H26)).toEqual([KS_H26]);
    expect(stateRollCallMinGapMs(KS_H18)).toBe(1_000);
    // the old host the dump stores, plain http, an archive prefix that is not the session's, a look-alike host, a bill page
    for (const u of [KS_H18.replace('www.kslegislature.gov/li_2018', 'www.kslegislature.org/li'), KS_H18.replace('https', 'http'),
      KS_H18.replace('li_2018/', 'li_2020/'), KS_H26.replace('.gov/', '.gov.example.com/'), `${KS}li_2018/b2017_18/measures/hb2476/`,
      KS_H26.replace('.odt', '.pdf')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('turns a member link and its printed label into a full name, and keeps a label that does not fit as printed', () => {
    expect(ksMemberName('Brownlee Paige', 'rep_paige_wanda_1', 'House')).toBe('Wanda Brownlee Paige');
    expect(ksMemberName("O'Shea", 'sen_oshea_kristen_1', 'Senate')).toBe("Kristen O'Shea");
    // an initial before the family name, or after it (2019-2020 prints both), must be the given name's
    expect(ksMemberName('A. Smith', 'rep_smith_adam_1', 'House')).toBe('Adam Smith');
    expect(ksMemberName('Carpenter, W.', 'rep_carpenter_will_1', 'House')).toBe('Will Carpenter');
    expect(ksMemberName('Carpenter, B.', 'rep_carpenter_will_1', 'House')).toBe('Carpenter, B.');
    // she was elected as Tory Arnberger; the 2023 pages print her married name, and the id keeps the first one
    expect(ksMemberName('Blew', 'rep_arnberger_tory_1', 'House')).toBe('Tory Blew');
    expect(ksMemberName('Lee', 'rep_leehahn_tatum_1', 'House')).toBe('Tatum Lee');
    // an id of more words than a family and a given name is not split by guess
    expect(ksMemberName('Smith', 'rep_jones_mary_ann_1', 'House')).toBe('Smith');
    expect(() => ksMemberName('Alcala', 'sen_alcala_john_1', 'House')).toThrow();
  });
});

describe('state roll-call pages — reading Kansas', () => {
  it('reads a 2018 archive House vote: bill, question, day, tally and every member by full name', () => {
    const t = ksRender(KS_H18, ksPage('ks-2018-house-je_20180329105013_233428'));
    expect(t.split('\n').slice(0, 3)).toEqual([
      'Kansas House vote je_20180329105013_233428 (2017-2018), SB 328, 2018-03-29.', 'Question: Final Action - Passed as amended',
      'Yea 111; Nay 13; Present 0; Absent 1; Not voting 0.',
    ]);
    expect(t).toMatch(/^Yea \(111\): John Alcala; Steve Alford;/m);
    expect(t).toMatch(/^Absent \(1\): Ponka We Victors$/m);
  });

  it('reads a 2017 Senate vote with members present and passing', () => {
    const t = ksRender(KS_S17, ksPage('ks-2017-senate-je_20170222110146_941423'));
    expect(t).toMatch(/^Present \(2\): Tom Hawk; Carolyn McGinn$/m);
    expect(t).toMatch(/Oletha Faust-Goudeau/);
  });

  it('reads a special session\'s vote, whose page prints the bill without a link', () => {
    expect(ksRender(KS_H20S, ksPage('ks-2020s-house-je_20200603210950_181372')).split('\n')[0])
      .toBe('Kansas House vote je_20200603210950_181372 (2020S1), HB 2016, 2020-06-03.');
  });

  it('reads current-site votes of 2023 and 2026, a Senate vote printed the day after its legislative day', () => {
    expect(ksRender(KS_H26, ksPage('ks-2026-house-0426_HB2513'))).toMatch(/^Nay \(35\): .*Wanda Brownlee Paige;/m);
    const s = ksRender(KS_S26, ksPage('ks-2026-senate-vote_407_HB2535'));
    expect(s.split('\n').slice(0, 3)).toEqual(['Kansas Senate vote vote_407_HB2535 (2025-2026), HB 2535, 2026-04-11.', 'Question: Adopt CCR',
      'Yea 30; Nay 8; Present 1; Absent 1; Not voting 0.']);
    // a member under a later family name than her id's
    const h23 = ksRender(KS_H23, ksPage('ks-2023-house-0353_SB113'));
    expect(h23).toMatch(/^Yea \(83\): .*; Tory Blew; /m);
    expect(stateRollCallLinesFor(KS_H23, h23, 'Blew', 'Tory Marie Blew')[0]).toMatch(/: Tory Blew voted Yea\.$/);
  });

  it('refuses a vote on a motion, and knows which questions are votes on the bill', () => {
    expect(ksWhy(KS_S17_MOTION, ksPage('ks-2017-senate-je_20170601142214_051767'))).toMatch(/^the question is not a vote on the bill/);
    for (const q of ['Final Action - Passed as amended', 'Emergency Final Action - Not passed', 'Conference Committee Report was adopted',
      'Adopt CCR', 'Concurred with amendments', 'Motion to override line item veto prevailed; Line item veto overridden', 'Consent Calendar Passed']) {
      expect(ksQuestionIsOnTheBill(q)).toBe(true);
    }
    for (const q of ['Committee of the Whole - Amendment by Representative Highberger was rejected', 'Motion to Call the Question',
      'Senator Olson motioned to return jointly to Committees. The motion failed.']) {
      expect(ksQuestionIsOnTheBill(q)).toBe(false);
    }
  });

  it('refuses a page whose counts, day, bill or member list do not hold together', () => {
    const h = ksPage('ks-2018-house-je_20180329105013_233428');
    expect(ksWhy(KS_H18, h)).toBe('read');
    // the vote page's heading says another day than its address
    expect(ksWhy(KS_H18, tamper(h, '03/29/2018', '03/28/2018'))).not.toBe('read');
    // a group's printed count no longer equals the members under it
    expect(ksWhy(KS_H18, tamper(h, 'Nay - (13)', 'Nay - (14)'))).not.toBe('read');
    // a member listed twice
    const c = ksPage('ks-2026-senate-vote_407_HB2535');
    expect(ksWhy(KS_S26, c)).toBe('read');
    expect(ksWhy(KS_S26, tamper(c, 'Yea 30, Nay 8', 'Yea 31, Nay 8'))).not.toBe('read');
    // a vote printed two days after its legislative day
    expect(ksWhy(KS_S26, tamper(c, 'April 11, 2026', 'April 12, 2026'))).not.toBe('read');
  });
});

describe('state roll-call pages — Kansas lines', () => {
  const t = ksRender(KS_H18, ksPage('ks-2018-house-je_20180329105013_233428'));

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(KS_H18, t, 'Alford', 'Steve Alford')).toEqual([KS_STEVE_ALFORD]);
    expect(verifyStateRollCallLine(KS_STEVE_ALFORD, KS_H18, t, 'Alford', 'Steve Alford')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(KS_STEVE_ALFORD)).toMatchObject({ state: 'KS', chamber: 'House', vote: 'Yea', name: 'Steve Alford', bill: 'SB 328' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Alford', full = 'Steve Alford', url = KS_H18) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(KS_STEVE_ALFORD.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(KS_STEVE_ALFORD.replace('Steve Alford', 'John Whitmer'))).not.toBe('verified');
    expect(v(KS_STEVE_ALFORD, 'Whitmer', 'John Whitmer')).toBe('name_not_present');
    expect(v(KS_STEVE_ALFORD.replace('SB 328', 'SB 329'))).toBe('snippet_not_found');
    expect(v(KS_STEVE_ALFORD.replace('2018-03-29', '2018-03-28'))).toBe('snippet_not_found');
    expect(v(KS_STEVE_ALFORD, 'Alford', 'Steve Alford', KS_H18.replace('233428', '233429'))).toBe('snippet_not_found');
  });

  it('gives an absent member "was absent" and a member present "was present and did not vote", never a Yea or a Nay', () => {
    expect(stateRollCallLinesFor(KS_H18, t, 'Victors', 'Ponka We Victors')).toEqual([
      'Kansas House vote je_20180329105013_233428 (2017-2018), SB 328 - Final Action - Passed as amended (2018-03-29): Ponka We Victors was absent.']);
    const s = ksRender(KS_S17, ksPage('ks-2017-senate-je_20170222110146_941423'));
    const [l] = stateRollCallLinesFor(KS_S17, s, 'Hawk', 'Tom Hawk');
    expect(l).toMatch(/Tom Hawk was present and did not vote\.$/);
    expect(verifyStateRollCallLine(l.replace('was present and did not vote', 'voted Yea'), KS_S17, s, 'Hawk', 'Tom Hawk').verdict).toBe('snippet_not_found');
  });

  it('reads the tally as Yea, Nay and the rest absent or not voting', () => {
    expect(readStateRollCallRecord([ksPage('ks-2017-senate-je_20170222110146_941423')], KS_S17)).toMatchObject({ bill: 'SB 144', date: '2017-02-22', chamber: 'Senate' });
  });
});

// Saved 2026-11-18 from leg.colorado.gov: a vote's own page (/bill_votes/<id>) and the session's member list
// (/legislators?sess=2019a), which is the second document the reader reads. The vote page prints surnames; the member list
// names them in full. The member list has a party column; the reader does not read it.
const CO = 'https://leg.colorado.gov/bill_votes/';
const CO_H19 = `${CO}16466#HB19-1177`;
const CO_S19 = `${CO}16461#HB19-1177`;
const CO_S22 = `${CO}26305#SB22-086`;
const CO_S26 = `${CO}28333#SB26-004`;
const coDocs = (vote: string, members: string): string[] => [ksPage(vote), ksPage(members)];
const coRender = (url: string, docs: string[]): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error('the page did not read');
  return t;
};
const coWhy = (url: string, docs: string[]): string => {
  const v = explainColoradoVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const CO_ARNDT = 'Colorado House vote 16466 (2019A), HB19-1177 - Third reading - Bill (2019-03-04): Jeni James Arndt voted Yes.';

describe('state roll-call pages — Colorado address', () => {
  it('knows a vote page named with its bill, and reads it with the session\'s member list, a second apart', () => {
    expect(parseColoradoVoteUrl(CO_H19)).toEqual({ state: 'CO', stateName: 'Colorado', session: '2019A', voteId: 16466, bill: 'HB19-1177' });
    expect(parseColoradoVoteUrl(`${CO}12#HB20B-1013`)).toMatchObject({ session: '2020B', bill: 'HB20B-1013' });
    expect(stateRollCallDocs(CO_S26)).toEqual([`${CO}28333`, 'https://leg.colorado.gov/legislators?sess=2026a']);
    expect(stateRollCallMinGapMs(CO_H19)).toBe(1_000);
    expect(isStateRollCallUrl(CO_H19)).toBe(true);
    // the dump's dead address, no bill after the #, plain http, a look-alike host, the bill's page
    for (const u of ['http://leg.colorado.gov/content/hb19-1166vote5b8aea', `${CO}16466`, CO_H19.replace('https', 'http'),
      CO_H19.replace('leg.colorado.gov', 'leg.colorado.gov.example.com'), 'https://leg.colorado.gov/bills/hb19-1177', `${CO}016466#HB19-1177`]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('writes the dump\'s bill numbers as the vote page prints them, and refuses another session\'s bill', () => {
    expect(coBillTag('2019A', 'HB 19-1177')).toBe('HB19-1177');
    expect(coBillTag('2026A', 'SB 4')).toBe('SB26-004');
    expect(coBillTag('2026A', 'HB1097')).toBe('HB26-1097');
    expect(coBillTag('2020B', 'HB 20B-1013')).toBe('HB20B-1013');
    expect(coBillTag('2019A', 'HB 18-1177')).toBeNull();
    expect(coBillTag('2020B', 'HB 20-1013')).toBeNull();
  });

  it('names a printed label in full from the session\'s member list, and keeps a label that fits none or several as printed', () => {
    const l19 = coMembers(ksPage('co-2019a-members'))!;
    expect(coMemberName('Valdez A.', l19)).toBe('Alex Valdez');
    expect(coMemberName('Valdez D.', l19)).toBe('Donald Valdez');
    expect(coMemberName('Valdez', l19)).toBe('Valdez');
    expect(coMemberName('Valdez Z.', l19)).toBe('Valdez Z.');
    expect(coMemberName('Kennedy', l19)).toBe('Chris deGruy Kennedy');
    // the presiding officer, through the list's leadership tile
    expect(coMemberName('President', l19)).toBe('Leroy Garcia');
    expect(coMemberName('Speaker', l19)).toBe('KC Becker');
    // 2022's list shows two Presidents of the Senate (one resigned during the session): two people fit, no name
    expect(coMemberName('President', coMembers(ksPage('co-2022a-members'))!)).toBe('President');
  });
});

describe('state roll-call pages — reading Colorado', () => {
  it('reads a 2019 House vote: bill, question, day, tally, a vacant seat, and every member by full name', () => {
    const t = coRender(CO_H19, coDocs('co-2019-house-16466', 'co-2019a-members'));
    expect(t.split('\n').slice(0, 3)).toEqual(['Colorado House vote 16466 (2019A), HB19-1177, 2019-03-04.', 'Question: Third reading - Bill',
      'Yes 38; No 25; Absent 0; Excused 1.']);
    expect(t).toMatch(/^Yes \(38\): Jeni James Arndt; Adrienne Benavidez;/m);
    expect(t).toMatch(/^Excused \(1\): Brianna Titone$/m);
    expect(t).not.toMatch(/District 57/);
  });

  it('reads a Senate vote whose presiding officer is printed only as "President"', () => {
    const t = coRender(CO_S19, coDocs('co-2019-senate-16461', 'co-2019a-members'));
    expect(t.split('\n')[2]).toBe('Yes 18; No 17; Absent 0; Excused 0.');
    expect(t).toMatch(/^No \(17\): .*; Leroy Garcia$/m);
  });

  it('counts the presiding officer once when the page lists him twice, by surname and as "President"', () => {
    const t = coRender(CO_S26, coDocs('co-2026-senate-28333', 'co-2026a-members'));
    expect(t.split('\n')[2]).toBe('Yes 20; No 13; Absent 0; Excused 2.');
    expect(t.match(/James Coleman/g)).toHaveLength(1);
    expect(stateRollCallLinesFor(CO_S26, t, 'Coleman', 'James Coleman')).toEqual([
      'Colorado Senate vote 28333 (2026A), SB26-004 - Third reading - Bill (2026-02-03): James Coleman voted Yes.']);
  });

  it('knows which questions are votes on the bill', () => {
    for (const q of ['Third reading - Bill', 'Third Reading - RESOLUTION', 'Senate Amendments - Concur', 'House amendments - Repass',
      'Conference Committee Report - Adopt CCR', 'Conference committee - Repass']) {
      expect(coQuestionIsOnTheBill(q)).toBe(true);
    }
    for (const q of ['Committee of the Whole - Amendment', 'Third reading - Amend (L.012)', 'Senate Amendments - Not Concur Appt CC',
      'Third reading - Refer', 'Senate Amendments - Adhere']) {
      expect(coQuestionIsOnTheBill(q)).toBe(false);
    }
  });

  it('refuses a page whose bill, question, chamber, counts or member rows do not hold together', () => {
    const [h, m] = coDocs('co-2019-house-16466', 'co-2019a-members');
    expect(coWhy(CO_H19, [h, m])).toBe('read');
    // the page prints another bill than its address names
    expect(coWhy(CO_H19, [tamper(h, "tag-heading-white'>\n    HB19-1177", "tag-heading-white'>\n    HB19-1178"), m])).toMatch(/^the page is for HB19-1178, not HB19-1177$/);
    // a vote on a motion
    expect(coWhy(CO_H19, [tamper(h, '<span>Bill</span>', '<span>Amend (L.012)</span>'), m])).toMatch(/^the question is not a vote on the bill/);
    // a printed count no longer equals the members under it
    expect(coWhy(CO_H19, [tamper(h, 'count-tag Yes">\n              38', 'count-tag Yes">\n              39'), m])).toMatch(/^the Yes group lists 38 members and prints 39$/);
    // a member's icon and tag disagree
    expect(coWhy(CO_H19, [tamper(h, '<td>Titone</td>\n          <td class="text-right">\n          <span class="icon vote-icon Excused">',
      '<td>Titone</td>\n          <td class="text-right">\n          <span class="icon vote-icon Yes">'), m])).toMatch(/^a member row that disagrees with itself: Titone$/);
    // a vacant seat printed as a member
    expect(coWhy(CO_H19, [tamper(h, '<td>District 57</td>', '<td>Valdez A.</td>'), m])).toMatch(/^a vacant row that names no district/);
    // the member table names the other chamber
    expect(coWhy(CO_H19, [tamper(h, 'Votes by House member', 'Votes by Senate member'), m])).toMatch(/^the member list is not the chamber's$/);
    // no member list
    expect(coWhy(CO_H19, [h, '<html></html>'])).toMatch(/^the member list did not read$/);
    // the presiding officer listed twice with two different votes
    const s = ksPage('co-2026-senate-28333');
    expect(coWhy(CO_S26, [s, ksPage('co-2026a-members')])).toBe('read');
    expect(coWhy(CO_S26, [tamper(s, '<td>President</td>\n          <td class="text-right">\n          <span class="icon vote-icon Yes">\n            <i class="fa-solid fa-thumbs-up" aria-hidden="true"></i>\n          </span>\n          <span class="vote-tag Yes">\n            Yes',
      '<td>President</td>\n          <td class="text-right">\n          <span class="icon vote-icon No">\n            <i class="fa-solid fa-thumbs-down" aria-hidden="true"></i>\n          </span>\n          <span class="vote-tag No">\n            No'), ksPage('co-2026a-members')])).toMatch(/^the president is listed twice under different votes$/);
  });
});

describe('state roll-call pages — Colorado lines', () => {
  const t = coRender(CO_H19, coDocs('co-2019-house-16466', 'co-2019a-members'));

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(CO_H19, t, 'Arndt', 'Jeni James Arndt')).toEqual([CO_ARNDT]);
    expect(verifyStateRollCallLine(CO_ARNDT, CO_H19, t, 'Arndt', 'Jeni James Arndt')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(CO_ARNDT)).toMatchObject({ state: 'CO', chamber: 'House', vote: 'Yes', name: 'Jeni James Arndt', bill: 'HB19-1177' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Arndt', full = 'Jeni James Arndt', url = CO_H19) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(CO_ARNDT.replace('voted Yes', 'voted No'))).toBe('snippet_not_found');
    expect(v(CO_ARNDT.replace('Jeni James Arndt', 'Mark Baisley'))).not.toBe('verified');
    expect(v(CO_ARNDT, 'Baisley', 'Mark Baisley')).toBe('name_not_present');
    expect(v(CO_ARNDT.replace('HB19-1177 -', 'HB19-1178 -'))).toBe('snippet_not_found');
    expect(v(CO_ARNDT.replace('2019-03-04', '2019-03-05'))).toBe('snippet_not_found');
    expect(v(CO_ARNDT, 'Arndt', 'Jeni James Arndt', CO_H19.replace('16466', '16467'))).toBe('snippet_not_found');
  });

  it('gives an excused member "was excused", never a Yes or a No', () => {
    const [l] = stateRollCallLinesFor(CO_H19, t, 'Titone', 'Brianna Titone');
    expect(l).toBe('Colorado House vote 16466 (2019A), HB19-1177 - Third reading - Bill (2019-03-04): Brianna Titone was excused.');
    expect(verifyStateRollCallLine(l.replace('was excused', 'voted Yes'), CO_H19, t, 'Titone', 'Brianna Titone').verdict).toBe('snippet_not_found');
  });

  it('gives no line to a label two people fit (2022\'s "President")', () => {
    const s = coRender(CO_S22, coDocs('co-2022-senate-26305', 'co-2022a-members'));
    expect(s).toMatch(/; President(;|$)/m);
    expect(stateRollCallLinesFor(CO_S22, s, 'Fenberg', 'Steve Fenberg')).toEqual([]);
  });

  it('reads the tally as Yea, Nay and the rest absent or not voting', () => {
    const r = readStateRollCallRecord(coDocs('co-2019-house-16466', 'co-2019a-members'), CO_H19)!;
    expect(r).toMatchObject({ bill: 'HB19-1177', date: '2019-03-04', chamber: 'House' });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting']]).toEqual([38, 25, ['Brianna Titone']]);
  });
});

describe('a name the person is also published under (md-01, 2026-11-18)', () => {
  // A roll call prints the name a member held on the day. Maryland's 2023 votes print "White" for the member the
  // roster calls "Jennifer White Holland": no label fit, so the vote got no line.
  const text = sdRender(84688)!;
  const now = { last: 'Castle', full: 'Wilma Castle' }; // a present name no label of this roll call fits
  const was = [{ fullName: 'Will Mortenson', lastName: 'Mortenson' }];

  it('gives no line under the present name alone, and the line under the other name', () => {
    expect(stateRollCallLinesFor(SD_URL(84688), text, now.last, now.full)).toEqual([]);
    expect(stateRollCallLinesFor(SD_URL(84688), text, now.last, now.full, was)).toEqual([MORTENSON]);
    expect(verifyStateRollCallLine(MORTENSON, SD_URL(84688), text, now.last, now.full).verdict).toBe('name_not_present');
    expect(verifyStateRollCallLine(MORTENSON, SD_URL(84688), text, now.last, now.full, was).verdict).toBe('verified');
  });

  it('another name that fits no member, or names that fit two members, give nothing', () => {
    expect(stateRollCallLinesFor(SD_URL(84688), text, now.last, now.full, [{ fullName: 'Will Nobody', lastName: 'Nobody' }])).toEqual([]);
    const two = [...was, { fullName: 'Julie Auch', lastName: 'Auch' }];
    expect(stateRollCallLinesFor(SD_URL(84688), text, 'Auch', 'Julie Auch')).toHaveLength(1); // the control: he is on the page
    expect(stateRollCallLinesFor(SD_URL(84688), text, now.last, now.full, two)).toEqual([]);
    // the line of a different member is never verified through another name
    const his = stateRollCallLinesFor(SD_URL(84688), text, 'Auch', 'Julie Auch')[0];
    expect(verifyStateRollCallLine(his, SD_URL(84688), text, now.last, now.full, was).verdict).not.toBe('verified');
  });

  it('does not reach for another name when the person\'s own name is on the page', () => {
    expect(stateRollCallLinesFor(SD_URL(84688), text, 'Mortenson', 'Will Mortenson', [{ fullName: 'Julie Auch', lastName: 'Auch' }])).toEqual([MORTENSON]);
  });
});

// Saved 2026-11-19 from ndlegis.gov: a day's journal (the PDF, as the reader receives it: its lines, pdfLinesBody) and the
// Assembly's member list (/members/members-by-district), the second document the reader reads. The journal prints family
// names ("Becker, Rick C.", "Lee, J.", "Speaker Bellew"); the member list names them in full. The member list prints a
// party on each tile; the reader does not read it.
const ND = 'https://ndlegis.gov/assembly/';
const ND_H17 = `${ND}65-2017/regular/journals/hr-dailyjnl-35.pdf#Page787-HB1279`;
const ND_S19 = `${ND}66-2019/regular/journals/sr-dailyjnl-56.pdf#Page1153-HB1042`;
const ND_S19B = `${ND}66-2019/regular/journals/sr-dailyjnl-56.pdf#Page1153-HB1163`;
const ND_H23 = `${ND}68-2023/regular/journals/hr-dailyjnl-33.pdf#Page910-HB1341`;
const ND_H25_FAIL = `${ND}69-2025/regular/journals/hr-dailyjnl-34.pdf#Page811-HB1326`;
const ND_H25_PASS = `${ND}69-2025/regular/journals/hr-dailyjnl-34.pdf#Page820-HB1326`;
const ndJ: Record<string, string> = { '65': 'nd-65-hr-dailyjnl-35', '66': 'nd-66-sr-dailyjnl-56', '68': 'nd-68-hr-dailyjnl-33', '69': 'nd-69-hr-dailyjnl-34' };
const ndM: Record<string, string> = { '65': 'nd-65-2017-members', '66': 'nd-66-2019-members', '68': 'nd-68-2023-members', '69': 'nd-69-2025-members' };
const ndDocs = (url: string): string[] => { const a = /assembly\/(\d{2})-/.exec(url)![1]; return [mdFile(`${ndJ[a]}.txt`), ksPage(ndM[a])]; };
const ndRender = (url: string, docs = ndDocs(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error('the journal did not read');
  return t;
};
const ndWhy = (url: string, docs: string[]): string => {
  const v = explainNorthDakotaVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const ND_BECKER = 'North Dakota House vote of 2017-02-22, journal page 787 (65th Legislative Assembly), HB 1279 - Final passage of the amended bill: Rick Becker voted Yea.';

describe('state roll-call pages — North Dakota address', () => {
  it('knows a journal page named with its bill, and reads it with the Assembly\'s member list, a second apart', () => {
    expect(parseNorthDakotaVoteUrl(ND_H17)).toEqual({ state: 'ND', stateName: 'North Dakota', chamber: 'House', assembly: 65, year: 2017, day: 35, page: 787, billType: 'HB', billNum: 1279 });
    expect(parseNorthDakotaVoteUrl(`${ND}68-2023/regular/journals/sr-dailyjnl-44.pdf#Page1220-SCR4010`)).toMatchObject({ chamber: 'Senate', billType: 'SCR', billNum: 4010 });
    expect(stateRollCallDocs(ND_S19)).toEqual([`${ND}66-2019/regular/journals/sr-dailyjnl-56.pdf`, `${ND}66-2019/regular/members/members-by-district`]);
    expect(stateRollCallMinGapMs(ND_H17)).toBe(1_000);
    expect(isStateRollCallUrl(ND_H17)).toBe(true);
    // the dump's address (old host, no page), no bill after the #, the page alone, a year that is not the Assembly's,
    // plain http, a look-alike host, a special session's journal
    for (const u of ['http://www.legis.nd.gov/assembly/65-2017/journals/hr-dailyjnl-35.pdf', ND_H17.replace('-HB1279', ''),
      ND_H17.replace('#Page787-HB1279', ''), ND_H17.replace('65-2017', '65-2019'), ND_H17.replace('https', 'http'),
      ND_H17.replace('ndlegis.gov', 'ndlegis.gov.example.com'), ND_H17.replace('/regular/', '/special-session/'), ND_H17.replace('Page787', 'Page0787')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('names a printed label in full from the member list, and keeps a label that fits none or several as printed', () => {
    const h17 = ndMembers(ksPage('nd-65-2017-members'))!.filter((m) => m.chamber === 'House');
    expect(ndMemberNames(['Becker, Rick C.', 'Becker, Rich S.', 'Roers Jones', 'Jones', 'Schreiber-Beck', 'Bellew'], h17))
      .toEqual(['Rick Becker', 'Rich S. Becker', 'Shannon Roers Jones', 'Terry B. Jones', 'Cynthia Schreiber-Beck', 'Larry Bellew']);
    expect(ndMemberNames(['Zzyzx'], h17)).toEqual(['Zzyzx']);
    const s19 = ndMembers(ksPage('nd-66-2019-members'))!.filter((m) => m.chamber === 'Senate');
    expect(ndMemberNames(['Lee, G.', 'Lee, J.', 'Lee'], s19)).toEqual(['Gary A. Lee', 'Judy Lee', 'Lee']);
    // 2023: Cole Christensen and Rose Christensen, who took his District 24 seat, are both on the list: two fit, no name
    const h23 = ndMembers(ksPage('nd-68-2023-members'))!.filter((m) => m.chamber === 'House');
    expect(ndMemberNames(['Christensen'], h23)).toEqual(['Christensen']);
    expect(ndMembers('<html></html>')).toBeNull();
  });

  it('knows which questions are votes on the bill', () => {
    for (const q of ['on the final passage of the bill', 'on the final passage of the amended bill', 'on the final passage of the reengrossed bill',
      "on the final passage of the bill, over the Governor's veto", 'on the final adoption of the resolution', 'on the final adoption of the amended resolution']) {
      expect(ndQuestionIsOnTheBill(q)).toBe(true);
    }
    for (const q of ['on the final adoption of Division A of Engrossed HB 1588', 'on the motion to reconsider the action whereby HB 1326 failed to pass',
      'on the motion to adopt the amendments', 'on the confirmation of the appointment']) {
      expect(ndQuestionIsOnTheBill(q)).toBe(false);
    }
  });
});

describe('state roll-call pages — reading North Dakota', () => {
  it('reads a 2017 House vote: bill, question, day, tally, the Speaker, and every member by full name', () => {
    const t = ndRender(ND_H17);
    expect(t.split('\n').slice(0, 3)).toEqual(['North Dakota House vote of 2017-02-22, journal page 787 (65th Legislative Assembly), HB 1279.',
      'Question: Final passage of the amended bill', 'Yea 89; Nay 0; Absent or excused 5.']);
    // the YEAS run over the page break (787 to 788); "Speaker Bellew" is the Speaker
    expect(t).toMatch(/^Yea \(89\): Bert Anderson; .*; Rich S\. Becker; Rick Becker; .*; Shannon Roers Jones; .*; Larry Bellew$/m);
    expect(t).toMatch(/^Absent or excused \(5\): Josh Boschee; Mike Brandenburg; Daniel Johnston; Gary Kreidt; Robin Weisz$/m);
  });

  it('reads two bills voted on one journal page apart, by the bill after the #', () => {
    expect(ndRender(ND_S19).split('\n').slice(0, 3)).toEqual(['North Dakota Senate vote of 2019-03-29, journal page 1153 (66th Legislative Assembly), HB 1042.',
      'Question: Final passage of the bill', 'Yea 42; Nay 3; Absent or excused 2.']);
    expect(ndRender(ND_S19B).split('\n')[2]).toBe('Yea 35; Nay 10; Absent or excused 2.');
    expect(ndRender(ND_S19)).toMatch(/^Absent or excused \(2\): Michael Dwyer; Judy Lee$/m);
  });

  it('reads two votes on one bill on one day apart, by the page (2025: HB 1326 failed, was reconsidered, and passed)', () => {
    expect(ndRender(ND_H25_FAIL).split('\n')[2]).toBe('Yea 44; Nay 48; Absent or excused 1.');
    expect(ndRender(ND_H25_PASS).split('\n')[2]).toBe('Yea 56; Nay 35; Absent or excused 2.');
    // the motion to reconsider, between them, is not a vote on the bill
    expect(ndWhy(`${ND}69-2025/regular/journals/hr-dailyjnl-34.pdf#Page819-HB1326`, ndDocs(ND_H25_PASS))).toMatch(/^the journal holds 0 roll calls on HB 1326/);
  });

  it('refuses a journal whose bill, question, counts, pages, result or members do not hold together', () => {
    const [j, m] = ndDocs(ND_H17);
    expect(ndWhy(ND_H17, [j, m])).toBe('read');
    // a printed count no longer equals the members under it
    expect(ndWhy(ND_H17, [tamper(j, 'there were 89 YEAS,', 'there were 88 YEAS,'), m])).toMatch(/^the YEAS group lists 89 members and the question prints 88$/);
    // the roll call follows another bill's heading
    expect(ndWhy(ND_H17, [tamper(j, 'HB 1279: A BILL for an Act to create and enact a new subdivision', 'HB 1278: A BILL for an Act to create and enact a new subdivision'), m]))
      .toMatch(/^the journal holds 0 roll calls on HB 1279/);
    // a vote on a division of the bill
    expect(ndWhy(ND_H17, [tamper(j, 'The question being on the final passage of the amended bill, which has been read, and has\ncommittee recommendation of DO PASS, the roll was called and there were 89 YEAS',
      'The question being on the final adoption of Division A of Engrossed HB 1279, the roll was\ncalled and there were 89 YEAS'), m])).toMatch(/^the journal holds 0 roll calls on HB 1279/);
    // the result line names another bill
    expect(ndWhy(ND_H17, [tamper(j, 'Engrossed HB 1279 passed and the emergency', 'Engrossed HB 1280 passed and the emergency'), m])).toMatch(/^the roll call does not end on the bill's result/);
    // a page the vote does not take in
    expect(ndWhy(ND_H17.replace('Page787', 'Page789'), [j, m])).toMatch(/^the journal holds 0 roll calls on HB 1279 that read as a vote on the bill and take in page 789$/);
    // a member printed twice
    expect(ndWhy(ND_H17, [tamper(j, 'ABSENT AND NOT VOTING: Boschee; Brandenburg', 'ABSENT AND NOT VOTING: Beadle; Brandenburg'), m])).toMatch(/^a member is listed twice$/);
    // a running head of another day, and of the other chamber
    expect(ndWhy(ND_H17, [tamper(j, '788 JOURNAL OF THE HOUSE 35th DAY', '788 JOURNAL OF THE HOUSE 36th DAY'), m])).toMatch(/^a running head that is not the House's day 35/);
    expect(ndWhy(ND_H17, [tamper(j, '788 JOURNAL OF THE HOUSE 35th DAY', '788 JOURNAL OF THE SENATE 35th DAY'), m])).toMatch(/^a running head that is not the House's day 35/);
    // no member list
    expect(ndWhy(ND_H17, [j, '<html></html>'])).toMatch(/^the member list did not read$/);
  });
});

describe('state roll-call pages — North Dakota lines', () => {
  const t = ndRender(ND_H17);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(ND_H17, t, 'Becker', 'Rick Becker')).toEqual([ND_BECKER]);
    expect(verifyStateRollCallLine(ND_BECKER, ND_H17, t, 'Becker', 'Rick Becker')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(ND_BECKER)).toMatchObject({ state: 'ND', chamber: 'House', vote: 'Yea', name: 'Rick Becker', bill: 'HB 1279' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or page', () => {
    const v = (line: string, last = 'Becker', full = 'Rick Becker', url = ND_H17) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(ND_BECKER.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(ND_BECKER.replace('Rick Becker voted', 'Rich S. Becker voted'))).not.toBe('verified');
    expect(v(ND_BECKER, 'Beadle', 'Thomas Beadle')).toBe('name_not_present');
    expect(v(ND_BECKER.replace('HB 1279 -', 'HB 1278 -'))).toBe('snippet_not_found');
    expect(v(ND_BECKER.replace('2017-02-22', '2017-02-21'))).toBe('snippet_not_found');
    expect(v(ND_BECKER.replace('journal page 787', 'journal page 788'))).toBe('snippet_not_found');
  });

  it('gives an absent member "was absent or excused and did not vote", never a Yea or a Nay', () => {
    const [l] = stateRollCallLinesFor(ND_H17, t, 'Boschee', 'Josh Boschee');
    expect(l).toBe('North Dakota House vote of 2017-02-22, journal page 787 (65th Legislative Assembly), HB 1279 - Final passage of the amended bill: Josh Boschee was absent or excused and did not vote.');
    expect(verifyStateRollCallLine(l.replace('was absent or excused and did not vote', 'voted Yea'), ND_H17, t, 'Boschee', 'Josh Boschee').verdict).toBe('snippet_not_found');
  });

  it('gives no line to a label two members fit (2023 "Christensen", 2025 "Brown")', () => {
    expect(ndRender(ND_H23)).toMatch(/; Christensen;/);
    expect(stateRollCallLinesFor(ND_H23, ndRender(ND_H23), 'Christensen', 'Cole Christensen')).toEqual([]);
    expect(stateRollCallLinesFor(ND_H25_PASS, ndRender(ND_H25_PASS), 'Brown', 'Collette Brown')).toEqual([]);
  });

  it('reads the tally as Yea, Nay and the rest absent or not voting', () => {
    const r = readStateRollCallRecord(ndDocs(ND_S19), ND_S19)!;
    expect(r).toMatchObject({ bill: 'HB 1042', date: '2019-03-29', chamber: 'Senate' });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting']]).toEqual([42, 3, ['Michael Dwyer', 'Judy Lee']]);
  });
});

// ── Minnesota ──────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-19, trimmed to the day's opening and the pages around the vote: the House journal of 2023-04-25
// (www.house.mn.gov/cco/journals/2023-24/J0425056.htm, windows-1252, pages 6825 and 7011-7014), the Senate journal of
// 2023-04-14 (www.mnsenate.gov/journals/2023-2024/20230414049.pdf, read as cells, pages 4967 and 5103-5106), and the
// Legislative Reference Library's member lists for the 90th House and the 93rd House and Senate.
const MN_H = 'https://www.house.mn.gov/cco/journals/2023-24/J0425056.htm#Page7013-SF2934';
const MN_S = 'https://www.mnsenate.gov/journals/2023-2024/20230414049.pdf#Page5105-SF2909';
// the site serves CRLF line ends and git may check the fixture out with LF: the tampers below anchor on CRLF
const mnHouseJournal = (): string => new TextDecoder('windows-1252').decode(readFileSync(fileURLToPath(new URL('./__fixtures__/stateRollCall/mn-93-house-J0425056.htm', import.meta.url)))).replace(/\r?\n/g, '\r\n');
const mnDocs = (url: string): string[] => url === MN_H ? [mnHouseJournal(), ksPage('mn-93-house-members')] : [mdFile('mn-93-senate-20230414049.cells.txt'), ksPage('mn-93-senate-members')];
const mnRender = (url: string, docs = mnDocs(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error('the journal did not read');
  return t;
};
const mnWhy = (url: string, docs: string[]): string => {
  const v = explainMinnesotaVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const MN_ACOMB = 'Minnesota House vote of 2023-04-25, journal page 7013 (93rd Legislature), SF 2934 - Passage of the bill: Patty Acomb voted Yea.';

describe('state roll-call pages — Minnesota address', () => {
  it('knows a journal page named with its bill, and reads it with the LRL member list, a second apart', () => {
    expect(parseMinnesotaVoteUrl(MN_H)).toEqual({ state: 'MN', stateName: 'Minnesota', chamber: 'House', legislature: 93, file: '2023-24/J0425056', page: 7013, billType: 'SF', billNum: 2934, special: 0 });
    expect(parseMinnesotaVoteUrl(MN_S)).toMatchObject({ chamber: 'Senate', legislature: 93, file: '2023-2024/20230414049', page: 5105, billType: 'SF', billNum: 2909, special: 0 });
    expect(parseMinnesotaVoteUrl('https://www.mnsenate.gov/journals/2021-2022/2021061704_ss1.pdf#Page28-SF50')).toMatchObject({ legislature: 92, special: 1 });
    expect(stateRollCallDocs(MN_H)).toEqual(['https://www.house.mn.gov/cco/journals/2023-24/J0425056.htm',
      'https://www.lrl.mn.gov/legdb/results?search=session&gender=all&sess=93&body=house']);
    expect(stateRollCallDocs(MN_S)).toEqual(['https://www.mnsenate.gov/journals/2023-2024/20230414049.pdf',
      'https://www.lrl.mn.gov/legdb/results?search=session&gender=all&sess=93&body=senate']);
    expect(stateRollCallMinGapMs(MN_H)).toBe(1_000);
    expect(isStateRollCallUrl(MN_S)).toBe(true);
    // the dump's 2023 addresses (the Senate's day file with a page, the House's vote page), no bill after the #, the page
    // alone, an even year opening the biennium, a biennium before the 90th, plain http, the old House host, a look-alike host
    for (const u of ['https://www.senate.mn/journals/2023-2024/20230330043.pdf#78', 'https://www.house.mn.gov/Votes/Details?SessionKey=302&BillNumber=HF5084',
      MN_H.replace('-SF2934', ''), MN_H.replace('#Page7013-SF2934', ''), MN_H.replace('2023-24', '2024-25'), MN_H.replace('2023-24', '2015-16'),
      MN_H.replace('https', 'http'), MN_H.replace('www.house.mn.gov', 'www.house.leg.state.mn.us'), MN_S.replace('mnsenate.gov', 'mnsenate.gov.example.com'),
      MN_S.replace('Page5105', 'Page05105')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('routes the Senate journal PDF to cells, as Maryland\'s, and every other PDF to lines', () => {
    const items = [{ page: 1, x: 10, y: 700, str: 'Boldon' }, { page: 1, x: 200, y: 700, str: 'Frentz' }];
    expect(pdfBodyFor('https://www.mnsenate.gov/journals/2023-2024/20230414049.pdf', items).split('\n')[0]).toBe('%PDF-CELLS');
    expect(pdfBodyFor('https://ndlegis.gov/assembly/69-2025/regular/journals/hr-dailyjnl-34.pdf', items).split('\n')[0]).not.toBe('%PDF-CELLS');
  });

  it('names a printed label in full from the member list, and keeps a label that fits none or several as printed', () => {
    const h93 = mnMembers(ksPage('mn-93-house-members'), 93, 'House')!;
    expect(h93).toHaveLength(136);
    const alias = (l: string): number | undefined => MN_LABEL_ALIASES[`93|House|${l}`];
    // "Anderson, P. E." is Patricia (also known as Patti): Paul H. Anderson's list name gives H as his second initial
    expect(mnMemberNames(['Anderson, P. E.', 'Anderson, P. H.', 'Hansen, R.', 'Hanson, J.', 'Neu Brindley', "O'Driscoll", 'Lee, F.', 'Lee, K.', "O'Neill", 'Zzyzx'], h93, alias))
      .toEqual(['Patricia Anderson', 'Paul H. Anderson', 'Rick Hansen', 'Jessica Hanson', 'Anne E Neu Brindley', "Tim O'Driscoll", 'Fue Lee', 'Liz Lee', 'Marion Rarick', 'Zzyzx']);
    // without the alias, "Lee, K." fits no one and "O'Neill" (Marion Rarick's former name) fits no one: kept as printed
    expect(mnMemberNames(['Lee, K.', "O'Neill"], h93)).toEqual(['Lee, K.', "O'Neill"]);
    // a bare family name two members share fits several: no name
    expect(mnMemberNames(['Anderson'], h93)).toEqual(['Anderson']);
    // 2017: Jason and Marion Rarick are both on the list; "O'Neill" is Marion, so "Rarick" is Jason
    const h90 = mnMembers(ksPage('mn-90-house-members'), 90, 'House')!;
    const alias90 = (l: string): number | undefined => MN_LABEL_ALIASES[`90|House|${l}`];
    expect(mnMemberNames(['Rarick', "O'Neill", 'Carlson, L.', 'Carlson, A.', 'Murphy, E.', 'Murphy, M.'], h90, alias90))
      .toEqual(['Jason Rarick', 'Marion Rarick', 'Lyndon R. Carlson Sr.', 'Andrew Carlson', 'Erin P. Murphy', 'Mary Catherine Murphy']);
    expect(mnMemberNames(['Rarick'], h90)).toEqual(['Rarick']);
    // 2020 (HF 8, HF 9): "Kunesh-Podein" and "Neu" are former names (LRL 15466 and 15494); the 91st list prints the present ones
    const h91 = mnMembers(ksPage('mn-91-house-members'), 91, 'House')!;
    const alias91 = (l: string): number | undefined => MN_LABEL_ALIASES[`91|House|${l}`];
    expect(mnMemberNames(['Kunesh-Podein', 'Neu'], h91, alias91)).toEqual(['Mary K. Kunesh', 'Anne E Neu Brindley']);
    expect(mnMemberNames(['Kunesh-Podein', 'Neu'], h91)).toEqual(['Kunesh-Podein', 'Neu']);
    // a list of another Legislature or chamber, or one that does not hold the count it prints, does not read
    expect(mnMembers(ksPage('mn-93-house-members'), 92, 'House')).toBeNull();
    expect(mnMembers(ksPage('mn-93-house-members'), 93, 'Senate')).toBeNull();
    expect(mnMembers(tamper(ksPage('mn-93-house-members'), '136 records matched', '137 records matched'), 93, 'House')).toBeNull();
  });

  it('knows which questions are votes on the bill', () => {
    for (const q of ['passage of the bill', 'passage of the bill, as amended', 'repassage of the bill', 'repassage of the bill, as amended by the Conference Committee',
      'Shall H. F. No. 1 be repassed, the objections of the Governor notwithstanding?']) {
      expect(mnQuestionIsOnTheBill(q)).toBe(true);
    }
    for (const q of ['adoption of the amendment', 'adoption of the Backer amendment to the Backer amendment', 'motion to lay the bill on the table',
      'appeal of the decision of the Speaker', 'adoption of the report of the Conference Committee']) {
      expect(mnQuestionIsOnTheBill(q)).toBe(false);
    }
  });
});

describe('state roll-call pages — reading Minnesota', () => {
  it('reads a 2023 House vote from the day\'s HTML journal: bill, question, day, tally, and every member by full name', () => {
    const t = mnRender(MN_H);
    expect(t.split('\n').slice(0, 3)).toEqual(['Minnesota House vote of 2023-04-25, journal page 7013 (93rd Legislature), SF 2934.',
      'Question: Passage of the bill', 'Yea 70; Nay 60.']);
    // "Spk. Hortman" is the Speaker; "Lee, K." is Liz Lee; "O'Neill" is Marion Rarick
    expect(t).toMatch(/^Yea \(70\): Patty Acomb; Esther Agbaje; .*; Fue Lee; Liz Lee; .*; Melissa Hortman$/m);
    expect(t).toMatch(/^Nay \(60\): Pam Altendorf; Patricia Anderson; Paul H\. Anderson; .*; Marion Rarick; .*$/m);
    // every label is named
    expect(t.split('\n').slice(3).join(';')).not.toMatch(/, [A-Z]\.|Spk\./);
  });

  it('reads a 2023 Senate vote from the day\'s PDF journal, past the votes cast under Rule 40', () => {
    const t = mnRender(MN_S);
    expect(t.split('\n').slice(0, 3)).toEqual(['Minnesota Senate vote of 2023-04-14, journal page 5105 (93rd Legislature), SF 2909.',
      'Question: Passage of the bill, as amended', 'Yea 34; Nay 33.']);
    // two-word family names in the grid
    expect(t).toMatch(/; Clare Oumou Verbeten;/);
    expect(t).toMatch(/; Erin K\. Maye Quade;/);
  });

  it('refuses a House journal whose bill, question, counts, pages, session or result do not hold together', () => {
    const [j, m] = mnDocs(MN_H);
    expect(mnWhy(MN_H, [j, m])).toBe('read');
    // a printed count no longer equals the members under it
    expect(mnWhy(MN_H, [tamper(j, 'were 70 yeas and 60 nays', 'were 71 yeas and 60 nays'), m])).toBe('the Yea group lists 70 members and the tally prints 71');
    // the roll call follows another bill's heading
    expect(mnWhy(MN_H, [tamper(j, 'No.&nbsp;2934,\r\nA bill', 'No.&nbsp;2935,\r\nA bill'), m])).toMatch(/^the journal holds 0 roll calls on SF 2934/);
    // a vote on something other than the bill
    expect(mnWhy(MN_H, [tamper(j, 'question was taken on the passage of\r\nthe bill and the roll was', 'question was taken on the adoption of\r\nthe amendment and the roll was'), m])).toMatch(/^the journal holds 0 roll calls on SF 2934/);
    // a page the vote does not take in: the third reading is on page 7013
    expect(mnWhy(MN_H.replace('Page7013', 'Page7012'), [j, m])).toMatch(/^the journal holds 0 roll calls on SF 2934 that read as a vote on the bill and take in page 7012$/);
    // the result line is not the bill's
    expect(mnWhy(MN_H, [tamper(j, 'The\r\nbill was passed, as amended, and its title agreed to.', 'The\r\nmotion prevailed.'), m])).toMatch(/^the roll call does not end on the bill's result/);
    // a member printed twice
    const k = j.indexOf('were 70 yeas');
    expect(mnWhy(MN_H, [j.slice(0, k) + tamper(j.slice(k), '>Agbaje<', '>Acomb<'), m])).toBe('a member is listed twice');
    // a page banner of another day, and pages out of order
    expect(mnWhy(MN_H, [tamper(j, '56th Day -\r\nTuesday, April 25, 2023 - Top of Page\r\n7014', '57th Day -\r\nTuesday, April 25, 2023 - Top of Page\r\n7014'), m]))
      .toBe("the journal's page banners print 1 dates and 2 days");
    expect(mnWhy(MN_H, [tamper(j, 'Top of Page\r\n7014', 'Top of Page\r\n7012'), m])).toMatch(/^a page banner whose anchor 7014 is not its page 7012$/);
    // the session heading names another Legislature
    expect(mnWhy(MN_H, [tamper(j, 'NINETY-THIRD\r\nSESSION', 'NINETY-SECOND\r\nSESSION'), m])).toMatch(/^the journal is of the NINETY-SECOND session/);
    // a member list of another Legislature
    expect(mnWhy(MN_H, [j, ksPage('mn-90-house-members')])).toBe('the member list did not read');
    // the file the address names is another day's
    expect(mnWhy(MN_H.replace('J0425056', 'J0426057'), [j, m])).toMatch(/^the journal is day 56 of 2023-04-25, not the file/);
  });

  it('refuses a Senate journal whose bill, counts, heads or result do not hold together', () => {
    const [j, m] = mnDocs(MN_S);
    expect(mnWhy(MN_S, [j, m])).toBe('read');
    expect(mnWhy(MN_S, [tamper(j, 'yeas 34 and nays 33', 'yeas 34 and nays 34'), m])).toBe('the Nay group lists 33 members and the tally prints 34');
    expect(mnWhy(MN_S, [tamper(j, 'S.F. No. 2909 was read the third time', 'S.F. No. 2908 was read the third time'), m])).toMatch(/^the journal holds 0 roll calls on SF 2909/);
    expect(mnWhy(MN_S, [tamper(j, 'So the bill, as amended, was passed and its title was agreed to.', 'The motion prevailed.'), m])).toMatch(/^the roll call does not end on the bill's result/);
    expect(mnWhy(MN_S, [tamper(j, '5106\tJOURNAL OF THE SENATE\t[49TH DAY', '5106\tJOURNAL OF THE SENATE\t[50TH DAY'), m])).toMatch(/^the journal's running heads print 1 dates and 2 days$/);
    expect(mnWhy(MN_S.replace('Page5105', 'Page5107'), [j, m])).toMatch(/take in page 5107$/);
    expect(mnWhy(MN_S, [j.replace('%PDF-CELLS', '%PDF-LINES'), m])).toBe('not a journal PDF read as cells');
  });
});

// Saved 2026-11-19, trimmed the same way: the House journal of 2026-04-20 (www.house.mn.gov/cco/journals/2025-26/
// J0420060.htm, utf-8, pages 5843-5846), the Senate journal of 2026-05-04 (www.mnsenate.gov/journals/2025-2026/
// 20260504068.pdf, read as cells, pages 9705-9707), and the LRL member lists for the 94th House and Senate.
const MN_H26 = 'https://www.house.mn.gov/cco/journals/2025-26/J0420060.htm#Page5845-HF3762';
const MN_S26 = 'https://www.mnsenate.gov/journals/2025-2026/20260504068.pdf#Page9706-SF4067';
const mnHouse26 = (): string => new TextDecoder('utf-8').decode(readFileSync(fileURLToPath(new URL('./__fixtures__/stateRollCall/mn-94-house-J0420060.htm', import.meta.url))));
const mnSenate26 = (): string => mdFile('mn-94-senate-20260504068.cells.txt');

describe('state roll-call pages — reading Minnesota in 2026', () => {
  it('reads the 2026 House banner ("<a name = 5845>", "Journal Of the House -  60th -Monday")', () => {
    const body = mnHouse26();
    expect(body).toContain('<a name = 5845></a><center><b>Journal Of the House -  60th -Monday, April 20, 2026 - Top of Page 5845');
    const t = mnRender(MN_H26, [body, ksPage('mn-94-house-members')]);
    expect(t.split('\n').slice(0, 3)).toEqual(['Minnesota House vote of 2026-04-20, journal page 5845 (94th Legislature), HF 3762.', 'Question: Passage of the bill', 'Yea 128; Nay 3.']);
    // a banner whose anchor is not its page still refuses
    expect(mnWhy(MN_H26, [tamper(body, '<a name = 5845>', '<a name = 5847>'), ksPage('mn-94-house-members')])).toMatch(/anchor 5847 is not its page 5845/);
  });

  it('reads a Senate vote whose reading has no comma before "and placed", across a call of the Senate', () => {
    const body = mnSenate26();
    expect(body).toContain('S.F. No. 4067 was read the third time and placed on its final passage.\nCALL OF THE SENATE\n');
    const t = mnRender(MN_S26, [body, ksPage('mn-94-senate-members')]);
    expect(t.split('\n').slice(0, 3)).toEqual(['Minnesota Senate vote of 2026-05-04, journal page 9706 (94th Legislature), SF 4067.', 'Question: Passage of the bill', 'Yea 34; Nay 33.']);
    // the call is set aside only in its own words: a call of the House here is not the Senate's, and the vote refuses
    expect(mnWhy(MN_S26, [tamper(body, 'imposed a call of the Senate', 'imposed a call of the House'), ksPage('mn-94-senate-members')])).toMatch(/0 roll calls on SF 4067/);
    // a question that is not on the bill still refuses
    expect(mnWhy(MN_S26, [tamper(body, 'The question was taken on the passage of the bill.', 'The question was taken on the adoption of the amendment.'), ksPage('mn-94-senate-members')])).toMatch(/0 roll calls on SF 4067/);
  });
});

describe('state roll-call pages — Minnesota lines', () => {
  const t = mnRender(MN_H);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(MN_H, t, 'Acomb', 'Patty Acomb')).toEqual([MN_ACOMB]);
    expect(verifyStateRollCallLine(MN_ACOMB, MN_H, t, 'Acomb', 'Patty Acomb')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(MN_ACOMB)).toMatchObject({ state: 'MN', chamber: 'House', vote: 'Yea', name: 'Patty Acomb', bill: 'SF 2934' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or page', () => {
    const v = (line: string, last = 'Acomb', full = 'Patty Acomb') => verifyStateRollCallLine(line, MN_H, t, last, full).verdict;
    expect(v(MN_ACOMB.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(MN_ACOMB.replace('Patty Acomb voted', 'Esther Agbaje voted'))).not.toBe('verified');
    expect(v(MN_ACOMB, 'Agbaje', 'Esther Agbaje')).toBe('name_not_present');
    expect(v(MN_ACOMB.replace('SF 2934 -', 'SF 2935 -'))).toBe('snippet_not_found');
    expect(v(MN_ACOMB.replace('2023-04-25', '2023-04-24'))).toBe('snippet_not_found');
    expect(v(MN_ACOMB.replace('journal page 7013', 'journal page 7014'))).toBe('snippet_not_found');
  });

  it('gives each of two members who share a family name their own line, and none to a label left as printed', () => {
    expect(stateRollCallLinesFor(MN_H, t, 'Anderson', 'Patricia Anderson')).toEqual([
      'Minnesota House vote of 2023-04-25, journal page 7013 (93rd Legislature), SF 2934 - Passage of the bill: Patricia Anderson voted Nay.']);
    expect(stateRollCallLinesFor(MN_H, t, 'Anderson', 'Paul H. Anderson')).toHaveLength(1);
    // Pam Altendorf printed as a bare "Anderson": both Andersons fit it, and each is the one another label fits alone
    const bare = mnRender(MN_H, [mnHouseJournal().split('>Altendorf<').join('>Anderson<'), ksPage('mn-93-house-members')]);
    expect(bare).toMatch(/: Anderson; /);
  });

  it('reads the tally as Yea and Nay, with no member absent: the journals name none', () => {
    const r = readStateRollCallRecord(mnDocs(MN_S), MN_S)!;
    expect(r).toMatchObject({ bill: 'SF 2909', date: '2023-04-14', chamber: 'Senate', rollNum: 5105 });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting']]).toEqual([34, 33, []]);
  });
});

// ── Nevada ────────────────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-19 from www.leg.state.nv.us (NELIS) with the verifier's own user-agent. The member list prints no party.
const NV = 'https://www.leg.state.nv.us/App/NELIS/REL/';
const NV_83 = `${NV}83rd2025/Bill/GetBillVoteMembers?voteKey=12948&voteResultPanel=All&billKey=12727#SB404`;
const NV_82_FAIL = `${NV}82nd2023/Bill/GetBillVoteMembers?voteKey=10886&voteResultPanel=All&billKey=10448#AB448`;
const NV_82_PASS = `${NV}82nd2023/Bill/GetBillVoteMembers?voteKey=10889&voteResultPanel=All&billKey=10448#AB448`;
const NV_80 = `${NV}80th2019/Bill/GetBillVoteMembers?voteKey=6502&voteResultPanel=All&billKey=6800#AB422`;
const nvDocs: Record<string, string[]> = {
  [NV_83]: ['nv-83-members-12948', 'nv-83-votes-12727', 'nv-83-bill-12727'],
  [NV_82_FAIL]: ['nv-82-members-10886', 'nv-82-votes-10448', 'nv-82-bill-10448'],
  [NV_82_PASS]: ['nv-82-members-10889', 'nv-82-votes-10448', 'nv-82-bill-10448'],
  [NV_80]: ['nv-80-members-6502', 'nv-80-votes-6800', 'nv-80-bill-6800'],
};
const nvBodies = (url: string): string[] => nvDocs[url].map(ksPage);
const nvWhy = (url: string, docs: string[]): string => {
  const v = explainNevadaVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const nvRender = (url: string, docs = nvBodies(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error(`the page did not read: ${nvWhy(url, docs)}`);
  return t;
};
const NV_ANDERSON = 'Nevada Assembly vote 12948 (83rd2025), SB 404 - Final Passage (2nd Reprint) - Passed (2025-05-22): Natha Anderson voted Yea.';

describe('state roll-call pages — Nevada address', () => {
  it('knows a vote\'s member list named with its bill key and bill, and reads it with the vote list and the bill page, a second apart', () => {
    expect(parseNevadaVoteUrl(NV_83)).toEqual({ state: 'NV', stateName: 'Nevada', session: '83rd2025', voteKey: 12948, billKey: 12727, bill: 'SB 404' });
    expect(parseNevadaVoteUrl(`${NV}31st2020Special/Bill/GetBillVoteMembers?voteKey=7&voteResultPanel=All&billKey=7128#SB4`)).toMatchObject({ session: '31st2020Special', bill: 'SB 4' });
    expect(stateRollCallDocs(NV_83)).toEqual([`${NV}83rd2025/Bill/GetBillVoteMembers?voteKey=12948&voteResultPanel=All&billKey=12727`,
      `${NV}83rd2025/Bill/GetBillVotes?billKey=12727&voteTypeId=3`, `${NV}83rd2025/Bill/12727/Overview`]);
    expect(stateRollCallMinGapMs(NV_83)).toBe(1_000);
    expect(isStateRollCallUrl(NV_83)).toBe(true);
    // the dump's 2017 pages (a disallowed path), the Votes tab, no bill, no bill key, one panel only, plain http, a look-alike host
    for (const u of ['http://www.leg.state.nv.us/Session/79th2017/Reports/BillVote.cfm?VoteID=1087&fldReprint=3&fldDocTypeCode=SB&fldBillNumber=149&fldBillname=SB149',
      `${NV}83rd2025/Bill/FillSelectedBillTab?selectedTab=Votes&billKey=12727`, NV_83.replace('#SB404', ''), NV_83.replace('&billKey=12727', ''),
      NV_83.replace('voteResultPanel=All', 'voteResultPanel=Yea'), NV_83.replace('https', 'http'), NV_83.replace('www.leg.state.nv.us', 'www.leg.state.nv.us.example.com')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('names a member given name first, and refuses a label with no given name', () => {
    expect(nvMemberName('Anderson, Natha')).toBe('Natha Anderson');
    expect(nvMemberName('La Rue Hatch, Selena')).toBe('Selena La Rue Hatch');
    expect(nvMemberName('Cruz-Crawford, Michelee "Shelly"')).toBe('Michelee "Shelly" Cruz-Crawford');
    expect(nvMemberName('Anderson')).toBeNull();
  });

  it('reads a bill\'s vote list: every roll call with its chamber, version, result, day and counts', () => {
    expect(nvVoteList(ksPage('nv-82-votes-10448')).map((v) => [v.voteKey, v.chamber, v.version, v.passed, v.date, v.counts.Yea, v.counts.Nay])).toEqual([
      [10220, 'House', 'As Introduced', true, '2023-05-25', 42, 0], [10886, 'Senate', 'As Introduced', false, '2023-06-05', 13, 8],
      [10889, 'Senate', 'As Introduced', true, '2023-06-05', 21, 0]]);
    expect(() => nvVoteList(tamper(ksPage('nv-82-votes-10448'), 'voteResultPanel=Absent', 'voteResultPanel=Paired'))).toThrow(/a kind of vote the reader does not know: Paired/);
    expect(() => nvVoteList(tamper(ksPage('nv-82-votes-10448'), '<h2 class="h4">Senate (As Introduced)</h2>', '<h2 class="h4">Joint (As Introduced)</h2>'))).toThrow(/has no chamber heading/);
  });
});

describe('state roll-call pages — reading Nevada', () => {
  it('reads a 2025 Assembly vote: bill, question, day, tally, and every member by full name', () => {
    const t = nvRender(NV_83);
    expect(t.split('\n').slice(0, 3)).toEqual(['Nevada Assembly vote 12948 (83rd2025), SB 404, 2025-05-22.', 'Question: Final Passage (2nd Reprint) - Passed',
      'Yea 42; Nay 0; Excused 0; Not voting 0; Absent 0.']);
    expect(t).toMatch(/^Yea \(42\): Natha Anderson; Shea Backus;.*; Selena La Rue Hatch;.*; Cinthia Zermeño Moore;/m);
  });

  it('reads a vote that failed for want of two thirds and the same day\'s vote that passed as two roll calls', () => {
    expect(nvRender(NV_82_FAIL).split('\n').slice(0, 3)).toEqual(['Nevada Senate vote 10886 (82nd2023), AB 448, 2023-06-05.',
      'Question: Final Passage (As Introduced) - Failed', 'Yea 13; Nay 8; Excused 0; Not voting 0; Absent 0.']);
    expect(nvRender(NV_82_PASS).split('\n').slice(0, 3)).toEqual(['Nevada Senate vote 10889 (82nd2023), AB 448, 2023-06-05.',
      'Question: Final Passage (As Introduced) - Passed', 'Yea 21; Nay 0; Excused 0; Not voting 0; Absent 0.']);
  });

  it('counts an empty seat apart from the members (80th 2019 AB 168: All 42, Yea 40, Excused 1, Vacant 1)', () => {
    const url = `${NV}80th2019/Bill/GetBillVoteMembers?voteKey=6556&voteResultPanel=All&billKey=6255#AB168`;
    const docs = ['nv-80-members-6556', 'nv-80-votes-6255', 'nv-80-bill-6255'].map(ksPage);
    expect(nvRender(url, docs).split('\n')[2]).toBe('Yea 40; Nay 0; Excused 1; Not voting 0; Absent 0.');
    expect(nvRender(url, docs)).not.toMatch(/District No/);
    expect(nvWhy(url, [tamper(docs[0], 'District No. 17', 'District No. 17x'), docs[1], docs[2]])).toMatch(/^a member row the reader cannot read$/);
    expect(nvWhy(url, [docs[0], tamper(docs[1], 'voteResultPanel=Vacant" onclick', 'voteResultPanel=Paired" onclick'), docs[2]])).toMatch(/a kind of vote the reader does not know: Paired/);
  });

  it('reads excused members as excused', () => {
    const t = nvRender(NV_80);
    expect(t.split('\n')[2]).toBe('Yea 19; Nay 0; Excused 2; Not voting 0; Absent 0.');
    expect(t).toMatch(/^Excused \(2\): Ben Kieckhefer; Marcia Washington$/m);
  });

  it('refuses a vote whose member list, vote list or bill page do not hold together', () => {
    const [m, l, b] = nvBodies(NV_82_FAIL);
    expect(nvWhy(NV_82_FAIL, [m, l, b])).toBe('read');
    // the bill page is another bill, or another session
    expect(nvWhy(NV_82_FAIL, [m, l, tamper(b, '<h1>AB448', '<h1>AB449')])).toMatch(/^the bill page is for AB449, not AB 448$/);
    expect(nvWhy(NV_82_FAIL, [m, l, tamper(b, 'session-year">82nd (2023) Session', 'session-year">82nd (2023) Special Session')])).toMatch(/^the bill page is not of the 82nd2023 session$/);
    // the vote is not on the bill's vote list
    expect(nvWhy(NV_82_FAIL, [m, tamper(l, 'billVoteTitleForVoteKey 10886', 'billVoteTitleForVoteKey 10887'), b])).toMatch(/^the vote list did not read: vote 10887 links another vote's members$/);
    expect(nvWhy(NV_82_FAIL, [m, ksPage('nv-83-votes-12727'), b])).toMatch(/^the bill's vote list holds vote 10886 0 times$/);
    // a printed count no longer equals the members under it
    expect(nvWhy(NV_82_FAIL, [m, tamper(l, 'voteKey=10886&amp;voteResultPanel=Yea">Yea: 13', 'voteKey=10886&amp;voteResultPanel=Yea">Yea: 14'), b])).toMatch(/^the Yea group lists 13 members and the vote list prints 14$/);
    expect(nvWhy(NV_82_FAIL, [m, tamper(l, 'voteKey=10886&amp;voteResultPanel=All">All: 21', 'voteKey=10886&amp;voteResultPanel=All">All: 22'), b])).toMatch(/^21 members and 0 vacant seats listed and All prints 22$/);
    // a member row whose class and text disagree, or a kind the reader does not know
    expect(nvWhy(NV_82_FAIL, [tamper(m, '(Nay ', '(Yea '), l, b])).toMatch(/^a member row that disagrees with itself/);
    expect(nvWhy(NV_82_FAIL, [tamper(m, 'class="vote-nay vote pl-1"', 'class="vote-paired vote pl-1"'), l, b])).toMatch(/^a kind of vote the reader does not know: paired$/);
    // a member listed twice
    expect(nvWhy(NV_82_PASS, [tamper(ksPage('nv-82-members-10889'), 'Cannizzaro, Nicole', 'Buck, Carrie'), ksPage('nv-82-votes-10448'), b])).toMatch(/^a member is listed twice$/);
    // the wrong number of documents
    expect(nvWhy(NV_82_FAIL, [m, l])).toMatch(/^not a member list, a vote list and a bill page$/);
  });
});

describe('state roll-call pages — Nevada lines', () => {
  const t = nvRender(NV_83);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(NV_83, t, 'Anderson', 'Natha Anderson')).toEqual([NV_ANDERSON]);
    expect(verifyStateRollCallLine(NV_ANDERSON, NV_83, t, 'Anderson', 'Natha Anderson')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(NV_ANDERSON)).toMatchObject({ state: 'NV', chamber: 'House', vote: 'Yea', name: 'Natha Anderson', bill: 'SB 404' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const v = (line: string, last = 'Anderson', full = 'Natha Anderson', url = NV_83) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(NV_ANDERSON.replace('voted Yea', 'voted Nay'))).toBe('snippet_not_found');
    expect(v(NV_ANDERSON.replace('Natha Anderson', 'Shea Backus'))).not.toBe('verified');
    expect(v(NV_ANDERSON, 'Backus', 'Shea Backus')).toBe('name_not_present');
    expect(v(NV_ANDERSON.replace('SB 404 -', 'SB 405 -'))).toBe('snippet_not_found');
    expect(v(NV_ANDERSON.replace('2025-05-22', '2025-05-23'))).toBe('snippet_not_found');
    expect(v(NV_ANDERSON, 'Anderson', 'Natha Anderson', NV_83.replace('12948', '12949'))).toBe('snippet_not_found');
  });

  it('gives an excused member "was excused", never a Yea or a Nay', () => {
    const s = nvRender(NV_80);
    const [l] = stateRollCallLinesFor(NV_80, s, 'Washington', 'Marcia Washington');
    expect(l).toBe('Nevada Senate vote 6502 (80th2019), AB 422 - Final Passage (3rd Reprint) - Passed (2019-05-24): Marcia Washington was excused.');
    expect(verifyStateRollCallLine(l.replace('was excused', 'voted Yea'), NV_80, s, 'Washington', 'Marcia Washington').verdict).toBe('snippet_not_found');
  });

  it('reads the tally as Yea, Nay and the rest absent or not voting', () => {
    const r = readStateRollCallRecord(nvBodies(NV_80), NV_80)!;
    expect(r).toMatchObject({ bill: 'AB 422', date: '2019-05-24', chamber: 'Senate', rollNum: 6502 });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting']]).toEqual([19, 0, ['Ben Kieckhefer', 'Marcia Washington']]);
  });
});

describe('state roll-call pages — Nevada names the roster holds otherwise', () => {
  // NELIS prints "O’Neill, PK" (initials run together) for the member the roster holds as "P. K. O'Neill", and "Taylor,
  // Angie" for Sen. Angela D. Taylor. Neither had a line in the dry batch of 2026-11-19 (13 votes).
  it('fits initials printed run together to the same initials printed apart, and no other initials', () => {
    expect(fullNameLabelFits('PK O’Neill', "O'Neill", "P. K. O'Neill")).toBe(true);
    expect(fullNameLabelFits('Philip PK O’Neill', "O'Neill", "P. K. O'Neill")).toBe(true);
    expect(fullNameLabelFits('PK O’Neill', "O'Neill", "P.K. O'Neill")).toBe(true);
    expect(fullNameLabelFits('PJ O’Neill', "O'Neill", "P. K. O'Neill")).toBe(false);
    expect(fullNameLabelFits('KP O’Neill', "O'Neill", "P. K. O'Neill")).toBe(false);
    expect(fullNameLabelFits('Pat O’Neill', "O'Neill", "P. K. O'Neill")).toBe(false);
  });

  it('fits Angie to Angela', () => {
    expect(fullNameLabelFits('Angie Taylor', 'Taylor', 'Angela D. Taylor')).toBe(true);
    expect(fullNameLabelFits('Annie Taylor', 'Taylor', 'Angela D. Taylor')).toBe(false);
  });

  it('gives P. K. O\'Neill his line on a real page', () => {
    const text = nvRender(NV_83);
    const lines = stateRollCallLinesFor(NV_83, text, "O'Neill", "P. K. O'Neill");
    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatch(/: PK O’Neill (voted Yea|voted Nay|was excused|did not vote|was absent)\.$/);
    expect(verifyStateRollCallLine(lines[0], NV_83, text, "O'Neill", "P. K. O'Neill")).toMatchObject({ verdict: 'verified' });
    expect(verifyStateRollCallLine(lines[0], NV_83, text, "O'Neill", 'P. J. O\'Neill').verdict).not.toBe('verified');
  });
});

// Saved 2026-11-20 from the Oregon Legislature's Open Data Service. The legislator lists are cut to the session, code,
// first and last name and chamber, so no fixture holds a party.
const orJson = (name: string): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}.json`, import.meta.url)), 'utf8');
const OR = 'https://olis.oregonlegislature.gov/liz/';
const OR_25H = `${OR}2025R1/Measures/MeasureVotes?id=624489#HB3041`;
const OR_17H = `${OR}2017R1/Measures/MeasureVotes?id=411795#SB66`;
const OR_25S = `${OR}2025R1/Measures/MeasureVotes?id=640802#SB473`;
const orFix: Record<string, string> = { [OR_25H]: 'or-2025-h-624489', [OR_17H]: 'or-2017-h-411795', [OR_25S]: 'or-2025-s-640802' };
const orBodies = (url: string): string[] => ['votes', 'action', 'legislators', 'legislators-before'].map((d) => orJson(`${orFix[url]}-${d}`));
/** Change one body's rows, and fail the test when the change did not apply. */
const orEdit = (body: string, f: (rows: Record<string, unknown>[]) => void): string => {
  const j = JSON.parse(body) as { value: Record<string, unknown>[] };
  f(j.value);
  const out = JSON.stringify(j);
  expect(out).not.toBe(JSON.stringify(JSON.parse(body)));
  return out;
};
const orWhy = (url: string, docs: string[]): string => {
  const v = explainOregonVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const orRender = (url: string, docs = orBodies(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error(`the vote did not read: ${orWhy(url, docs)}`);
  return t;
};
const OR_ISADORE = 'Oregon House vote 624489 (2025R1), HB 3041 - Third reading. Carried by McLain. Passed. (2025-02-25): Shannon Isadore voted Aye.';

describe('state roll-call pages — Oregon address', () => {
  it('knows a vote\'s member list on OLIS named with its bill, and reads it from four Open Data Service queries, a second apart', () => {
    expect(parseOregonVoteUrl(OR_25H)).toEqual({ state: 'OR', stateName: 'Oregon', session: '2025R1', historyId: 624489, prefix: 'HB', number: 3041, bill: 'HB 3041' });
    expect(oregonVoteUrl('2025R1', 624489, 'hb', 3041)).toBe(OR_25H);
    expect(stateRollCallDocs(OR_25H)).toEqual([
      `${OR_DATA}MeasureVotes?$filter=MeasureHistoryId%20eq%20624489&$format=json`,
      `${OR_DATA}MeasureHistoryActions?$filter=MeasureHistoryId%20eq%20624489&$format=json`,
      `${OR_DATA}Legislators?$filter=SessionKey%20eq%20'2025R1'&$format=json`,
      `${OR_DATA}Legislators?$filter=SessionKey%20eq%20'2024S1'&$format=json`]);
    expect(stateRollCallMinGapMs(OR_25H)).toBe(1_000);
    expect(isStateRollCallUrl(OR_25H)).toBe(true);
    // a session with no session before it in the reader's list
    expect(stateRollCallDocs(`${OR}2013R1/Measures/MeasureVotes?id=1#HB1`)).toBeNull();
    // the dump's old host, plain http, no bill, the bill's overview, a zero id, a look-alike host
    for (const u of ['https://olis.leg.state.or.us/liz/2025R1/Measures/MeasureVotes?id=624489#HB3041', OR_25H.replace('https', 'http'),
      OR_25H.replace('#HB3041', ''), `${OR}2025R1/Measures/Overview/HB3041`, OR_25H.replace('id=624489', 'id=0'),
      OR_25H.replace('olis.oregonlegislature.gov', 'olis.oregonlegislature.gov.example.com')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('takes third readings, repassage and overrides as votes on the bill, and every motion as not', () => {
    for (const q of ['Third reading. Carried by McLain. Passed.', 'Rules suspended. Third reading. Carried by Nosse. Passed.', 'Passed.',
      'Third reading. Carried by Prozanski. Failed.', 'House concurred in Senate amendments and repassed bill.',
      'Senate adopted Conference Committee report and repassed bill.', 'Repassed.', 'Vote to override Governor\'s veto. Veto overridden.']) {
      expect([q, orQuestionIsOnTheBill(q)]).toEqual([q, true]);
    }
    for (const q of ['Motion to rerefer to Rules failed.', 'Motion to substitute Minority Report for Committee Report failed.',
      'Vote explanation(s) filed by Boice.', 'Motion to reconsider carried. Third reading. Passed.', 'Rules suspended.', 'Motion to lay on the table carried.']) {
      expect([q, orQuestionIsOnTheBill(q)]).toEqual([q, false]);
    }
  });

  it('reads a tally line, case-blind, and refuses a group it cannot read or a count its names disagree with', () => {
    const t = orTally('Ayes, 54; nays, 1--Post; Excused for Business of the House, 1--Speaker Kotek.');
    expect([...t.entries()]).toEqual([['Aye', { n: 54, named: null }], ['Nay', { n: 1, named: ['Post'] }], ['Excused for business', { n: 1, named: ['Speaker Kotek'] }]]);
    expect(() => orTally('Ayes, 54; Paired, 1--Post.')).toThrow(/a kind of vote the reader does not know: Paired/);
    expect(() => orTally('Ayes, 54; Nays, 2--Post.')).toThrow(/Nay prints 2 and names 1/);
    expect(() => orTally('Ayes, 54; Ayes, 1.')).toThrow(/the count of Aye is printed twice/);
    expect(() => orTally('Ayes 54.')).toThrow(/a tally group the reader cannot read/);
  });
});

describe('state roll-call pages — reading Oregon', () => {
  it('reads a 2025 House vote: bill, question, day, tally, and every member by the session\'s full name', () => {
    const t = orRender(OR_25H);
    expect(t.split('\n').slice(0, 3)).toEqual(['Oregon House vote 624489 (2025R1), HB 3041, 2025-02-25.', 'Question: Third reading. Carried by McLain. Passed.',
      'Aye 35; Nay 19; Excused 6; Excused for business 0; Absent 0.']);
    expect(t).toMatch(/^Nay \(19\): .*\bBobby Levy\b/m);
    expect(t).toMatch(/^Aye \(35\): .*\bShannon Isadore\b/m);
    expect(t).not.toMatch(/Rep /);
  });

  it('reads the Speaker excused for the business of the House (2017), whose row and tally print the office differently', () => {
    const t = orRender(OR_17H);
    expect(t.split('\n')[2]).toBe('Aye 54; Nay 0; Excused 5; Excused for business 1; Absent 0.');
    expect(t).toMatch(/^Excused for business \(1\): Tina Kotek$/m);
    expect(t).toMatch(/^Excused \(5\): .*\bGregory Smith\b/m);
    // the office is not part of the member: the tally may print him with it or without it
    const [v, act, l, b] = orBodies(OR_17H);
    expect(orRender(OR_17H, [v, orEdit(act, (rows) => { rows[0].VoteText = String(rows[0].VoteText).replace('--Speaker Kotek', '--Kotek'); }), l, b])).toMatch(/^Excused for business \(1\): Tina Kotek$/m);
  });

  it('reads a tally that leaves out its empty groups, and names a member seated only in the session before', () => {
    const t = orRender(OR_25S);
    expect(t.split('\n').slice(1, 3)).toEqual(['Question: Third reading. Carried by Broadman. Passed.', 'Aye 29; Nay 0; Excused 1; Excused for business 0; Absent 0.']);
    expect(t).toMatch(/^Excused \(1\): Aaron Woods$/m);
    // without the session before's list, the member keeps the code he is printed under: no name is made up
    const [v, a, l, b] = orBodies(OR_25S);
    expect(orRender(OR_25S, [v, a, l, orEdit(b, (rows) => { rows.splice(rows.findIndex((x) => x.LegislatorCode === 'Sen Woods'), 1); })])).toMatch(/^Excused \(1\): Sen Woods$/m);
    // nor when a member of this session carries the code in the other chamber: the code is then not his to give away
    expect(orRender(OR_25S, [v, a, orEdit(l, (rows) => { rows.push({ SessionKey: '2025R1', LegislatorCode: 'Sen Woods', FirstName: 'Pat', LastName: 'Woods', Chamber: 'H' }); }), b]))
      .toMatch(/^Excused \(1\): Sen Woods$/m);
  });

  it('refuses a vote whose rows, history action or legislator lists do not hold together', () => {
    const [v, a, l, b] = orBodies(OR_25H);
    expect(orWhy(OR_25H, [v, a, l, b])).toBe('read');
    const act = (f: (x: Record<string, unknown>) => void): string => orEdit(a, (rows) => f(rows[0]));
    const row = (f: (rows: Record<string, unknown>[]) => void): string => orEdit(v, f);
    // the history action is of another bill, missing, a motion, or prints no tally
    expect(orWhy(OR_25H, [v, act((x) => { x.MeasureNumber = 3042; }), l, b])).toBe('action 624489 is not of HB 3041 in 2025R1');
    expect(orWhy(OR_25H, [v, orEdit(a, (rows) => { rows.length = 0; }), l, b])).toBe('the history holds action 624489 0 times');
    expect(orWhy(OR_25H, [v, act((x) => { x.ActionText = 'Motion to rerefer to Rules failed.'; }), l, b])).toMatch(/^the question is not a vote on the bill/);
    expect(orWhy(OR_25H, [v, act((x) => { x.VoteText = null; }), l, b])).toBe('the action prints no tally');
    // a row of another time, of another chamber, or of a kind the reader does not know
    expect(orWhy(OR_25H, [row((r) => { r[0].ActionDate = '2025-02-26T11:52:04'; }), a, l, b])).toBe('a vote row of another time: Rep Isadore');
    expect(orWhy(OR_25H, [row((r) => { r[0].Chamber = 'S'; }), a, l, b])).toBe('a vote row of another bill, session or chamber: Rep Isadore');
    expect(orWhy(OR_25H, [row((r) => { r[0].Vote = 'Paired'; }), a, l, b])).toBe('a kind of vote the reader does not know: Paired');
    // a row's vote flipped, so a count no longer equals the tally
    expect(orWhy(OR_25H, [row((r) => { r.find((x) => x.VoteName === 'Rep Wallan')!.Vote = 'Aye'; }), a, l, b])).toBe('the Aye group lists 36 members and the tally prints 35');
    // the tally names another member, or does not name a group it must
    expect(orWhy(OR_25H, [v, act((x) => { x.VoteText = String(x.VoteText).replace('Wallan', 'Walland'); }), l, b])).toBe('the Nay members the tally names are not the members listed');
    expect(orWhy(OR_25H, [v, act((x) => { x.VoteText = String(x.VoteText).replace(/Nays, 19--[^;]+;/, 'Nays, 19;'); }), l, b])).toBe('the tally names no Nay member');
    // a member listed twice
    expect(orWhy(OR_25H, [row((r) => { r.find((x) => x.VoteName === 'Rep Nathanson')!.VoteName = 'Rep Isadore'; }), a, l, b])).toBe('a member is listed twice');
    // more members than the chamber has seats (the Senate has 30)
    const [sv, sa, sl, sb] = orBodies(OR_25S);
    expect(orWhy(OR_25S, [orEdit(sv, (r) => { r.push({ ...r[0], VoteName: 'Sen Extra' }); }),
      orEdit(sa, (r) => { r[0].VoteText = 'Ayes, 30; Excused, 1--Woods.'; }), sl, sb])).toBe('more members than the chamber has');
    // a legislator list of another session, or two members given one name
    expect(orWhy(OR_25H, [v, a, b, b])).toBe('a legislator list is of another session');
    expect(orWhy(OR_25H, [v, a, orEdit(l, (rows) => { Object.assign(rows.find((x) => x.LegislatorCode === 'Rep Isadore')!, { FirstName: 'Tom', LastName: 'Andersen' }); }), b])).toBe('two members render as one name');
    // a body that runs past one page, and the wrong number of documents
    expect(orWhy(OR_25H, [JSON.stringify({ ...JSON.parse(v), 'odata.nextLink': 'x' }), a, l, b])).toBe('the reader failed: the vote runs past one page');
    expect(orWhy(OR_25H, [v, a, l])).toBe('not a vote, its history action and two sessions\' legislators');
  });
});

describe('state roll-call pages — Oregon lines', () => {
  const t = orRender(OR_25H);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(OR_25H, t, 'Isadore', 'Shannon Isadore')).toEqual([OR_ISADORE]);
    expect(verifyStateRollCallLine(OR_ISADORE, OR_25H, t, 'Isadore', 'Shannon Isadore')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(OR_ISADORE)).toMatchObject({ state: 'OR', chamber: 'House', vote: 'Aye', name: 'Shannon Isadore', bill: 'HB 3041' });
  });

  it('tells two members of one family name apart', () => {
    expect(stateRollCallLinesFor(OR_25H, t, 'Levy', 'Bobby Levy')).toEqual([OR_ISADORE.replace('Shannon Isadore voted Aye', 'Bobby Levy voted Nay')]);
    expect(stateRollCallLinesFor(OR_25H, t, 'Levy', 'Emerson Levy')).toHaveLength(1);
    expect(stateRollCallLinesFor(OR_25H, t, 'Levy', 'Emerson Levy')[0]).toMatch(/: Emerson Levy voted Aye\.$/);
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const vr = (line: string, last = 'Isadore', full = 'Shannon Isadore', url = OR_25H) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(vr(OR_ISADORE.replace('voted Aye', 'voted Nay'))).toBe('snippet_not_found');
    expect(vr(OR_ISADORE.replace('Shannon Isadore', 'Tom Andersen'))).not.toBe('verified');
    expect(vr(OR_ISADORE, 'Andersen', 'Tom Andersen')).toBe('name_not_present');
    expect(vr(OR_ISADORE.replace('HB 3041 -', 'HB 3042 -'))).toBe('snippet_not_found');
    expect(vr(OR_ISADORE.replace('(2025-02-25)', '(2025-02-26)'))).toBe('snippet_not_found');
    expect(vr(OR_ISADORE, 'Isadore', 'Shannon Isadore', OR_25H.replace('624489', '624490'))).toBe('snippet_not_found');
  });

  it('gives the Speaker "was excused for legislative business", never a Yea or a Nay', () => {
    const s = orRender(OR_17H);
    const [l] = stateRollCallLinesFor(OR_17H, s, 'Kotek', 'Tina Kotek');
    expect(l).toBe('Oregon House vote 411795 (2017R1), SB 66 - Third reading. Carried by Lininger. Passed. (2017-05-25): Tina Kotek was excused for legislative business.');
    expect(verifyStateRollCallLine(l.replace('was excused for legislative business', 'voted Aye'), OR_17H, s, 'Kotek', 'Tina Kotek').verdict).toBe('snippet_not_found');
    expect(verifyStateRollCallLine(l.replace('was excused for legislative business', 'was excused'), OR_17H, s, 'Kotek', 'Tina Kotek').verdict).toBe('snippet_not_found');
  });

  it('reads the tally as Aye, Nay and the rest absent or not voting', () => {
    const r = readStateRollCallRecord(orBodies(OR_17H), OR_17H)!;
    expect(r).toMatchObject({ bill: 'SB 66', date: '2017-05-25', chamber: 'House', rollNum: 411795 });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length]).toEqual([54, 0, 6]);
    expect(r.groups['Absent or not voting']).toContain('Tina Kotek');
  });
});

// Saved 2026-11-20 from the Legislature's PUBINFO download (pubinfo_2025.zip, pubinfo_2017.zip) through ca_pubinfo.py: a
// bill's file and the session's member list. The member list is cut to label, names, district and chamber: no fixture holds
// a party.
const caJson = (name: string): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}.json`, import.meta.url)), 'utf8');
const CA = 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=';
const CA_25A = `${CA}202520260AB1127#2025-09-13-AFLOOR-187240-1186`;
const CA_25S = `${CA}202520260AB1127#2025-09-12-SFLOOR-187281-1034`;
const CA_17A = `${CA}201720180AB1419#2018-01-29-AFLOOR-158903-1039`;
const caBodies = (url: string): string[] => url.includes('2017')
  ? [caJson('ca-2017-201720180AB1419'), caJson('ca-2017-legislators')]
  : [caJson('ca-2025-202520260AB1127'), caJson('ca-2025-legislators')];
/** Change the bill file, and fail the test when the change did not apply. */
const caEdit = (body: string, f: (b: { summary: Record<string, string | null>[]; detail: Record<string, string | null>[]; motions: Record<string, string | null>; bill_id: string }) => void): string => {
  const j = JSON.parse(body);
  f(j);
  const out = JSON.stringify(j);
  expect(out).not.toBe(JSON.stringify(JSON.parse(body)));
  return out;
};
const caWhy = (url: string, docs: string[]): string => {
  const v = explainCaliforniaVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const caRender = (url: string, docs = caBodies(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error(`the vote did not read: ${caWhy(url, docs)}`);
  return t;
};
const CA_GABRIEL = 'California Assembly vote of 2025-09-13 (2025-2026), AB 1127 - AB 1127 GABRIEL Concurrence in Senate Amendments, passed: Jesse Gabriel voted Aye.';

describe('state roll-call pages — California address', () => {
  it('knows a bill\'s Votes page on leginfo with the vote after a #, and reads it from two local PUBINFO files, never the site', () => {
    expect(parseCaliforniaVoteUrl(CA_25A)).toEqual({ state: 'CA', stateName: 'California', billId: '202520260AB1127', year: 2025, session: '2025-2026',
      bill: 'AB 1127', date: '2025-09-13', location: 'AFLOOR', motionId: '187240', seq: '1186' });
    expect(californiaVoteUrl('202520260AB1127', '2025-09-13 16:02:11', 'AFLOOR', '187240', '1186')).toBe(CA_25A);
    expect(californiaBillId('20232024', 1, 'ab', 4)).toBe('202320241AB4');
    expect(parseCaliforniaVoteUrl(`${CA}202320241AB4#2023-12-01-SFLOOR-1-2`)).toMatchObject({ session: '2023-2024 Special Session 1', bill: 'AB 4' });
    expect(stateRollCallDocs(CA_25A)).toEqual(['pubinfo:2025/bills/202520260AB1127.json', 'pubinfo:2025/legislators.json']);
    expect(stateRollCallMinGapMs(CA_25A)).toBe(0);
    expect(isStateRollCallUrl(CA_25A)).toBe(true);
    expect(isLocalStateRollCallUrl(CA_25A)).toBe(true);
    expect(isLocalStateRollCallUrl(OR_25H)).toBe(false);
    // no vote named, plain http, a committee's vote, an even first year, years that are not one session, a look-alike host
    for (const u of [`${CA}202520260AB1127`, CA_25A.replace('https', 'http'), CA_25A.replace('AFLOOR', 'CX18'), CA_25A.replace('20252026', '20242025'),
      CA_25A.replace('20252026', '20252027'), CA_25A.replace('leginfo.legislature.ca.gov', 'leginfo.legislature.ca.gov.example.com'),
      CA_25A.replace('billVotesClient', 'billNavClient')]) {
      expect([u, isStateRollCallUrl(u)]).toEqual([u, false]);
    }
  });

  it('takes third readings, concurrence, consent calendars and conference reports as votes on the bill, and every motion as not', () => {
    for (const q of ['AB 1127 GABRIEL Assembly Third Reading', 'Assembly 3rd Reading AB1127 Gabriel et al. By Blakespear', 'AB 199 EGGMAN Concurrence in Senate Amendments',
      'Unfinished Business SB1176 Galgiani Concurrence', 'AB 2788 GATTO Consent Calendar Second Day Regular Session', 'Special Consent AB1900',
      'AB 199 EGGMAN Third Reading Urgency', 'AB 526 HOLDEN Concurrence - Urgency Added', 'W/O REF. TO FILE ACR81 Chiu By Pan', 'Conference Report SB2 Hernandez',
      'Senate 3rd Reading SB119      B. & F.R.']) {
      expect([q, caQuestionIsOnTheBill(q)]).toEqual([q, true]);
    }
    for (const q of ['Assembly 3rd Reading AB199 Eggman Urgency Clause', 'Senate 3rd Reading SB1033 Hill Reconsider', 'SB 1176 Galgiani Senate Third Reading Amendment Set #1',
      'AB 37 Berman Assembly Third Reading Amend By GALLAGHER Set #1 Motion to Lay on the Table By REYES', 'SB 32 Pavley Motion to Reconsider',
      'AB 645 WILLIAMS Assembly Third Reading Motion to Appeal the Decision of the Chair By JONES', 'AB 1066 GONZALEZ Concurrence in Senate Amendments Motion to Re-refer to Committee By OBERNOLTE',
      'AB 3234 GLORIA Remove from Inactive File By TING Amendment Set #1', 'HR 2 RENDON By CALDERON', 'Do pass as amended']) {
      expect([q, caQuestionIsOnTheBill(q)]).toEqual([q, false]);
    }
  });
});

describe('state roll-call pages — reading California', () => {
  it('reads a 2025 Assembly vote: bill, question, day, tally, and every member by the session\'s full name', () => {
    const t = caRender(CA_25A);
    expect(t.split('\n').slice(0, 3)).toEqual(['California Assembly vote of 2025-09-13 (2025-2026), AB 1127, AFLOOR 187240 1186.',
      'Question: AB 1127 GABRIEL Concurrence in Senate Amendments, passed', 'Aye 54; No 16; No vote recorded 10.']);
    expect(t).toMatch(/^Aye \(54\): .*\bJesse Gabriel\b/m);
    expect(t).toMatch(/^No \(16\): .*\bJeff Gonzalez\b/m);
    expect(t).toMatch(/^No vote recorded \(10\): .*\bDiane Dixon\b|^No vote recorded \(10\): .*\bMia Bonta\b/m);
    // the member list holds her twice, "Ávila Farías" and "Avila Farias"; the vote prints the first
    expect(t).toMatch(/\bAnamarie Ávila Farías\b/);
  });

  it('reads the Senate vote of the same bill, and a failed 2017 vote', () => {
    expect(caRender(CA_25S).split('\n').slice(0, 3)).toEqual(['California Senate vote of 2025-09-12 (2025-2026), AB 1127, SFLOOR 187281 1034.',
      'Question: Assembly 3rd Reading AB1127 Gabriel et al. By Blakespear, passed', 'Aye 29; No 9; No vote recorded 2.']);
    expect(caRender(CA_25S)).toMatch(/^No vote recorded \(2\): .*\bLena Gonzalez\b/m);
    expect(caRender(CA_17A).split('\n').slice(1, 3)).toEqual(['Question: AB 1419 QUIRK Assembly Third Reading, failed', 'Aye 35; No 26; No vote recorded 16.']);
  });

  it('refuses a vote whose summary, member rows or member list do not hold together', () => {
    const [b, l] = caBodies(CA_25A);
    expect(caWhy(CA_25A, [b, l])).toBe('read');
    const vote = (x: Record<string, string | null>) => x.location_code === 'AFLOOR' && x.vote_date_seq === '1186';
    // another bill's file, a vote the address does not name, a committee's vote, a motion, a result it does not know
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.bill_id = '202520260AB1128'; }), l])).toBe('the bill file is of 202520260AB1128, not 202520260AB1127');
    expect(caWhy(CA_25A.replace('1186', '1187'), [b, l])).toBe('0 votes of the bill fit the address');
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.summary.push({ ...j.summary.find(vote)! }); }), l])).toBe('2 votes of the bill fit the address');
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.motions['187240'] = 'AB 1127 GABRIEL Motion to Reconsider'; }), l])).toMatch(/^the question is not a vote on the bill/);
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.motions['187240'] = null; }), l])).toBe('the vote has no motion text');
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.summary.find(vote)!.vote_result = '(TIE)'; }), l])).toBe('a result the reader does not know: (TIE)');
    // a member's vote flipped, so a count no longer equals the tally; a kind it does not know; a row of another time
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.detail.find((x) => vote(x) && x.legislator_name === 'Castillo')!.vote_code = 'AYE'; }), l]))
      .toBe('the Aye group lists 55 members and the tally prints 54');
    // a No turned into a member with no vote recorded: the No group no longer holds the summary's count
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.detail.find((x) => vote(x) && x.legislator_name === 'Castillo')!.vote_code = 'ABS'; }), l]))
      .toBe('the No group lists 15 members and the tally prints 16');
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.detail.find((x) => vote(x) && x.legislator_name === 'Castillo')!.vote_code = 'PAIR'; }), l]))
      .toBe('a kind of vote the reader does not know: PAIR');
    expect(caWhy(CA_25A, [caEdit(b, (j) => { const d = j.detail.find((x) => vote(x) && x.legislator_name === 'Castillo')!; d.vote_date_time = `${d.vote_date_time!.slice(0, 11)}23:59:59`; }), l]))
      .toBe('a member row of another time: Castillo');
    // a member listed twice, and more members than the chamber has
    expect(caWhy(CA_25A, [caEdit(b, (j) => { j.detail.find((x) => vote(x) && x.legislator_name === 'Castillo')!.legislator_name = 'Chen'; }), l])).toBe('a member is listed twice');
    expect(caWhy(CA_25A, [caEdit(b, (j) => {
      const s = j.summary.find(vote)!; s.ayes = String(Number(s.ayes) + 1);
      j.detail.push({ ...j.detail.find(vote)!, legislator_name: 'Extra', vote_code: 'AYE' });
    }), l])).toBe('more members than the chamber has');
    // a member list of another session, or two members given one name
    expect(caWhy(CA_25A, [b, caJson('ca-2017-legislators')])).toBe('the member list is of another session');
    const two = JSON.parse(l) as Record<string, string | null>[];
    Object.assign(two.find((x) => x.author_name === 'Castillo' && x.house_type === 'A')!, { first_name: 'Jesse', last_name: 'Gabriel' });
    expect(caWhy(CA_25A, [b, JSON.stringify(two)])).toBe('two members render as one name');
    expect(caWhy(CA_25A, [b])).toBe('not a bill file and a member list');
  });

  it('counts No vote recorded from the member rows, as the Votes page prints it, when the summary\'s figure differs', () => {
    // 2026-11-20: over 43,971 floor votes of 2015-2026 the summary's "abstain" figure is below the member rows on 341
    // Assembly votes and above them on 16 (AB 3064 of 2024: summary 4, rows and leginfo's page 11); Aye and No differ on 1
    const [b, l] = caBodies(CA_25A);
    const vote = (x: Record<string, string | null>) => x.location_code === 'AFLOOR' && x.vote_date_seq === '1186';
    for (const n of ['4', '12']) {
      const t = caRender(CA_25A, [caEdit(b, (j) => { j.summary.find(vote)!.abstain = n; }), l]);
      expect(t.split('\n')[2]).toBe('Aye 54; No 16; No vote recorded 10.');
    }
  });

  it('keeps a label the member list does not hold as printed: no name is made up', () => {
    const [b, l] = caBodies(CA_25A);
    const less = (JSON.parse(l) as Record<string, string | null>[]).filter((x) => !(x.author_name === 'Gabriel' && x.house_type === 'A'));
    const t = caRender(CA_25A, [b, JSON.stringify(less)]);
    expect(t).toMatch(/^Aye \(54\): (?:.*; )?Gabriel(?:;|$)/m);
    expect(stateRollCallLinesFor(CA_25A, t, 'Gabriel', 'Jesse Gabriel')).toEqual([]);
  });
});

describe('state roll-call pages — California lines', () => {
  const t = caRender(CA_25A);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(CA_25A, t, 'Gabriel', 'Jesse Gabriel')).toEqual([CA_GABRIEL]);
    expect(verifyStateRollCallLine(CA_GABRIEL, CA_25A, t, 'Gabriel', 'Jesse Gabriel')).toEqual({ verdict: 'verified', matchOffset: 0 });
    expect(parseStateRollCallLine(CA_GABRIEL)).toMatchObject({ state: 'CA', chamber: 'House', vote: 'Aye', name: 'Jesse Gabriel', bill: 'AB 1127' });
  });

  it('names a member as the member list does, with a Jr. or Sr. and without a degree', () => {
    // the 2025 list prints Steven Choi's suffix as "Ph.D.": no roster name ends in a degree, so it gave him no line
    const s = caRender(CA_25S);
    expect(s).toMatch(/^No vote recorded \(2\): Steven Choi; Lena Gonzalez$/m);
    expect(stateRollCallLinesFor(CA_25S, s, 'Choi', 'Steven "Steve" Choi')).toEqual([
      'California Senate vote of 2025-09-12 (2025-2026), AB 1127 - Assembly 3rd Reading AB1127 Gabriel et al. By Blakespear, passed: Steven Choi had no vote recorded.']);
    expect(caRender(CA_25A)).toMatch(/\bJosé Luis Solache Jr\.(;|$)/m);
  });

  it('tells members of one family name apart, in the Assembly and across chambers', () => {
    expect(stateRollCallLinesFor(CA_25A, t, 'Gonzalez', 'Jeff Gonzalez')).toEqual([CA_GABRIEL.replace('Jesse Gabriel voted Aye', 'Jeff Gonzalez voted No')]);
    expect(stateRollCallLinesFor(CA_25A, t, 'Gonzalez', 'Lena Gonzalez')).toEqual([]);
    const s = caRender(CA_25S);
    expect(stateRollCallLinesFor(CA_25S, s, 'Gonzalez', 'Lena Gonzalez')[0]).toMatch(/: Lena Gonzalez had no vote recorded\.$/);
  });

  it('refuses the line with the vote flipped, given to another member, or on another bill, day or vote', () => {
    const vr = (line: string, last = 'Gabriel', full = 'Jesse Gabriel', url = CA_25A) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(vr(CA_GABRIEL.replace('voted Aye', 'voted No'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL.replace('voted Aye', 'had no vote recorded'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL.replace('Jesse Gabriel', 'Mia Bonta'))).not.toBe('verified');
    expect(vr(CA_GABRIEL, 'Bonta', 'Mia Bonta')).toBe('name_not_present');
    expect(vr(CA_GABRIEL.replace('AB 1127 -', 'AB 1128 -'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL.replace('2025-09-13', '2025-09-12'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL.replace(', passed:', ', failed:'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL, 'Gabriel', 'Jesse Gabriel', CA_25A.replace('1186', '1187'))).toBe('snippet_not_found');
    expect(vr(CA_GABRIEL.replace('California Assembly', 'California Senate'))).toBe('snippet_not_found');
  });

  it('reads the tally as Aye, No and No vote recorded, the last never a Yea or a Nay', () => {
    const r = readStateRollCallRecord(caBodies(CA_25A), CA_25A)!;
    expect(r).toMatchObject({ bill: 'AB 1127', date: '2025-09-13', chamber: 'House', rollNum: 1186 });
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length]).toEqual([54, 16, 10]);
  });

  it('reads the vote from the local copy through the verifier\'s adapter, and from nowhere when the copy is missing', async () => {
    resetStateRollCallPacing();
    const asked: string[] = [];
    const fetchImpl = async (u: string): Promise<Response> => { asked.push(u); return new Response('', { status: 403 }); };
    const [b, l] = caBodies(CA_25A);
    const local = (d: string): string | null => (d.endsWith('202520260AB1127.json') ? b : d.endsWith('legislators.json') ? l : null);
    expect(await fetchStateRollCallText(CA_25A, { fetchImpl, readLocal: local })).toBe(t);
    expect(await fetchStateRollCallText(CA_25A, { fetchImpl, readLocal: () => null, toText: (h) => h })).toBeNull();
    // a vote the files refuse hands on no plain text: a data file is not a page
    expect(await fetchStateRollCallText(CA_25A.replace('1186', '1187'), { fetchImpl, readLocal: local, toText: (h) => h })).toBeNull();
    expect(asked).toEqual([]);
  });
});

// ── Maine ─────────────────────────────────────────────────────────────────────────────────────────────────
// Saved 2026-11-19 and 2026-11-20 from legislature.maine.gov (allowed paths; robots.txt disallows /LawMakerWeb only):
// House and Senate roll-call PDFs, kept as the positioned runs the adapter hands on (pdfItemsBody), and one House PDF as
// the file itself; 2026-11-21, the 128th and 129th House PDFs and four 131st Senate PDFs (a pair, a pair marked P and P*,
// a veto vote, a question stored in pieces). No fixture prints a party. Senators are named from the saved member lists
// and the 128th-130th House from the saved rosters (maineLegislatureMembers.ts), which a test may change and restore.
const meFix = (name: string): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}`, import.meta.url)), 'utf8').replace(/\n$/, '');
const ME_H131 = 'https://legislature.maine.gov/house/Repository/Documents/131/RollCalls/020.012.131R1.pdf#LD32';
const ME_H132 = 'https://legislature.maine.gov/house/Repository/Documents/132/RollCalls/034.574.132S1.pdf#LD1971';
const ME_H130 = 'https://legislature.maine.gov/house/Repository/Documents/130/RollCalls/004.118.130S1.pdf#LD1138';
const ME_H130M = 'https://legislature.maine.gov/house/Repository/Documents/130/RollCalls/002.002.130R1.pdf#LD115';
const ME_H129 = 'https://legislature.maine.gov/house/Repository/Documents/129/RollCalls/049.204.pdf#LD379';
const ME_H128 = 'https://legislature.maine.gov/house/Repository/Documents/128/RollCalls/00245.pdf#LD9';
const ME_S760 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-760-ld-2238.pdf#LD2238';
const ME_S759 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-759-ld-2086.pdf#LD2086';
const ME_S797 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-797-ld-2086.pdf#LD2086';
const ME_S783 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-783-ld-2224.pdf#LD2224';
const ME_HMOT = 'https://legislature.maine.gov/house/Repository/Documents/132/RollCalls/016.127.132S1.pdf#LD644';
const ME_S634 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-634-ld-1971.pdf#LD1971';
const ME_S454 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-454-ld-1138.pdf#LD1138';
const ME_S184 = 'https://legislature.maine.gov/uploads/visual_edit/roll-call-184-ld-16.pdf#LD16';
const ME_HMIN = 'https://legislature.maine.gov/house/Repository/Documents/131/RollCalls/012.051.131S1.pdf#LD541';
const meBody: Record<string, string> = { [ME_H131]: 'me-131-house-012', [ME_H132]: 'me-132-house-574', [ME_H130]: 'me-130-house-118', [ME_H130M]: 'me-130-house-002', [ME_HMOT]: 'me-132-house-127',
  [ME_S634]: 'me-132-senate-634', [ME_S454]: 'me-132-senate-454', [ME_S184]: 'me-132-senate-184', [ME_HMIN]: 'me-131-house-051',
  [ME_H129]: 'me-129-house-204', [ME_H128]: 'me-128-house-245', [ME_S760]: 'me-131-senate-760', [ME_S759]: 'me-131-senate-759',
  [ME_S797]: 'me-131-senate-797', [ME_S783]: 'me-131-senate-783' };
const meDocs = (url: string, body = meFix(`${meBody[url]}.txt`)): string[] => [body];
/** Run with one saved Senate list or House roster changed (or removed, with null), restoring it after. */
const meWith = <T,>(saved: Record<number, T>, legislature: number, value: T | null, fn: () => void): void => {
  const was = saved[legislature];
  if (value === null) delete saved[legislature]; else saved[legislature] = value;
  try { fn(); } finally { saved[legislature] = was; }
};
const meRoster = (legislature: number, change: (m: MeHouseMember[]) => MeHouseMember[]) => change(ME_HOUSE_ROSTERS[legislature].map((m) => ({ ...m, also: [...m.also] })));
const meUnnamed = (url: string, docs = meDocs(url)): string[] => {
  const v = explainMaineVote(docs, url);
  if ('refused' in v) throw new Error(v.refused);
  return (v.unnamed ?? []).map((u) => `${u.label}: ${u.why}`);
};
const meWhy = (url: string, docs: string[]): string => {
  const v = explainMaineVote(docs, url);
  return 'refused' in v ? v.refused : 'read';
};
const meRender = (url: string, docs = meDocs(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error(`the vote did not read: ${meWhy(url, docs)}`);
  return t;
};
/** A House or Senate body with one change, failing the test when it did not apply. */
const meTamper = (url: string, from: string, to: string): string[] => meDocs(url, tamper(meFix(`${meBody[url]}.txt`), from, to));
const ME_ABDI = 'Maine House roll call 574 (132nd Legislature, First Special Session), LD 1971 - Enactment (2025-06-18): Abdi, M.H. voted Yea.';
const ME_LIBBY = 'Maine Senate roll call 634 (132nd Legislature, First Special Session), LD 1971 - Enactment (2025-06-18): James D. Libby voted Nay.';

describe('state roll-call pages — Maine address', () => {
  it('knows a House PDF and a Senate PDF named with the LD, read a second apart, each alone', () => {
    expect(parseMaineVoteUrl(ME_H132)).toEqual({ state: 'ME', stateName: 'Maine', chamber: 'House', rollNum: 574, ld: 1971,
      file: ME_H132.replace('#LD1971', ''), legislature: 132, session: 'S1', day: 34 });
    expect(parseMaineVoteUrl(ME_S634)).toEqual({ state: 'ME', stateName: 'Maine', chamber: 'Senate', rollNum: 634, ld: 1971, file: ME_S634.replace('#LD1971', '') });
    expect(stateRollCallDocs(ME_H132)).toEqual([ME_H132.replace('#LD1971', '')]);
    // the senators come from the saved list: the live senators page is never asked for
    expect(stateRollCallDocs(ME_S634)).toEqual([ME_S634.replace('#LD1971', '')]);
    expect(stateRollCallMinGapMs(ME_H132)).toBe(1_000);
    expect(stateRollCallMinGapMs(ME_S634)).toBe(1_000);
    // no LD, the two Legislatures of a House path disagreeing, the disallowed roll-call pages, http, a look-alike host, LD 0
    for (const u of [ME_H132.replace('#LD1971', ''), ME_H132.replace('/132/RollCalls', '/131/RollCalls'), ME_S634.replace('#LD1971', ''),
      'https://legislature.maine.gov/LawMakerWeb/rollcall.asp?ID=280096418&chamber=House&serialnumber=574',
      'https://legislature.maine.gov/legis/LawMakerWeb/rollcall.asp?ID=280096418&chamber=Senate&serialnumber=634',
      ME_H132.replace('https', 'http'), ME_S634.replace('legislature.maine.gov', 'legislature.maine.gov.example.com'), ME_S634.replace('#LD1971', '#LD0')]) {
      expect([u, isStateRollCallUrl(u)]).toEqual([u, false]);
    }
  });

  it('knows each Legislature\'s House file name, and no other', () => {
    expect(parseMaineVoteUrl(ME_H128)).toMatchObject({ chamber: 'House', rollNum: 245, ld: 9, legislature: 128, file: ME_H128.replace('#LD9', '') });
    expect(parseMaineVoteUrl(ME_H129)).toMatchObject({ chamber: 'House', rollNum: 204, ld: 379, legislature: 129, day: 49 });
    expect(parseMaineVoteUrl(ME_H130)).toMatchObject({ chamber: 'House', rollNum: 118, ld: 1138, legislature: 130, session: 'S1' });
    const H = 'https://legislature.maine.gov/house/Repository/Documents/';
    for (const u of [`${H}128/RollCalls/054.252.pdf#LD1`, `${H}128/RollCalls/054.252.128R1.pdf#LD1`, `${H}129/RollCalls/00245.pdf#LD1`,
      `${H}129/RollCalls/054.252.129R1.pdf#LD1`, `${H}130/RollCalls/054.252.pdf#LD1`, `${H}130/RollCalls/00245.pdf#LD1`,
      `${H}130/RollCalls/054.252.131R1.pdf#LD1`, `${H}131/RollCalls/00245.pdf#LD1`, `${H}127/RollCalls/00245.pdf#LD1`, `${H}128/RollCalls/0245.pdf#LD1`]) {
      expect([u, isStateRollCallUrl(u)]).toEqual([u, false]);
    }
  });

  it('reads a vote to accept the Majority report, Ought to Pass or Ought Not to Pass, and says which way it goes', () => {
    // runner, 2026-11-20: "read majority report votes for Maine", "Both, with the flag". Maine reports out every bill, so the
    // chamber's vote on the Majority report is its vote on the bill; accepting Ought Not to Pass kills it. A Minority,
    // lettered or unanimous report is still a motion.
    for (const [q, way] of [['ACC MAJ OTP AS AMENDED REP', 'for'], ['ACC MAJ OUGHT TO PASS REP', 'for'], ['ACC MAJ OTP REP', 'for'],
      ['ACC MAJ OUGHT NOT TO PASS REP', 'against'], ['Acc Maj Ought Not to Pass Rep', 'against'],
      ['Accept Majority Ought to Pass as Amended Report from the Committee on Appropriations and Financial Affairs ( HP 257 ) ( LD 424 )', 'for'],
      ['Accept Majority Ought Not To Pass Report from the Committee on Environment and Natural Resources ( LD 425)(HP 258 )', 'against'],
      ['Accept Majority Ought to Pass Report from the Committee on Judiciary', 'for'],
      // as the 132nd's Senate and House PDFs print them (fetched 2026-11-20): an amendment named, no "Report", a word
      // dropped, "Acceptance", and words the PDF splits
      ['Accept Majority Ought to Pass as Amended by Committee Amendment "A" from the Committee on Judiciary', 'for'],
      ['Accept Majority Ought to Pass as Amended by Committee Amendment "A" Report from the Committee on Judiciary', 'for'],
      ['acc maj otp-am by ca-a', 'for'], ['Accept Majority Ought Not Pass Report from the Committee on Judiciary', 'against'],
      ['Accept M ajority Ought Not to Pass Report from the Committee on Judiciary', 'against'],
      ['Acceptance Majority Ought Not to Pass Report from the Committee on Judiciary', 'against']] as const) {
      expect([q, meMajorityReport(q), meQuestionIsRead(q), meQuestionIsOnTheBill(q)]).toEqual([q, way, true, false]);
    }
    for (const q of ['ACC MIN OUGHT NOT TO PASS REP', 'ACC MIN OTP AS AMENDED REP', 'Accept Minority Ought to Pass as Amended Report from the Committee on Taxation',
      'ACC OTP-AM BY CA "A"', 'ACCEPT REPORT "A" OTP-AM', 'Accept Report "B" Ought Not to Pass', 'INDEF PP HAH-285', 'Enactment',
      'Recede from Passage to be Engrossed as Amended by Committee Amendment "A" and Concur Acceptance of the Minority Ought Not to Pass Report',
      'Reconsider Acceptance of the Majority Ought Not to Pass Report', 'ACC MAJ OUGHT NOT TO PASS REP AND SEND FORTHWITH']) {
      expect([q, meMajorityReport(q)]).toEqual([q, null]);
    }
    expect(meQuestionIsRead('Enactment')).toBe(true);
  });

  it('takes enactment, engrossing, final passage and a veto vote as votes on the bill, and every motion as not', () => {
    for (const q of ['Enactment', 'ENACTMENT', 'Enactment - Emer', 'Emergency Enactment', 'Final Enactment', 'PASSAGE TO BE ENGROSSED', 'Passage to be Engrossed as Amended by Committee Amendment "A"',
      'Passage to be Engrossed as Amended by Committee Amendment "A" as Amended by Senate Amendment "B"', 'Final Passage', 'Reconsideration - Veto',
      'Shall this Bill become law notwithstanding the objections of the Governor?']) {
      expect([q, meQuestionIsOnTheBill(q)]).toEqual([q, true]);
    }
    // accepting a committee's report is a motion: the bill is not voted on (standing answer 3)
    for (const q of ['ACC MAJ OTP AS AMENDED REP', 'ACC MAJ OUGHT NOT TO PASS REP', 'Accept Majority Ought Not to Pass Report from the Committee on Judiciary',
      'INDEF PP HAH-285', 'Adopt Senate Amendment "A"', 'RECEDE AND CONCUR', 'Suspend Rules for Reconsideration', 'OTP-AM', 'Adjournment',
      'Recede from Passage to be Engrossed as Amended by Committee Amendment "A" and Concur Acceptance of the Minority Ought Not to Pass Report']) {
      expect([q, meQuestionIsOnTheBill(q)]).toEqual([q, false]);
    }
  });

  it('hands a Maine PDF on as positioned runs, and every other PDF as before', () => {
    const items = [{ page: 1, x: 18.71, y: 622.54, str: 'Y' }, { page: 1, x: 53.3, y: 622.5, str: ' Abdi,  M.H. ' }, { page: 1, x: 1, y: 1, str: ' ' }];
    expect(pdfItemsBody(items)).toBe(`${PDF_ITEMS_MARK}\n1\t18.7\t622.5\tY\n1\t53.3\t622.5\tAbdi, M.H.`);
    expect(pdfBodyFor(ME_H132, items)).toBe(pdfItemsBody(items));
    expect(pdfBodyFor(ME_S634, items)).toBe(pdfItemsBody(items));
    expect(pdfBodyFor('https://www.mnsenate.gov/journals/2025-2026/20250519.pdf#x', items).startsWith(PDF_ITEMS_MARK)).toBe(false);
  });

  it('holds the saved Senate lists of the 128th to 132nd, from allowed pages only, and the House rosters of the 128th to 130th', () => {
    expect(Object.keys(ME_SENATE_LISTS).map(Number)).toEqual([128, 129, 130, 131, 132]);
    for (const [l, list] of Object.entries(ME_SENATE_LISTS)) {
      // 35 seats; a Legislature's list also names a senator who took a seat mid-term
      expect([l, list.names.length >= 35 && list.names.length <= 37, new Set(list.names).size === list.names.length]).toEqual([l, true, true]);
      for (const src of list.sources) expect([src, /LawMakerWeb/i.test(src), /^https:\/\/(?:legislature\.maine\.gov|web\.archive\.org)\//.test(src)]).toEqual([src, false, true]);
    }
    expect(ME_SENATE_LISTS[132].names).toContain('James D. Libby');
    expect(ME_SENATE_LISTS[131].names).toContain('Teresa S. Pierce');
    expect(Object.keys(ME_HOUSE_ROSTERS).map(Number)).toEqual([128, 129, 130]);
  });
});

describe('state roll-call pages — reading Maine', () => {
  it('reads a 131st House vote: bill, question, day, tally, and every member by the label the PDF prints', () => {
    const t = meRender(ME_H131);
    expect(t.split('\n').slice(0, 3)).toEqual(['Maine House roll call 12 (131st Legislature, First Regular Session), LD 32, 2023-03-28.',
      'Question: PASSAGE TO BE ENGROSSED', 'Yea 122; Nay 12; Not voting 16; Excused 0; Restricted 0.']);
    expect(t).toMatch(/^Nay \(12\): Adams, J\.S\.; Bagshaw, B\.A\.;/m);
    expect(t).toMatch(/^Not voting \(16\): Abdi, M\.H\.;/m);
    expect(t).not.toMatch(/\b(?:Democrat|Republican|Independent)\b|\([DRIU]\)/);
  });

  it('reads a 132nd House vote with its excused members, a label printed "Collins, A. C" and the Speaker as printed', () => {
    const t = meRender(ME_H132);
    expect(t.split('\n').slice(0, 3)).toEqual(['Maine House roll call 574 (132nd Legislature, First Special Session), LD 1971, 2025-06-18.',
      'Question: Enactment', 'Yea 75; Nay 73; Not voting 1; Excused 2; Restricted 0.']);
    expect(t).toMatch(/^Excused \(2\): Eaton, H\.R\.; Griffin, A\.W\.$/m);
    expect(t).toMatch(/^Nay \(73\): .*; Collins, A\. C;/m);
    expect(t).toMatch(/Mr\. Speaker/);
    expect(stateRollCallLinesFor(ME_H132, t, 'Fecteau', 'Ryan M. Fecteau')).toEqual([]);
    expect(stateRollCallLinesFor(ME_H132, t, 'Collins', 'Alicia Collins')).toEqual([
      'Maine House roll call 574 (132nd Legislature, First Special Session), LD 1971 - Enactment (2025-06-18): Collins, A. C voted Nay.']);
  });

  it('reads a House and a Senate vote to accept the Majority Ought Not to Pass report, its question as printed', () => {
    const h = meRender(ME_HMOT);
    expect(h.split('\n')[1]).toBe('Question: ACC MAJ OUGHT NOT TO PASS REP');
    // the fixture prints N at x 170.6 beside "Eder, J." on row 567.4
    expect(stateRollCallLinesFor(ME_HMOT, h, 'Eder', 'John Eder')).toEqual([
      'Maine House roll call 127 (132nd Legislature, First Special Session), LD 644 - ACC MAJ OUGHT NOT TO PASS REP (2025-05-13): Eder, J. voted Nay.']);
    const s = meRender(ME_S184);
    expect(s.split('\n')[1]).toBe('Question: Accept Majority Ought Not to Pass Report from the Committee on Judiciary');
    expect(s).not.toMatch(/\b(?:Democrat|Republican|Independent)\b|\([DRIU]\)/);
  });

  it('reads the same bill\'s Senate vote, naming each senator from the member list', () => {
    const t = meRender(ME_S634);
    expect(t.split('\n').slice(0, 3)).toEqual(['Maine Senate roll call 634 (132nd Legislature, First Special Session), LD 1971, 2025-06-18.',
      'Question: Enactment', 'Yea 20; Nay 14; Absent 0; Excused 1.']);
    expect(t).toMatch(/^Excused \(1\): Joseph Rafferty$/m);
    expect(t).toMatch(/^Nay \(14\): .*\bJames D\. Libby\b/m);
    expect(meRender(ME_S454).split('\n')[1]).toBe('Question: Passage to be Engrossed as Amended by Committee Amendment "A"');
  });

  it('keeps a Senate surname as printed when no senator or two of them fit it, and refuses a Legislature with no saved list', () => {
    const list = ME_SENATE_LISTS[132];
    meWith(ME_SENATE_LISTS, 132, { ...list, names: list.names.map((n) => (n === 'Joseph Martin' ? 'Joseph Libby' : n)) }, () => {
      const t = meRender(ME_S634);
      expect(t).toMatch(/^Nay \(14\): .*; Libby; Martin;/m);
      expect(stateRollCallLinesFor(ME_S634, t, 'Libby', 'James D. Libby')).toEqual([]);
      expect(meUnnamed(ME_S634)).toEqual(['Libby: 2 senators of the list share it (James D. Libby, Joseph Libby)', 'Martin: no senator of the list has it']);
    });
    expect(meUnnamed(ME_S634)).toEqual([]);
    meWith(ME_SENATE_LISTS, 132, null, () => expect(meWhy(ME_S634, meDocs(ME_S634))).toBe('no Senate member list of the 132nd Legislature is saved'));
  });

  it('reads a 131st Senate vote that stores its numbers and words in pieces, a veto vote, and a vote with pairs', () => {
    // "YEA: 1" "6", "Question" ": E" "nactment", "M" "otion" ": Reconsideration - Veto"
    expect(meRender(ME_S760).split('\n').slice(0, 3)).toEqual(['Maine Senate roll call 760 (131st Legislature, Second Regular Session), LD 2238, 2024-04-17.',
      'Question: Enactment', 'Yea 16; Nay 15; Absent 0; Excused 0.']);
    expect(meRender(ME_S783).split('\n').slice(1, 3)).toEqual(['Question: Enactment', 'Yea 18; Nay 15; Absent 0; Excused 2.']);
    expect(meRender(ME_S797).split('\n').slice(1, 3)).toEqual(['Question: Reconsideration - Veto', 'Yea 18; Nay 16; Absent 0; Excused 1.']);
    // two pairs, each a P under Yea and a P under Nay with the pair's number above: listed, not counted, given no line
    const t = meRender(ME_S760);
    expect(t).toMatch(/^Paired \(4\): Joseph M\. Baldacci; David P\. LaFountain; Teresa S\. Pierce; Cameron D\. Reny$/m);
    expect(stateRollCallLinesFor(ME_S760, t, 'Pierce', 'Teresa S. Pierce')).toEqual([]);
    expect(readStateRollCallRecord(meDocs(ME_S760), ME_S760)!.groups['Absent or not voting']).toEqual(['Joseph M. Baldacci', 'David P. LaFountain', 'Teresa S. Pierce', 'Cameron D. Reny']);
    // one pair, printed P and P* with no number
    expect(meRender(ME_S759)).toMatch(/^Paired \(2\): Timothy E\. Nangle; Teresa S\. Pierce$/m);
  });

  it('refuses a pair that is not one Yea and one Nay, a pair number with no pair, and a row above the heads it cannot read', () => {
    for (const [url, from, to, why] of [
      [ME_S760, '1\t441.1\t408.1\t1\n', '', /^a pair mark with no pair number$/],
      [ME_S760, '1\t441.1\t408.1\t1', '1\t441.1\t408.1\t2', /^pair 2 is not one Yea and one Nay$/],
      // two numbers right of one P, far enough apart not to read as one number
      [ME_S760, '1\t441.1\t408.1\t1', '1\t434.0\t408.1\t1\n1\t443.5\t408.1\t3', /^the pair mark of Pierce has 2 pair numbers$/],
      [ME_S760, '1\t441.1\t408.1\t1', '1\t441.1\t408.1\t1\n1\t500.0\t408.1\t3', /^the vote prints 5 pair numbers for 4 paired members$/],
      [ME_S760, '1\t441.1\t408.1\t1', '1\t441.1\t418.1\t1', /^a pair number with no member below it/],
      [ME_S760, '1\t433.7\t404.7\tP', '1\t491.6\t404.7\tP', /^the pair mark of Pierce is under Absent$/],
      [ME_S759, '1\t433.7\t404.7\tP*', '1\t433.7\t404.7\tP', /^2 paired members and no pair numbers$/],
      [ME_S759, '1\t464.7\t426.6\tP', '1\t433.7\t426.6\tP', /^pair {2}is not one Yea and one Nay$/],
      [ME_S797, '(Veto Sustained)', '(Veto Pending)', /^a row the reader cannot read above the column heads: \(Veto Pending\)$/],
    ] as const) {
      expect([to, meWhy(url, meTamper(url, from, to))]).toEqual([to, expect.stringMatching(why)]);
    }
  });

  it('refuses a vote that is not on the bill, a Legislature that prints surnames only, and a vote with no LD', () => {
    expect(meWhy(ME_HMIN, meDocs(ME_HMIN))).toBe('the question is not a vote on the bill: ACC MIN OUGHT NOT TO PASS REP');
    expect(meWhy(ME_HMOT, meTamper(ME_HMOT, 'MOTION: ACC MAJ OUGHT NOT TO PASS REP', 'MOTION: ACC MIN OUGHT NOT TO PASS REP'))).toBe('the question is not a vote on the bill: ACC MIN OUGHT NOT TO PASS REP');
    expect(meWhy(ME_S184, meTamper(ME_S184, 'Accept Majority', 'Accept Minority'))).toMatch(/^the question is not a vote on the bill: Accept Minority Ought Not to Pass Report/);
    expect(meWhy(ME_H132, ['not a pdf'])).toBe('the vote is not a PDF');
    expect(meWhy(ME_S634, [meFix('me-132-senate-634.txt'), '<p>a second body</p>'])).toBe('not the vote and its documents');
    // a 130th vote reaches the question check like any other
    expect(meWhy(ME_H130M, meDocs(ME_H130M))).toBe('the question is not a vote on the bill: ACC MIN OUGHT TO PASS REP');
  });

  it('refuses a House PDF whose heading is not the address\'s vote', () => {
    for (const [from, to, why] of [
      ['132nd LEGISLATURE', '131st LEGISLATURE', /^the vote is of the 131 Legislature$/],
      ['First Special Session', 'Second Regular Session', /^the vote is of the Second Regular Session, not S1$/],
      ['ROLL CALL NO. 574', 'ROLL CALL NO. 575', /^the vote is roll call 575$/],
      ['\tLD 1971\n', '\tLD 1972\n', /^the vote is on LD 1972$/],
      ['DATE: 6/18/2025', 'DATE: 6/31/2025', /^the date is not a real day$/],
      ['MOTION: Enactment', 'MOTION: ACC MIN OTP REP', /^the question is not a vote on the bill/],
      ['1\t20.2\t687.5\tDATE', '2\t20.2\t687.5\tDATE', /^the vote runs past one page$/],
      ['1\t459.8\t662.2\tVOTES REQUIRED: 75', '1\t459.8\t662.2\tNOTE: 75', /^a header item the reader cannot read: NOTE: 75$/],
    ] as const) {
      expect([to, meWhy(ME_H132, meTamper(ME_H132, from, to))]).toEqual([to, expect.stringMatching(why)]);
    }
  });

  it('refuses a House tally the marks do not add up to, a mark out of its slot, and a label it cannot read', () => {
    for (const [from, to, why] of [
      ['YES: 75', 'YES: 76', /^the Yea group lists 75 members and the tally prints 76$/],
      ['EXC VOTE: 0', 'EXC VOTE: 1', /^the vote prints EXC VOTE: 1$/],
      ['VACANT: 0', 'VACANT: 1', /^151 members and 1 vacant seats are not the House's 151$/],
      ['1\t18.7\t622.5\tY', '1\t18.7\t622.5\tN', /^the mark N of Abdi, M\.H\. sits in slot 1$/],
      ['1\t18.7\t622.5\tY', '1\t27.4\t622.5\tY', /^the mark Y of Abdi, M\.H\. sits in slot 2$/],
      ['1\t18.7\t622.5\tY', '1\t10.0\t622.5\tY', /^a mark Y in no slot/],
      ['1\t18.7\t622.5\tY\n', '', /^a member with no mark: Abdi, M\.H\.$/],
      ['Lavigne, T.A.', 'Lavigne T.A.', /^a label the reader cannot read: Lavigne T\.A\.$/],
      ['Lance, M.J.', 'Abdi, M.H.', /^a label is printed twice$/],
      ['Rep. Eaton, H.R., Rep. Griffin, A.W.', 'Rep. Eaton, H.R.', /^the EXCUSED DAY list is not the members marked E$/],
    ] as const) {
      expect([to, meWhy(ME_H132, meTamper(ME_H132, from, to))]).toEqual([to, expect.stringMatching(why)]);
    }
  });

  it('refuses a Senate PDF whose heading, marks, totals or footer disagree', () => {
    for (const [from, to, why] of [
      ['ROLL CALL #634', 'ROLL CALL #635', /^the vote is roll call 635$/],
      ['1\t495.5\t766.2\tLD 1971', '1\t495.5\t766.2\tLD 1972', /^the vote is on LD 1972$/],
      ['HP 1315\n', 'LD 1315\n', /^the vote prints more than one LD$/],
      ['DATE: June 18, 2025', 'DATE: June 31, 2025', /^the date is not a real day$/],
      ['Question: Enactment', 'Question: Adopt Senate Amendment "A"', /^the question is not a vote on the bill: Adopt Senate Amendment "A"$/],
      ['1\t202.6\t558.2\tX', '1\t231.4\t558.2\tX', /^the Yea group lists 19 members and the tally prints 20$/],
      ['1\t202.6\t558.2\tX', '1\t202.6\t558.2\tX\n1\t231.4\t558.2\tX', /^Bailey has 2 marks$/],
      ['1\t202.6\t558.2\tX', '1\t215.0\t558.2\tX', /^the mark of Bailey is under no column head$/],
      ['1\t462.2\t185.4\t14', '1\t462.2\t185.4\t15', /^the TOTALS row 20-15-0-1/],
      ['Senator Rafferty excused.', 'Senator Lawrence excused.', /^the members the footer names excused/],
      ['Senator Rafferty excused.', 'Senator Rafferty left.', /^a footer sentence the reader cannot read: Senator Rafferty left\.$/],
      ['1\t516.8\t579.8\tExc\n', '', /^the vote prints no row of column heads$/],
      ['1\t196.5\t579.8\tYea\n1\t225.3\t579.8\tNay\n', '1\t196.5\t579.8\tYea Nay\n', /^the column heads are not eight$/],
    ] as const) {
      expect([to, meWhy(ME_S634, meTamper(ME_S634, from, to))]).toEqual([to, expect.stringMatching(why)]);
    }
  });
});

describe('state roll-call pages — Maine House 128th to 130th, printed by surname', () => {
  const pick = (t: string, kind: string): string[] => (new RegExp(`^${kind} \\(\\d+\\): (.*)$`, 'm').exec(t)?.[1] ?? '').split('; ');
  it('names each member from our roster of that Legislature, and keeps a surname two seated members share', () => {
    const t = meRender(ME_H130);
    expect(t.split('\n').slice(0, 3)).toEqual(['Maine House roll call 118 (130th Legislature, First Special Session), LD 1138, 2021-06-03.',
      'Question: ACC MAJ OUGHT NOT TO PASS REP', 'Yea 79; Nay 62; Not voting 10; Excused 0; Restricted 0.']);
    // "MartinJ", "MartinR", "MartinT": an initial glued on where members share a surname
    expect(pick(t, 'Yea')).toEqual(expect.arrayContaining(['Roland Danny Martin', 'Reb Millett', 'Teresa Pierce', 'Bruce White']));
    expect(pick(t, 'Nay')).toEqual(expect.arrayContaining(['John L. Martin', 'MillettH', 'Dustin Michael White']));
    expect(pick(t, 'Not voting')).toContain('Thomas H. Martin');
    // Open States names the member printed MillettH "Sawin Millett": no H, so kept as printed
    expect(meUnnamed(ME_H130)).toEqual(['MillettH: no seated Reb Millett or Sawin Millett has the initial H']);
    expect(stateRollCallLinesFor(ME_H130, t, 'Martin', 'John L. Martin')).toEqual([
      'Maine House roll call 118 (130th Legislature, First Special Session), LD 1138 - ACC MAJ OUGHT NOT TO PASS REP (2021-06-03): John L. Martin voted Nay.']);
    expect(stateRollCallLinesFor(ME_H130, t, 'Millett', 'Sawin Millett')).toEqual([]);

    const t129 = meRender(ME_H129);
    expect(t129.split('\n')[2]).toBe('Yea 67; Nay 64; Not voting 17; Excused 2; Restricted 0.');
    expect(meUnnamed(ME_H129)).toEqual(['Foley: 2 seated members share it (Bob Foley, Victoria Foley)', 'Roberts-Lovell: no seated member of the roster has it']);
    expect(pick(t129, 'Nay')).toEqual(expect.arrayContaining(['Foley', 'Madam Speaker', 'Teresa Pierce']));
    expect(stateRollCallLinesFor(ME_H129, t129, 'Foley', 'Victoria Foley')).toEqual([]);
  });

  it('reads a 128th vote, laid out on its own, with its excused member', () => {
    const t = meRender(ME_H128);
    expect(t.split('\n').slice(0, 3)).toEqual(['Maine House roll call 245 (128th Legislature, First Regular Session), LD 9, 2017-06-06.',
      'Question: ACC MAJ OTP AS AMENDED REP', 'Yea 122; Nay 24; Not voting 4; Excused 1; Restricted 0.']);
    expect(t).toMatch(/^Excused \(1\): Michael G\. Devin$/m);
    // "X Lockman", a close mark stored with its label; "Austin, B." and "Austin, S."
    expect(pick(t, 'Not voting')).toContain('Lawrence E. Lockman');
    expect(pick(t, 'Yea')).toEqual(expect.arrayContaining(['Betty A. Austin', 'Susan M. W. Austin', 'Robert W. Alley']));
    expect(meUnnamed(ME_H128)).toEqual(['Casas: no seated member of the roster has it', 'Fecteau: 2 seated members share it (Justin Fecteau, Ryan Fecteau)',
      'Foley: 2 seated members share it (Bob Foley, Victoria Foley)', 'White: 2 seated members share it (Bruce White, Dustin Michael White)']);
    expect(stateRollCallLinesFor(ME_H128, t, 'Alley', 'Robert W. Alley')).toEqual([
      'Maine House roll call 245 (128th Legislature, First Regular Session), LD 9 - ACC MAJ OTP AS AMENDED REP (2017-06-06): Robert W. Alley voted Yea.']);
  });

  it('keeps as printed a surname the roster shares, lacks, has unseated that day, or fits to two labels; refuses a missing roster', () => {
    const was = ME_HOUSE_ROSTERS[130];
    const pierce = was.find((m) => m.name === 'Teresa Pierce')!;
    const cases: [MeHouseMember[] | null, string[] | string][] = [
      [meRoster(130, (r) => [...r, { name: 'Jeffrey K. Pierce', family: 'Pierce', also: [], from: null, to: null }]),
        ['MillettH: no seated Reb Millett or Sawin Millett has the initial H', 'Pierce: 2 seated members share it (Teresa Pierce, Jeffrey K. Pierce)']],
      [meRoster(130, (r) => r.filter((m) => m.name !== 'Teresa Pierce')), ['MillettH: no seated Reb Millett or Sawin Millett has the initial H', 'Pierce: no seated member of the roster has it']],
      [meRoster(130, (r) => r.map((m) => (m.name === pierce.name ? { ...m, to: '2021-06-02' } : m))), ['MillettH: no seated Reb Millett or Sawin Millett has the initial H', 'Pierce: no seated member of the roster has it']],
      [meRoster(130, (r) => r.filter((m) => m.name !== 'Roland Danny Martin').map((m) => (m.name === 'John L. Martin' ? { ...m, also: ['Roland L. Martin'] } : m))),
        ['MartinJ: another label fits John L. Martin too', 'MartinR: another label fits John L. Martin too', 'MillettH: no seated Reb Millett or Sawin Millett has the initial H']],
      [meRoster(130, (r) => r.map((m) => (m.name === 'Reb Millett' ? { ...m, name: 'Roland Danny Martin' } : m))), 'two members render as one name'],
      [null, 'no House roster of the 130th Legislature is saved'],
    ];
    for (const [roster, want] of cases) {
      meWith(ME_HOUSE_ROSTERS, 130, roster, () => {
        if (typeof want === 'string') expect(meWhy(ME_H130, meDocs(ME_H130))).toBe(want);
        else expect(meUnnamed(ME_H130)).toEqual(want);
      });
    }
    expect(ME_HOUSE_ROSTERS[130]).toBe(was);
  });

  it('refuses a 128th page whose heading, tally, sentences, marks or labels disagree', () => {
    const body = meFix('me-128-house-245.txt');
    expect(meWhy(ME_H128, meDocs(ME_H128, body.split('\n').slice(0, 20).join('\n')))).toBe('the vote prints no members');
    for (const [from, to, why] of [
      ['128th LEGISLATURE', '129th LEGISLATURE', /^the vote is of the 129 Legislature$/],
      ['1\t554.4\t754.6\t245', '1\t554.4\t754.6\t246', /^the vote is roll call 246$/],
      ['MAINE HOUSE OF REPRESENTATIVES', 'MAINE STATE SENATE', /^the vote prints no House heading$/],
      ['1\t28.8\t713.5\tLD 9', '1\t28.8\t713.5\tLD 10', /^the vote is on LD 10$/],
      ['6/06/2017', '6/31/2017', /^the date is not a real day$/],
      ['MOTION: ACC MAJ OTP AS AMENDED REP', 'MOTION: ACC MIN OTP AS AMENDED REP', /^the question is not a vote on the bill: ACC MIN OTP AS AMENDED REP$/],
      ['YES: 122', 'YES: 123', /^the Yea group lists 122 members and the tally prints 123$/],
      ['EXCUSED: 1', 'EXCUSED: 2', /^the Excused group lists 1 members and the tally prints 2$/],
      ['1\t446.4\t617.8\tMOTION: PREVAILS', '1\t446.4\t617.8\tMOTION: TABLED', /^the vote prints no tally$/],
      ['Rep. Devin excused', 'Rep. Lockman excused', /^the members the sentences name excused are not the members marked E$/],
      ['Rep. Devin excused pursuant to House Rule 401.12.', 'Rep. Devin left.', /^a sentence the reader cannot read: Rep\. Devin left\.$/],
      ['1\t201.6\t604.1\tEXCUSED: 1', '1\t201.6\t604.1\tEXCUSED: 1\n1\t28.8\t630.0\tNOTE: 1', /^a header row the reader cannot read: NOTE: 1$/],
      ['1\t28.8\t549.4\tY', '1\t36.0\t549.4\tY', /^the mark Y of Ackley sits 21\.6 before it$/],
      ['X Lockman', 'Y Lockman', /^the mark Y of Lockman is stored with its label$/],
      ['1\t57.6\t549.4\tAckley', '1\t57.6\t549.4\tAckley3', /^a label the reader cannot read: Ackley3$/],
      ['1\t57.6\t535.7\tAlley', '1\t57.6\t535.7\tAckley', /^a label is printed twice$/],
      ['1\t28.8\t549.4\tY\n', '', /^a member with no mark: Ackley$/],
      ['1\t57.6\t549.4\tAckley\n', '', /^a mark Y with no member beside it$/],
      ['1\t28.8\t549.4\tY', '1\t28.8\t549.4\tY\n1\t36.0\t549.4\tN', /^two marks for Ackley$/],
      ['YES: 122', 'YES: 123\n1\t28.8\t40.0\tY\n1\t57.6\t40.0\tZed', /^152 members are more than the House's 151$/],
    ] as const) {
      expect([to, meWhy(ME_H128, meTamper(ME_H128, from, to))]).toEqual([to, expect.stringMatching(why)]);
    }
  });
});

describe('state roll-call pages — Maine lines', () => {
  it('gives a House member and a senator their line, and refuses the line with the vote flipped or given to another member', () => {
    const h = meRender(ME_H132);
    expect(stateRollCallLinesFor(ME_H132, h, 'Abdi', 'Mana Abdi')).toEqual([ME_ABDI]);
    expect(verifyStateRollCallLine(ME_ABDI, ME_H132, h, 'Abdi', 'Mana Abdi')).toMatchObject({ verdict: 'verified' });
    expect(verifyStateRollCallLine(ME_ABDI.replace('voted Yea', 'voted Nay'), ME_H132, h, 'Abdi', 'Mana Abdi').verdict).not.toBe('verified');
    expect(verifyStateRollCallLine(ME_ABDI, ME_H132, h, 'Adams', 'Jennifer Adams').verdict).not.toBe('verified');
    expect(verifyStateRollCallLine(ME_ABDI.replace('LD 1971', 'LD 1972'), ME_H132, h, 'Abdi', 'Mana Abdi').verdict).not.toBe('verified');
    const s = meRender(ME_S634);
    expect(stateRollCallLinesFor(ME_S634, s, 'Libby', 'James D. Libby')).toEqual([ME_LIBBY]);
    expect(verifyStateRollCallLine(ME_LIBBY, ME_S634, s, 'Libby', 'James D. Libby')).toMatchObject({ verdict: 'verified' });
    expect(verifyStateRollCallLine(ME_LIBBY.replace('voted Nay', 'voted Yea'), ME_S634, s, 'Libby', 'James D. Libby').verdict).not.toBe('verified');
    expect(verifyStateRollCallLine(ME_LIBBY, ME_S634, s, 'Bailey', 'Donna Bailey').verdict).not.toBe('verified');
    expect(parseStateRollCallLine(ME_LIBBY)).toMatchObject({ state: 'ME', chamber: 'Senate', rollNum: 634, bill: 'LD 1971', name: 'James D. Libby', vote: 'Nay' });
  });

  it('gives the record Yea, Nay and one group for everyone else', () => {
    const r = readStateRollCallRecord(meDocs(ME_H132), ME_H132)!;
    expect([r.groups.Yea.length, r.groups.Nay.length, r.groups['Absent or not voting'].length]).toEqual([75, 73, 3]);
    const s = readStateRollCallRecord(meDocs(ME_S634), ME_S634)!;
    expect(s.groups['Absent or not voting']).toEqual(['Joseph Rafferty']);
  });

  it('reads the House PDF itself through the adapter', async () => {
    const pdf = readFileSync(fileURLToPath(new URL('./__fixtures__/stateRollCall/me-132-house-574.pdf', import.meta.url)));
    const fetchImpl = async (u: string) => new Response(u === ME_H132.replace('#LD1971', '') ? pdf : 'not found', { status: u === ME_H132.replace('#LD1971', '') ? 200 : 404 });
    expect(await fetchStateRollCallText(ME_H132, { fetchImpl, now: () => 0, sleep: async () => {} })).toBe(meRender(ME_H132));
    resetStateRollCallPacing();
  });
});


// ── Hawaii ───────────────────────────────────────────────────────────────────────────────────────────
// Cut 2026-11-21 from data.capitol.hawaii.gov: each bill page to its title, status tables and text links; each member list
// to its year field, hidden fields and member cards (name, district, dates). Every party letter is replaced by P.
const hiPage = (name: string): string => readFileSync(fileURLToPath(new URL(`./__fixtures__/stateRollCall/${name}.html`, import.meta.url)), 'utf8');
const HI_26H = hawaiiVoteUrl('HB', 2033, 2026, '2026-03-05', 'House', 'Third-Reading');
const HI_22H = hawaiiVoteUrl('HB', 1688, 2022, '2022-05-03', 'House', 'Final-Reading');
const HI_22S = hawaiiVoteUrl('HB', 1688, 2022, '2022-05-03', 'Senate', 'Final-Reading');
const HI_17S = hawaiiVoteUrl('HB', 1478, 2017, '2017-04-11', 'Senate', 'Third-Reading');
const HI_17H = hawaiiVoteUrl('HB', 1478, 2017, '2017-03-07', 'House', 'Third-Reading');
const hiFix: Record<string, [string, string]> = {
  [HI_26H]: ['hi-hb2033-2026-bill', 'hi-h-2026-members'], [HI_22H]: ['hi-hb1688-2022-bill', 'hi-h-2022-members'],
  [HI_22S]: ['hi-hb1688-2022-bill', 'hi-s-2022-members'], [HI_17S]: ['hi-hb1478-2017-bill', 'hi-s-2017-members'],
  [HI_17H]: ['hi-hb1478-2017-bill', 'hi-h-2017-members'],
};
const hiBodies = (url: string): string[] => hiFix[url].map(hiPage);
const hiWhy = (url: string, docs = hiBodies(url)): string => { const v = explainHawaiiVote(docs, url); return 'refused' in v ? v.refused : 'read'; };
const hiRender = (url: string, docs = hiBodies(url)): string => {
  const t = readStateRollCallDocs(docs, url);
  if (!t) throw new Error(`the vote did not read: ${hiWhy(url, docs)}`);
  return t;
};
const HI_AMATO = 'Hawaii House vote of 2026-03-05 (2026), HB 2033 - Passed Third Reading: Terez Amato voted No.';
const hm = (name: string, district: number, from: string | null = null, to: string | null = null): HiMember => {
  const [given, ...rest] = name.split(' ');
  return { name, given, family: rest.join(' '), district, from, to };
};

describe('state roll-call pages — Hawaii address', () => {
  it('knows a vote cited on www by bill, year, day, chamber and kind, and reads it from the data host a second apart', () => {
    expect(HI_26H).toBe('https://www.capitol.hawaii.gov/session/measure_indiv.aspx?billtype=HB&billnumber=2033&year=2026#2026-03-05-House-Third-Reading');
    expect(parseHawaiiVoteUrl(HI_26H)).toEqual({ state: 'HI', stateName: 'Hawaii', type: 'HB', number: 2033, year: 2026, date: '2026-03-05', chamber: 'House', kind: 'Third-Reading', bill: 'HB 2033' });
    expect(stateRollCallDocs(HI_26H)).toEqual(['https://data.capitol.hawaii.gov/session/measure_indiv.aspx?billtype=HB&billnumber=2033&year=2026',
      'https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=H&year=2026']);
    expect(stateRollCallDocs(HI_22S)![1]).toBe('https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=S&year=2022');
    expect(stateRollCallMinGapMs(HI_26H)).toBe(1_000);
    expect(isStateRollCallUrl(HI_26H)).toBe(true);
    // cited on the data host, plain http, no vote after the #, a kind it does not read, a look-alike host, and a day of
    // another year (a carried-over bill's first-year vote is cited on its own year's page, once)
    for (const u of [HI_26H.replace('www.', 'data.'), HI_26H.replace('https', 'http'), HI_26H.replace(/#.*/, ''), HI_26H.replace('Third-Reading', 'Second-Reading'),
      HI_26H.replace('www.capitol.hawaii.gov', 'www.capitol.hawaii.gov.example.com'), hawaiiVoteUrl('SB', 1037, 2018, '2017-03-07', 'Senate', 'Third-Reading')]) {
      expect(isStateRollCallUrl(u)).toBe(false);
    }
  });

  it('chooses the member list\'s year by the form the page posts, and only for a member list', () => {
    const pb = statePostbackOf(stateRollCallDocs(HI_22H)![1])!;
    expect(pb.page).toBe('https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=H');
    const form = pb.form(hiPage('hi-h-2026-members'));
    expect(form.get('ctl00$MainContent$DropDownListYear')).toBe('2022');
    expect(form.get('__EVENTTARGET')).toBe('ctl00$MainContent$DropDownListYear');
    expect([form.get('__VIEWSTATE'), form.get('__EVENTVALIDATION'), form.get('__VIEWSTATEGENERATOR')]).toEqual(['cut', 'cut', 'cut']);
    expect(() => pb.form(tamper(hiPage('hi-h-2026-members'), 'name="__EVENTVALIDATION" id="__EVENTVALIDATION"', 'name="__OTHER" id="__OTHER"'))).toThrow(/has no __EVENTVALIDATION/);
    expect(() => pb.form('<html></html>')).toThrow(/has no year field/);
    expect(statePostbackOf(HI_26H)).toBeNull();
    expect(statePostbackOf(stateRollCallDocs(HI_26H)![0])).toBeNull();
  });
});

describe('state roll-call pages — Hawaii status rows', () => {
  it('reads a House floor vote: the members named, and no Aye count, since the House prints none', () => {
    expect(hawaiiFloorLine('Passed Third Reading with Representative(s) Garcia voting aye with reservations; Representative(s) Amato, Lee, M. voting no (2) and Representative(s) Perruso excused (1).  Transmitted to Senate.', 'House'))
      .toEqual({ kind: 'Third-Reading', passed: true, question: 'Passed Third Reading', ayes: null, named: { 'Aye with reservations': ['Garcia'], No: ['Amato', 'Lee, M.'], Excused: ['Perruso'] } });
    // the clause of ayes with reservations is left out on some votes (2017)
    expect(hawaiiFloorLine('Passed Final Reading with none voting no (0) and Representative(s) Ichiyama excused (1).', 'House')!.named)
      .toEqual({ 'Aye with reservations': [], No: [], Excused: ['Ichiyama'] });
    expect(hawaiiFloorLine('Failed to pass Third Reading with none voting aye with reservations; none voting no (0) and none excused (0).', 'House')).toMatchObject({ kind: 'Third-Reading', passed: false });
  });

  it('reads a Senate floor vote in both of its forms, with every label form the page prints', () => {
    expect(hawaiiFloorLine('Report adopted; Passed Third Reading, as amended (SD 2). Ayes, 22; Aye(s) with reservations: Senator(s) Lee, C. . Noes, 2 (Senator(s) S. Chang, J.Keohokalole). Excused, 1 (Senator(s) Awa).  Transmitted to House.', 'Senate'))
      .toEqual({ kind: 'Third-Reading', passed: true, question: 'Report adopted; Passed Third Reading, as amended (SD 2)', ayes: 22, named: { 'Aye with reservations': ['Lee, C.'], No: ['S. Chang', 'J.Keohokalole'], Excused: ['Awa'] } });
    expect(hawaiiFloorLine('Passed Final Reading, as amended (CD 1). 24 Aye(s); Aye(s) with reservations: none . 1 No(es): Senator(s) Awa. 0 Excused: none.', 'Senate'))
      .toMatchObject({ kind: 'Final-Reading', ayes: 24, named: { No: ['Awa'], Excused: [] } });
    // the clause of ayes with reservations left out
    expect(hawaiiFloorLine('Failed to pass Third Reading. Ayes, 9. Noes, 16 (Senator(s) Awa, Fevella, Inouye, Kanuha, Keith-Agaran, Kidani, Kim, Lee, C., Misalucha, Moriwaki, Nishihara, Rhoads, Riviere, San Buenaventura, Shimabukuro, Wakai). Excused, 0 (none).', 'Senate'))
      .toMatchObject({ passed: false, ayes: 9, named: { No: expect.arrayContaining(['Lee, C.', 'San Buenaventura', 'Keith-Agaran']) } });
  });

  it('reads a House veto override with its printed counts', () => {
    expect(hawaiiFloorLine('Veto overridden with 45 Ayes; 5 Noes Representative(s) Amato, Garcia, Matsumoto, Pierick, Ward; and 1 Excused Representative(s) Perruso.', 'House'))
      .toMatchObject({ kind: 'Veto-Override', ayes: 45, named: { No: ['Amato', 'Garcia', 'Matsumoto', 'Pierick', 'Ward'], Excused: ['Perruso'] } });
  });

  it('reads no second reading, referral, committee report or motion, and refuses a count that is not the members named', () => {
    expect(hawaiiFloorLine('Passed Second Reading as amended in HD 1 and referred to the committee(s) on FIN with none voting aye with reservations; none voting no (0) and none excused (0).', 'House')).toBeNull();
    expect(hawaiiFloorLine('The committee(s) on JDC recommend(s) that the measure be PASSED, WITH AMENDMENTS. The votes in JDC were as follows: 5 Aye(s)', 'Senate')).toBeNull();
    expect(hawaiiFloorLine('Passed Third Reading', 'House')).toBeNull();
    expect(() => hawaiiFloorLine('Passed Third Reading with none voting aye with reservations; Representative(s) Amato voting no (2) and none excused (0).', 'House')).toThrow(/a count that is not the members named/);
    expect(() => hawaiiFloorLine('Passed Third Reading, as amended (SD 2). Ayes, 24; Aye(s) with reservations: none . Noes, 0 (Senator(s) Awa). Excused, 0 (none).', 'Senate')).toThrow(/a count that is not the members named/);
    expect(hawaiiFloorLine('Passed Third Reading by a show of hands.', 'Senate')).toBeNull();
  });
});

describe('state roll-call pages — Hawaii members', () => {
  it('reads the year\'s member list, with the dates of a member who joined or left, and refuses another year or chamber', () => {
    const ms = hawaiiMembers(hiPage('hi-h-2026-members'), 'House', 2026);
    expect(ms).toHaveLength(52);
    expect(ms.find((m) => m.family === 'Holt')).toMatchObject({ name: 'Daniel Holt', district: 28, from: null, to: '2026-02-13' });
    expect(ms.find((m) => m.family === 'Hartsfield')).toMatchObject({ district: 36, from: '2026-01-12', to: null });
    expect(ms.find((m) => m.family === 'Alcos')).toMatchObject({ name: 'David Alcos III', given: 'David' });
    expect(() => hawaiiMembers(hiPage('hi-h-2026-members'), 'House', 2022)).toThrow(/is of 2026, not 2022/);
    expect(() => hawaiiMembers(hiPage('hi-h-2026-members'), 'Senate', 2026)).toThrow(/it is not the Senate's/);
  });

  it('seats a dated member inside their dates, and leaves unplaced an undated member whose district changed hands that year', () => {
    const ms = [hm('Ann Able', 1), hm('Ben Baker', 2, null, '2026-02-13'), hm('Cal Cole', 2), hm('Dee Dunn', 3, '2026-01-12'), hm('Eve Ennis', 4, null, '2026-01-02')];
    const at = (day: string) => { const s = hawaiiSeated(ms, day); return [s.seated.map((m) => m.given), s.uncertain.map((m) => m.given)]; };
    expect(at('2026-02-01')).toEqual([['Ann', 'Ben', 'Dee'], []]);
    // Cal is the likely successor, but the list does not date him: he may or may not have sat
    expect(at('2026-03-05')).toEqual([['Ann', 'Dee'], ['Cal']]);
    // before Dee's appointment, district 3 is empty; after Eve left, district 4 is
    expect(at('2026-01-05')).toEqual([['Ann', 'Ben'], []]);
    expect(() => hawaiiSeated([...ms, hm('Fay Fox', 3, '2026-01-01')], '2026-03-05')).toThrow(/district 3 has two members on 2026-03-05/);
    expect(() => hawaiiSeated([...ms, hm('Gus Gray', 1)], '2026-03-05')).toThrow(/district 1 has 2 members with no dates/);  });

  it('seats a successor the list gives only an end date after the member before them left (2024 Senate district 22)', () => {
    const d22 = [hm('Maile Shimabukuro', 22, null, '2024-05-31'), hm('Cross Crabbe', 22, null, '2024-11-05')];
    const at = (day: string) => { const s = hawaiiSeated(d22, day); return [s.seated.map((m) => m.given), s.uncertain.map((m) => m.given)]; };
    expect(at('2024-03-05')).toEqual([['Maile'], []]);
    expect(at('2024-05-31')).toEqual([['Maile'], []]);
    // when Crabbe was appointed the list does not say: after Shimabukuro left he may or may not have sat
    expect(at('2024-06-10')).toEqual([[], ['Cross']]);
    expect(at('2024-11-06')).toEqual([[], []]);
  });

  it('names a member by family name, and by the initial the page adds when two members share it', () => {
    const seated = [hm('Chris Lee', 25), hm('Mike Lee', 3), hm('Stanley Chang', 9), hm('Jarrett Keohokalole', 24), hm('Sue Keohokapu-Lee Loy', 4), hm('Terez Amato', 5)];
    expect(hawaiiLabelMember('Amato', seated)?.name).toBe('Terez Amato');
    expect(hawaiiLabelMember('Lee, C.', seated)?.name).toBe('Chris Lee');
    expect(hawaiiLabelMember('S. Chang', seated)?.name).toBe('Stanley Chang');
    expect(hawaiiLabelMember('J.Keohokalole', seated)?.name).toBe('Jarrett Keohokalole');
    expect(hawaiiLabelMember('Keohokapu-Lee Loy', seated)?.name).toBe('Sue Keohokapu-Lee Loy');
    // two members fit, or none does
    expect(hawaiiLabelMember('Lee', seated)).toBeNull();
    expect(hawaiiLabelMember('Lee, J.', seated)).toBeNull();
    expect(hawaiiLabelMember('Chang, T.', seated)).toBeNull();
  });
});

describe('state roll-call pages — reading Hawaii', () => {
  it('reads a 2026 House vote: the Ayes are the members seated that day less those named', () => {
    const t = hiRender(HI_26H);
    expect(t.split('\n').slice(0, 3)).toEqual(['Hawaii House vote of 2026-03-05 (2026), HB 2033, Third Reading.', 'Question: Passed Third Reading',
      'Aye 48; Aye with reservations 0; No 1; Excused 1.']);
    expect(t).toMatch(/^No \(1\): Terez Amato$/m);
    expect(t).toMatch(/^Excused \(1\): Amy A\. Perruso$/m);
    // Holt left on 02-13 and Hartsfield joined on 01-12; Ratcliffe, Holt's undated successor, is unplaced and in no group
    expect(t).not.toMatch(/Daniel Holt|Ratcliffe/);
    expect(t).toMatch(/Daisy Hartsfield/);
    expect(explainHawaiiVote(hiBodies(HI_26H), HI_26H)).toMatchObject({ unplaced: ['M. Cov Ratcliffe'] });
  });

  it('reads a Senate vote whose printed Aye count equals the members seated less those named', () => {
    expect(hiRender(HI_22S).split('\n').slice(0, 3)).toEqual(['Hawaii Senate vote of 2022-05-03 (2022), HB 1688, Final Reading.',
      'Question: Passed Final Reading, as amended (CD 1)', 'Aye 25; Aye with reservations 0; No 0; Excused 0.']);
    expect(hiRender(HI_17S).split('\n')[2]).toBe('Aye 25; Aye with reservations 0; No 0; Excused 0.');
  });

  it('reads a 2022 final reading and a 2017 third reading of the House', () => {
    expect(hiRender(HI_22H).split('\n').slice(1, 3)).toEqual(['Question: Passed Final Reading as amended in CD 1', 'Aye 48; Aye with reservations 0; No 2; Excused 0.']);
    expect(hiRender(HI_22H)).toMatch(/^No \(2\): Bob McDermott; Gene Ward$/m);
    expect(explainHawaiiVote(hiBodies(HI_22H), HI_22H)).toMatchObject({ unplaced: ['Luella Costales'] });
    expect(hiRender(HI_17H).split('\n')[2]).toBe('Aye 50; Aye with reservations 0; No 0; Excused 1.');
  });

  it('maps the record to Yea (ayes with reservations too), Nay and Absent, with no party', () => {
    const r = readStateRollCallRecord(hiBodies(HI_26H), HI_26H)!;
    expect(r).toMatchObject({ bill: 'HB 2033', date: '2026-03-05', chamber: 'House' });
    expect([r.groups.Yea.length, r.groups.Nay, r.groups['Absent or not voting']]).toEqual([48, ['Terez Amato'], ['Amy A. Perruso']]);
    expect(hiRender(HI_26H)).not.toMatch(/\((?:D|R|P)\)/);
  });

  it('refuses a vote whose page or member list does not hold together', () => {
    const [b, m] = hiBodies(HI_26H);
    // the member list of another year, the page of another bill, the wrong number of documents
    expect(hiWhy(HI_26H, [b, hiPage('hi-h-2022-members')])).toMatch(/the member list is of 2022, not 2026/);
    expect(hiWhy(HI_26H, [hiPage('hi-hb1688-2022-bill'), m])).toMatch(/^the page is for HB 1688, not HB 2033$/);
    expect(hiWhy(HI_26H, [b])).toBe('not a bill page and a member list');
    // a vote the page does not hold on that day, or a label no seated member fits
    expect(hiWhy(HI_26H.replace('2026-03-05', '2026-03-06'), [b, m])).toMatch(/^the page holds 0 House Third Reading votes on 2026-03-06$/);
    expect(hiWhy(HI_26H, [tamper(b, 'Representative(s) Amato voting no', 'Representative(s) Amatox voting no'), m])).toMatch(/^"Amatox" is not exactly one member seated on 2026-03-05$/);
    // Holt, who left on 02-13, is named in the vote
    expect(hiWhy(HI_26H, [tamper(b, 'Representative(s) Amato voting no', 'Representative(s) Holt voting no'), m])).toMatch(/^"Holt" is not exactly one member seated/);
    // a member named twice
    expect(hiWhy(HI_26H, [tamper(b, 'Representative(s) Perruso excused (1)', 'Representative(s) Amato excused (1)'), m])).toMatch(/Terez Amato is named twice/);
    // the Senate's printed Aye count no longer closes
    const [sb, sm] = hiBodies(HI_22S);
    const row = /Passed Final Reading, as amended \(CD 1\)\. Ayes, 25;/.exec(sb);
    expect(row).not.toBeNull();
    expect(hiWhy(HI_22S, [tamper(sb, row![0], row![0].replace('Ayes, 25', 'Ayes, 24')), sm])).toMatch(/^the page prints 24 Ayes and the members seated less those named are 25$/);
    // a member card the reader cannot read
    expect(hiWhy(HI_26H, [b, tamper(m, '<strong>Holt, Daniel (P)</strong>', '<strong>Holt Daniel</strong>')])).toMatch(/a member card the reader cannot read/);
  });
});

describe('state roll-call pages — Hawaii lines', () => {
  const t = hiRender(HI_26H);

  it('builds one line for a member and verifies it', () => {
    expect(stateRollCallLinesFor(HI_26H, t, 'Amato', 'Terez Amato')).toEqual([HI_AMATO]);
    expect(verifyStateRollCallLine(HI_AMATO, HI_26H, t, 'Amato', 'Terez Amato')).toMatchObject({ verdict: 'verified' });
    expect(parseStateRollCallLine(HI_AMATO)).toMatchObject({ state: 'HI', chamber: 'House', vote: 'No', name: 'Terez Amato', bill: 'HB 2033', date: '2026-03-05' });
  });

  it('refuses the line with the vote flipped, given to another member, or on another day', () => {
    const v = (line: string, last = 'Amato', full = 'Terez Amato', url = HI_26H) => verifyStateRollCallLine(line, url, t, last, full).verdict;
    expect(v(HI_AMATO.replace('voted No', 'voted Aye'))).not.toBe('verified');
    expect(v(HI_AMATO.replace('Terez Amato', 'Amy A. Perruso'), 'Perruso', 'Amy A. Perruso')).not.toBe('verified');
    expect(v(HI_AMATO, 'Perruso', 'Amy A. Perruso')).not.toBe('verified');
    expect(v(HI_AMATO.replace('2026-03-05', '2026-03-06'))).not.toBe('verified');
  });

  it('gives an excused member "was excused", an Aye "voted Aye", and an unplaced member no line', () => {
    expect(stateRollCallLinesFor(HI_26H, t, 'Perruso', 'Amy A. Perruso')).toEqual(['Hawaii House vote of 2026-03-05 (2026), HB 2033 - Passed Third Reading: Amy A. Perruso was excused.']);
    expect(stateRollCallLinesFor(HI_26H, t, 'Alcos', 'David Alcos III')).toEqual(['Hawaii House vote of 2026-03-05 (2026), HB 2033 - Passed Third Reading: David Alcos III voted Aye.']);
    expect(stateRollCallLinesFor(HI_26H, t, 'Ratcliffe', 'M. Cov Ratcliffe')).toEqual([]);
    expect(stateRollCallLinesFor(HI_26H, t, 'Holt', 'Daniel Holt')).toEqual([]);
  });
});

describe('state roll-call pages — the Hawaii adapter', () => {
  it('reads the bill page by GET and the member list by the form its own page posts, and never asks the cited host', async () => {
    resetStateRollCallPacing();
    let clock = 9_000_000;
    const asked: string[] = [];
    const [bill, members22] = hiBodies(HI_22H);
    const deps = {
      now: () => clock, sleep: async (ms: number) => { clock += ms; },
      fetchImpl: async (u: string, init?: RequestInit) => {
        asked.push(`${init?.method ?? 'GET'} ${u}`);
        clock += 100;
        if (u.startsWith('https://data.capitol.hawaii.gov/session/measure_indiv.aspx')) return new Response(bill, { status: 200 });
        if (u === 'https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=H') {
          // the page answers the current year to a GET, and the year posted to a POST
          if (init?.method !== 'POST') return new Response(hiPage('hi-h-2026-members'), { status: 200 });
          const form = new URLSearchParams(String(init.body));
          return new Response(form.get('ctl00$MainContent$DropDownListYear') === '2022' ? members22 : '', { status: 200 });
        }
        return new Response('', { status: 403 });
      },
    };
    expect(await fetchStateRollCallText(HI_22H, deps)).toBe(hiRender(HI_22H));
    expect(asked).toEqual(['GET https://data.capitol.hawaii.gov/session/measure_indiv.aspx?billtype=HB&billnumber=1688&year=2022',
      'GET https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=H', 'POST https://data.capitol.hawaii.gov/legislature/legislators.aspx?chamber=H']);
    expect(asked.some((a) => a.includes('www.'))).toBe(false);
    resetStateRollCallPacing();
  });
});
