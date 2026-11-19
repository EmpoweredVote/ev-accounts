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
  explainMinnesotaVote, mnQuestionIsOnTheBill, mnMembers, mnMemberNames, MN_LABEL_ALIASES, parseMinnesotaVoteUrl, pdfBodyFor,
} from './stateRollCallEvidence.js';
import { fetchStateRollCallText, renderStateRollCallHtml, resetStateRollCallPacing } from './adapters/stateRollCallAdapter.js';
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
