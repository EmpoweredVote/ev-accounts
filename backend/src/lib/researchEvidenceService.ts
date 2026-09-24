/**
 * researchEvidenceService — helpers for the stance research verification pipeline.
 * Pure data-shaping functions (buildEvidenceRowsForInsert, buildReviewRowForInsert)
 * plus DB-executing functions (accumulateEvidence, upsertReviewRow).
 */

import type { VerifiedRow } from './researchVerifier.js';
// Type-only: erased at runtime, so it does not pull db.js in before a test's mock (see below).
import type { Queryable } from './seasonService.js';

export interface EvidenceInsertRow {
  politician_id: string;
  topic_id: string;
  source_url: string;
  snippet: string;
  snippet_index: number;
  batch_id: string;
}

export interface ReviewInsertRow {
  batch_id: string;
  politician_id: string | null;
  full_name_raw: string;
  topic_id: string | null;
  topic_key: string;
  proposed_value: number | null;
  proposed_reasoning: string;
  evidence: unknown;
  verified_source_count: number;
  threshold: number;
  status: 'pending' | 'unresolved_politician';
  re_research_attempted: boolean;
  /**
   * The ladder revision (bundle topics.json topic_revision_id) this row was researched against,
   * and the season open at queue time (CA_0264). null = not known — approval then allows the row
   * but flags it as "ladder revision unknown".
   */
  topic_revision_id: string | null;
  season_id: string | null;
}

export function buildEvidenceRowsForInsert(args: {
  row: VerifiedRow;
  politicianId: string;
  topicId: string;
  batchId: string;
}): EvidenceInsertRow[] {
  const out: EvidenceInsertRow[] = [];
  for (const src of args.row.verifiedSources) {
    for (const snip of src.snippets) {
      if (snip.verdict.verdict === 'verified') {
        out.push({
          politician_id: args.politicianId,
          topic_id: args.topicId,
          source_url: src.url,
          snippet: snip.snippet,
          snippet_index: snip.snippet_index,
          batch_id: args.batchId,
        });
      }
    }
  }
  return out;
}

function snippetsForJsonb(verifiedSources: VerifiedRow['verifiedSources'], failedSources: VerifiedRow['failedSources']) {
  const all = [...verifiedSources, ...failedSources];
  return all.map((s) => ({
    url: s.url,
    snippets: s.snippets.map((snip) => ({
      snippet_index: snip.snippet_index,
      snippet: snip.snippet,
      verdict: snip.verdict.verdict,
      reason:
        snip.verdict.verdict === 'url_broken' || snip.verdict.verdict === 'robots_disallowed'
          ? snip.verdict.reason
          : undefined,
    })),
  }));
}

export function buildReviewRowForInsert(args: {
  row: VerifiedRow;
  politicianId: string | null;
  topicId: string | null;
  batchId: string;
  threshold: number;
  reResearchAttempted: boolean;
  /** The bundle's topic_revision_id for this row's topic (topics.json). */
  topicRevisionId?: string | null;
  /** The open season's id at queue time. */
  seasonId?: string | null;
}): ReviewInsertRow {
  return {
    batch_id: args.batchId,
    politician_id: args.politicianId,
    full_name_raw: args.row.stance.full_name,
    topic_id: args.topicId,
    topic_key: args.row.stance.topic_key,
    proposed_value: args.row.stance.value,
    proposed_reasoning: args.row.stance.reasoning,
    evidence: snippetsForJsonb(args.row.verifiedSources, args.row.failedSources),
    verified_source_count: args.row.verifiedSources.length,
    threshold: args.threshold,
    status: args.politicianId === null ? 'unresolved_politician' : 'pending',
    re_research_attempted: args.reResearchAttempted,
    topic_revision_id: args.topicRevisionId ?? null,
    season_id: args.seasonId ?? null,
  };
}

/**
 * Accumulate evidence for a (politician, topic) — upserts each snippet, deduped
 * by the unique index on (politician_id, topic_id, source_url, snippet_index).
 * Never deletes existing rows; safe to re-run with the same or updated batches.
 *
 * Returns the number of rows ACTUALLY inserted (sum of rowCount), which can be fewer than
 * `rows.length`: that unique index has no season column, so a snippet already stored for the
 * pair (from any earlier batch or season) is skipped by ON CONFLICT DO NOTHING.
 *
 * Pass `db` (a transaction client) to write inside the caller's transaction; defaults to pool.
 */
export async function accumulateEvidence(rows: EvidenceInsertRow[], db?: Queryable): Promise<number> {
  if (rows.length === 0) return 0;
  // Imported lazily alongside pool, NOT at module scope. This module is loaded
  // by tests that mock './db.js', and a static import of seasonService pulls
  // db.js in before the mock is installed — which broke collection of
  // researchEvidenceService.test.ts the first time this predicate was added.
  const runner: Queryable = db ?? (await import('./db.js')).pool;
  const { SEASON_IS_PUBLISHED } = await import('./seasonService.js');
  let inserted = 0;
  for (const r of rows) {
    const res = await runner.query(
      // season_id comes from the context row this evidence supports. The FK from
      // evidence to context has always required that row to exist, so this
      // subselect cannot come up empty for a row that would have inserted before.
      // Newest season, so evidence attaches to the current reading of the topic.
      `INSERT INTO inform.politician_context_evidence
         (politician_id, topic_id, season_id, source_url, snippet, snippet_index, batch_id)
       SELECT $1, $2, c.season_id, $3, $4, $5, $6
         FROM inform.politician_context c
         JOIN inform.seasons s ON s.id = c.season_id AND ${SEASON_IS_PUBLISHED}
        WHERE c.politician_id = $1 AND c.topic_id = $2
        ORDER BY s.number DESC
        LIMIT 1
       ON CONFLICT (politician_id, topic_id, source_url, snippet_index) DO NOTHING`,
      [r.politician_id, r.topic_id, r.source_url, r.snippet, r.snippet_index, r.batch_id],
    );
    inserted += res.rowCount ?? 0;
  }
  return inserted;
}

// ── Read / resolve helpers (used by admin review UI) ─────────────────────────

export interface ResearchReviewRow {
  id: string;
  batchId: string;
  politicianId: string | null;
  fullNameRaw: string;
  topicId: string | null;
  topicKey: string;
  proposedValue: number | null;
  proposedReasoning: string;
  evidence: Array<{
    url: string;
    snippets: Array<{
      snippet_index: number;
      snippet: string;
      verdict: string;
      reason?: string;
    }>;
  }>;
  verifiedSourceCount: number;
  threshold: number;
  status: string;
  reResearchAttempted: boolean;
  createdAt: string;
  /**
   * The pair's value in the OPEN season — what approving this row would replace. null = none.
   * A 0 is an editor's blank and is returned as 0, not hidden (see CURRENT_VALUE_SQL).
   */
  currentValue: number | null;
  /** The ladder revision the row was researched against (CA_0264). null = unknown (legacy row). */
  topicRevisionId: string | null;
  /** The season open when the row was queued (CA_0264). null = unknown (legacy row). */
  seasonId: string | null;
  /** The open season's CURRENT pin for this topic. null = no open season, or it no longer asks the topic. */
  openTopicRevisionId: string | null;
  /**
   * true = the row was queued before CA_0264 stored a revision, so nobody can say which ladder it
   * answers. Approval is allowed; the page says "ladder revision unknown (queued before 2026-09-24)".
   */
  ladderRevisionUnknown: boolean;
  /**
   * true = the row's revision is known and is NOT the open season's current pin. Approval refuses
   * it (CONFLICT): the value answers a sentence the open season no longer asks.
   */
  ladderChanged: boolean;
}

/** The refusal message for a row whose ladder was re-pinned after it was researched. */
export const LADDER_CHANGED_MESSAGE = 'the ladder changed since this row was researched — re-research it';

/**
 * The (politician, topic) pair's stored value in the open season, as a scalar subselect on
 * `r` (inform.stance_research_review). At most one row: one open season (seasons_one_open) and
 * one answer per (politician, topic, season).
 */
const CURRENT_VALUE_SQL = `
  -- @zero-scope: counts-blanks — the reviewer must see that an editor blanked this row.
  (SELECT a.value
     FROM inform.politician_answers a
     JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
    WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id) AS current_value`;

/**
 * The open season's CURRENT pin for the row's topic, as a scalar subselect on `r`. At most one
 * row: one open season, and season_questions' PRIMARY KEY (season_id, topic_id).
 *
 * Deliberately names NO CA_0264 column: the row's own topic_revision_id / season_id come through
 * `r.*`, so these reads work unchanged before that migration is applied (they read as undefined,
 * mapped to null = "unknown").
 */
const OPEN_PIN_SQL = `
  (SELECT sq.topic_revision_id::text
     FROM inform.season_questions sq
     JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
    WHERE sq.topic_id = r.topic_id) AS open_topic_revision_id`;

const nullable = (v: unknown): string | null => (v === null || v === undefined ? null : String(v));

function mapReviewRow(row: any): ResearchReviewRow {
  return {
    id: row.id,
    batchId: row.batch_id,
    politicianId: row.politician_id,
    fullNameRaw: row.full_name_raw,
    topicId: row.topic_id,
    topicKey: row.topic_key,
    proposedValue: row.proposed_value,
    proposedReasoning: row.proposed_reasoning,
    evidence: row.evidence ?? [],
    verifiedSourceCount: row.verified_source_count,
    threshold: row.threshold,
    status: row.status,
    reResearchAttempted: row.re_research_attempted,
    createdAt: row.created_at,
    // numeric comes back from pg as a string.
    currentValue: row.current_value === null || row.current_value === undefined ? null : Number(row.current_value),
    ...ladderState(nullable(row.topic_revision_id), nullable(row.open_topic_revision_id)),
    seasonId: nullable(row.season_id),
  };
}

/**
 * The row's ladder against the open season's pin. Pure, so the three cases are testable alone:
 *   known + equal     → approvable;
 *   known + different → ladderChanged (includes "the open season no longer asks this topic");
 *   unknown (null)    → ladderRevisionUnknown, approvable with the flag shown.
 */
export function ladderState(topicRevisionId: string | null, openTopicRevisionId: string | null) {
  return {
    topicRevisionId,
    openTopicRevisionId,
    ladderRevisionUnknown: topicRevisionId === null,
    ladderChanged: topicRevisionId !== null && topicRevisionId !== openTopicRevisionId,
  };
}

export async function listPendingResearchReview(): Promise<ResearchReviewRow[]> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT r.*, ${CURRENT_VALUE_SQL}, ${OPEN_PIN_SQL}
       FROM inform.stance_research_review r
      WHERE r.status = 'pending'
      ORDER BY r.full_name_raw, r.topic_key`,
  );
  return rows.map(mapReviewRow);
}

export async function getResearchReviewById(id: string): Promise<ResearchReviewRow | null> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT r.*, ${CURRENT_VALUE_SQL}, ${OPEN_PIN_SQL}
       FROM inform.stance_research_review r
      WHERE r.id = $1`,
    [id],
  );
  return rows[0] ? mapReviewRow(rows[0]) : null;
}

/**
 * Write one stance (answer + its public "why") into the OPEN season. The only stance write path
 * for research: verify-stance-research --apply and the review queue both call this.
 * Answer and context are written together on purpose — reasoning must never lag the value.
 * Throws if the open season wrote nothing (no open season, or topic not in its question set).
 *
 * Pass `db` (a transaction client) so the answer, the context and the caller's evidence commit
 * or roll back together; defaults to pool. Without a transaction a failure after the answer
 * write leaves a value with no reasoning — and nothing re-runs it (I6).
 */
export async function writeVerifiedStance(args: {
  politicianId: string; topicId: string; value: number; reasoning: string; sources: string[]; editorId: string | null;
}, db?: Queryable): Promise<void> {
  // Dynamic imports: a static import pulls db.js in before this file's tests install their mock.
  const runner: Queryable = db ?? (await import('./db.js')).pool;
  const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, assertWritten } = await import('./seasonService.js');
  const ans = await runner.query(UPSERT_ANSWER_SQL, [args.politicianId, args.topicId, args.value, args.editorId]);
  await assertWritten(ans.rowCount ?? 0, args.topicId);
  const ctx = await runner.query(UPSERT_CONTEXT_SQL,
    [args.politicianId, args.topicId, args.reasoning, args.sources, args.editorId]);
  await assertWritten(ctx.rowCount ?? 0, args.topicId);
}

/**
 * Approval input validation (2026-09-23 polish pass), defence in depth: the route already
 * rejects a shape it doesn't like with a 400, but this function is also reachable directly (a
 * script, a future caller), so a blank/whitespace entry (`['']`) or a non-http(s) string
 * (mailto:, javascript:, a bare word) must not slip through and count as a citation below. Keeps
 * only entries that parse as an http: or https: URL.
 */
function cleanHumanVerifiedUrls(urls: string[]): string[] {
  return urls
    .map((u) => u.trim())
    .filter((u) => u.length > 0)
    .filter((u) => {
      try {
        const parsed = new URL(u);
        return parsed.protocol === 'http:' || parsed.protocol === 'https:';
      } catch {
        return false;
      }
    });
}

/**
 * Approve a queued review row: write its stance, then its machine-verified citations, then any
 * human-verified URLs, then mark it resolved.
 *
 * Citations are written HERE, on approval, not when the row was queued (ruling 2026-09-22, R1)
 * — verify-stance-research.ts's queue loop stores every snippet with its verdict in the review
 * row's `evidence` jsonb and stops there. Writing them at queue time would render a snippet for
 * a still-PROPOSED value under whatever stance is displayed right now (getPoliticianCitations
 * has no batch filter), which for a `value-change` row is a different chair than the one being
 * proposed, and for a pair whose only context row predates this season lands on a closed one.
 *
 * Refuses (code CONFLICT → 409) a row that is not `pending` — an approval must never rewrite a
 * row somebody already resolved or rejected — and (code INCOMPLETE → 422) a row with no
 * machine-verified and no human-verified source: a stance cannot be published without a citation.
 *
 * The stance write, both evidence writes and the status UPDATE run in ONE transaction on one
 * client (I6): either the row is approved with its value, reasoning and citations, or nothing is
 * written and it stays pending.
 *
 * Also refuses (CONFLICT → 409, LADDER_CHANGED_MESSAGE) a row whose stored ladder revision is known
 * and is not the open season's current pin for the topic (CA_0264): the proposed value answers a
 * sentence the open season no longer asks. A legacy row (revision NULL, queued before CA_0264) is
 * allowed, and the result says so (`ladderRevisionUnknown`) so the caller can show it.
 */
export async function resolveResearchReview(
  id: string,
  resolvedBy: string,
  humanVerifiedUrls: string[] = [],
  valueOverride?: number | null,
  reasoningOverride?: string,
): Promise<{ ladderRevisionUnknown: boolean }> {
  // Lazy, for the same reason as accumulateEvidence above: a static import of
  // seasonService drags db.js in before the test mock is installed.
  const { pool } = await import('./db.js');
  const { SEASON_IS_PUBLISHED } = await import('./seasonService.js');
  const row = await getResearchReviewById(id);
  if (!row) throw Object.assign(new Error('Not found'), { code: 'NOT_FOUND' });
  if (row.status !== 'pending') {
    throw Object.assign(
      new Error(`Review row is ${row.status}, not pending — only a pending row can be approved`),
      { code: 'CONFLICT' });
  }
  if (row.ladderChanged) {
    throw Object.assign(new Error(LADDER_CHANGED_MESSAGE), { code: 'CONFLICT' });
  }

  // Same defence-in-depth reasoning as cleanHumanVerifiedUrls above: the route already rejects a
  // non-integer or out-of-range valueOverride with a 400, but a direct caller could still pass one.
  if (valueOverride !== undefined && valueOverride !== null
    && (!Number.isInteger(valueOverride) || valueOverride < 1 || valueOverride > 5)) {
    throw Object.assign(new Error('valueOverride must be an integer 1-5'), { code: 'INCOMPLETE' });
  }

  const finalValue = valueOverride !== undefined && valueOverride !== null ? valueOverride : row.proposedValue;
  const finalReasoning = reasoningOverride || row.proposedReasoning;

  if (!row.politicianId || !row.topicId || finalValue === null) {
    throw Object.assign(new Error('Row is missing politician_id, topic_id, or value'), { code: 'INCOMPLETE' });
  }

  const cleanedHumanVerifiedUrls = cleanHumanVerifiedUrls(humanVerifiedUrls);

  // All sources to attach: machine-verified + human-verified (deduped)
  const machineVerifiedUrls = row.evidence
    .filter((e) => e.snippets.some((s) => s.verdict === 'verified'))
    .map((e) => e.url);
  const allSources = [...new Set([...machineVerifiedUrls, ...cleanedHumanVerifiedUrls])];
  if (allSources.length === 0) {
    throw Object.assign(
      new Error('No verified or human-verified source — a stance cannot be published without a citation'),
      { code: 'INCOMPLETE' });
  }

  // Machine-verified snippets, written on approval (R1) — AFTER writeVerifiedStance, so the
  // open-season context row exists and accumulateEvidence's "newest published season" pick lands
  // on it. ON CONFLICT DO NOTHING (inside accumulateEvidence) makes this safe to re-run even for a
  // review row an older build already wrote snippets for at queue time.
  const politicianId = row.politicianId;
  const topicId = row.topicId;
  const machineVerifiedRows: EvidenceInsertRow[] = row.evidence.flatMap((e) =>
    e.snippets
      .filter((s) => s.verdict === 'verified')
      .map((s) => ({
        politician_id: politicianId,
        topic_id: topicId,
        source_url: e.url,
        snippet: s.snippet,
        snippet_index: s.snippet_index,
        batch_id: row.batchId,
      })));
  const batchId = `human-review-${id}`;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Season-aware write (answer + context together); see writeVerifiedStance.
    await writeVerifiedStance({
      politicianId, topicId, value: finalValue,
      reasoning: finalReasoning, sources: allSources, editorId: resolvedBy,
    }, client);

    await accumulateEvidence(machineVerifiedRows, client);

    // Write human-verified URLs to politician_context_evidence so they appear in citations
    for (const url of cleanedHumanVerifiedUrls) {
      await client.query(
        // Same season derivation as accumulateEvidence above.
        `INSERT INTO inform.politician_context_evidence
           (politician_id, topic_id, season_id, source_url, snippet, snippet_index, batch_id)
         SELECT $1, $2, c.season_id, $3, $4, 0, $5
           FROM inform.politician_context c
           JOIN inform.seasons s ON s.id = c.season_id AND ${SEASON_IS_PUBLISHED}
          WHERE c.politician_id = $1 AND c.topic_id = $2
          ORDER BY s.number DESC
          LIMIT 1
         ON CONFLICT (politician_id, topic_id, source_url, snippet_index) DO NOTHING`,
        [politicianId, topicId, url, '[Human verified during review]', batchId],
      );
    }

    await client.query(
      `UPDATE inform.stance_research_review
       SET status = 'resolved', resolved_at = NOW(), resolved_by = $2
       WHERE id = $1`,
      [id, resolvedBy],
    );
    await client.query('COMMIT');
  } catch (err) {
    // A failed ROLLBACK (broken connection) must not mask the error that caused it.
    await client.query('ROLLBACK').catch(() => undefined);
    throw err;
  } finally {
    client.release();
  }
  return { ladderRevisionUnknown: row.ladderRevisionUnknown };
}

export async function rejectResearchReview(id: string, resolvedBy: string, notes?: string): Promise<void> {
  const { pool } = await import('./db.js');
  await pool.query(
    `UPDATE inform.stance_research_review
     SET status = 'rejected', resolved_at = NOW(), resolved_by = $2, notes = COALESCE($3, notes)
     WHERE id = $1`,
    [id, resolvedBy, notes ?? null],
  );
}

let ladderColumnsProbe: Promise<boolean> | null = null;

/**
 * Whether inform.stance_research_review carries CA_0264's topic_revision_id + season_id. Probed
 * once per process and cached. Until CA_0264 is applied the queue write omits them (the row is
 * then a legacy "ladder revision unknown" row) instead of failing every INSERT — the caller
 * (verify-stance-research.ts) prints a WARN when this is false.
 */
export function reviewLadderColumnsExist(): Promise<boolean> {
  ladderColumnsProbe ??= (async () => {
    const { pool } = await import('./db.js');
    const { rows } = await pool.query<{ n: string }>(
      `SELECT count(*)::text AS n FROM information_schema.columns
        WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
          AND column_name IN ('topic_revision_id', 'season_id')`,
    );
    return Number(rows[0]?.n ?? 0) === 2;
  })();
  return ladderColumnsProbe;
}

/**
 * Idempotent upsert into the review queue keyed on (batch_id, politician_id-or-name, topic_key).
 *
 * 🔴 The DO UPDATE touches only rows still UNDECIDED (pending / unresolved_politician). Without
 * that guard, re-running a batch reset a row a person had already rejected or resolved back to
 * `pending` (it copies EXCLUDED.status) — resurrecting a decision (I1).
 *
 * Writes the row's ladder revision + queue-time season (CA_0264) when those columns exist; a
 * re-run refreshes them on an undecided row, like every other research field. Pass
 * `opts.ladderColumns` to skip the probe (the verifier probes once and warns).
 *
 * Returns true when a row was inserted or updated, false when the existing row was already
 * decided and was left alone.
 */
export async function upsertReviewRow(row: ReviewInsertRow, opts: { ladderColumns?: boolean } = {}): Promise<boolean> {
  const { pool } = await import('./db.js');
  const ladder = opts.ladderColumns ?? await reviewLadderColumnsExist();
  const params: unknown[] = [
    row.batch_id, row.politician_id, row.full_name_raw, row.topic_id, row.topic_key,
    row.proposed_value, row.proposed_reasoning, JSON.stringify(row.evidence),
    row.verified_source_count, row.threshold, row.status, row.re_research_attempted,
  ];
  if (ladder) params.push(row.topic_revision_id, row.season_id);
  const res = await pool.query(
    `INSERT INTO inform.stance_research_review
       (batch_id, politician_id, full_name_raw, topic_id, topic_key,
        proposed_value, proposed_reasoning, evidence,
        verified_source_count, threshold, status, re_research_attempted${ladder ? ',\n        topic_revision_id, season_id' : ''})
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10, $11, $12${ladder ? ', $13, $14' : ''})
     ON CONFLICT (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key)
     DO UPDATE SET
       proposed_value = EXCLUDED.proposed_value,
       proposed_reasoning = EXCLUDED.proposed_reasoning,
       evidence = EXCLUDED.evidence,
       verified_source_count = EXCLUDED.verified_source_count,
       threshold = EXCLUDED.threshold,
       status = EXCLUDED.status,
       re_research_attempted = EXCLUDED.re_research_attempted${ladder ? `,
       topic_revision_id = EXCLUDED.topic_revision_id,
       season_id = EXCLUDED.season_id` : ''}
     WHERE inform.stance_research_review.status IN ('pending', 'unresolved_politician')`,
    params,
  );
  return (res.rowCount ?? 0) > 0;
}
