/**
 * writtenLedger — shared shape and pure helpers for the audit-chair-evidence ledger
 * (`<dir>/written-<batch>.json`), consumed by `node scripts/audit-chair-evidence.mjs --check`.
 *
 * Two producers, one shape:
 *   - verify-stance-research.ts --apply writes it for the rows IT wrote (auto-push).
 *   - export-written-ledger.ts writes it for a batch's RESOLVED review rows, after a person
 *     approved them in the admin queue — reading research.csv only to classify evidence_type,
 *     never to decide values (see that script's header).
 *
 * Global Constraint (docs/superpowers/plans/2026-09-23-stance-program-reconciliation.md):
 * "audit-chair-evidence --check runs on record rows only" — a statement row is the person's own
 * words and cannot name an instrument, act or vote by definition (NAMES_INSTRUMENT), so it is
 * never asked to; classifyResolvedRows below drops it rather than let it read as an unevidenced
 * record row.
 */

export interface LedgerRow {
  politician_id: string;
  topic_id: string;
  chair_after: number;
  season_id: string;
}

export interface LedgerFile {
  /**
   * Present when every row shares one season (the normal case — see CLAUDE.md "Migrations":
   * seasons_one_open). null when rows span more than one, in which case audit-chair-evidence.mjs
   * still reads the correct season off each row (`r.season_id ?? j.season_id ?? null`).
   */
  season_id: string | null;
  rows: LedgerRow[];
}

/** audit-chair-evidence.mjs's exact `--check` input shape: `{rows: [{politician_id, topic_id, chair_after, season_id}], season_id?}`. */
export function buildLedgerFile(rows: LedgerRow[]): LedgerFile {
  const seasonIds = new Set(rows.map((r) => r.season_id));
  return { season_id: seasonIds.size === 1 ? [...seasonIds][0] : null, rows };
}

/**
 * Which politicians a batch's `last_stances_researched_at` stamp should cover (C118): every CSV
 * name that resolved to a politician_id, deduped — including a name whose only stances.csv rows
 * were `value=null` ("insufficient evidence") or went to the review queue rather than being
 * written. A research timestamp with zero answers is legitimate; what matters is that the person
 * was researched this batch, not that a chair was seated for them.
 */
export function politicianIdsInBatch(
  names: Iterable<string>,
  idByName: ReadonlyMap<string, string | null>,
): string[] {
  const ids = new Set<string>();
  for (const name of names) {
    const id = idByName.get(name);
    if (id) ids.add(id);
  }
  return [...ids];
}

export interface ResearchCsvRow {
  full_name: string;
  topic_key: string;
  evidence_type: string;
}

/**
 * research.csv's evidence_type, keyed through the caller's normalizer (stanceKey in
 * src/lib/researchVerifier.js — the same one stance-gate.ts and verify-stance-research.ts key
 * on), so "Jo Smith" / "jo  smith" and "Healthcare" / "healthcare" land on one entry.
 */
export function evidenceTypeByKey(
  records: ResearchCsvRow[],
  keyOf: (_fullName: string, _topicKey: string) => string,
): Map<string, string> {
  const m = new Map<string, string>();
  for (const r of records) {
    if (!r.full_name.trim() || !r.topic_key.trim()) continue;
    m.set(keyOf(r.full_name, r.topic_key), r.evidence_type.trim());
  }
  return m;
}

export interface ResolvedReviewRow {
  full_name_raw: string;
  topic_key: string;
  politician_id: string | null;
  topic_id: string | null;
  season_id: string | null;
  /** The pair's ACTUAL written value (read from inform.politician_answers), not proposed_value —
   * a reviewer's valueOverride can differ from what was proposed. null = nothing written. */
  chair_after: number | null;
}

export interface ClassifyResult {
  included: LedgerRow[];
  /** One human-readable line per excluded row, so a caller can print and NOT silently drop rows. */
  excluded: string[];
}

/**
 * Record rows only. A row this function cannot classify — no matching research.csv row, or an
 * evidence_type that is neither `record` nor `statement` — is left OUT and reported, never
 * guessed into either lane (Requirement 2: "If a row cannot be classified, leave it out and list
 * it").
 */
export function classifyResolvedRows(
  rows: ResolvedReviewRow[],
  typeByKey: ReadonlyMap<string, string>,
  keyOf: (_fullName: string, _topicKey: string) => string,
): ClassifyResult {
  const included: LedgerRow[] = [];
  const excluded: string[] = [];
  for (const r of rows) {
    const label = `${r.full_name_raw} / ${r.topic_key}`;
    const evidenceType = typeByKey.get(keyOf(r.full_name_raw, r.topic_key));
    if (evidenceType === undefined) {
      excluded.push(`${label}: no matching research.csv row — cannot classify`);
      continue;
    }
    if (evidenceType === 'statement') {
      excluded.push(`${label}: statement evidence — excluded by design (cannot name an instrument)`);
      continue;
    }
    if (evidenceType !== 'record') {
      excluded.push(`${label}: unrecognized evidence_type "${evidenceType}"`);
      continue;
    }
    if (!r.politician_id || !r.topic_id) {
      excluded.push(`${label}: no politician_id/topic_id on the review row`);
      continue;
    }
    if (r.chair_after === null) {
      excluded.push(`${label}: no written value found in inform.politician_answers for this pair`);
      continue;
    }
    if (!r.season_id) {
      excluded.push(`${label}: no season_id resolvable for this pair`);
      continue;
    }
    included.push({
      politician_id: r.politician_id,
      topic_id: r.topic_id,
      chair_after: r.chair_after,
      season_id: r.season_id,
    });
  }
  return { included, excluded };
}
