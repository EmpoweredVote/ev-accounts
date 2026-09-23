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
