/**
 * Ballotpedia Candidate Connection carve-out — the ONE definition both BALLOTPEDIA_ONLY predicates use.
 *
 * Ruling 2026-10-07 (Chris Andrews): a Candidate Connection survey answer is the candidate's own
 * words and may stand as a stance source. Every other Ballotpedia page (editorial bio, measure page)
 * stays refused when it is the only source.
 *
 * TWO TESTS, BOTH REQUIRED:
 *   1. URL    — ballotpedia.org/<Page>#Campaign_themes. The section id is #Campaign_themes; there is NO
 *               #Candidate_Connection id (verified against live pages, deep-link-candidate-connection.mjs).
 *               A bare ballotpedia.org/Name stays BALLOTPEDIA_ONLY.
 *   2. TEXT   — the cited passage is found INSIDE that section of the fetched page. An anchor alone is a
 *               claim about the URL; text inside the section is a claim about the page. Never trust the
 *               reasoning wording ("per her Candidate Connection survey").
 *
 * Callers: check-stance-sources.mjs (SQL; mirrors test 1 in a Postgres regex and is held in line by
 * candidate-connection.test.ts) and stanceGate.ts (pre-write; needs both tests, fails closed on test 2).
 */
import { norm } from './claim-match.mjs';

export const CC_SECTION_ID = 'Campaign_themes';

/** The Postgres-compatible regex source used in check-stance-sources.mjs. Same text, JS and SQL. */
export const CC_ANCHOR_PATTERN = 'ballotpedia\\.org/[^#]+#Campaign_themes';

const HEADING = /^h[1-6]$/i;

/** True when `url` is a Ballotpedia page deep-linked to the survey section (test 1 only). */
export function isCandidateConnectionUrl(url) {
  let u;
  try { u = new URL(String(url).trim()); } catch { return false; }
  if (!/(^|\.)ballotpedia\.org$/i.test(u.hostname)) return false;
  if (u.pathname === '' || u.pathname === '/') return false;
  return u.hash.toLowerCase() === `#${CC_SECTION_ID.toLowerCase()}`;
}

/** `url` without its fragment — what you fetch to read the page. */
export const withoutFragment = (url) => String(url).trim().replace(/#.*$/, '');

/**
 * Text of the section introduced by the element carrying `id`, up to the next heading of the same or
 * higher rank. `content` is a node-html-parser element. MediaWiki puts the id on a <span> inside the
 * heading in one skin and on the heading in another, so ascend to the heading first.
 */
export function sectionText(content, id = CC_SECTION_ID) {
  const marker = content.querySelector(`#${id}`);
  if (!marker) return null;
  let heading = marker;
  while (heading && !HEADING.test(heading.tagName ?? '')) heading = heading.parentNode;
  if (!heading) heading = marker;
  const rank = HEADING.test(heading.tagName ?? '') ? parseInt(heading.tagName[1], 10) : 2;
  const sibs = heading.parentNode?.childNodes ?? [];
  const start = sibs.indexOf(heading);
  if (start < 0) return null;
  const out = [];
  for (let i = start + 1; i < sibs.length; i++) {
    const n = sibs[i];
    const tag = n.tagName ?? '';
    if (HEADING.test(tag) && parseInt(tag[1], 10) <= rank) break;
    out.push(n.textContent ?? '');
  }
  return out.join(' ').replace(/\s+/g, ' ').trim();
}

/**
 * Test 2. Is `passage` (a cited snippet) inside `section` (the survey section's text)?
 * A section that is missing or empty never verifies. Stricter than the audit's "any one 6-word run":
 * at least MIN_COVERAGE of the passage's 6-word runs must be in the section, so a snippet that only
 * shares one stock phrase with the survey does not pass. Same shingle size and ratio the snippet
 * verifier uses (researchVerifier.ts SHINGLE_WORDS / MIN_SHINGLE_COVERAGE).
 */
export const SHINGLE_WORDS = 6;
export const MIN_COVERAGE = 0.6;
/**
 * 🔴 A "Campaign themes" section with this notice carries NO survey answers: Ballotpedia prints it under
 * the same heading, beside an editorial summary of the campaign website. Measured 2026-10-07: 10 of 13
 * pages the deep-link sweep had marked CC_VERIFIED said it, and the sweep's term matcher had matched the
 * editorial summary. The section id alone does not make the text the candidate's own words.
 */
export const NO_SURVEY_NOTICE = /has not (?:yet )?completed Ballotpedia'?s?\b|did not complete Ballotpedia'?s?\b|has not responded to Ballotpedia'?s?\b/i;

/**
 * "<Name> completed Ballotpedia's Candidate Connection survey in 2022." The notice CONTAINS this phrase
 * ("has not completed Ballotpedia's ..."), so a match negated within the 24 characters before it does not
 * count (sweep-candidate-connection-anchors.mjs correction 5).
 */
export const COMPLETED_SURVEY = /completed\s+Ballotpedia'?s?\s+(?:\d{4}\s+)?Candidate\s+Connection\s+survey/gi;
const NEGATED_BEFORE = /\b(?:not|never|hasn't|haven't|didn't)\b[^.]{0,24}$/i;
/** Where one completed survey's answers end: Ballotpedia's edit note, or the next cycle's survey block. */
const SURVEY_BLOCK_END = /Note: Ballotpedia reserves the right to edit|Ballotpedia survey responses/i;

/** Start offsets of each affirmative "completed ... survey" statement, negations excluded. */
function completedSurveyStarts(text) {
  const starts = [];
  for (const m of text.matchAll(COMPLETED_SURVEY)) {
    if (!NEGATED_BEFORE.test(text.slice(Math.max(0, m.index - 24), m.index))) starts.push(m.index);
  }
  return starts;
}

/** True when the section affirmatively states a completed survey, negations excluded. */
export function statesCompletedSurvey(text) {
  return completedSurveyStarts(String(text ?? '')).length > 0;
}

/**
 * The text that is the candidate's own survey answers. A page can carry the current cycle's notice and an
 * earlier cycle's completed survey under the same heading (Jonah Garson, 2026-11-02: no 2026 survey, a
 * full 2022 one). So when a completed survey is stated, only those blocks count, and the notice does not
 * void them; with no completed survey stated, the notice voids the section; otherwise the whole section.
 */
function surveyAnswerText(section) {
  const starts = completedSurveyStarts(section);
  if (starts.length > 0) {
    return starts.map((s) => {
      const rest = section.slice(s);
      const end = rest.slice(1).search(SURVEY_BLOCK_END);
      return end < 0 ? rest : rest.slice(0, end + 1);
    }).join(' ');
  }
  return NO_SURVEY_NOTICE.test(section) ? null : section;
}

export function passageInSurveySection(section, passage) {
  if (!section || !String(passage ?? '').trim()) return false;
  const answers = surveyAnswerText(section);
  if (!answers) return false;
  const hay = norm(answers);
  const words = norm(passage).split(' ').filter(Boolean);
  if (words.length === 0) return false;
  if (words.length < SHINGLE_WORDS) return hay.includes(words.join(' '));
  let hit = 0;
  const total = words.length - SHINGLE_WORDS + 1;
  for (let i = 0; i < total; i++) if (hay.includes(words.slice(i, i + SHINGLE_WORDS).join(' '))) hit++;
  return hit / total >= MIN_COVERAGE;
}
