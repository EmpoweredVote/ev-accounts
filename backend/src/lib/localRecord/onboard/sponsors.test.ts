import { describe, expect, it } from 'vitest';
import { sponsorSentencesFromDocument, sponsorSentencesFromSynopsis } from './sponsors.js';

describe('sponsor sentence finder', () => {
  it('reads "sponsored by Councilmember X"', () =>
    expect(
      sponsorSentencesFromSynopsis('This Ordinance, sponsored by Councilmember Stosberg, amends Section 14.40.060.')[0].names,
    ).toEqual([{ printed: 'Stosberg', role: 'sponsor' }]));
  it('reads "Cm." and an amendment heading', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment, sponsored by Cm. Piedmont-Smith, would delay the effective date.',
      ),
    ).toEqual([expect.objectContaining({ label: 'Amendment 01', names: [{ printed: 'Piedmont-Smith', role: 'sponsor' }] })]));
  it('reads two sponsors joined by "and"', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 04 Synopsis: This Amendment is sponsored by Councilmember Sandberg and Councilmember Rollo. The Amendment changes',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Sandberg', 'Rollo']));
  it('reads "Councilmembers X and Y"', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by Councilmembers Smith and Rollo to remove a provision',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Smith', 'Rollo']));
  it('skips a heading caught inside the name list', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by Councilmembers Amendment 01 Flaherty and Volan. It replaces',
      )[0].names.map((n) => n.printed),
    ).toEqual(['Flaherty', 'Volan']));
  it('marks co-sponsors', () =>
    expect(
      sponsorSentencesFromSynopsis('This resolution is sponsored by Councilmember Sims and co-sponsored by Councilmember Volan.')[0]
        .names,
    ).toEqual([
      { printed: 'Sims', role: 'sponsor' },
      { printed: 'Volan', role: 'cosponsor' },
    ]));
  it('reads a Reasonable Condition', () =>
    expect(
      sponsorSentencesFromDocument(
        'RC 16 Synopsis: This Reasonable Condition 16 is sponsored by Councilmember Piedmont-Smith. It offers',
      )[0].label,
    ).toBe('Reasonable Condition 16'));
  it('reads "O2" as 02', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment O2 to Ordinance 23-11 Amendment 02 Synopsis: This amendment is sponsored by Councilmember Sgambelluri and replaces',
      )[0].label,
    ).toBe('Amendment 02'));
  it('treats a bracketed placeholder as no sponsor', () =>
    expect(
      sponsorSentencesFromDocument(
        'Amendment 01 Synopsis: This amendment is sponsored by [CM sponsor needed] [sic] and is being brought forward',
      )[0],
    ).toEqual(expect.objectContaining({ placeholder: true, names: [] })));
  it('keeps "PiedmontSmith" as printed for the resolver', () =>
    expect(
      sponsorSentencesFromDocument('Amendment 01 Synopsis: This amendment is sponsored by Cm. PiedmontSmith and would add')[0]
        .names[0].printed,
    ).toBe('PiedmontSmith'));
  it('finds nothing in a synopsis with no sponsor', () =>
    expect(sponsorSentencesFromSynopsis('This ordinance amends Title 2.')).toEqual([]));
});
