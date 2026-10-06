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
import { instrumentKey, passageAllowsChair, type CoderRow, type Passage } from './coderLabel.js';

export const EVIDENCE_TIERS = ['corroborated', 'single-source'] as const;
export type EvidenceTier = typeof EVIDENCE_TIERS[number];

export interface EvidenceTierResult {
  tier: EvidenceTier | null;
  /** Independent source keys that stood on their own. Explains the tier; never shown to voters. */
  sources: string[];
}

const FULL_DAY = /^\d{4}-\d{2}-\d{2}$/;

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
 *  - Statements: one occasion is one source (principle 6 — two reports of one statement). The key is
 *    the full date. A coarse or missing date cannot show a different occasion, so it joins a full-date
 *    statement it could contain, else the shared undated key.
 *  - 🔴 owed (codebook): a person's own explanation of a vote. Until ruled it is the same act, so a
 *    statement that names the instrument of a record in the row joins that record's key.
 */
function sourceKeys(passages: Passage[]): Map<string, string> {
  const recordInstruments = new Set(
    passages.filter((p) => p.v3_class === 'record').map((p) => instrumentKey(p.instrument) ?? '∅'),
  );
  const fullDates = passages
    .filter((p) => p.v3_class !== 'record' && p.date !== null && FULL_DAY.test(p.date))
    .map((p) => p.date as string);
  const keys = new Map<string, string>();
  for (const p of passages) {
    const instr = instrumentKey(p.instrument);
    if (p.v3_class === 'record') { keys.set(p.snapshot_id, `instrument:${instr ?? '∅'}`); continue; }
    if (instr !== null && recordInstruments.has(instr)) { keys.set(p.snapshot_id, `instrument:${instr}`); continue; }
    if (p.date !== null && FULL_DAY.test(p.date)) { keys.set(p.snapshot_id, `occasion:${p.date}`); continue; }
    const contained = p.date === null ? undefined : fullDates.find((d) => d.startsWith(p.date as string));
    keys.set(p.snapshot_id, contained ? `occasion:${contained}` : 'occasion:undetermined');
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
): EvidenceTierResult {
  if (row.v6_value === null || row.v6_value === undefined) return { tier: null, sources: [] };
  const ids = new Set(restsOnIds ?? row.rests_on);
  const cited = row.passages.filter((p) => ids.has(p.snapshot_id) && standsAlone(p));
  const keyOf = sourceKeys(row.passages);
  const sources = [...new Set(cited.map((p) => keyOf.get(p.snapshot_id) as string))].sort();
  return { tier: sources.length >= 2 ? 'corroborated' : 'single-source', sources };
}
