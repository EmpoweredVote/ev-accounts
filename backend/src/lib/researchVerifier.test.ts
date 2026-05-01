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
