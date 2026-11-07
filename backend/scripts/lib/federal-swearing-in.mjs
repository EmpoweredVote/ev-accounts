/**
 * federal-swearing-in.mjs — when the 2026 federal winners take office.
 *
 * Piece 4, federal tier. One rule, 470 offices, 50 states, no per-state research:
 *
 *   U.S. Const. amend. XX, § 1 — "The terms of the President and the Vice President shall end at
 *   noon on the 20th day of January, and the terms of Senators and Representatives at noon on
 *   the 3d day of January, of the years in which such terms would have ended if this article had
 *   not been ratified; and the terms of their successors shall then begin."
 *
 * Read from https://constitution.congress.gov/constitution/amendment-20/ on 2026-11-04.
 *
 * 🔴🔴 THIS RULE DOES NOT BEND AROUND THE CALENDAR, AND EVERY OTHER RULE IN THIS PROGRAMME DOES.
 * 3 January 2027 is a SUNDAY. California's dates are "the second Friday in December", "the first
 * Monday after 1 January", "the next regular council meeting" — all of them weekday rules that
 * move. The reflex is to move this one to the 4th. It does not move: § 1 names a DAY OF THE
 * MONTH, and the term begins at noon on it whatever weekday that is.
 *
 * ⚠ A DIFFERENT EVENT DOES MOVE, AND IT IS THE ONE PEOPLE SEE ON TELEVISION. § 2 has Congress
 * assemble on 3 January "unless they shall by law appoint a different day", and Congress
 * routinely appoints another day when the 3rd falls on a weekend. Members take the oath when
 * their chamber convenes — AFTER their terms have already begun. That is the same
 * commencement-versus-oath split as Cal. Educ. Code §§ 5017 and 35143, and this column holds the
 * COMMENCEMENT, because that is what decides who holds the seat.
 */

/**
 * The date a federal term begins, following an election held in `electionYear`.
 *
 * No weekday arithmetic, deliberately. If this function ever grows a weekday adjustment, the
 * test that pins 2027-01-03 — a Sunday — is what should stop it.
 */
export function federalTermStart(electionYear) {
  return `${electionYear + 1}-01-03`;
}

export const US_FEDERAL_RULE = {
  id: 'us-const-amend-xx-1',
  label: 'United States Senators and Representatives',
  authority:
    'U.S. Const. amend. XX, § 1 — the terms of Senators and Representatives end at noon on the 3d day of January, and the terms of their successors then begin',
  source: 'https://constitution.congress.gov/constitution/amendment-20/ (read 2026-11-04)',
  compute: federalTermStart,
};
