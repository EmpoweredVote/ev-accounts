import { describe, expect, it } from 'vitest';
import { normaliseName, resolveName, type NameFile, type TermSpan } from './names.js';

// Fixture ids stand in for politician ids. Names and term dates come from the
// Bloomington council roster.
const names: NameFile = {
  city: 'place:1805860',
  members: [
    { politicianId: 'p-1', onboardId: null, variants: ['Ron Smith', 'Smith'] },
    // 'Smith' listed for p-2 too: this collision is constructed for the test.
    { politicianId: 'p-2', onboardId: null, variants: ['Isabel Piedmont-Smith', 'Piedmont-Smith', 'Smith'] },
    { politicianId: 'p-3', onboardId: null, variants: ['Isak Nti Asare'] },
  ],
};

const terms: TermSpan[] = [
  { politicianId: 'p-1', start: '2020-01-01', end: '2023-12-31' },
  { politicianId: 'p-2', start: '2020-01-01', end: null },
  { politicianId: 'p-3', start: '2024-01-02', end: null },
];

describe('normaliseName', () => {
  it('strips the remote marker and lower-cases', () => {
    expect(normaliseName('Isak Nti Asare*')).toBe('isak nti asare');
  });
  it('strips titles but keeps hyphens', () => {
    expect(normaliseName('Councilmember Piedmont-Smith')).toBe('piedmont-smith');
    expect(normaliseName('Council President Isabel Piedmont-Smith')).toBe('isabel piedmont-smith');
    expect(normaliseName('Vice President Sue Sgambelluri')).toBe('sue sgambelluri');
  });
  it('folds accents and collapses spaces and punctuation', () => {
    expect(normaliseName('  José   O’Brien, ')).toBe('jose obrien');
  });
});

describe('resolveName', () => {
  it('resolves a listed variant inside the term', () => {
    expect(resolveName('Isak Nti Asare*', '2024-05-01', names, terms)).toEqual({ politicianId: 'p-3' });
  });
  it('is not_seated outside every term', () => {
    const r = resolveName('Isak Nti Asare', '2023-06-01', names, terms);
    expect(r).toMatchObject({ error: 'not_seated' });
  });
  it('is unknown_name for an unlisted name', () => {
    expect(resolveName('Pat Nobody', '2024-05-01', names, terms)).toMatchObject({ error: 'unknown_name' });
  });
  it('is ambiguous when a variant matches two people seated that day', () => {
    expect(resolveName('Councilmember Smith', '2022-01-01', names, terms)).toMatchObject({ error: 'ambiguous' });
  });
  it('resolves a shared variant when only one person is seated', () => {
    expect(resolveName('Smith', '2024-05-01', names, terms)).toEqual({ politicianId: 'p-2' });
  });
  it('treats term end as inclusive', () => {
    expect(resolveName('Ron Smith', '2023-12-31', names, terms)).toEqual({ politicianId: 'p-1' });
    expect(resolveName('Ron Smith', '2024-01-01', names, terms)).toMatchObject({ error: 'not_seated' });
  });
});
