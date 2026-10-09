/**
 * How a stance source URL is classified by the generic-sourcing detectors — the ONE definition
 * every tier script uses, so a correction lands in one place instead of being pasted twice.
 *
 * THREE CLASSES, not two. The detectors used to answer "generic or not", and that single bit was
 * wrong for a large, growing slice of the corpus.
 *
 *   'generic'         a page that structurally holds no per-topic position: a legislature member
 *                     page, an encyclopedia biography, an aggregator profile, a bare Ballotpedia
 *                     page. Reading it cannot tell you where someone sits on a ladder.
 *   'candidate-page'  a page carrying the CANDIDATE'S OWN WORDS: a Ballotpedia page deep-linked to
 *                     #Campaign_themes, or a BallotReady profile, which has an Issue Stances
 *                     section. These are the right source for a candidate -- person-first research
 *                     has nowhere better to point -- so counting them as "generic" overstated the
 *                     backlog and sent readers to rows that were already sound.
 *   'specific'        anything else: a bill, a roll call, a news article, a campaign site.
 *
 * 🔴 WHY 'candidate-page' IS A CLASS AND NOT AN EXEMPTION. A URL test is a claim about the URL,
 * not about the page, and that gap is a design fact rather than a tally of offenders. The repo
 * already carries NO_SURVEY_NOTICE in candidate-connection.mjs because an earlier sweep met pages
 * whose section said the candidate never answered. Pages also change after a row is written.
 *
 * ✅ MEASURED 2026-10-08 over all 160 Ballotpedia pages the corpus deep-links, and the current
 * population is clean: 143 pages state a completed Candidate Connection survey, 16 more carry no
 * survey but quote the candidate's own campaign site under the same heading, and the single page
 * left over was read by hand and also carries his own policy statements. ZERO pages hold the
 * anchor and nothing behind it. BallotReady the same way: 31 of 33 profiles / 131 of 137 rows
 * carry an Issue Stances section.
 *
 * ⚠ AN EARLIER VERSION OF THIS COMMENT CLAIMED 19 PAGES / 58 ROWS WERE EMPTY. That was four bugs
 * in the sweep, not a finding -- chiefly un-decoded HTML entities, so every pattern containing an
 * apostrophe failed against Ballotpedia&#39;s. The full account, and the corrected numbers, are in
 * data/stance-research/2026-10-08-campaign-themes-anchor-sweep.json.
 *
 * ⚠ The CI gate (check-stance-sources.mjs) carves out the same anchor on the URL alone, because
 * SQL cannot fetch a page. That remains a documented limit there; it is a standing exposure, not
 * a backlog of known-bad rows.
 */
import { CC_SECTION_ID } from './candidate-connection.mjs';

/** Hosts whose person pages hold no per-topic position. Each verified, not assumed — see tier-a. */
export const GENERIC_PATTERNS = [
  'en.wikipedia.org/wiki/',
  '/mgawebsite/members/details/',
  'capitol.texas.gov/members/memberinfo',
  'malegislature.gov/legislators/profile',
  'legislature.maine.gov/house/memberprofiles',
  'legislature.maine.gov/senate/memberprofiles',
  'azleg.gov/house/house-member',
  'azleg.gov/senate/senate-member',
  'congress.gov/member/',
  'govtrack.us/congress/members/',
];

/** Pages that carry the candidate's own words rather than an editor's summary. */
export const CANDIDATE_PAGE_PATTERNS = [
  'ballotready.org/people/',
];

const likeAny = (col, pats) => pats.map((p) => `${col} ILIKE '%${p}%'`).join('\n        OR ');

/**
 * A SQL CASE expression returning 'candidate-page' | 'generic' | 'specific' for the column `col`,
 * which must already be the unwrapped URL (Wayback prefixes stripped).
 *
 * The candidate-page test runs FIRST: a Ballotpedia URL is generic only when it is NOT deep-linked
 * to the survey section. That ordering is the whole correction.
 */
export function sourceClassSql(col = 'nu') {
  return `CASE
      WHEN ${col} ILIKE '%ballotpedia.org/%#${CC_SECTION_ID}%'
        OR ${col} ILIKE '%candidate_connection%'
        OR ${likeAny(col, CANDIDATE_PAGE_PATTERNS)}
        THEN 'candidate-page'
      WHEN ${col} ILIKE '%ballotpedia.org/%'
        OR ${likeAny(col, GENERIC_PATTERNS)}
        THEN 'generic'
      ELSE 'specific'
    END`;
}

/** The same decision in JavaScript, for callers that already hold the URL. */
export function sourceClass(url) {
  const u = String(url ?? '').toLowerCase();
  if (u.includes('ballotpedia.org/') && u.includes(`#${CC_SECTION_ID.toLowerCase()}`)) return 'candidate-page';
  if (u.includes('candidate_connection')) return 'candidate-page';
  if (CANDIDATE_PAGE_PATTERNS.some((p) => u.includes(p))) return 'candidate-page';
  if (u.includes('ballotpedia.org/')) return 'generic';
  if (GENERIC_PATTERNS.some((p) => u.includes(p))) return 'generic';
  return 'specific';
}
