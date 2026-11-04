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

/**
 * The last Friday in November of `year` — Cal. Educ. Code § 19422 / § 19510.
 *
 * ⚠ Counted forward from the END of the month, not backwards from 1 December. When November
 * ends on a Friday (2029-11-30) the answer is that day; walking back from December returns the
 * 23rd, a week early — on the only class of California seat that changes hands before December.
 */
export function lastFridayInNovember(year) {
  const nov30 = new Date(Date.UTC(year, 10, 30));
  const offset = (nov30.getUTCDay() - FRIDAY + 7) % 7;
  return iso(year, 11, 30 - offset);
}

/**
 * The second Monday in December of `year` — Los Angeles City Charter § 205(c).
 *
 * ⚠ 1 December COUNTS when it is itself a Monday (December 2025). Searching for the first
 * Monday strictly after the 1st is a week late in those years.
 */
export function secondMondayInDecember(year) {
  const dec1 = new Date(Date.UTC(year, 11, 1));
  const offset = (MONDAY - dec1.getUTCDay() + 7) % 7;
  return iso(year, 12, 1 + offset + 7);
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
 * The first Monday IN January of `year` — the water-district principal acts' phrasing.
 *
 * 🔴 NOT THE SAME RULE as `firstMondayAfterJanuary1`, and the difference is invisible this
 * cycle. Both give 2027-01-04 for the 2026 election, because 1 January 2027 is a Friday. When
 * 1 January is itself a Monday they are a week apart — 2029-01-01 against 2029-01-08. One
 * function would have passed every test this wave can write and been wrong in the next.
 */
export function firstMondayInJanuary(year) {
  const jan1 = new Date(Date.UTC(year, 0, 1));
  const offset = (MONDAY - jan1.getUTCDay() + 7) % 7;
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
    label: 'District officers under the Uniform District Election Law whose principal act does not say otherwise',
    authority: 'Cal. Elec. Code § 10554 — noon on the first Friday in December next following the general district election',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
    // 🔴 § 10554 IS A DEFAULT, NOT A BLANKET RULE, AND IT READS EXACTLY LIKE ONE. "Elective
    // officers, elected or appointed pursuant to this part" is bounded by each district's
    // PRINCIPAL ACT. Applying it by a predicate over the office title (`Director%`) covers 25
    // California district offices in this wave; the correct answer for 6 of them is a month
    // later. Use this rule only where the principal act is silent on the date — in the 2026
    // California set that is the county water districts, whose Water Code § 30502 gives the
    // term's LENGTH and nothing about when it starts.
    warning:
      'A default. Check the district\'s principal act first — water agencies and water replenishment districts override it.',
  },
  'ca-wat-71253': {
    id: 'ca-wat-71253',
    label: 'Municipal water districts',
    authority:
      'Cal. Water Code § 71253 — "directors elected to office shall take office at noon on the first Friday in December succeeding their election"',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=71253. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
    // 🔴🔴 CC_0345 PUT THESE SEATS ON 2027-01-04 AND THAT WAS WRONG BY A MONTH.
    // It followed the LA County handbook's Calendar of Events heading, "TAKING OF OFFICE —
    // MUNICIPAL WATER, WATER AGENCIES, AND WATER REPLENISHMENT DISTRICTS … first Monday in
    // January". The heading NAMES municipal water districts and its citations do not: § 60139 is
    // the Water Replenishment District act and Appendix 98-51 / 103-5(b) are two water agencies'
    // special acts. The same handbook's General Information table gives municipal water
    // districts their own row on 4 December, citing §§ 71252 and 71253, and § 71253 says so in
    // plain words. CC_0346 corrects the 8 rows.
    // ▶ READ THE CITATION, NOT THE HEADING.
  },
  'ca-wat-21101': {
    id: 'ca-wat-21101',
    label: 'Irrigation districts',
    authority:
      'Cal. Water Code § 21101 — notwithstanding Elec. Code §§ 10505 and 10554, officers elected at a general district election take office at noon on the first Friday in December next following',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=21101. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
  },
  'ca-gov-61042': {
    id: 'ca-gov-61042',
    label: 'Community services districts',
    authority:
      'Cal. Gov. Code § 61042(a) — "Directors shall take office at noon on the first Friday in December following their election"',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=GOV&sectionNum=61042. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
  },
  'ca-wat-35057-udel': {
    id: 'ca-wat-35057-udel',
    label: 'California water districts (Water Code division 13) with resident voting divisions',
    authority:
      'Cal. Water Code § 35057 routes the conduct of these elections to the Uniform District Election Law; Cal. Elec. Code § 10554 then sets taking office at noon on the first Friday in December',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=WAT&sectionNum=35057. and https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=ELEC&sectionNum=10554. (both read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
  },
  'ca-edc-19422': {
    id: 'ca-edc-19422',
    label: 'Library district trustees — Educ. Code chapter 8 (§§ 19400-19532)',
    authority:
      'Cal. Educ. Code § 19422 — "The trustee shall hold office for the term of four years beginning on the last Friday in November next succeeding their appointment or election" (§ 19510 to the same effect)',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=19422. (read 2026-11-04)',
    compute: (electionYear) => lastFridayInNovember(electionYear),
    // 🔴 THE EARLIEST DATE ANY CALIFORNIA RULE PRODUCES — 2026-11-27, before December entirely.
    // No body in the 2026 California set uses it: both library districts here are chapter 9
    // (below). It is kept because the two chapters are a week apart and look identical from the
    // outside, and the next county's wave will meet a chapter 8 district.
  },
  'ca-edc-19700': {
    id: 'ca-edc-19700',
    label: 'Library district trustees — Educ. Code chapter 9 (§§ 19600-19734, unincorporated towns and villages)',
    authority:
      'Cal. Educ. Code § 19700(b) — "The trustees shall hold office for the term of four years beginning on the first Friday in December next succeeding their appointment or election"',
    source: 'https://leginfo.legislature.ca.gov/faces/codes_displaySection.xhtml?lawCode=EDC&sectionNum=19700. (read 2026-11-04)',
    compute: (electionYear) => firstFridayInDecember(electionYear),
    // ⚠ WHICH CHAPTER A LIBRARY DISTRICT BELONGS TO IS ITS FORMATION STATUTE, NOT ITS TERRITORY.
    // Palos Verdes Library District serves four INCORPORATED cities and is still a chapter 9
    // district: "formed in April 1928 under the provision of Sections 19600-19734" (pvld.org).
    // Its own trustee roster prints "Term Expires: 11/27/2026", the chapter 8 date, while the
    // same roster prints "Term Began: 12/02/2022" — the first Friday in December 2022, which is
    // chapter 9. A source can be right about its own statute and wrong in a roster field.
  },
  'ca-water-principal-act': {
    id: 'ca-water-principal-act',
    label: 'Water agencies and water replenishment districts (special acts only)',
    authority:
      'Cal. Water Code § 60139 (water replenishment districts), Water Code Appendix §§ 98-51 and 103-5(b) (the Antelope Valley-East Kern and Santa Clarita Valley water agencies), and Cal. Gov. Code § 24200 — noon on the first Monday in January following the election',
    source:
      'Los Angeles County Registrar-Recorder/County Clerk, Candidate Handbook and Resource Guide, November 3, 2026 General Election, Calendar of Events, "JAN. 4 (M) NOON E+62", corroborated by that handbook\'s General Information table row for the Antelope Valley-East Kern Water Agency ("Monday at noon, January 4, 2027") — https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf (read 2026-11-04)',
    compute: (electionYear) => firstMondayInJanuary(electionYear + 1),
    // ⚠ NARROWED BY CC_0346. This rule used to carry municipal water districts too, because the
    // handbook's calendar heading names them. None of that entry's citations is the Municipal
    // Water District Law, and § 71253 puts those districts on 4 December. See `ca-wat-71253`.
  },
  'ca-la-county-charter': {
    id: 'ca-la-county-charter',
    label: 'Los Angeles County Assessor, Sheriff and Supervisors',
    authority: 'Los Angeles County Charter, Art. II § 6 and Art. IV § 13',
    source:
      'Los Angeles County Registrar-Recorder/County Clerk, Candidate Handbook and Resource Guide, November 3, 2026 General Election, Calendar of Events — https://content.lavote.gov/docs/rrcc/documents/candidate-handbook-general-election-complete-v-10.pdf (read 2026-11-04)',
    // 🔴 UNRESOLVED, ON PURPOSE. The handbook states the rule as "noon on the first Monday in
    // December following the election" and then calendars that very entry at NOV. 30 (M) NOON,
    // E+27. 30 November 2026 IS a Monday and is NOT in December; the first Monday in December
    // 2026 is the 7th. Both readings cannot hold, the gap is a week, and the charter sections
    // the entry cites are the only thing that can settle it.
    compute: null,
    notComputableReason:
      'the county\'s own handbook contradicts itself: it states "the first Monday in December" and calendars that entry on 30 November (E+27). Read Art. II § 6 and Art. IV § 13 of the charter before seating the Sheriff',
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
  'ca-la-city-charter-205c': {
    id: 'ca-la-city-charter-205c',
    label: 'City of Los Angeles elected officers',
    authority:
      'Los Angeles City Charter § 205(c) — "The term of an official elected to City office shall commence on the second Monday in December next following his or her election"',
    source: 'https://codelibrary.amlegal.com/codes/los_angeles/latest/laac/0-0-0-392 (read 2026-11-04)',
    compute: (electionYear) => secondMondayInDecember(electionYear),
    // 🔴 LOS ANGELES IS THE EXCEPTION AMONG THE 53 CITIES, NOT THE PATTERN. Its charter fixes a
    // DATE, so no council meeting stands between the election and the handover. Burbank's
    // charter, read the same day, fixes no commencement at all — it says only that the county
    // certifies to the Council, "who shall thereupon declare the result". Being a charter city
    // does not mean having a date.
    // ⚠ § 205(c) also stages the cycle: the Mayor, City Attorney, Controller and ODD-numbered
    // council districts commence on each fourth anniversary of 2022, which is 2026. The four
    // offices in this wave are Mayor, City Attorney and Council Districts 3 and 9 — both odd.
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
