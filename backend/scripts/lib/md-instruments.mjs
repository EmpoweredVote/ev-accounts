/**
 * Named-instrument extraction + corpus lookup for the Maryland stance-sourcing workstream.
 *
 * PROVENANCE: copied VERBATIM from scripts/md-pass4-instrument-worklist.mjs (migs 1685-1687).
 * That script is shipped and its outputs are recorded in data/stance-retirement/, so it is left
 * untouched; this module is the single home for the logic going forward.
 *
 * ⚠ DO NOT "improve" the extractor without re-reading the residue. It has already been through two
 * rounds of manufacturing FAKE findings, neither of them real defects in the data:
 *   1. A leading verb rode along  -> "Sponsored ICE Breaker Act"
 *   2. Stripping verbs let leading CONNECTORS ride -> "for the Climate Solutions Now Act"
 * Unresolved went 15 -> 30 -> 10. A raw `[A-Z][A-Za-z]+ ... Act` regex reproduces the truncation
 * artifacts "Maryland Act" and "Opportunity Act"; this version does not. Never report an extractor
 * artifact as a finding.
 */

const LEAD_NOISE = new Set(['sponsored', 'cosponsored', 'co', 'supported', 'backed', 'championed',
  'introduced', 'passed', 'voted', 'vote', 'votes', 'and', 'both', 'the', 'also', 'a', 'an',
  'his', 'her', 'their', 'yes', 'no', 'for', 'of', 'from', 'with', 'in', 'on', 'to', 'against']);
const CONNECTORS = 'for|from|of|the|and|in|to|on|with';

export function extractInstruments(text) {
  const out = new Set();
  for (const m of text.matchAll(/\b([SH]B)\s*0*(\d{1,4})\b/gi)) out.add(`${m[1].toUpperCase()}${m[2].padStart(4, '0')}`);

  const word = `(?:[A-Z][A-Za-z’'()]+|${CONNECTORS})`;
  const re = new RegExp(`\\b(${word}(?:\\s+${word}){0,8}\\s+Act)\\b`, 'g');
  for (const m of text.matchAll(re)) {
    let toks = m[1].split(/\s+/);
    while (toks.length > 1 && LEAD_NOISE.has(toks[0].toLowerCase().replace(/[^a-z]/g, ''))) toks.shift();
    const name = toks.join(' ');
    if (toks.length >= 2 && !new RegExp(`^(?:${CONNECTORS})\\s+Act$`, 'i').test(name)) out.add(name);
  }
  if (/blueprint for maryland/i.test(text)) out.add("Blueprint for Maryland's Future");
  return [...out];
}

export const norm = (s) => s.toLowerCase().replace(/[‘’']/g, '').replace(/[^a-z0-9 ]+/g, ' ')
  .replace(/\bmarylands?\b/g, ' ').replace(/\bof \d{4}\b/g, ' ').replace(/\s+/g, ' ').trim();

export function buildIndex(bills) {
  return bills.map((b) => ({ ...b, n: norm(b.title) }));
}

/**
 * Resolve an act NAME against the corpus.
 *
 * ⚠ FOUND_LOOSE is a token-subset match and it HAS landed on the wrong statute before:
 * "CROWN Act" -> "Crown and Care Act", "Fair Housing Act" -> "Fair Chance in Housing Act" (mig 1686).
 * Treat FOUND_LOOSE as a candidate for a human, never as a resolution.
 *
 * ⚠ A hit list spanning MULTIPLE SESSIONS is ambiguous, not resolved. The Climate Solutions Now Act
 * exists in 2021 AND 2022; the Maryland Voting Rights Act in 2024, 2025 AND 2026; the Juvenile
 * Justice Restoration Act in 2024 AND 2025. Callers must gate on the year the prose states.
 */
export function lookupAct(act, idx, _depth = 0) {
  const a = norm(act);
  if (a.length < 6) return { verdict: 'TOO_SHORT', hits: [] };
  let hits = idx.filter((b) => b.n.includes(a));
  let verdict = hits.length ? 'FOUND' : null;
  if (!hits.length) {
    const toks = a.split(' ').filter((t) => t.length > 2);
    if (toks.length >= 2) { hits = idx.filter((b) => toks.every((t) => b.n.includes(t))); if (hits.length) verdict = 'FOUND_LOOSE'; }
  }
  // ⚠ EXTRACTOR BUG, ROUND 3 (found 2026-08-11, pass 6). Maryland bill titles are long and
  // hyphen-segmented, so prose routinely names TWO instruments joined by "and" -- and the capture
  // welds them into one name that can never resolve:
  //   "Juvenile Justice Restoration Act and Juvenile Offender Protection Act"  (two real acts)
  //   "Savings Account Program and the Opting in on Opportunity Act"           (two real things)
  // That manufactured 7 of 15 "unresolved" rows -- fake findings, exactly like rounds 1 and 2.
  // 🔑 The split is a FALLBACK ONLY, applied after the whole name has already failed, because real
  // statutes DO contain "and": "Crown and Care Act", "Body-Worn Cameras, Employee Programs, and
  // Use of Force". Splitting first would break matches that work; splitting last cannot.
  if (!verdict && _depth === 0 && /\band\b/.test(a)) {
    const parts = act.split(/\s+and\s+(?:the\s+)?/i).filter((p) => norm(p).length >= 6);
    if (parts.length > 1) {
      const sub = parts.map((p) => ({ part: p, ...lookupAct(p, idx, 1) }));
      const good = sub.filter((s) => s.verdict === 'FOUND' || s.verdict === 'FOUND_LOOSE');
      if (good.length) {
        return {
          verdict: 'FOUND_CONJUNCTION',
          conjunction_parts: sub.map((s) => ({ part: s.part, verdict: s.verdict, hits: s.hits })),
          ambiguous_sessions: null,
          hits: good.flatMap((s) => s.hits).slice(0, 8),
        };
      }
    }
  }
  if (!verdict) verdict = 'NOT_IN_CORPUS';
  const uniq = [...new Map(hits.map((h) => [h.number + h.session, h])).values()];
  const sessions = [...new Set(uniq.map((h) => h.session))];
  return { verdict, ambiguous_sessions: sessions.length > 1 ? sessions : null, hits: uniq.slice(0, 8) };
}

/** Years stated anywhere in the prose -- the gate that mig 1690 showed is mandatory. */
export function statedYears(text) {
  return [...new Set([...text.matchAll(/\b(20[0-2]\d)\b/g)].map((m) => m[1]))];
}

/**
 * Which test can settle this claim? mig 1690's rule: a sponsor list cannot settle a floor vote.
 * "sponsored"/"co-sponsored"/"introduced" -> SPONSORSHIP
 * "supported"/"backed"/"voted"/"championed" -> ROLLCALL (sponsorship is corroborating, not decisive)
 */
export function claimVerb(text, instrument) {
  const i = instrument ? text.toLowerCase().indexOf(instrument.toLowerCase().slice(0, 24)) : -1;
  // Score only the clause GOVERNING the instrument, with '.' as a boundary (mig 1694 lesson:
  // a 90-char window manufactured 8 fake contradictions by crossing into a second clause).
  let clause = text;
  if (i > -1) {
    const start = Math.max(0, text.lastIndexOf('.', i) + 1);
    const endDot = text.indexOf('.', i);
    clause = text.slice(start, endDot === -1 ? text.length : endDot);
  }
  const c = clause.toLowerCase();
  if (/\b(co-?sponsored|sponsored|introduced|authored|lead sponsor)\b/.test(c)) return 'SPONSORSHIP';
  if (/\b(voted|vote|supported|backed|championed|opposed|led)\b/.test(c)) return 'ROLLCALL';
  return 'UNKNOWN';
}
