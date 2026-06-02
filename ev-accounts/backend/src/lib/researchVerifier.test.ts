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
});

import { verifyEvidence, type StanceRow, type EvidenceRow } from './researchVerifier.js';
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
