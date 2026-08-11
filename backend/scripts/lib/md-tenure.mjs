/**
 * Maryland legislator tenure + chamber, parsed from the STRUCTURED "Tenure" field on an mgaleg member page.
 *
 * 🔴 WHY THIS MODULE EXISTS. The first attempt regexed the whole page text for /(Senate|House of Delegates)[^.]*\./
 * and captured NAV MENUS, OFFICE ADDRESSES and HEARING NOTICES ("Senate - Hearing 4/09 at 2:30 p."). That
 * produced junk service spans, "chamber undetermined" for every row, and — worse — a tenure screen whose
 * PRE_TENURE verdicts were built on noise. Read the labelled `<dt>Tenure</dt>` field, nothing else.
 *
 * Shared by md-pass5-tenure-screen.mjs and md-pass5-rollcall.mjs so the two cannot drift.
 *
 * Observed field shapes (all handled):
 *   "Member of the Maryland House of Delegates December 19, 2012 to January 30, 2023. Member of the
 *    Maryland Senate since January 30, 2023"
 *   "First elected to the Maryland Senate in 2018. Member of the Senate since January 9, 2019. Member of
 *    the House of Delegates 2011-2019."
 *   "First elected to the Maryland House of Delegates, 1998. Member of the House since 1997: appointed …"
 *   "Elected to the Maryland House of Delegates in November 2022. Member of the House of Delegates since
 *    January 11, 2023."
 *
 * ⚠ "First elected"/"Elected" sentences give an ELECTION year, which is not service — a member elected in
 *   November 2022 is not seated until January 2023. They are used only as a last-resort fallback.
 */
import { parse } from 'node-html-parser';

export function tenureText(html) {
  const root = parse(html);
  for (const dt of root.querySelectorAll('dt')) {
    if (/^\s*tenure\s*$/i.test(dt.text)) {
      const dd = dt.nextElementSibling;
      if (dd) return dd.text.replace(/\s+/g, ' ').trim();
    }
  }
  // fallback: the sentence itself, wherever it sits
  for (const el of root.querySelectorAll('dd,p,div,span')) {
    const t = el.text.replace(/\s+/g, ' ').trim();
    if (/^(First elected|Elected|Member of the)/i.test(t) && t.length < 500 && /House|Senate/.test(t)) return t;
  }
  return null;
}

const chamberOf = (s) => (/House/i.test(s) ? 'house' : /Senate/i.test(s) ? 'senate' : null);

/** [{chamber, from, to}] — `to` is 9999 for "since". */
export function chamberSpans(tenure) {
  if (!tenure) return [];
  const spans = [];
  for (const sentence of tenure.split(/(?<=\.)\s+/)) {
    const s = sentence.trim();
    if (!s) continue;
    if (!/^Member of the/i.test(s)) continue;          // skip "First elected …"/"Elected …"
    const ch = chamberOf(s);
    if (!ch) continue;
    const years = [...s.matchAll(/\b(19|20)\d{2}\b/g)].map((m) => parseInt(m[0], 10));
    if (!years.length) continue;
    if (/\bsince\b/i.test(s)) spans.push({ chamber: ch, from: Math.min(...years), to: 9999, src: s });
    else spans.push({ chamber: ch, from: Math.min(...years), to: Math.max(...years), src: s });
  }
  return spans;
}

/** Election-year fallback, clearly marked so callers can treat it as weaker. */
export function electionYear(tenure) {
  if (!tenure) return null;
  const m = tenure.match(/(?:First elected|Elected)[^.]*?\b((?:19|20)\d{2})\b/i);
  return m ? parseInt(m[1], 10) : null;
}

export function serviceStart(spans, tenure = null) {
  if (spans.length) return Math.min(...spans.map((s) => s.from));
  const e = electionYear(tenure);
  return e == null ? null : e + 1;   // elected in November, seated the following January
}

/**
 * Which chamber the member sat in during `year`; null when it cannot be decided.
 *
 * ⚠ A CHAMBER SWITCH MAKES ONE YEAR LOOK AMBIGUOUS. Kramer is "Senate since January 9, 2019" AND
 * "House of Delegates 2007-2019", so 2019 matches both spans. Maryland's regular session runs
 * January-April and members are sworn in the second Wednesday of January, so a session in the year
 * someone MOVED belongs to the chamber they moved INTO. Prefer the span that STARTS in that year.
 * If that still does not single one out, return null -- never guess a chamber, because surnames collide
 * across chambers (Alonzo Washington in the House, Mary Washington in the Senate, same session).
 */
export function chamberFor(spans, year) {
  const inYear = spans.filter((s) => year >= s.from && year <= s.to);
  const chambers = [...new Set(inYear.map((s) => s.chamber))];
  if (chambers.length === 1) return chambers[0];
  if (chambers.length > 1) {
    const starting = [...new Set(inYear.filter((s) => s.from === year).map((s) => s.chamber))];
    if (starting.length === 1) return starting[0];
  }
  return null;
}
