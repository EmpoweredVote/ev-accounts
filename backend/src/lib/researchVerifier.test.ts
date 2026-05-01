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
