import { describe, expect, it } from 'vitest';
import { readCsv, sweepHit } from './lib.js';

describe('readCsv', () => {
  it('reads quoted fields, doubled quotes and embedded newlines', () => {
    const rows = readCsv('full_name,reasoning\r\n"Smith, Jo","said ""no""\nthen left"\nAl,plain\n');
    expect(rows).toEqual([
      { full_name: 'Smith, Jo', reasoning: 'said "no"\nthen left' },
      { full_name: 'Al', reasoning: 'plain' },
    ]);
  });
  it('fills a short row with empty strings', () => {
    expect(readCsv('a,b,c\n1,2\n')).toEqual([{ a: '1', b: '2', c: '' }]);
  });
});

describe('sweepHit', () => {
  it.each([
    'Rep. Matt Pierce (D-Bloomington) said',
    'Sen. Blake Doriot, R-Goshen, wrote',
    'CLANCY D N',
    'Smith (R) voted',
    'Republicans passed it',
  ])('flags %s', (t) => expect(sweepHit(t)).toBe(true));
  it.each([
    'the democratic process',
    'Senate Bill 10 passed 39-9',
    'SB 10, House roll call 340: Pierce voted Nay.',
  ])('passes %s', (t) => expect(sweepHit(t)).toBe(false));
});
