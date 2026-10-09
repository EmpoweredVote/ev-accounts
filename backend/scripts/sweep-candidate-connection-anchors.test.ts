import { describe, it, expect } from 'vitest';
import { classify, decode } from './sweep-candidate-connection-anchors.mjs';

/**
 * The classifier behind data/candidate-connection-anchors.json, which decides whether a row may
 * keep the #Campaign_themes carve-out in check-stance-sources.mjs.
 *
 * EVERY CASE BELOW IS A BUG THAT WAS ACTUALLY MADE. The 2026-10-08 sweep published "19 pages carry
 * the anchor and nothing behind it", then 15, then 1, then 0, as four defects were found in the
 * sweep itself. These tests pin all four, because the cost of getting this wrong is asymmetric: a
 * false `empty` FAILS the build on a row that is fine.
 */
const page = (body: string) =>
  `<html><body><div id="mw-content-text"><h2><span id="Biography">Biography</span></h2><p>Bio text.</p>`
  + `<h2><span id="Campaign_themes">Campaign themes</span></h2>${body}`
  + `<h2><span id="Elections">Elections</span></h2><p>Results</p></div></body></html>`;

describe('classify — earns the carve-out', () => {
  it('a completed survey is the candidate\'s own words', () => {
    const r = classify(page('<p>Jane Doe completed Ballotpedia\'s 2026 Candidate Connection survey.</p>'));
    expect(r.verdict).toBe('own-words');
  });

  // Correction 3. Ballotpedia writes Ballotpedia&#39;s, so every pattern containing an apostrophe
  // failed silently against entity-encoded pages. THIS ONE DEFECT MOVED 33 PAGES.
  it('an HTML-ENTITY apostrophe still matches — the bug that moved 33 pages', () => {
    const r = classify(page('<p>Jane Doe completed Ballotpedia&#39;s 2026 Candidate Connection survey.</p>'));
    expect(r.verdict).toBe('own-words');
  });

  it('a double-encoded apostrophe also matches', () => {
    const r = classify(page('<p>Jane Doe completed Ballotpedia&amp;#39;s Candidate Connection survey.</p>'));
    expect(r.verdict).toBe('own-words');
  });

  // Correction 2. Ballotpedia lists every cycle it has asked about, so most pages say BOTH. Testing
  // the no-survey notice first scored a page with a completed 2026 survey as empty.
  it('"completed 2026" beside "did not complete 2020" is own-words, not empty', () => {
    const r = classify(page(
      '<p>Jane Doe did not complete Ballotpedia\'s 2020 Candidate Connection survey.</p>'
      + '<p>Jane Doe completed Ballotpedia\'s 2026 Candidate Connection survey.</p>',
    ));
    expect(r.verdict).toBe('own-words');
  });

  // Correction 4. No survey, but her own site is quoted under the same heading — the 16-page group.
  it('no survey but a quoted campaign website is still own-words', () => {
    const r = classify(page(
      '<p>Jane Doe has not completed Ballotpedia\'s Candidate Connection survey.</p>'
      + '<h3>Campaign website</h3><p>"I will fight for lower taxes."</p>',
    ));
    expect(r.verdict).toBe('own-words');
  });
});

describe('classify — does NOT earn it (these FAIL the build, so they must be right)', () => {
  // 🔴 CORRECTION 5, found by this test and by nothing else. "has NOT completed Ballotpedia's
  // Candidate Connection survey" CONTAINS the affirmative phrase as a substring, so a bare
  // affirmative match turns the clearest possible empty page into a verified one.
  it('the no-survey notice with nothing quoted is empty', () => {
    const r = classify(page('<p>Jane Doe has not completed Ballotpedia\'s Candidate Connection survey.</p>'));
    expect(r.verdict).toBe('empty');
  });

  it.each([
    "Jane Doe has not completed Ballotpedia's Candidate Connection survey.",
    "Jane Doe did not complete Ballotpedia's 2026 Candidate Connection survey.",
    'Jane Doe has not yet completed Ballotpedia&#39;s Candidate Connection survey.',
  ])('a negated survey notice is never read as a completed one: %s', (notice) => {
    expect(classify(page(`<p>${notice}</p>`)).verdict).toBe('empty');
  });

  it('an editorial summary with no survey and no quote is empty', () => {
    const r = classify(page('<p>She has focused her campaign on infrastructure and schools.</p>'));
    expect(r.verdict).toBe('empty');
  });

  // The sharpest case: the anchor points at a section that is not on the page at all.
  it('NO #Campaign_themes section means the anchor points nowhere', () => {
    const html = '<html><body><div id="mw-content-text"><h2><span id="Biography">Biography</span></h2>'
      + '<p>Bio only.</p></div></body></html>';
    const r = classify(html);
    expect(r.verdict).toBe('empty');
    expect(r.why).toMatch(/anchor points nowhere/);
  });

  it('an empty section is empty', () => {
    expect(classify(page('')).verdict).toBe('empty');
  });
});

// Correction 1. script/style are stripped from the WHOLE document before the section is sliced; a
// page whose block opens with Ballotpedia's survey stylesheet otherwise read CSS as prose.
describe('classify — stylesheet noise is not evidence', () => {
  it('a section opening with <style> is judged on its text, not its CSS', () => {
    const r = classify(page('<style>.survey{content:"completed Ballotpedia\'s Candidate Connection survey"}</style>'
      + '<p>She has focused her campaign on infrastructure.</p>'));
    expect(r.verdict).toBe('empty');
  });
});

describe('decode', () => {
  it.each([
    ['Ballotpedia&#39;s', "Ballotpedia's"],
    ['Ballotpedia&amp;#39;s', "Ballotpedia's"],
    ['a&nbsp;b', 'a b'],
    ['&quot;quoted&quot;', '"quoted"'],
  ])('%s -> %s', (raw, want) => expect(decode(raw)).toBe(want));
});
