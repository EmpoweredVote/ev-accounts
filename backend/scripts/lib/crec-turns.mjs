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

/**
 * Where a turn stops being SPEECH and becomes a printed document.
 *
 * 🔴 A SENATOR WHO ASKS THAT A BILL BE PRINTED IN THE RECORD "SPEAKS" THE WHOLE
 * BILL. Durbin's 2023-05-15 turn is 24,000 characters and almost all of it is the
 * text of S. 1600, because he asked unanimous consent to insert it. The attribution
 * is CORRECT — it is his bill and his request — and the turn is still not something
 * he said. Left alone, any bill text can masquerade as a floor statement: its words
 * sit inside his turn, so they pass the verifier's attribution check, and a chair
 * could be published on legislative language nobody spoke.
 *
 * The formula that opens the insert is fixed, which is what makes this cuttable.
 *
 * \u26a0 EVERY GAP IS `\\s+`, NOT A LITERAL SPACE. The Record wraps at about 72
 * columns, so any of these phrases can be split across a newline mid-sentence. A
 * first version used literal spaces and silently failed on the very granule that
 * motivated it — "the text of the bill was ordered to be printed" was wrapped, so
 * only the `be it enacted` alternative fired and the cut landed late.
 */
const PRINTED_TEXT =
  /there\s+being\s+no\s+objection[\s\S]{0,160}?ordered\s+to\s+be\s+printed\s+in\s+the\s+record|be\s+it\s+enacted\s+by\s+the\s+senate\s+and\s+house/i;

/**
 * The spoken part of a turn: everything before the first printed insert.
 *
 * Truncating rather than discarding keeps the real sentence — "I ask unanimous
 * consent that the text of the bill be printed" is preceded often enough by actual
 * argument to be worth keeping. Anything the member says AFTER the insert is lost,
 * which is the conservative direction: less evidence, never borrowed evidence.
 */
export function spokenPart(body) {
  const m = PRINTED_TEXT.exec(String(body || ''));
  return m ? String(body).slice(0, m.index) : String(body || '');
}

/** Does this turn carry a printed insert at all? */
export const hasPrintedText = (body) => PRINTED_TEXT.test(String(body || ''));

/**
 * Turns spoken by one member, with an on-axis flag.
 *
 * \u26a0 `body` IS THE SPOKEN PART, NOT THE RAW TURN, and the axis test runs on it.
 * A bill full of the word "asylum" inserted into the Record must not make its
 * sponsor look like they argued an asylum posture on the floor.
 */
export function turnsBy(text, surname, axis = SPEECH_AXIS) {
  const want = String(surname).toUpperCase();
  return turns(text)
    .filter((t) => t.surname === want)
    .map((t) => {
      const body = spokenPart(t.body);
      return {
        ...t,
        body,
        printedTextStripped: body.length !== t.body.length,
        onAxis: axis.test(body),
        asylumMentions: (body.match(/asylum/gi) || []).length,
      };
    });
}
