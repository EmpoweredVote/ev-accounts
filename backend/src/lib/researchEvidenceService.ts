/**
 * researchEvidenceService — helpers for the stance research verification pipeline.
 * Pure data-shaping functions (buildEvidenceRowsForInsert, buildReviewRowForInsert)
 * plus DB-executing functions (accumulateEvidence, upsertReviewRow).
 */

import type { VerifiedRow } from './researchVerifier.js';

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
  };
}

/**
 * Accumulate evidence for a (politician, topic) — upserts each snippet, deduped
 * by the unique index on (politician_id, topic_id, source_url, snippet_index).
 * Never deletes existing rows; safe to re-run with the same or updated batches.
 */
export async function accumulateEvidence(rows: EvidenceInsertRow[]): Promise<void> {
  if (rows.length === 0) return;
  // Imported lazily alongside pool, NOT at module scope. This module is loaded
  // by tests that mock './db.js', and a static import of seasonService pulls
  // db.js in before the mock is installed — which broke collection of
  // researchEvidenceService.test.ts the first time this predicate was added.
  const { pool } = await import('./db.js');
  const { SEASON_IS_PUBLISHED } = await import('./seasonService.js');
  for (const r of rows) {
    await pool.query(
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
  }
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
}

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
  };
}

export async function listPendingResearchReview(): Promise<ResearchReviewRow[]> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT * FROM inform.stance_research_review
     WHERE status = 'pending'
     ORDER BY full_name_raw, topic_key`,
  );
  return rows.map(mapReviewRow);
}

export async function getResearchReviewById(id: string): Promise<ResearchReviewRow | null> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT * FROM inform.stance_research_review WHERE id = $1`,
    [id],
  );
  return rows[0] ? mapReviewRow(rows[0]) : null;
}

/**
 * Write one stance (answer + its public "why") into the OPEN season. The only stance write path
 * for research: verify-stance-research --apply and the review queue both call this.
 * Answer and context are written together on purpose — reasoning must never lag the value.
 * Throws if the open season wrote nothing (no open season, or topic not in its question set).
 */
export async function writeVerifiedStance(args: {
  politicianId: string; topicId: string; value: number; reasoning: string; sources: string[]; editorId: string | null;
}): Promise<void> {
  // Dynamic imports: a static import pulls db.js in before this file's tests install their mock.
  const { pool } = await import('./db.js');
  const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, assertWritten } = await import('./seasonService.js');
  const ans = await pool.query(UPSERT_ANSWER_SQL, [args.politicianId, args.topicId, args.value, args.editorId]);
  await assertWritten(ans.rowCount ?? 0, args.topicId);
  const ctx = await pool.query(UPSERT_CONTEXT_SQL,
    [args.politicianId, args.topicId, args.reasoning, args.sources, args.editorId]);
  await assertWritten(ctx.rowCount ?? 0, args.topicId);
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
 */
export async function resolveResearchReview(
  id: string,
  resolvedBy: string,
  humanVerifiedUrls: string[] = [],
  valueOverride?: number | null,
  reasoningOverride?: string,
): Promise<void> {
  // Lazy, for the same reason as accumulateEvidence above: a static import of
  // seasonService drags db.js in before the test mock is installed.
  const { pool } = await import('./db.js');
  const { SEASON_IS_PUBLISHED } = await import('./seasonService.js');
  const row = await getResearchReviewById(id);
  if (!row) throw Object.assign(new Error('Not found'), { code: 'NOT_FOUND' });

  const finalValue = valueOverride !== undefined && valueOverride !== null ? valueOverride : row.proposedValue;
  const finalReasoning = reasoningOverride || row.proposedReasoning;

  if (!row.politicianId || !row.topicId || finalValue === null) {
    throw Object.assign(new Error('Row is missing politician_id, topic_id, or value'), { code: 'INCOMPLETE' });
  }

  // All sources to attach: machine-verified + human-verified (deduped)
  const machineVerifiedUrls = row.evidence
    .filter((e) => e.snippets.some((s) => s.verdict === 'verified'))
    .map((e) => e.url);
  const allSources = [...new Set([...machineVerifiedUrls, ...humanVerifiedUrls])];

  // Season-aware write (answer + context together); see writeVerifiedStance.
  await writeVerifiedStance({
    politicianId: row.politicianId, topicId: row.topicId, value: finalValue,
    reasoning: finalReasoning, sources: allSources, editorId: resolvedBy,
  });

  // Machine-verified snippets, written now (R1) — AFTER writeVerifiedStance, so the open-season
  // context row exists and accumulateEvidence's "newest published season" pick lands on it.
  // ON CONFLICT DO NOTHING (inside accumulateEvidence) makes this safe to re-run even for a
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
  await accumulateEvidence(machineVerifiedRows);

  // Write human-verified URLs to politician_context_evidence so they appear in citations
  const batchId = `human-review-${id}`;
  for (const url of humanVerifiedUrls) {
    await pool.query(
      // Same season derivation as saveEvidenceRows above.
      `INSERT INTO inform.politician_context_evidence
         (politician_id, topic_id, season_id, source_url, snippet, snippet_index, batch_id)
       SELECT $1, $2, c.season_id, $3, $4, 0, $5
         FROM inform.politician_context c
         JOIN inform.seasons s ON s.id = c.season_id AND ${SEASON_IS_PUBLISHED}
        WHERE c.politician_id = $1 AND c.topic_id = $2
        ORDER BY s.number DESC
        LIMIT 1
       ON CONFLICT (politician_id, topic_id, source_url, snippet_index) DO NOTHING`,
      [row.politicianId, row.topicId, url, '[Human verified during review]', batchId],
    );
  }

  await pool.query(
    `UPDATE inform.stance_research_review
     SET status = 'resolved', resolved_at = NOW(), resolved_by = $2
     WHERE id = $1`,
    [id, resolvedBy],
  );
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

/**
 * Idempotent upsert into the review queue keyed on (batch_id, politician_id-or-name, topic_key).
 */
export async function upsertReviewRow(row: ReviewInsertRow): Promise<void> {
  const { pool } = await import('./db.js');
  await pool.query(
    `INSERT INTO inform.stance_research_review
       (batch_id, politician_id, full_name_raw, topic_id, topic_key,
        proposed_value, proposed_reasoning, evidence,
        verified_source_count, threshold, status, re_research_attempted)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10, $11, $12)
     ON CONFLICT (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key)
     DO UPDATE SET
       proposed_value = EXCLUDED.proposed_value,
       proposed_reasoning = EXCLUDED.proposed_reasoning,
       evidence = EXCLUDED.evidence,
       verified_source_count = EXCLUDED.verified_source_count,
       threshold = EXCLUDED.threshold,
       status = EXCLUDED.status,
       re_research_attempted = EXCLUDED.re_research_attempted`,
    [
      row.batch_id, row.politician_id, row.full_name_raw, row.topic_id, row.topic_key,
      row.proposed_value, row.proposed_reasoning, JSON.stringify(row.evidence),
      row.verified_source_count, row.threshold, row.status, row.re_research_attempted,
    ],
  );
}
