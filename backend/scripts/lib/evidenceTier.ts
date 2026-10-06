/**
 * evidenceTier — how much evidence stands behind a seated chair (codebook V6 "Evidence tier",
 * ruling 2026-10-06, Chris Andrews, option C). Computed from the coder row's `rests_on`, never coded.
 * Pure: no DB, no network.
 *
 *   corroborated  — at least two INDEPENDENT sources, each of which supports the chair on its own.
 *   single-source — a chair seated on anything less.
 *   null          — a blank. A tier never upgrades a blank.
 *
 * Every doubt resolves to "same source". Counting too many sources upgrades a chair in front of
 * voters, so the function errs toward `single-source`.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { instrumentKey, passageAllowsChair, type CoderRow, type Passage } from './coderLabel.js';

export const EVIDENCE_TIERS = ['corroborated', 'single-source'] as const;
export type EvidenceTier = typeof EVIDENCE_TIERS[number];

export interface EvidenceTierResult {
  tier: EvidenceTier | null;
  /** Independent source keys that stood on their own. Explains the tier; never shown to voters. */
  sources: string[];
}

const FULL_DAY = /^\d{4}-\d{2}-\d{2}$/;
/** Source kinds that are not the person's own page (source_snapshots.source_kind). */
const NOT_FIRST_PARTY = new Set(['news', 'pointer']);
/** Words in a shared run that make two pages "overlap" (one reprints the other). */
export const OVERLAP_WORDS = 8;

export interface TierContext {
  /** snapshot_id -> source_kind. Without it no statement is first-party, so same-day statements collapse. */
  sourceKind?: ReadonlyMap<string, string>;
  /** snapshot_id -> snapshot_text. Without it overlap cannot be ruled out, so same-day statements collapse. */
  snapshotText?: ReadonlyMap<string, string>;
}

function shingles(text: string): Set<string> {
  const words = normalizeText(text).toLowerCase().split(/\s+/).filter(Boolean);
  const out = new Set<string>();
  for (let i = 0; i + OVERLAP_WORDS <= words.length; i++) out.add(words.slice(i, i + OVERLAP_WORDS).join(' '));
  return out;
}
/** True when the two snapshots share a run of OVERLAP_WORDS words, or when either text is unknown. */
export function textsOverlap(a: string | undefined, b: string | undefined): boolean {
  if (a === undefined || b === undefined) return true;
  const sa = shingles(a);
  const sb = shingles(b);
  // A text shorter than one run has no shingles: fall back to containment, so two identical short
  // texts still overlap.
  if (sa.size === 0 || sb.size === 0) {
    const na = normalizeText(a).toLowerCase(), nb = normalizeText(b).toLowerCase();
    return na.trim() === '' || nb.trim() === '' || na.includes(nb) || nb.includes(na);
  }
  for (const g of sb) if (sa.has(g)) return true;
  return false;
}

/** A passage supports the chair on its own: V1–V5 allow it, and a vote passes the V4.1 ladder. */
function standsAlone(p: Passage): boolean {
  if (!passageAllowsChair(p)) return false;
  // V4.1: a vote proves a chair only on a single-subject bill, an amendment or a divided question.
  // A multi-subject, procedural or near-unanimous vote has a different V4 shape, and
  // passageAllowsChair already refused it. A vote with no tally is not a vote (codebook V4.1).
  if (p.v3_class === 'record' && p.record_kind === 'vote' && !p.tally_quote?.trim()) return false;
  return true;
}

/**
 * The independence key of a passage. Two passages with one key are one source.
 *  - Record passages: one instrument is one source (V3 instrument group). No instrument → one shared
 *    key, because independence cannot be shown.
 *  - Statements: one occasion is one source (principle 6 — two reports of one statement). Grouped by
 *    full date. Within one day (ruling 2026-10-06) a statement is a separate occasion only if it is
 *    first-party (not news/pointer), on its own snapshot, and its text does not overlap another
 *    first-party statement's that day. News that day joins an existing occasion and adds none. A
 *    coarse or missing date cannot show a different occasion, so it joins a full-date occasion it
 *    could contain, else the shared undated key.
 *  - 🔴 owed (codebook): a person's own explanation of a vote. Until ruled it is the same act, so a
 *    statement that names the instrument of a record in the row joins that record's key.
 */
function sourceKeys(passages: Passage[], ctx: TierContext): Map<string, string> {
  const recordInstruments = new Set(
    passages.filter((p) => p.v3_class === 'record').map((p) => instrumentKey(p.instrument) ?? '∅'),
  );
  const keys = new Map<string, string>();
  const byDay = new Map<string, Passage[]>();
  const coarse: Passage[] = [];
  for (const p of passages) {
    const instr = instrumentKey(p.instrument);
    if (p.v3_class === 'record') { keys.set(p.snapshot_id, `instrument:${instr ?? '∅'}`); continue; }
    if (instr !== null && recordInstruments.has(instr)) { keys.set(p.snapshot_id, `instrument:${instr}`); continue; }
    if (p.date !== null && FULL_DAY.test(p.date)) byDay.set(p.date, [...(byDay.get(p.date) ?? []), p]);
    else coarse.push(p);
  }
  for (const [day, ps] of byDay) {
    const firstParty = (p: Passage) => {
      const kind = ctx.sourceKind?.get(p.snapshot_id);
      return kind !== undefined && !NOT_FIRST_PARTY.has(kind);
    };
    // Occasions are first-party snapshots; each joins the first earlier occasion it overlaps.
    const occasions: { key: string; snapshot: string }[] = [];
    for (const p of ps.filter(firstParty)) {
      const same = occasions.find((o) => o.snapshot === p.snapshot_id
        || textsOverlap(ctx.snapshotText?.get(o.snapshot), ctx.snapshotText?.get(p.snapshot_id)));
      if (same) { keys.set(p.snapshot_id, same.key); continue; }
      const key = `occasion:${day}#${occasions.length + 1}`;
      occasions.push({ key, snapshot: p.snapshot_id });
      keys.set(p.snapshot_id, key);
    }
    // News, pointers and unknown kinds add no occasion: they join the day's first one.
    for (const p of ps.filter((x) => !firstParty(x))) keys.set(p.snapshot_id, occasions[0]?.key ?? `occasion:${day}#1`);
  }
  for (const p of coarse) {
    const day = p.date === null ? undefined : [...byDay.keys()].sort().find((d) => d.startsWith(p.date as string));
    keys.set(p.snapshot_id, day ? keys.get(byDay.get(day)![0].snapshot_id)! : 'occasion:undetermined');
  }
  return keys;
}

/**
 * @param restsOnIds  restrict to these snapshot ids (the sources every coder shares — what is
 *                    published). Defaults to the row's own `rests_on`.
 */
export function evidenceTier(
  row: Pick<CoderRow, 'passages' | 'rests_on' | 'v6_value'>,
  restsOnIds?: readonly string[],
  ctx: TierContext = {},
): EvidenceTierResult {
  if (row.v6_value === null || row.v6_value === undefined) return { tier: null, sources: [] };
  const ids = new Set(restsOnIds ?? row.rests_on);
  const cited = row.passages.filter((p) => ids.has(p.snapshot_id) && standsAlone(p));
  const keyOf = sourceKeys(row.passages, ctx);
  const sources = [...new Set(cited.map((p) => keyOf.get(p.snapshot_id) as string))].sort();
  return { tier: sources.length >= 2 ? 'corroborated' : 'single-source', sources };
}
