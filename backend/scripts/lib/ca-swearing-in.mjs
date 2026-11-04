/**
 * ca-swearing-in.mjs — when California's 2026 winners actually take office.
 *
 * Piece 4 of the post-election transition programme, California slice. `seat_officeholder`
 * needs a REAL DATE: a term written a week early seats a winner who is not yet in office, and a
 * term written a week late leaves the departing holder on a seat they have left. Both are
 * wrong on the live site and neither errors.
 *
 * 🔴 THE DATES WE ALREADY HELD WERE NOT DATES. The wave-3 scope was drawn by reading the month
 * of each office's existing `office_terms.term_start`, and 118 of ~140 dated California SCHOOL
 * terms read `2022-12-01` — every one with `start_precision = 'month'`. That is this repo's
 * honest encoding of "December, day unknown", and reading its DAY turned a precision artifact
 * into a deadline ("the earliest on 1 December"). Reading the month was right. Reading the day
 * was reading a value the column never claimed to hold.
 *
 * 🔴 AND THE MONTH IS CONTAMINATED TOO. 22 offices across 16 states carry NOVEMBER historical
 * term starts, almost all `NATIONAL_LOWER`/`NATIONAL_UPPER` — federal terms begin 3 January by
 * statute, so those rows are SPECIAL-ELECTION seatings, not a convention. A historical start
 * month cannot tell a regular term from a mid-term vacancy fill. It is a search tool for
 * finding seats to check, never evidence of when the next term begins.
 *
 * So the dates here are COMPUTED FROM STATUTE, each carrying the citation it came from, all
 * read from leginfo.legislature.ca.gov on 2026-11-04.
 *
 * ⚠ ONE CLASS IS DELIBERATELY NOT COMPUTABLE. Cal. Gov. Code § 36503 ties a city officer's term
 * to "the installation of officers following adoption by the council of the official canvass" —
 * a per-council event with no statewide date. 110 of California's 337 offices in this wave are
 * city offices. `swearingInDateForRule` THROWS for that rule rather than returning a plausible
 * December date, because a seeded term is only as good as the authority behind it.
 */

/** Days in the ISO week, as `Date#getUTCDay` numbers them. */
const MONDAY = 1;
const FRIDAY = 5;

function iso(year, month, day) {
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

/**
 * The first Friday in December of `year`.
 *
 * ⚠ 1 December COUNTS when it is itself a Friday (December 2023). Searching for the first
 * Friday strictly after the 1st is a week late in those years.
 */
export function firstFridayInDecember(year) {
  const dec1 = new Date(Date.UTC(year, 11, 1));
  const offset = (FRIDAY - dec1.getUTCDay() + 7) % 7;
  return iso(year, 12, 1 + offset);
}

/** The second Friday in December of `year` — Cal. Educ. Code § 5017. */
export function secondFridayInDecember(year) {
  const first = firstFridayInDecember(year);
  return iso(year, 12, Number(first.slice(8)) + 7);
}

/**
 * The first Monday AFTER 1 January of `year`.
 *
 * ⚠ STRICTLY after, so a Monday the 1st does not answer — the next Monday does. 1 January 2027
 * is a Friday, so this does not bite the 2026 cycle; it is written this way because the statute
 * says "after", not "on or after".
 */
export function firstMondayAfterJanuary1(year) {
  const jan1 = new Date(Date.UTC(year, 0, 1));
  const offset = ((MONDAY - jan1.getUTCDay() + 7) % 7) || 7;
  return iso(year, 1, 1 + offset);
}

/**
 * The rules, each with the authority that makes a seated term defensible.
 *
 * `compute` is null where the authority fixes no statewide date. That is a fact about the law,
 * not a gap in this file.
 */
export const CA_SWEARING_IN_RULES = {
  'ca-edc-5017': {
    id: 'ca-edc-5017',
    label: 'School and community college district governing boards',
    authority: 'Cal. Educ. Code § 5017 — second Friday in December next succeeding the election',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=5017. (read 2026-11-04)',
    compute: (electionYear) => secondFridayInDecember(electionYear),
  },
  'ca-elec-10554': {
    id: 'ca-elec-10554',
    label: 'District officers elected under the Uniform District Election Law',
    authority: 'Cal. Elec. Code § 10554 — noon on the first Friday in December next following the general district election',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
  },
  'ca-gov-24200': {
    id: 'ca-gov-24200',
    label: 'Elective county officers',
    authority: 'Cal. Gov. Code § 24200 — 12 noon on the first Monday after the January 1 succeeding the election',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=24200. (read 2026-11-04)',
    compute: (electionYear) => firstMondayAfterJanuary1(electionYear + 1),
  },
  'ca-const-vi-16c': {
    id: 'ca-const-vi-16c',
    label: 'Judges of the superior courts',
    authority: 'Cal. Const. art. VI § 16(c) — terms begin the Monday after January 1 following their election',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=CONS&sectionNum=SEC.%2016.&article=VI (read 2026-11-04)',
    compute: (electionYear) => firstMondayAfterJanuary1(electionYear + 1),
  },
  'ca-gov-36503': {
    id: 'ca-gov-36503',
    label: 'City officers (general law cities)',
    authority: 'Cal. Gov. Code § 36503 — from the date of the installation of officers following adoption by the council of the official canvass',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=36503. (read 2026-11-04)',
    // 🔴 NOT COMPUTABLE, ON PURPOSE. See the file header.
    compute: null,
    notComputableReason:
      'per city: the term begins at the installation meeting following the council\'s adoption of the canvass, and no statewide date exists',
  },
};

/**
 * The date a rule gives for an election held in `electionYear`.
 *
 * 🔴 THROWS rather than returning a guess, for both an unknown rule and a rule whose authority
 * fixes no date. A caller that wanted a date and got `undefined` would write `null` into a
 * column the seeding script reads as "no handover", which is the silent half of this failure.
 */
export function swearingInDateForRule(ruleId, electionYear) {
  const rule = CA_SWEARING_IN_RULES[ruleId];
  if (!rule) throw new Error(`unknown rule: ${ruleId}`);
  if (!rule.compute) {
    throw new Error(
      `${ruleId} is not computable — ${rule.notComputableReason}. Source this office's date from the city itself.`,
    );
  }
  return rule.compute(electionYear);
}
