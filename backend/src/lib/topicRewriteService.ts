// topicRewriteService.ts — thin wrappers around the migration 061 RPCs
// in the `inform` schema. All business logic lives in SQL for atomicity.

import { adminRpc } from './supabase.js';
import { pool } from './db.js';

export type RewriteState =
  | 'draft'
  | 'pending_framing_review'
  | 're_evaluation_queue'
  | 'publish_ready'
  | 'published'
  | 'cancelled';

export type ProposalStatus = 'pending' | 'approved' | 'rejected';

export interface NewStance {
  value: number;
  text: string;
}

export interface CreateRewriteInput {
  topicKey: string;
  actorId: string;
  newTitle: string;
  newShortTitle: string;
  newQuestionText: string;
  newStances: NewStance[];
  notes?: string | undefined;
}

export async function createTopicRewrite(input: CreateRewriteInput): Promise<string> {
  const { data, error } = await adminRpc(
    'admin_create_topic_rewrite',
    {
      p_topic_key: input.topicKey,
      p_actor_id: input.actorId,
      p_new_title: input.newTitle,
      p_new_short_title: input.newShortTitle,
      p_new_question_text: input.newQuestionText,
      p_new_stances: input.newStances,
      p_notes: input.notes ?? null,
    },
    'inform',
  );
  if (error) throw new Error(`createTopicRewrite failed: ${error.message}`);
  return data as string;
}

export async function submitRewriteForFramingReview(rewriteId: string): Promise<void> {
  const { error } = await adminRpc(
    'admin_submit_rewrite_for_framing_review',
    { p_rewrite_id: rewriteId },
    'inform',
  );
  if (error) throw new Error(`submitRewriteForFramingReview failed: ${error.message}`);
}

export async function approveRewriteFraming(
  rewriteId: string,
  actorId: string,
): Promise<number> {
  const { data, error } = await adminRpc(
    'admin_approve_rewrite_framing',
    { p_rewrite_id: rewriteId, p_actor_id: actorId },
    'inform',
  );
  if (error) throw new Error(`approveRewriteFraming failed: ${error.message}`);
  return (data as number) ?? 0;
}

export interface UpsertProposalInput {
  rewriteId: string;
  politicianId: string;
  proposedValue: number | null;
  proposedReasoning: string | null;
  proposedSources: string[];
}

export async function upsertStanceProposal(input: UpsertProposalInput): Promise<void> {
  const { error } = await adminRpc(
    'admin_upsert_stance_proposal',
    {
      p_rewrite_id: input.rewriteId,
      p_politician_id: input.politicianId,
      p_proposed_value: input.proposedValue,
      p_proposed_reasoning: input.proposedReasoning,
      p_proposed_sources: input.proposedSources,
    },
    'inform',
  );
  if (error) throw new Error(`upsertStanceProposal failed: ${error.message}`);
}

export async function approveStanceProposal(
  rewriteId: string,
  politicianId: string,
  actorId: string,
  reviewerNotes: string | null,
): Promise<void> {
  const { error } = await adminRpc(
    'admin_approve_stance_proposal',
    {
      p_rewrite_id: rewriteId,
      p_politician_id: politicianId,
      p_actor_id: actorId,
      p_reviewer_notes: reviewerNotes,
    },
    'inform',
  );
  if (error) throw new Error(`approveStanceProposal failed: ${error.message}`);
}

export async function rejectStanceProposal(
  rewriteId: string,
  politicianId: string,
  actorId: string,
  reviewerNotes: string | null,
): Promise<void> {
  const { error } = await adminRpc(
    'admin_reject_stance_proposal',
    {
      p_rewrite_id: rewriteId,
      p_politician_id: politicianId,
      p_actor_id: actorId,
      p_reviewer_notes: reviewerNotes,
    },
    'inform',
  );
  if (error) throw new Error(`rejectStanceProposal failed: ${error.message}`);
}

export async function markRewritePublishReady(rewriteId: string): Promise<void> {
  const { error } = await adminRpc(
    'admin_mark_rewrite_publish_ready',
    { p_rewrite_id: rewriteId },
    'inform',
  );
  if (error) throw new Error(`markRewritePublishReady failed: ${error.message}`);
}

export async function publishTopicRewrite(
  rewriteId: string,
  actorId: string,
): Promise<{ approved_copied: number; rejected_skipped: number }> {
  const { data, error } = await adminRpc(
    'admin_publish_topic_rewrite',
    { p_rewrite_id: rewriteId, p_actor_id: actorId },
    'inform',
  );
  if (error) throw new Error(`publishTopicRewrite failed: ${error.message}`);
  return data as { approved_copied: number; rejected_skipped: number };
}

// ---------------------------------------------------------------------------
// Read helpers (plain SELECTs via pg pool — no RPC needed)
// ---------------------------------------------------------------------------

export async function listRewrites(): Promise<unknown[]> {
  const { rows } = await pool.query(`
    SELECT r.id, r.topic_key, r.state, r.old_topic_id, r.new_topic_id,
           r.created_at, r.framing_approved_at, r.published_at, r.notes,
           ot.title AS old_title, ot.version AS old_version,
           nt.title AS new_title, nt.version AS new_version
    FROM inform.topic_rewrites r
    JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
    JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
    ORDER BY r.created_at DESC
    LIMIT 100
  `);
  return rows;
}

export async function getRewriteDetail(rewriteId: string): Promise<unknown> {
  const { rows: rewriteRows } = await pool.query(
    `SELECT r.*, ot.title AS old_title, ot.question_text AS old_question_text,
            ot.version AS old_version,
            nt.title AS new_title, nt.question_text AS new_question_text,
            nt.version AS new_version
     FROM inform.topic_rewrites r
     JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
     JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
     WHERE r.id = $1`,
    [rewriteId],
  );
  if (rewriteRows.length === 0) return null;

  // 🔴 THESE FOUR READS TAKE THE FROZEN v1 TEXT, AND THAT IS NOT ENDORSED — IT IS UNJUDGED.
  // `CA_0012` froze compass_topics'/compass_stances' text columns at the introduction of content
  // versioning (ADR 0004); the live wording lives in compass_stance_revisions. Measured 2026-09-08,
  // 29 of the 60 topics in the open season disagree with the frozen text, 16 on all five rungs.
  //
  // They are NOT given a `@ladder-text: frozen-ok` marker, deliberately. A marker is a positive claim
  // that v1 wording is the thing you want, and this workflow has **never run**: `inform.topic_rewrites`
  // held ZERO rows when this was checked, so there is no behaviour to infer intent from. Plan D
  // creates a separate NEW TOPIC ROW per rewrite, which predates and was superseded by the
  // revision-and-season model that actually shipped. Claiming an intent here would silence the gate on
  // a justification nobody can stand behind, which is worse than leaving it counted.
  //
  // ▶️ IF YOU REVIVE THIS WORKFLOW, decide the source FIRST: a rewrite that diffs "the old wording"
  // wants the old topic's *pinned* revision, not whatever v1 happened to say. Then either fix the
  // query or add the marker with a reason that is true.
  //
  // Counted in scripts/lib/ladder-text-baseline.json. Leave it counted until it is decided.
  const { rows: oldStances } = await pool.query(
    `SELECT value, text FROM inform.compass_stances WHERE topic_id = $1 ORDER BY value`,
    [rewriteRows[0].old_topic_id],
  );
  const { rows: newStances } = await pool.query(
    `SELECT value, text FROM inform.compass_stances WHERE topic_id = $1 ORDER BY value`,
    [rewriteRows[0].new_topic_id],
  );
  const { rows: proposals } = await pool.query(
    `SELECT p.*, pol.full_name AS politician_name
     FROM inform.topic_rewrite_stance_proposals p
     JOIN essentials.politicians pol ON pol.id = p.politician_id
     WHERE p.rewrite_id = $1
     ORDER BY pol.full_name`,
    [rewriteId],
  );

  return {
    ...rewriteRows[0],
    old_stances: oldStances,
    new_stances: newStances,
    proposals,
  };
}
