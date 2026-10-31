import { describe, it, expect } from 'vitest';
// @ts-expect-error -- plain .mjs helper, no type declarations (scripts/ is outside tsconfig include)
import { extractInstrumentKeys, jurisdictionOf, directionFor, clauseAt } from './instrument-keys.mjs';

const TX = ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=SB13'];
const MA = ['https://malegislature.gov/Bills/191/S2963'];
const US = ['https://clerk.house.gov/Votes/202162'];
const keys = (t: string, s: string[] = []) =>
  extractInstrumentKeys(t, s).map((x: { key: string }) => x.key);

describe('jurisdictionOf', () => {
  it('reads the jurisdiction off the cited host', () => {
    expect(jurisdictionOf(TX)).toBe('TX');
    expect(jurisdictionOf(MA)).toBe('MA');
    expect(jurisdictionOf(US)).toBe('US');
  });

  it('declines when two legislatures are cited, rather than guessing', () => {
    expect(jurisdictionOf([...TX, ...MA])).toBeNull();
  });

  it('declines when the hosts say nothing about a legislature', () => {
    expect(jurisdictionOf(['https://en.wikipedia.org/wiki/Someone'])).toBeNull();
  });
});

describe('extractInstrumentKeys', () => {
  it('scopes a bare bill number to its jurisdiction', () => {
    expect(keys('87(R) SB13, voted to bar state investment', TX)).toContain('TX:SB0013');
  });

  // 🔴 The reason the scoping exists at all: merging these two would manufacture a contradiction
  // out of two correct rows about two different bills.
  it('does NOT collide the same number across two legislatures', () => {
    const a = keys('voted for SB 13', TX);
    const b = keys('voted for SB 13', MA);
    expect(a).toContain('TX:SB0013');
    expect(b).toContain('MA:SB0013');
    expect(a.filter((k: string) => b.includes(k))).toHaveLength(0);
  });

  it('emits no numeric key when the jurisdiction is unknown', () => {
    expect(keys('voted for SB 13', ['https://en.wikipedia.org/wiki/X'])).toHaveLength(0);
  });

  it('pads so SB13 and SB 0013 are one key', () => {
    expect(keys('SB13', TX)).toEqual(keys('SB 0013', TX));
  });

  it('reads the federal and Massachusetts numbering the Act extractor does not', () => {
    expect(keys('passage of H.R. 8035, the supplemental', US)).toContain('US:HR8035');
    expect(keys('ENACTED AS S.2963, Chapter 253', MA)).toContain('MA:S2963');
    expect(keys('cosponsor of 193/H2103', MA)).toContain('MA:H2103');
    expect(keys('89(R) HJR 138, as coauthor', TX)).toContain('TX:HJR0138');
  });

  it('still catches a named act, with no host at all', () => {
    expect(keys('cosponsor of the Safe Communities Act')).toContain('ACT:safe communities act');
  });
});

describe('directionFor', () => {
  const at = (t: string, needle: string) => t.indexOf(needle);

  it('separates a yes vote from a no vote', () => {
    const t = 'Representative Good voting Nay on H.R. 8035.';
    expect(directionFor(t, at(t, 'H.R. 8035'))).toBe('AGAINST');
    const u = 'Wilson voted Yea on H.R. 1.';
    expect(directionFor(u, at(u, 'H.R. 1'))).toBe('FOR');
  });

  it('keeps SPONSOR distinct from FOR — they are different claims', () => {
    const t = 'She is a cosponsor of the Safe Communities Act.';
    expect(directionFor(t, at(t, 'Safe Communities Act'))).toBe('SPONSOR');
  });

  // 🔴 md-instruments' migration-1694 lesson: a window that crosses a clause boundary invents
  // contradictions. Each instrument must be scored on ITS OWN clause.
  it('does not smear a direction across two clauses', () => {
    const t = 'He voted for HB 100; he voted against SB 200.';
    expect(directionFor(t, at(t, 'HB 100'))).toBe('FOR');
    expect(directionFor(t, at(t, 'SB 200'))).toBe('AGAINST');
  });

  it('declines when one clause carries both directions', () => {
    const t = 'He voted for the bill against the wishes of his party, then voted nay.';
    expect(directionFor(t, at(t, 'bill'))).toBeNull();
  });

  // 🔴 Both of these were found running the check against production for the first time. Each one
  // made the detector report a real member as taking the side opposite the one they took.
  it('declines a comma splice carrying two kinds of claim', () => {
    const t = 'Matsui co-sponsored the Respect for Marriage Act (2015) allowing state recognition'
      + ' of same-sex marriages with federal benefits, voted NO on a constitutional amendment'
      + ' defining marriage as one-man-one-woman (2006).';
    // She SPONSORED it; the "voted NO" belongs to a different instrument and no full stop separates
    // them. Reading the nearer verb would file her as opposing the act she sponsored.
    expect(directionFor(t, at(t, 'Respect for Marriage Act'))).toBeNull();
  });

  it('declines an inversion rather than reading it backwards', () => {
    const t = 'LaLota publicly supports same-sex marriage and opposed efforts to repeal the'
      + ' Respect for Marriage Act (2026).';
    // Opposing a REPEAL means he is FOR the act. The nearest verb says the opposite.
    expect(directionFor(t, at(t, 'Respect for Marriage Act'))).toBeNull();
  });

  // 🔴 The largest false group in the first live run: 101 Texas rows on HB 3, where every member
  // who did NOT co-author the voucher bill was filed as one of its sponsors.
  it('declines a NEGATED sponsorship instead of inverting it', () => {
    const a = 'Canales did not co-author HB 3 (Texas ESA/school vouchers)';
    expect(directionFor(a, a.indexOf('HB 3'))).toBeNull();
    const b = 'Geren is NOT listed as a co-author of HB 3 or SB 2';
    expect(directionFor(b, b.indexOf('HB 3'))).toBeNull();
    const c = 'He never voted for HB 3.';
    expect(directionFor(c, c.indexOf('HB 3'))).toBeNull();
  });

  // The two shapes that defeated a window-based negation guard, kept so they cannot come back.
  it('declines when the only un-negated verb is about OTHER people', () => {
    const t = "Did not co-author HB3 (89R school voucher ESA bill), the session's flagship school"
      + ' choice legislation co-authored by 71 Republicans including DeAyala and LaHood';
    expect(directionFor(t, t.indexOf('HB3'))).toBeNull();
  });

  it('declines when the negator is far from the verb it negates', () => {
    const t = 'Not listed as co-sponsor of SB 2 or co-author of HB 3 (89R voucher bills)';
    expect(directionFor(t, t.indexOf('HB 3'))).toBeNull();
  });

  // One verb genuinely governing two instruments must still read — the rule is about one
  // instrument ACTING ON another, not about counting them.
  it('still reads a joint sponsorship of two bills', () => {
    const t = 'Co-authored both HB3 and SB2, the Texas Education Savings Account bills';
    expect(directionFor(t, t.indexOf('HB3'))).toBe('SPONSOR');
  });

  it('still reads a bill named twice, by number and by title', () => {
    const t = 'Co-authored HB3, the Texas Education Savings Account bill';
    expect(directionFor(t, t.indexOf('HB3'))).toBe('SPONSOR');
  });

  // 🔴 Found on the third live run. He voted for the bill that GUTTED the act he is filed as
  // supporting — the clause is about one instrument acting ON another.
  it('declines when the clause names two instruments', () => {
    const t = 'She voted for the One Big Beautiful Bill which scales back Inflation Reduction Act'
      + ' clean energy incentives';
    expect(directionFor(t, t.indexOf('Inflation Reduction Act'))).toBeNull();
  });

  it('declines a bare "no confirmed vote" rather than reading it as a vote', () => {
    const t = 'No confirmed Yea vote on the Respect for Marriage Act was found in available sources';
    expect(directionFor(t, t.indexOf('Respect for Marriage Act'))).toBeNull();
  });

  it('still reads a plain, single-claim sentence', () => {
    const t = 'She voted for the Respect for Marriage Act, which requires federal recognition.';
    expect(directionFor(t, at(t, 'Respect for Marriage Act'))).toBe('FOR');
    const u = 'the Clerk records VA-5 Representative Bob Good voting Nay.';
    expect(directionFor(u, 10)).toBe('AGAINST');
  });

  it('declines when the clause states no direction at all', () => {
    const t = 'The Act was considered in committee.';
    expect(directionFor(t, at(t, 'Act'))).toBeNull();
  });
});

describe('clauseAt', () => {
  it('stops at the sentence boundary on both sides', () => {
    const t = 'First thing. Second thing with HB 1. Third thing.';
    expect(clauseAt(t, t.indexOf('HB 1'))).toContain('Second thing');
    expect(clauseAt(t, t.indexOf('HB 1'))).not.toContain('Third thing');
    expect(clauseAt(t, t.indexOf('HB 1'))).not.toContain('First thing');
  });
});
