/**
 * researchEvidenceService — pure helpers that shape VerifiedRow objects into
 * rows ready for `inform.politician_context_evidence` and
 * `inform.stance_research_review`. The actual SQL execution lives in the
 * skill orchestrator; this module is unit-testable on its own.
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
      reason: snip.verdict.verdict === 'url_broken' ? snip.verdict.reason : undefined,
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
 * Replace evidence for a (politician, topic) and insert fresh snippets.
 * Idempotent across re-runs of the same batch.
 */
export async function replaceEvidence(rows: EvidenceInsertRow[]): Promise<void> {
  if (rows.length === 0) return;
  const { pool } = await import('./db.js');
  const { politician_id, topic_id } = rows[0];
  await pool.query(
    `DELETE FROM inform.politician_context_evidence WHERE politician_id=$1 AND topic_id=$2`,
    [politician_id, topic_id],
  );
  for (const r of rows) {
    await pool.query(
      `INSERT INTO inform.politician_context_evidence
        (politician_id, topic_id, source_url, snippet, snippet_index, batch_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [r.politician_id, r.topic_id, r.source_url, r.snippet, r.snippet_index, r.batch_id],
    );
  }
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
