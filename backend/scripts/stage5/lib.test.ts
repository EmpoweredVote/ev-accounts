import { describe, expect, it } from 'vitest';
import { checkNameProximity, matchedSpan } from '../../src/lib/researchVerifier.js';
import { readCsv, sweepHit, unverifiableNote, verifiableWindow } from './lib.js';

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
    '"FullName":"Oscar De Los Santos","Party":"D","Vote":"N"',
  ])('flags %s', (t) => expect(sweepHit(t)).toBe(true));
  it.each([
    'the democratic process',
    'Senate Bill 10 passed 39-9',
    'SB 10, House roll call 340: Pierce voted Nay.',
  ])('passes %s', (t) => expect(sweepHit(t)).toBe(false));
});

// A congress.gov bill page in the shape of S. 2747 (2026-10-31): the latest action at the top, far from the
// cosponsor list; every name in the list carries a party label; the same action line again right after it.
const ACTION = 'Motion by Senator Schumer to reconsider the vote by which cloture on the motion to proceed to S. 2747 '
  + 'was not invoked (Record Vote No. 420) entered in Senate.';
const filler = (n: number) => Array.from({ length: n }, (_, i) => `summary sentence ${i} about voter registration access.`).join(' ');
const cosponsors = ['Baldwin, Tammy [D-WI]', 'Van Hollen, Chris [D-MD]', 'Warner, Mark R. [D-VA]', 'Warren, Elizabeth [D-MA]',
  'Wyden, Ron [D-OR]'].map((c) => `Sen. ${c}`).join(', ');
const CONGRESS = `Freedom to Vote Act Sponsor: Sen. Klobuchar, Amy [D-MN] Latest action: ${ACTION} ${filler(40)} `
  + `Cosponsors: ${cosponsors} Actions: ${ACTION} Cloture on the motion to proceed to the measure not invoked in Senate `
  + `by Yea-Nay Vote. 49 - 51. Record Vote Number: 420. Motion to proceed to consideration of measure made in Senate.`;

describe('verifiableWindow', () => {
  const verified = (w: string, page: string, fullName: string, lastName: string) => {
    const span = matchedSpan(w, page)!;
    return checkNameProximity({ fullName, lastName, pageText: page, matchOffsetInNormalized: span.offset }).verdict;
  };
  it('takes the party-free action line beside a labelled cosponsor list (Warner, S. 2747)', () => {
    const w = verifiableWindow(CONGRESS, { fullName: 'Mark Warner' })!;
    expect(w).not.toBeNull();
    expect(sweepHit(w)).toBe(false);
    expect(w.split(' ').length).toBeGreaterThanOrEqual(25);
    expect(verified(w, CONGRESS, 'Mark Warner', 'Warner')).toBe('verified');
  });
  it('control: the page-start window the old fallback took fails the name check', () => {
    const top = CONGRESS.split(/\s+/).slice(9, 39).join(' ');
    expect(sweepHit(top)).toBe(false);
    expect(verified(top, CONGRESS, 'Mark Warner', 'Warner')).toBe('name_not_present');
  });
  it('control: every window holding the name also holds a party label', () => {
    const words = CONGRESS.split(/\s+/); const at = words.indexOf('Warner,');
    for (let a = Math.max(0, at - 29); a <= at; a++) expect(sweepHit(words.slice(a, a + 30).join(' '))).toBe(true);
  });
  const roll = (names: string) => `${filler(30)} Ayes: ${names}, Bennett, Berman, Boerner, Bonta, Bryan, Calderon, `
    + 'Carrillo, Connolly, Fong, Friedman, Gabriel, Garcia, Gipson, Grayson, Haney, Hart, Holden, Irwin, Jackson. '
    + filler(30);
  it('refuses a common surname with no full name or title nearby (a roll call that lists "Lee")', () => {
    expect(verifiableWindow(roll('Aguiar-Curry, Alvarez, Lee'), { fullName: 'Alex Lee' })).toBeNull();
  });
  it('accepts the same roll call when it prints the full name', () => {
    const page = roll('Aguiar-Curry, Alvarez, Alex Lee');
    const w = verifiableWindow(page, { fullName: 'Alex Lee' })!;
    expect(verified(w, page, 'Alex Lee', 'Lee')).toBe('verified');
  });
  it('returns null for a page that never names the person', () => {
    expect(verifiableWindow(filler(80), { fullName: 'Mark Warner' })).toBeNull();
  });
});

describe('unverifiableNote', () => {
  it('lists each cited page with its verdicts', () => {
    expect(unverifiableNote([{ url: 'https://a.example/x', snippets: [{ verdict: 'name_not_present' }, { verdict: 'name_not_present' }] }],
      '2026-11-03')).toBe('Blank approved with no verified source (2026-11-03, approve-batch --unverifiable-blank; ruling '
      + '2026-10-31 "Write a blank for all 26"): no cited page verified: https://a.example/x (name_not_present).');
  });
  it('says so when nothing could be cited', () => {
    expect(unverifiableNote(null, '2026-11-03')).toMatch(/: no page could be cited\.$/);
  });
});
