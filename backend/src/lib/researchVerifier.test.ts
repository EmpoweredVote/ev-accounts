import { describe, it, expect } from 'vitest';
import { normalizeText } from './researchVerifier.js';

describe('normalizeText', () => {
  it('collapses whitespace to single spaces', () => {
    expect(normalizeText('a  b\nc\t\td')).toBe('a b c d');
  });

  it('lowercases', () => {
    expect(normalizeText('Hello WORLD')).toBe('hello world');
  });

  it('normalizes curly quotes to straight quotes', () => {
    expect(normalizeText('“hello” ‘world’')).toBe('"hello" \'world\'');
  });

  it('normalizes em and en dashes to hyphens', () => {
    expect(normalizeText('a—b–c')).toBe('a-b-c');
  });

  it('decodes common HTML entities', () => {
    expect(normalizeText('a &amp; b &nbsp; c &quot;d&quot;')).toBe('a & b c "d"');
  });

  it('decodes numeric HTML entities (decimal and hex) before quote normalization', () => {
    // &#8217; and &#x2019; are both the curly right single quote (U+2019) — neither is a named
    // entity, so undecoded they would survive as literal "&#8217;"/"&#x2019;" text and never fold
    // to the straight apostrophe a snippet types.
    expect(normalizeText('you&#8217;re here')).toBe("you're here");
    expect(normalizeText('you&#x2019;re here')).toBe("you're here");
    expect(normalizeText('you&#X2019;re here')).toBe("you're here");
  });

  it('trims leading and trailing whitespace', () => {
    expect(normalizeText('   hi   ')).toBe('hi');
  });
});

import { matchSnippet, MIN_SNIPPET_WORDS, checkNameProximity, NAME_PROXIMITY_CHARS } from './researchVerifier.js';

describe('matchSnippet', () => {
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  it('returns verified for a verbatim match', () => {
    const page = `Some article text. ${longSnippet} More article text.`;
    expect(matchSnippet(longSnippet, page)).toEqual({ verdict: 'verified', matchOffset: expect.any(Number) });
  });

  it('returns verified despite whitespace differences', () => {
    const page = `prefix ${longSnippet.replace(/ /g, '\n  ')} suffix`;
    expect(matchSnippet(longSnippet, page).verdict).toBe('verified');
  });

  it('returns verified despite curly quote differences', () => {
    const snippetCurly = longSnippet.replace('public option', '“public option”');
    const pageStraight = `prefix ${longSnippet.replace('public option', '"public option"')} suffix`;
    expect(matchSnippet(snippetCurly, pageStraight).verdict).toBe('verified');
  });

  it('returns snippet_not_found when text is absent', () => {
    expect(matchSnippet(longSnippet, 'totally unrelated content here that is also long enough to look like a real article')).toEqual({
      verdict: 'snippet_not_found',
    });
  });

  it('returns snippet_too_short for fewer than 25 words', () => {
    expect(matchSnippet('only a few words here', 'irrelevant')).toEqual({
      verdict: 'snippet_too_short',
    });
    expect(MIN_SNIPPET_WORDS).toBe(25);
  });

  it('verifies a real excerpt wrapped in light agent framing (clusters in one passage)', () => {
    // Light "Headline. Date. He stated:" wrapper around a real passage; the
    // wrapper words aren't on the page but the bulk of the snippet is.
    const framed = `President Adams responded. August 1, 2024. He stated: ${longSnippet}`;
    const page = `nav home about newsroom ${longSnippet} more footer links`;
    expect(matchSnippet(framed, page)).toEqual({ verdict: 'verified', matchOffset: expect.any(Number) });
  });

  it('verifies a non-contiguous excerpt with interior words dropped (no 25-word run, but shingles cluster)', () => {
    const pagePassage = 'The senator told reporters she strongly supports a robust public option for healthcare coverage and has personally cosponsored several major bills since the year 2021 to expand Medicare access for many older Americans without ever raising taxes on middle class families.';
    // Drops "robust" and "major" mid-passage, so no contiguous 25-word run survives.
    const snippetDropped = 'The senator told reporters she strongly supports a public option for healthcare coverage and has personally cosponsored several bills since the year 2021 to expand Medicare access for many older Americans without ever raising taxes on middle class families.';
    const page = `nav links ${pagePassage} footer`;
    expect(matchSnippet(snippetDropped, page).verdict).toBe('verified');
  });

  it('rejects a snippet stitched from two far-apart passages', () => {
    const passageA = 'She voted against the income tax cut bill because it favored large corporations over middle class families this year';
    const passageB = 'On housing she proposed building thousands of new affordable units across the state to ease the shortage statewide';
    const farApart = `intro ${passageA} ${'filler word '.repeat(500)} ${passageB} outro`;
    const stitched = `${passageA} ${passageB}`; // two real comments, far apart on the page
    expect(matchSnippet(stitched, farApart).verdict).toBe('snippet_not_found');
  });

  it('rejects a paraphrase that shares little verbatim text with the page', () => {
    const paraphrase = 'The senator broadly backs a government insurance choice for medical coverage and has repeatedly sponsored measures expanding elder healthcare access without lifting middle income tax burdens over recent years in office.';
    const page = `prefix ${longSnippet} suffix`;
    expect(matchSnippet(paraphrase, page).verdict).toBe('snippet_not_found');
  });

  it('verifies a snippet with straight apostrophes against a page whose apostrophes are numeric HTML entities (decimal and hex)', () => {
    // Before the numeric-entity decode, this snippet would NOT match either page: the raw
    // "&#8217;"/"&#x2019;" text has no curly quote for the curly->straight step to fold, so the
    // page's "we&#8217;ve" never becomes "we've" and the whole-string / windowed matches all miss.
    const snippet = "The senator said we've finally reached a point where we can't ignore the crisis "
      + "any longer and it's time to act with real urgency for every family in this district.";
    const pageDecimal = 'nav home. The senator said we&#8217;ve finally reached a point where we '
      + 'can&#8217;t ignore the crisis any longer and it&#8217;s time to act with real urgency for '
      + 'every family in this district. footer links';
    const pageHex = pageDecimal.replace(/&#8217;/g, '&#x2019;');
    expect(matchSnippet(snippet, pageDecimal).verdict).toBe('verified');
    expect(matchSnippet(snippet, pageHex).verdict).toBe('verified');
  });

  it('honors a lower minWords for concise quotes (e.g. read-rank)', () => {
    const shortQuote = 'she strongly supports a public option for healthcare expansion right now';
    const page = `The mayor said she strongly supports a public option for healthcare expansion right now during the debate.`;
    expect(matchSnippet(shortQuote, page).verdict).toBe('snippet_too_short'); // default floor 25
    expect(matchSnippet(shortQuote, page, { minWords: 8 })).toEqual({ verdict: 'verified', matchOffset: expect.any(Number) });
  });
});

describe('checkNameProximity', () => {
  const fullName = 'Brad Sherman';
  const lastName = 'Sherman';
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  it('verified when full name appears within snippet', () => {
    const page = `prefix Brad Sherman: ${longSnippet} suffix`;
    expect(NAME_PROXIMITY_CHARS).toBe(500);
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v).toEqual({ verdict: 'verified', matchOffset: expect.any(Number) });
  });

  it('verified when last name appears within 500 chars before the snippet', () => {
    const filler = 'x'.repeat(200);
    const page = `Sherman said in a statement, ${filler}. Background: ${longSnippet}`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('verified');
  });

  it('name_not_present when last name is too far from snippet', () => {
    const filler = 'x'.repeat(2000);
    const page = `Sherman said something. ${filler}. Now an unrelated paragraph: ${longSnippet}`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('name_not_present');
  });

  it('name_not_present when name is absent from page entirely', () => {
    const page = `prefix ${longSnippet} suffix`;
    const v = checkNameProximity({
      fullName,
      lastName,
      pageText: page,
      matchOffsetInNormalized: normalizeText(page).indexOf(normalizeText(longSnippet)),
    });
    expect(v.verdict).toBe('name_not_present');
  });

  it('common last name "Smith" requires title qualifier within proximity', () => {
    const filler = 'x'.repeat(100);
    const noTitle = `Smith was at the meeting. ${filler}. Then: ${longSnippet}`;
    const withTitle = `Sen. Smith was at the meeting. ${filler}. Then: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jane Smith',
      lastName: 'Smith',
      pageText: noTitle,
      matchOffsetInNormalized: normalizeText(noTitle).indexOf(normalizeText(longSnippet)),
    }).verdict).toBe('name_not_present');
    expect(checkNameProximity({
      fullName: 'Jane Smith',
      lastName: 'Smith',
      pageText: withTitle,
      matchOffsetInNormalized: normalizeText(withTitle).indexOf(normalizeText(longSnippet)),
    }).verdict).toBe('verified');
  });
});

// A source routinely prints a ballot name ("Jenn Hernandez") where the record holds the legal one
// ("Jennifer Hernandez"). Neither name test then fires: the full name is absent, and the surname is
// on COMMON_LAST_NAMES, which demands a title the article has no reason to use for a candidate.
// `aliases` carries the other names the record knows, each treated as a full name.
describe('checkNameProximity with aliases', () => {
  const longSnippet = 'We need a mix of housing options that support both current and future residents, encouraging smaller homes like cottages, townhomes, or starter homes designed to fit the character of this town.';
  const at = (page: string) => normalizeText(page).indexOf(normalizeText(longSnippet));

  it('name_not_present without the alias, when the surname is common and untitled', () => {
    const page = `Jenn Hernandez: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez', pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('name_not_present');
  });

  it('verified when an alias full name appears in the window', () => {
    const page = `Jenn Hernandez: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez', aliases: ['Jenn Hernandez'],
      pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('verified');
  });

  it('matches an alias through normalization (case, spacing, curly punctuation)', () => {
    const page = `JENN   HERNANDEZ said: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez', aliases: ['  jenn hernandez  '],
      pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('verified');
  });

  it('refuses a one-token alias — a bare first name must not bypass the common-surname rule', () => {
    const page = `Jenn: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez', aliases: ['Jenn'],
      pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('name_not_present');
  });

  it('holds an alias to the same 500-character window as the full name', () => {
    const page = `Jenn Hernandez spoke first. ${'x'.repeat(2000)}. Later: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez', aliases: ['Jenn Hernandez'],
      pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('name_not_present');
  });

  it('ignores blank and non-string aliases without throwing', () => {
    const page = `Jenn Hernandez: ${longSnippet}`;
    expect(checkNameProximity({
      fullName: 'Jennifer Hernandez', lastName: 'Hernandez',
      aliases: ['', '   ', null as unknown as string, 'Jenn Hernandez'],
      pageText: page, matchOffsetInNormalized: at(page),
    }).verdict).toBe('verified');
  });
});

import { decodeForDisplay } from './researchVerifier.js';

// The published citation is the matched span. It was stored exactly as the page's extracted text
// had it, so a span cut from a news page carried raw `&ldquo;` and `&mdash;` into what a voter
// reads. Measured 2026-10-06: 3 of 12 live citations in the Redmond and Duvall batches.
describe('decodeForDisplay', () => {
  it('decodes the typographic named entities a news page actually uses', () => {
    expect(decodeForDisplay('Council position 6 &mdash; Jenn Hernandez'))
      .toBe('Council position 6 — Jenn Hernandez');
    expect(decodeForDisplay('&ldquo;Placing a levy&rdquo; said the Mayor'))
      .toBe('“Placing a levy” said the Mayor');
    expect(decodeForDisplay('the city&rsquo;s finances')).toBe('the city’s finances');
    expect(decodeForDisplay('RCW &sect; 35.21.830')).toBe('RCW § 35.21.830');
  });

  it('decodes numeric and hex references', () => {
    expect(decodeForDisplay('you&#8217;re here')).toBe('you’re here');
    expect(decodeForDisplay('you&#x2019;re here')).toBe('you’re here');
  });

  it('preserves case, straight quotes and spacing — it is not normalizeText', () => {
    const s = 'The Mayor said "no" — twice.';
    expect(decodeForDisplay(s)).toBe(s);
    expect(decodeForDisplay('A  B')).toBe('A  B');
  });

  it('leaves a malformed reference alone rather than throwing', () => {
    expect(decodeForDisplay('a &notanentity; b &#; c')).toBe('a &notanentity; b &#; c');
  });
});

describe('normalizeText folds the same entities, so a decoded span still matches its snippet', () => {
  it('folds named typographic entities to the characters it already normalizes', () => {
    expect(normalizeText('a &mdash; b')).toBe(normalizeText('a — b'));
    expect(normalizeText('&ldquo;x&rdquo;')).toBe(normalizeText('“x”'));
    expect(normalizeText('city&rsquo;s')).toBe(normalizeText('city’s'));
  });
});

import { aliasesFrom } from './researchVerifier.js';

describe('aliasesFrom', () => {
  it('keeps multi-token names and trims them', () => {
    expect(aliasesFrom(['  Jenn Hernandez ', 'J. C. Hernandez'])).toEqual(['Jenn Hernandez', 'J. C. Hernandez']);
  });

  it('drops one-token names, blanks and non-strings', () => {
    expect(aliasesFrom(['Jenn', '', '   ', 42, null, undefined, 'Jenn Hernandez'])).toEqual(['Jenn Hernandez']);
  });

  it('dedupes case-insensitively, keeping the first spelling', () => {
    expect(aliasesFrom(['Jenn Hernandez', 'JENN HERNANDEZ', 'jenn  hernandez'])).toEqual(['Jenn Hernandez']);
  });

  it('returns an empty array for null, a non-array, or an empty array', () => {
    expect(aliasesFrom(null)).toEqual([]);
    expect(aliasesFrom(undefined)).toEqual([]);
    expect(aliasesFrom('Jenn Hernandez')).toEqual([]);
    expect(aliasesFrom([])).toEqual([]);
  });

  it('caps the list so one bad row cannot slow every snippet check', () => {
    const many = Array.from({ length: 50 }, (_, i) => `Name Number${i}`);
    expect(aliasesFrom(many)).toHaveLength(8);
  });
});

import { createPageFetcher } from './researchVerifier.js';

describe('createPageFetcher', () => {
  it('caches results per URL within a batch', async () => {
    let calls = 0;
    const fakeFetch = async (url: string) => {
      calls++;
      return `content for ${url}`;
    };
    const fetcher = createPageFetcher(fakeFetch);
    expect(await fetcher('https://a.example')).toEqual({ ok: true, text: 'content for https://a.example' });
    expect(await fetcher('https://a.example')).toEqual({ ok: true, text: 'content for https://a.example' });
    expect(await fetcher('https://b.example')).toEqual({ ok: true, text: 'content for https://b.example' });
    expect(calls).toBe(2);
  });

  it('maps thrown errors to url_broken with a reason', async () => {
    const fakeFetch = async () => { throw new Error('ENOTFOUND'); };
    const fetcher = createPageFetcher(fakeFetch);
    const result = await fetcher('https://broken.example');
    expect(result).toEqual({ ok: false, reason: 'ENOTFOUND' });
  });

  it('caches failures too, to avoid hammering broken URLs', async () => {
    let calls = 0;
    const fakeFetch = async () => { calls++; throw new Error('boom'); };
    const fetcher = createPageFetcher(fakeFetch);
    await fetcher('https://x.example');
    await fetcher('https://x.example');
    expect(calls).toBe(1);
  });

  it('maps a robots-disallowed error (by code) to a distinct result, not url_broken', async () => {
    const robotsErr = Object.assign(new Error('robots_disallowed: https://blocked.example'), {
      code: 'robots_disallowed',
    });
    const fetcher = createPageFetcher(async () => { throw robotsErr; });
    const result = await fetcher('https://blocked.example');
    expect(result).toEqual({ ok: false, reason: 'robots_disallowed', robotsDisallowed: true });
  });
});

import { verifyEvidence, normName, normTopic, stanceKey, type StanceRow, type EvidenceRow } from './researchVerifier.js';

describe('normName / normTopic / stanceKey', () => {
  it('trims, collapses inner whitespace and lowercases a name', () => {
    expect(normName('  Jane   Doe ')).toBe('jane doe');
  });
  it('trims and lowercases a topic_key', () => {
    expect(normTopic(' Healthcare ')).toBe('healthcare');
  });
  it('keys a (name, topic) pair so spelling variants collide and different pairs do not', () => {
    expect(stanceKey('Jane Doe ', 'Healthcare')).toBe(stanceKey('jane  doe', 'healthcare'));
    expect(stanceKey('Jane Doe', 'healthcare')).not.toBe(stanceKey('Jane Doe', 'housing'));
    // The separator cannot occur in either part, so ("a b", "c") and ("a", "b c") stay distinct.
    expect(stanceKey('a b', 'c')).not.toBe(stanceKey('a', 'b c'));
  });
});
import type { PageFetcher as _PageFetcher } from './researchVerifier.js';

describe('verifyEvidence', () => {
  const longSnippet = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';

  const stanceRows: StanceRow[] = [
    { full_name: 'Brad Sherman', topic_key: 'healthcare', value: 2, reasoning: 'public option', politician_id: '' },
  ];

  it('partitions verified rows into pushable bucket', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://b.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: _PageFetcher = async (url) => ({
      ok: true,
      text: `prefix Brad Sherman: ${longSnippet} suffix from ${url}`,
    });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources).toHaveLength(2);
    expect(result.needsReResearch).toHaveLength(0);
    expect(result.reviewQueue).toHaveLength(0);
  });

  it('waives name proximity for a declared own-site URL, and only for it', async () => {
    const far = `${'filler '.repeat(200)}`;
    const text = `Brad Sherman header ${far} ${longSnippet} ${far}`;
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://own.example/issues', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: _PageFetcher = async () => ({ ok: true, text });
    const base = { stanceRows, evidenceRows, fetcher, threshold: 1,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } } };
    const without = await verifyEvidence(base);
    expect(without.needsReResearch).toHaveLength(1);
    expect(without.needsReResearch[0].failedSources[0].snippets[0].verdict.verdict).toBe('name_not_present');
    const withOwn = await verifyEvidence({ ...base, ownSiteUrls: new Set(['https://own.example/issues']) });
    expect(withOwn.pushable).toHaveLength(1);
    const otherUrl = await verifyEvidence({ ...base, ownSiteUrls: new Set(['https://elsewhere.example/']) });
    expect(otherUrl.needsReResearch).toHaveLength(1);
  });

  it('routes below-threshold rows to needsReResearch', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: _PageFetcher = async () => ({ ok: true, text: `Brad Sherman: ${longSnippet}` });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(1);
    expect(result.pushable).toHaveLength(0);
  });

  it('drops a source whose snippets all fail and counts remaining sources', async () => {
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://good.example', snippet: longSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://bad.example', snippet: longSnippet, snippet_index: 0 },
    ];
    const fetcher: _PageFetcher = async (url) => {
      if (url === 'https://bad.example') return { ok: true, text: 'unrelated content not containing the snippet at all' };
      return { ok: true, text: `Brad Sherman: ${longSnippet}` };
    };
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(1);
    expect(result.needsReResearch[0].failedSources).toHaveLength(1);
    expect(result.needsReResearch[0].failedSources[0].url).toBe('https://bad.example');
  });

  it('keeps source verified if at least one of its snippets verifies', async () => {
    const otherLongSnippet = 'Completely different paragraph that nonetheless has at least twenty five words in it so the minimum length check passes for this snippet here.';
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: otherLongSnippet, snippet_index: 0 },
      { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: longSnippet, snippet_index: 1 },
    ];
    const fetcher: _PageFetcher = async () => ({ ok: true, text: `Brad Sherman said: ${longSnippet}` });
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows,
      fetcher,
      threshold: 1,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources).toHaveLength(1);
  });

  // I3: the gate and the verifier share one normalizer (normName/normTopic/stanceKey), so evidence
  // spelled `jane doe` or `Jane Doe ` (trailing space) must back the `Jane Doe` stance row here
  // exactly as it does in stance-gate — not pass the gate and then verify nothing.
  it('joins evidence to its stance row through the shared normalizer (case, trailing space)', async () => {
    const snip = 'Representative Jane Doe voted yes on House Bill 1001 in 2025 because she believes every '
      + 'family deserves affordable coverage and lower prescription costs at the pharmacy counter today';
    const evidenceRows: EvidenceRow[] = [
      { full_name: 'jane doe', topic_key: 'healthcare', source_url: 'https://a.example', snippet: snip, snippet_index: 0 },
      { full_name: 'Jane Doe ', topic_key: 'Healthcare ', source_url: 'https://b.example', snippet: snip, snippet_index: 0 },
    ];
    const fetcher: _PageFetcher = async () => ({ ok: true, text: `Jane Doe: ${snip}` });
    const result = await verifyEvidence({
      stanceRows: [{ full_name: 'Jane Doe', topic_key: 'healthcare', value: 2, reasoning: 'HB 1001', politician_id: 'p1' }],
      evidenceRows,
      fetcher,
      threshold: 2,
      politicianNames: { 'Jane Doe': { fullName: 'Jane Doe', lastName: 'Doe' } },
    });
    expect(result.pushable).toHaveLength(1);
    expect(result.pushable[0].verifiedSources.map((s) => s.url).sort()).toEqual(['https://a.example', 'https://b.example']);
  });

  it('routes stance rows with zero evidence rows directly to review queue', async () => {
    const fetcher: _PageFetcher = async () => { throw new Error('should not be called'); };
    const result = await verifyEvidence({
      stanceRows,
      evidenceRows: [],
      fetcher,
      threshold: 2,
      politicianNames: { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } },
    });
    expect(result.needsReResearch).toHaveLength(1);
    expect(result.needsReResearch[0].verifiedSources).toHaveLength(0);
  });
});

import { matchedSpan } from './researchVerifier.js';

// I6 (ruling 2026-09-24): the 60% rule decides whether a snippet is grounded; only the matched
// on-page span is ever published, and that span must itself be >= 25 contiguous page words.
describe('matchedSpan (I6)', () => {
  const passage = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';
  it('returns the whole snippet when it is on the page verbatim, in the snippet\'s own casing', () => {
    const span = matchedSpan(passage, `nav ${passage.toUpperCase()} footer`);
    expect(span?.text).toBe(passage);
    expect(span?.words).toBe(passage.split(' ').length);
  });
  it('drops the researcher\'s framing words: the span is page text only', () => {
    const framed = `President Adams responded. August 1, 2024. He stated: ${passage}`;
    const span = matchedSpan(framed, `nav home about ${passage} more footer`);
    expect(span?.text).toBe(passage);
    expect(span?.text).not.toContain('He stated');
  });
  it('matches whole page words only — a span never ends in a clipped word', () => {
    const page = 'alpha beta gamma deltas';
    expect(matchedSpan('alpha beta gamma delta', page)?.text).toBe('alpha beta gamma');
  });
  it('returns null when no word of the snippet is on the page', () => {
    expect(matchedSpan('zzz yyy', 'alpha beta')).toBeNull();
  });
});

describe('verifyEvidence — I6 published span and I1 cited URLs', () => {
  const names = { 'Brad Sherman': { fullName: 'Brad Sherman', lastName: 'Sherman' } };
  const pagePassage = 'The senator told reporters she strongly supports a robust public option for healthcare coverage and has personally cosponsored several major bills since the year 2021 to expand Medicare access for many older Americans without ever raising taxes on middle class families.';
  const verbatim = 'The senator strongly supports a public option for healthcare and has cosponsored multiple bills since 2021 to expand Medicare access for older Americans without raising taxes on the middle class.';
  const row = (source_urls?: string[]): StanceRow => ({ full_name: 'Brad Sherman', topic_key: 'healthcare', value: 2, reasoning: 'r', politician_id: '', ...(source_urls ? { source_urls } : {}) });

  it('a snippet that passes the 60% rule but has no 25-word contiguous span is span_too_short, not verified', async () => {
    // Drops "robust" and "major": matchSnippet verifies it on shingle coverage, but the longest
    // contiguous run on the page is under 25 words.
    const dropped = 'The senator told reporters she strongly supports a public option for healthcare coverage and has personally cosponsored several bills since the year 2021 to expand Medicare access for many older Americans without ever raising taxes on middle class families.';
    expect(matchSnippet(dropped, `Brad Sherman: ${pagePassage}`).verdict).toBe('verified');
    const result = await verifyEvidence({
      stanceRows: [row()], threshold: 1, politicianNames: names,
      evidenceRows: [{ full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: dropped, snippet_index: 0 }],
      fetcher: async () => ({ ok: true, text: `Brad Sherman: ${pagePassage}` }),
    });
    expect(result.pushable).toHaveLength(0);
    expect(result.needsReResearch[0].failedSources[0].snippets[0].verdict.verdict).toBe('span_too_short');
  });

  it('a verified snippet carries its matched span, without the framing words', async () => {
    const result = await verifyEvidence({
      stanceRows: [row()], threshold: 1, politicianNames: names,
      evidenceRows: [{ full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: `He stated at a town hall on Tuesday: ${verbatim}`, snippet_index: 0 }],
      fetcher: async () => ({ ok: true, text: `Brad Sherman: ${verbatim}` }),
    });
    const snip = result.pushable[0].verifiedSources[0].snippets[0];
    expect(snip.verdict.verdict).toBe('verified');
    expect(snip.matchedSpan).toBe(verbatim);
  });

  it('an evidence URL that is not in the row sources is url_not_cited, never fetched, and does not count', async () => {
    const fetched: string[] = [];
    const result = await verifyEvidence({
      stanceRows: [row(['https://a.example'])], threshold: 2, politicianNames: names,
      evidenceRows: [
        { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://a.example', snippet: verbatim, snippet_index: 0 },
        { full_name: 'Brad Sherman', topic_key: 'healthcare', source_url: 'https://www.vote411.org/x', snippet: verbatim, snippet_index: 0 },
      ],
      fetcher: async (url) => { fetched.push(url); return { ok: true, text: `Brad Sherman: ${verbatim}` }; },
    });
    expect(fetched).toEqual(['https://a.example']);
    expect(result.pushable).toHaveLength(0); // only 1 of the 2 needed sources counts
    const failed = result.needsReResearch[0].failedSources;
    expect(failed.map((f) => [f.url, f.snippets[0].verdict.verdict])).toEqual([['https://www.vote411.org/x', 'url_not_cited']]);
  });
});

describe('checkNameProximity — accented stored names and spaced council titles', () => {
  // Both regressions were measured on the Charlotte city batch, 2026-10-02.
  const longSnippet = 'There is a place for single-family subdivisions, period. You can have strategic development and that is what we are asking for. There are urban areas where duplexes and triplexes are appropriate but not inside them.';

  it('verifies when the source drops an accent the stored name carries', () => {
    const page = `Council member Renee Johnson, who is also Black, agreed. ${longSnippet}`;
    const v = checkNameProximity({
      fullName: 'Reneé Johnson',
      lastName: 'Johnson',
      pageText: page,
      matchOffsetInNormalized: page.toLowerCase().indexOf('there is a place'),
    });
    expect(v.verdict).toBe('verified');
  });

  it('verifies a common surname qualified by the two-word rendering "Council member"', () => {
    // "johnson" is a COMMON_LAST_NAME, so this can only pass via TITLE_PATTERN.
    // The FULL name must not appear, or the full-name branch short-circuits
    // the test and it passes without exercising TITLE_PATTERN at all.
    const page = `Council member Johnson spoke. ${longSnippet}`;
    const v = checkNameProximity({
      fullName: 'Dana Johnson',
      lastName: 'Johnson',
      pageText: page,
      matchOffsetInNormalized: page.toLowerCase().indexOf('there is a place'),
    });
    expect(v.verdict).toBe('verified');
  });

  it('still refuses an unqualified common surname — the guard is not loosened', () => {
    const page = `A spokesman named Johnson commented. ${longSnippet}`;
    const v = checkNameProximity({
      fullName: 'Dana Johnson',
      lastName: 'Johnson',
      pageText: page,
      matchOffsetInNormalized: page.toLowerCase().indexOf('there is a place'),
    });
    expect(v.verdict).toBe('name_not_present');
  });
});

describe('checkNameProximity — municipal and county titles', () => {
  const longSnippet = 'There is a place for single-family subdivisions, period. You can have strategic development and that is what we are asking for. There are urban areas where duplexes and triplexes are appropriate but not inside them.';

  // "king", "moore", "brown" and "gonzalez" are all COMMON_LAST_NAMES, and real
  // Knight-city members carry them. The full name is deliberately absent so the
  // test exercises TITLE_PATTERN rather than the full-name branch.
  for (const title of ['Commissioner', 'County Commissioner', 'Alderman', 'Supervisor', 'Trustee']) {
    it(`verifies a common surname qualified by "${title}"`, () => {
      const page = `${title} King spoke at the meeting. ${longSnippet}`;
      const v = checkNameProximity({
        fullName: 'Christine King',
        lastName: 'King',
        pageText: page,
        matchOffsetInNormalized: page.toLowerCase().indexOf('there is a place'),
      });
      expect(v.verdict).toBe('verified');
    });
  }

  it('still refuses a common surname with no title at all', () => {
    const page = `A resident named King spoke. ${longSnippet}`;
    const v = checkNameProximity({
      fullName: 'Christine King',
      lastName: 'King',
      pageText: page,
      matchOffsetInNormalized: page.toLowerCase().indexOf('there is a place'),
    });
    expect(v.verdict).toBe('name_not_present');
  });
});
