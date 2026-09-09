/**
 * crec-turns.mjs — attribute a passage of the Congressional Record to the member
 * who actually spoke it.
 *
 * WHY THIS EXISTS. The sponsorship instrument has a gate that ties a person to a
 * document independently of anything a researcher writes: the member's bioguide id
 * must appear in the bill's BILLSTATUS sponsor/cosponsor roll. Floor statements
 * have no such gate, and the verifier cannot supply one — `verify-reresearch-rows`
 * checks that the reasoning's claim terms appear in the cited page's raw HTML, and
 * a CREC page carries every senator who spoke on that page. So a row could cite a
 * page that genuinely contains "asylum", "eliminates" and "seek", have all three
 * satisfied, and be quoting a DIFFERENT SENATOR. This module is the missing gate.
 *
 * 🔴 CO-OCCURRENCE IS NOT ATTRIBUTION. A search for a surname and a topic word in
 * the same granule is satisfied by a cosponsor list on an unrelated resolution.
 * Measured on the 2026-09-08 border sweep, Padilla had 90 such granules and spoke
 * in 6 of them. Nothing but a turn should ever reach a citation.
 */

/**
 * A speaking turn opens with an honorific, a SURNAME IN CAPITALS, an optional
 * " of <State>", and a period.
 *
 * ⚠ THE CAPITALS ARE LOAD-BEARING. The Record writes the speaker in caps and
 * everything else in mixed case, so "Mr. Padilla's amendment was agreed to" is
 * prose ABOUT him and "Mr. PADILLA." is him talking. Relaxing the case here
 * silently turns every mention into an attribution.
 */
const TURN = /(?:^|\n)\s{0,6}((?:Mr|Mrs|Ms|Miss)\.\s+([A-Z][A-Z'’\-.]+(?:\s+[A-Z][A-Z'’\-.]+){0,3})(?:\s+of\s+[A-Z][a-zA-Z ]+)?)\.\s/g;

/** Split a plain-text granule into { surname, body } turns, in order. */
export function turns(text) {
  const marks = [];
  let m;
  TURN.lastIndex = 0;
  while ((m = TURN.exec(text))) {
    marks.push({ at: m.index + m[0].length, surname: m[2].replace(/\.$/, '').trim() });
  }
  return marks.map((mark, i) => ({
    surname: mark.surname,
    body: text.slice(mark.at, i + 1 < marks.length ? marks[i + 1].at : text.length),
  }));
}

/**
 * What counts as the border-security axis IN SPEECH.
 *
 * 🔴 THIS IS NOT THE TITLE AXIS AND MUST NOT BE UNIFIED WITH IT. `refugee` and
 * `persecut` are reliable inside a bill title and worthless inside a floor
 * statement: on 2026-09-08 they matched Kaine describing the Congolese parish he
 * attends, and the "political persecution of Donald Trump's enemies". `port of
 * entry` and `seek protection` failed the same way. A keyword gate calibrated on
 * one kind of text does not transfer to another — the same lesson the named-bill
 * list taught, in a new medium.
 */
export const SPEECH_AXIS =
  /asylum|credible fear|expedited removal|remain in mexico|migrant protection protocol|withholding of removal/i;

/**
 * The Record's surname for a senator.
 *
 * ⚠ HAND-MAINTAINED ON PURPOSE, AND FAIL-CLOSED. Last-whitespace-word is wrong for
 * this chamber — Cortez Masto, Van Hollen and Blunt Rochester are two-word
 * surnames, Luján loses its accent, King drops a suffix — and the next name it
 * gets wrong fails SILENTLY, by attributing nothing. Callers that cannot find a
 * name here should refuse the row rather than guess at it.
 */
export const RECORD_SURNAME = {
  'Ben Ray Luján': 'LUJAN',
  'Catherine Cortez Masto': 'CORTEZ MASTO',
  'Chris Van Hollen': 'VAN HOLLEN',
  'Lisa Blunt Rochester': 'BLUNT ROCHESTER',
  'Angus S. King, Jr.': 'KING',
  'Shelley Moore Capito': 'CAPITO',
  'Cindy Hyde-Smith': 'HYDE-SMITH',
};

export function recordSurname(fullName) {
  if (RECORD_SURNAME[fullName]) return RECORD_SURNAME[fullName];
  return fullName
    .replace(/,\s*(Jr\.|Sr\.|II|III|IV)\s*$/i, '')
    .trim()
    .split(/\s+/)
    .pop()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toUpperCase();
}

/**
 * Is this granule from the Senate section?
 *
 * A CREC package covers both chambers plus Extensions of Remarks, and page
 * prefixes separate them: PgS is Senate, PgH House, PgE Extensions. Without this,
 * "Mr. SMITH" in a House granule is attributed to the senator of that name — and
 * SMITH, SCOTT, JOHNSON and YOUNG all sit in both chambers.
 */
export const isSenateGranule = (granuleId) => /-PgS/.test(String(granuleId));

/**
 * The granule id inside a Congressional Record citation, or null if the URL is not
 * one. Citations point at the public page, which is the same bytes a verifier
 * fetches:
 *   https://www.govinfo.gov/content/pkg/CREC-2024-05-22/html/CREC-2024-05-22-pt1-PgS3844.htm
 *
 * ⚠ MATCHED ON THE PATH, NOT ON THE WORD "CREC" ANYWHERE IN THE URL. A press
 * release that happens to link the Record, or a query string carrying the id, is
 * not a Record citation and must not be treated as one.
 */
export function crecGranuleId(url) {
  const m = /^https?:\/\/(?:www\.)?govinfo\.gov\/content\/pkg\/(CREC-\d{4}-\d{2}-\d{2})\/html\/(CREC-[\w.-]+)\.htm$/i
    .exec(String(url || '').trim());
  return m ? m[2] : null;
}

/**
 * Tag-stripped text that KEEPS LINE BREAKS.
 *
 * ⚠ THE NEWLINES ARE NOT COSMETIC. A turn opens at the start of a line, so the
 * whitespace-collapsing `rawOf` the verifier uses for claim terms destroys every
 * attribution boundary — run it after the split, never before.
 */
export const plainLines = (html) => String(html || '')
  .replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ')
  .replace(/<[^>]+>/g, ' ')
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&nbsp;|&#160;/g, ' ')
  .replace(/&#8217;|&rsquo;/g, "'")
  .replace(/&#8220;|&#8221;|&ldquo;|&rdquo;/g, '"')
  .replace(/&quot;/g, '"').replace(/&#39;/g, "'")
  .replace(/[ \t]+/g, ' ');

/** Every surname that speaks in a granule — the diagnostic when attribution fails. */
export const speakersIn = (text) => [...new Set(turns(text).map((t) => t.surname))];

/** Turns spoken by one member, with an on-axis flag. */
export function turnsBy(text, surname, axis = SPEECH_AXIS) {
  const want = String(surname).toUpperCase();
  return turns(text)
    .filter((t) => t.surname === want)
    .map((t) => ({
      ...t,
      onAxis: axis.test(t.body),
      asylumMentions: (t.body.match(/asylum/gi) || []).length,
    }));
}
