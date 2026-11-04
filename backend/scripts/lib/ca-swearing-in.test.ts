/**
 * California swearing-in dates, computed from cited statute.
 *
 * 🔴 WHY THIS IS COMPUTED AND NOT COPIED. The wave-3 scope was drawn by reading the MONTH of
 * each office's existing `office_terms.term_start`. That was the right field to read and the
 * wrong value to trust: 118 of ~140 dated California SCHOOL terms read `2022-12-01`, and every
 * one of them carries `start_precision = 'month'`. 1 December is the repo's honest way of
 * writing "December, day unknown" — it is a PRECISION ARTIFACT, not a date, and the design doc
 * turned it into "the earliest on 1 December, 27 days from this document".
 *
 * The real dates come from statute, and none of them is 1 December:
 *
 *   Cal. Educ. Code § 5017          second Friday in December   2026-12-11   school + CCD
 *   Cal. Elec. Code § 10554         first Friday in December    2026-12-04   UDEL districts
 *   Cal. Gov. Code § 24200          first Monday after Jan 1    2027-01-04   county officers
 *   Cal. Const. art. VI § 16(c)     Monday after Jan 1          2027-01-04   superior court
 *   Cal. Gov. Code § 36503          installation after the council adopts the canvass
 *                                   — NO statewide date. Per city, and not computable here.
 *
 * Read from leginfo.legislature.ca.gov on 2026-11-04.
 */
import { describe, it, expect } from 'vitest';
import {
  firstFridayInDecember,
  secondFridayInDecember,
  firstMondayAfterJanuary1,
  CA_SWEARING_IN_RULES,
  swearingInDateForRule,
} from './ca-swearing-in.mjs';

describe('secondFridayInDecember — Cal. Educ. Code § 5017', () => {
  it('is 2026-12-11 for the 2026 general election', () => {
    expect(secondFridayInDecember(2026)).toBe('2026-12-11');
  });

  it('counts 1 December itself as the first Friday when it falls on one', () => {
    // 🔴 THE OFF-BY-ONE THIS EXISTS TO CATCH. December 2023 opened on a Friday, so "the second
    // Friday" is the 8th. An implementation that looks for the first Friday STRICTLY AFTER the
    // 1st returns the 15th — a week late, and a week late is a week of a seat reading as held
    // by the wrong person.
    expect(secondFridayInDecember(2023)).toBe('2023-12-08');
  });

  it('is 2024-12-13, the date the previous cycle of these boards was seated', () => {
    expect(secondFridayInDecember(2024)).toBe('2024-12-13');
  });
});

describe('firstFridayInDecember — Cal. Elec. Code § 10554', () => {
  it('is 2026-12-04 for the 2026 general district election', () => {
    expect(firstFridayInDecember(2026)).toBe('2026-12-04');
  });

  it('is 1 December when December opens on a Friday', () => {
    expect(firstFridayInDecember(2023)).toBe('2023-12-01');
  });
});

describe('firstMondayAfterJanuary1 — Cal. Gov. Code § 24200', () => {
  it('is 2027-01-04 for officers elected in 2026', () => {
    expect(firstMondayAfterJanuary1(2027)).toBe('2027-01-04');
  });

  it('is STRICTLY after 1 January, so a Monday the 1st does not count', () => {
    // 🔴 The statute says "the first Monday AFTER the January 1 succeeding their election".
    // 1 January 2029 is a Monday; the answer is the 8th, not the 1st. This does not bite the
    // 2026 cycle — 1 January 2027 is a Friday — and it is pinned so that it never has to be
    // re-derived under time pressure in a cycle where it does.
    expect(firstMondayAfterJanuary1(2029)).toBe('2029-01-08');
  });
});

describe('the rule catalogue', () => {
  it('gives every rule a citation, because a date with no authority cannot seat a term', () => {
    for (const rule of Object.values(CA_SWEARING_IN_RULES)) {
      expect(rule.authority, `rule ${rule.id} has no authority`).toMatch(/§|art\./);
      expect(rule.source, `rule ${rule.id} has no source`).toMatch(/^https:\/\//);
    }
  });

  it('resolves each computable rule to its 2026-cycle date', () => {
    expect(swearingInDateForRule('ca-edc-5017', 2026)).toBe('2026-12-11');
    expect(swearingInDateForRule('ca-elec-10554', 2026)).toBe('2026-12-04');
    expect(swearingInDateForRule('ca-gov-24200', 2026)).toBe('2027-01-04');
    expect(swearingInDateForRule('ca-const-vi-16c', 2026)).toBe('2027-01-04');
  });

  it('refuses to compute a date for the city rule instead of inventing one', () => {
    // 🔴 Gov. Code § 36503 ties the term to "the installation of officers following adoption by
    // the council of the official canvass". There is no statewide date to compute, and 110 of
    // the 337 California offices in this wave are city offices. Returning a plausible December
    // date here would be the exact failure the sourcing rules forbid: a term written against an
    // authority that does not say it.
    expect(() => swearingInDateForRule('ca-gov-36503', 2026)).toThrow(/per city|not computable/i);
  });

  it('refuses an unknown rule id rather than returning undefined', () => {
    expect(() => swearingInDateForRule('ca-made-up', 2026)).toThrow(/unknown rule/i);
  });
});
