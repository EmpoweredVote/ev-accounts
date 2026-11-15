import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  isStateRollCallUrl, parseStateRollCallUrl, readStateRollCallHtml, renderStateRollCall, parseStateRollCallRender,
  parseStateRollCallLine, stateLabelFits, stateRollCallLinesFor, verifyStateRollCallLine, STATE_VOTES,
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
