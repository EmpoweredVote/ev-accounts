import { describe, expect, it } from 'vitest';
import { checkSponsorPage, sampleSponsorPages, type SponsorRow } from './sponsorPageCheck.js';

const row = (name: string, n: number, year: number, act = 'sponsor', ch = 'HB'): SponsorRow =>
  [name, `https://leg.example.gov/${year}/${ch}${n}`, `XX-${ch}-${n}-${year}`, act];
const PAGE = 'HB 25 Relating to firearms. Introducer(s): DOE, Smith. Status: passed third reading. ' + 'Text of the measure follows here. '.repeat(20);

describe('checkSponsorPage', () => {
  it('passes a page that prints the sponsor and the bill', () => {
    expect(checkSponsorPage(row('Jane Q. Doe', 25, 2019), PAGE)).toEqual([]);
    expect(checkSponsorPage(row('John Smith, Jr.', 25, 2019), PAGE)).toEqual([]);
  });
  it('fails a page that prints no sponsor (Nevada, Oregon: the names are loaded by script or sit on another page)', () => {
    expect(checkSponsorPage(row('Ann Able', 25, 2019), PAGE).map((f) => f.why)).toEqual(['no-name']);
    // a surname inside another word is not the surname
    expect(checkSponsorPage(row('Bo Doer', 25, 2019), PAGE).map((f) => f.why)).toEqual(['no-name']);
  });
  it('fails a page that never prints the bill number (Colorado, Hawaii: the gate cannot tie the line to the bill)', () => {
    expect(checkSponsorPage(row('Jane Doe', 26, 2019), PAGE).map((f) => f.why)).toEqual(['no-bill']);
    expect(checkSponsorPage(row('Ann Able', 26, 2019), PAGE).map((f) => f.why)).toEqual(['no-name', 'no-bill']);
  });
});

describe('sampleSponsorPages', () => {
  const rows: SponsorRow[] = [];
  for (const y of [2017, 2019, 2021, 2023, 2025]) for (let n = 1; n <= 30; n++) rows.push(row(`P ${n}`, n, y, n % 3 ? 'cosponsor' : 'sponsor', n % 2 ? 'HB' : 'SB'));
  it('takes one person per page, from every session and both chambers, and never more than asked', () => {
    const s = sampleSponsorPages([...rows, ...rows], 12);
    expect(s).toHaveLength(12);
    expect(new Set(s.map((r) => r[1])).size).toBe(12);
    expect(new Set(s.map((r) => r[2].slice(-4))).size).toBe(5);
    expect(new Set(s.map((r) => r[2].split('-')[1])).size).toBe(2);
  });
  it('is the same sample every time, and all of a short list', () => {
    expect(sampleSponsorPages(rows, 12)).toEqual(sampleSponsorPages([...rows].reverse(), 12));
    expect(sampleSponsorPages(rows.slice(0, 3), 12)).toHaveLength(3);
    expect(sampleSponsorPages([], 12)).toEqual([]);
  });
});
