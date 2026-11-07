/**
 * The federal swearing-in rule — piece 4, federal tier.
 *
 * One rule covers all 470 federal offices on the 2026-11-03 ballot (435 Representatives, 35
 * Senators), in every state, with no per-state research at all:
 *
 *   U.S. Const. amend. XX, § 1 — "the terms of Senators and Representatives [shall end] at noon
 *   on the 3d day of January … and the terms of their successors shall then begin."
 *
 * Read from constitution.congress.gov on 2026-11-04.
 */
import { describe, it, expect } from 'vitest';
import { federalTermStart, US_FEDERAL_RULE } from './federal-swearing-in.mjs';

describe('federalTermStart — U.S. Const. amend. XX § 1', () => {
  it('is 2027-01-03 for the 2026 election', () => {
    expect(federalTermStart(2026)).toBe('2027-01-03');
  });

  it('does NOT move when 3 January falls on a weekend', () => {
    // 🔴🔴 THE PLAUSIBLE-WRONG ANSWER, AND THE ONLY REASON THIS FUNCTION IS TESTED AT ALL.
    // 3 January 2027 is a SUNDAY. Every other date in this programme is "the second Friday",
    // "the first Monday after", "the next regular meeting" — rules that bend around the
    // calendar — so the reflex is to bend this one too, to the 4th.
    //
    // It does not bend. § 1 names the DAY OF THE MONTH, not a weekday, and a constitutional
    // term begins at noon on it whatever day of the week that is.
    //
    // ⚠ What DOES move is a different event. § 2 has Congress assemble on 3 January "unless
    // they shall by law appoint a different day", and Congress routinely appoints one when the
    // 3rd is a weekend. Members then take the oath on the day the chamber convenes — AFTER
    // their terms have already begun. Commencement and oath again, as with the school boards:
    // this column holds the commencement.
    expect(federalTermStart(2026)).toBe('2027-01-03');
    expect(new Date(Date.UTC(2027, 0, 3)).getUTCDay()).toBe(0); // Sunday, and still the answer
  });

  it('is 2025-01-03 for the 2024 election, which is what actually happened', () => {
    // A positive control against a seating everyone can check: the 119th Congress's terms began
    // 2025-01-03, a Friday.
    expect(federalTermStart(2024)).toBe('2025-01-03');
  });

  it('carries its authority and source, like every other rule in piece 4', () => {
    expect(US_FEDERAL_RULE.authority).toMatch(/amend\. XX/);
    expect(US_FEDERAL_RULE.source).toMatch(/https:\/\/\S+/);
    expect(US_FEDERAL_RULE.compute(2026)).toBe('2027-01-03');
  });
});
