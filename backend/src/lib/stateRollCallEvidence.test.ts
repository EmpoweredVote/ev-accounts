import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  isStateRollCallUrl, parseStateRollCallUrl, readStateRollCallHtml, renderStateRollCall, parseStateRollCallRender,
  parseStateRollCallLine, stateLabelFits, stateRollCallLinesFor, verifyStateRollCallLine, STATE_VOTES,
  readStateRollCallDocs, stateRollCallDocs, stateRollCallMinGapMs, fullNameLabelFits,
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
