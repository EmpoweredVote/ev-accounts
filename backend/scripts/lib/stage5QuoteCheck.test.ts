import { describe, it, expect } from 'vitest';
import { namesParty, normaliseForMatch, passageOnPage, QuoteCheckSchema, readQuoteChecks } from './stage5QuoteCheck.js';

const PID = '11111111-1111-4111-8111-111111111111';
const check = (over: Record<string, unknown> = {}) => ({
  finding_id: 'f1', politician_id: PID, topic_key: 'voting-rights', verdict: 'passed',
  on_page: true, own_words: true, on_topic: true, names_party: false,
  reason: 'On the page word for word; their own floor speech; about voter ID.', checker: 'quote-checker', at: '2026-10-22T00:00:00Z', ...over,
});

describe('normaliseForMatch', () => {
  it('collapses whitespace and straightens quotes and dashes, nothing else', () => {
    expect(normaliseForMatch('  “Every  voter”\n— it’s ‘fair’ – ok ')).toBe('"Every voter" - it\'s \'fair\' - ok');
    expect(normaliseForMatch('Voter ID.')).toBe('Voter ID.');
  });
});

describe('passageOnPage', () => {
  const page = 'Senator Doe said: “Every eligible voter should be able to cast a ballot\n   without   showing a photo ID,” at the hearing.';
  it('matches through curly quotes, extra spaces and a line break', () => {
    expect(passageOnPage('"Every eligible voter should be able to cast a ballot without showing a photo ID,"', page)).toBe(true);
    expect(passageOnPage('cast a ballot without showing', page)).toBe(true);
  });
  it('fails on one changed word', () => {
    expect(passageOnPage('cast a vote without showing', page)).toBe(false);
  });
  it('fails on a change of case or punctuation', () => {
    expect(passageOnPage('Cast a ballot without showing', page)).toBe(false);
    expect(passageOnPage('without showing a photo ID.', page)).toBe(false);
  });
  it('fails an empty passage', () => {
    expect(passageOnPage('   ', page)).toBe(false);
  });
});

describe('namesParty', () => {
  it('finds a party name', () => {
    expect(namesParty('The Republicans in this chamber blocked it.')).toBe(true);
    expect(namesParty('Our Democratic Party platform says so.')).toBe(true);
    expect(namesParty('the GOP plan')).toBe(true);
  });
  it('passes plain words', () => {
    expect(namesParty('Every eligible voter should be able to vote.')).toBe(false);
    expect(namesParty('a democratic process')).toBe(false);
  });
});

describe('QuoteCheckSchema', () => {
  it('accepts a passed check with every part true', () => {
    expect(QuoteCheckSchema.safeParse(check()).success).toBe(true);
  });
  it('accepts a failed check with any part false', () => {
    expect(QuoteCheckSchema.safeParse(check({ verdict: 'failed', own_words: false })).success).toBe(true);
  });
  it('refuses passed with own_words false', () => {
    expect(QuoteCheckSchema.safeParse(check({ own_words: false })).success).toBe(false);
  });
  it('refuses passed with on_page or on_topic false', () => {
    expect(QuoteCheckSchema.safeParse(check({ on_page: false })).success).toBe(false);
    expect(QuoteCheckSchema.safeParse(check({ on_topic: false })).success).toBe(false);
  });
  it('refuses passed when the passage names a party', () => {
    expect(QuoteCheckSchema.safeParse(check({ names_party: true })).success).toBe(false);
  });
  it('needs a reason', () => {
    expect(QuoteCheckSchema.safeParse(check({ reason: '' })).success).toBe(false);
  });
});

describe('readQuoteChecks', () => {
  it('reads JSONL, skipping blank lines, and names the bad line', () => {
    const ok = JSON.stringify(check());
    expect(readQuoteChecks(`${ok}\n\n${ok}\n`)).toHaveLength(2);
    expect(() => readQuoteChecks(`${ok}\n${JSON.stringify(check({ own_words: false }))}\n`)).toThrow(/line 2/);
  });
});
