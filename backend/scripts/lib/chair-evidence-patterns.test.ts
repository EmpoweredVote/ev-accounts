import { describe, it, expect } from 'vitest';
import { NAMES_INSTRUMENT, INSTRUMENT_SRC } from './chair-evidence-patterns.mjs';

// The pattern audit-chair-evidence.mjs gates on had been widened five times with no regression
// cover at all, and the sixth widening was prompted by a FALSE FAIL: 8 of the 11 attributed
// Miami-Dade rows scored "directional only" while every one of them named an adopted resolution.
//
// So this file pins two things. First, that each documented widening still does what its comment
// claims — otherwise the next one can silently undo an earlier one. Second, and more important,
// that the REFUSALS still refuse: every widening in that file is justified by requiring an
// identifier, and a pattern that admits ordinary prose makes passing the gate meaningless.
//
// Every string below is real, taken from rows this repo has actually written or read.

describe('NAMES_INSTRUMENT — what each widening admits', () => {
  it('sees a state legislature, which is what it was built for', () => {
    expect(NAMES_INSTRUMENT.test('Voted for HB 1234 in committee')).toBe(true);
    expect(NAMES_INSTRUMENT.test('sponsored SB 90')).toBe(true);
    expect(NAMES_INSTRUMENT.test('cosponsored House Bill 509')).toBe(true);
    expect(NAMES_INSTRUMENT.test('ratified as S.L. 2021-165')).toBe(true);
  });

  it('sees a city council and a mayor (migs 1738, 1740)', () => {
    expect(NAMES_INSTRUMENT.test('adopted Resolution No. 12-345')).toBe(true);
    expect(NAMES_INSTRUMENT.test('adopted Ordinance No. 7788')).toBe(true);
    // ⚠ The rule is `referrals? (approved|adopted|considered)` — ADJACENT. "referral approved"
    // passes; "referral WAS approved" does not. Pinned as measured, not as assumed: this tripped
    // the author of this test. It is a real narrowness, so write the citation in the tight form.
    expect(NAMES_INSTRUMENT.test('the referral approved by the council')).toBe(true);
    expect(NAMES_INSTRUMENT.test('the referral was approved by the council')).toBe(false);
    expect(NAMES_INSTRUMENT.test('Measure 1.1 of the Climate Action Plan')).toBe(true);
    expect(NAMES_INSTRUMENT.test('Ordinance O-21528 N.S.')).toBe(true);
    expect(NAMES_INSTRUMENT.test('Resolution R-316659')).toBe(true);
  });

  it('sees a county commissioners court (Travis wave)', () => {
    expect(NAMES_INSTRUMENT.test('Travis County Proposition A carried in Nov 2024')).toBe(true);
    expect(NAMES_INSTRUMENT.test('the Commissioners Court approved the budget')).toBe(true);
  });

  it('sees the U.S. Senate (CC_0078)', () => {
    expect(NAMES_INSTRUMENT.test('cosponsored S. 1531')).toBe(true);
    expect(NAMES_INSTRUMENT.test('cosponsored S.25')).toBe(true);
    expect(NAMES_INSTRUMENT.test('the Assault Weapons Ban of 2025')).toBe(true);
    expect(NAMES_INSTRUMENT.test('voted for H.R. 8')).toBe(true);
  });

  it('sees a Miami-Dade County resolution — the sixth widening', () => {
    // The three instruments the transportation and housing rows are seated on.
    expect(NAMES_INSTRUMENT.test('She is the prime sponsor of R-551-26, adopted in 2026')).toBe(true);
    expect(NAMES_INSTRUMENT.test('also the prime sponsor of R-992-25')).toBe(true);
    expect(NAMES_INSTRUMENT.test('prime sponsor of R-446-25, adopted in 2025')).toBe(true);
    // A four-digit resolution number in the same series.
    expect(NAMES_INSTRUMENT.test('co-sponsored R-1223-25')).toBe(true);
  });

  it('still sees the San Diego form the sixth widening did not replace', () => {
    // `\bR-\d{5,6}\b` and the new `\bR-\d{1,4}-\d{2}\b` are siblings, not substitutes.
    expect(NAMES_INSTRUMENT.test('Resolution R-316659 (Climate Action Plan)')).toBe(true);
  });
});

describe('NAMES_INSTRUMENT — what it must keep refusing', () => {
  it('refuses direction with no instrument, which is the whole point of the gate', () => {
    expect(NAMES_INSTRUMENT.test('She supports better transit and has spoken about it often.')).toBe(false);
    expect(NAMES_INSTRUMENT.test('He generally favours road building, per his campaign website.')).toBe(false);
    expect(NAMES_INSTRUMENT.test('a longstanding advocate for affordable housing')).toBe(false);
  });

  it('refuses the bare county ORDINANCE form, deliberately', () => {
    // Two digits, a hyphen and two more digits is a date range, a score and a code section as
    // often as it is an instrument. Admitting `25-59` would make passing mean nothing.
    expect(NAMES_INSTRUMENT.test('voted on 25-59 in June')).toBe(false);
    expect(NAMES_INSTRUMENT.test('the 2025-26 session')).toBe(false);
    expect(NAMES_INSTRUMENT.test('26-51 was adopted')).toBe(false);
  });

  it('refuses an R- that is not a resolution number', () => {
    expect(NAMES_INSTRUMENT.test('the R-2 zoning district applies here')).toBe(false);
    expect(NAMES_INSTRUMENT.test('rated R-13 insulation')).toBe(false);
  });

  it('refuses a middle initial or an initialism, per the CC_0078 lookbehind', () => {
    expect(NAMES_INSTRUMENT.test('Angus S. King voted with the majority')).toBe(false);
    expect(NAMES_INSTRUMENT.test('U.S. 2024 turnout was high')).toBe(false);
  });

  it('is case-sensitive on Act so the ordinary verb cannot pass', () => {
    // The regex carries no `i` flag precisely for this: `\bAct\b` must not match "they act".
    expect(NAMES_INSTRUMENT.test('the Fair Maps Act')).toBe(true);
    expect(NAMES_INSTRUMENT.test('they act on constituent concerns')).toBe(false);
  });

  it('accepts a recorded vote in either transcription case', () => {
    expect(NAMES_INSTRUMENT.test('voted AYE on the measure')).toBe(true);
    expect(NAMES_INSTRUMENT.test('Voted Yes')).toBe(true);
    expect(NAMES_INSTRUMENT.test('a Roll Call was taken')).toBe(true);
  });
});

describe('INSTRUMENT_SRC', () => {
  it('recognises a source that can carry an instrument', () => {
    expect(INSTRUMENT_SRC.test('https://www.congress.gov/bill/119th-congress/senate-bill/1531')).toBe(true);
    expect(INSTRUMENT_SRC.test('https://www.miamidade.gov/govaction/legistarfiles/Matters/Y2026/260764.pdf')).toBe(true);
    expect(INSTRUMENT_SRC.test('https://www.ncleg.gov/Legislation/x')).toBe(true);
  });

  it('does not mistake a bio or an aggregator profile for one', () => {
    expect(INSTRUMENT_SRC.test('https://ballotpedia.org/Raquel_Regalado')).toBe(false);
    expect(INSTRUMENT_SRC.test('https://en.wikipedia.org/wiki/Miami-Dade_County')).toBe(false);
  });
});
