/**
 * compassRevisionService — the review surface's data layer (ADR 0004 §7).
 *
 * WHY THIS EXISTS, AND WHY IT LOOKS LIKE THIS:
 * Migration 061 built a review workflow that was never used once. Two causes,
 * and both are design constraints here:
 *
 *   1. Its publish gate required individually approving every politician answer
 *      on the topic — 2,014 rows for `taxes`. Nothing in this file touches
 *      politician answers. Publishing is a pointer flip.
 *   2. Its one admin screen served both authors (who work in SQL) and reviewers
 *      (non-technical `Compass Stance Editor` holders — exactly ONE account holds
 *      that role today, despite four grant rows). This layer serves
 *      REVIEWERS only. Authoring happens in the author's own tooling, which
 *      writes a `status='draft'` revision row via the propose RPC.
 *
 * The reviewer never sees SQL or JSON. `getRevisionForReview` returns the
 * current and proposed text already paired rung-by-rung, with each rung's
 * disposition resolved from `rung_map`, so the UI renders prose and nothing else.
 *
 * DIFFING IS DELIBERATELY NOT DONE HERE.
 * Revisions are full snapshots, so the diff is a pure function of two strings.
 * Computing it in the browser keeps this layer free of presentation choices and
 * lets the UI mark insertions and deletions as real <ins>/<del> elements —
 * required, because a highlight alone is colour-only signalling and vanishes for
 * a screen reader (ADR 0004 §9).
 *
 * All writes go through SECURITY DEFINER RPCs (CA_0015). Authorisation is the
 * route's job via requireRole('compass_stance_editor'), matching
 * routes/compassContributor.ts. This layer does not re-authorise; it records who
 * acted.
 */

import { pool } from './db.js';
import { adminRpc } from './supabase.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ChangeClass = 'editorial' | 'clarifying' | 'substantive';
export type RevisionStatus =
  | 'draft'
  | 'approved'
  | 'published'
  | 'superseded'
  | 'rejected';

/** A rung's fate under a revision. Resolved from rung_map, never guessed. */
export type RungDisposition = 'unchanged' | 'reworded' | 'moved' | 'replaced';

export interface RungPair {
  value: number;
  currentText: string | null;
  proposedText: string | null;
  currentDescription: string | null;
  proposedDescription: string | null;
  /**
   * How to render this rung. `reworded` marks changes inline; `replaced` shows
   * old and new as whole blocks, because marking word-by-word would be noise
   * when nothing survived. A text differ cannot tell these apart — rung_map can.
   */
  disposition: RungDisposition;
  /** Where an answer at this rung goes. null when the rung is invalidated. */
  movesTo: number | null;
}

export interface RevisionSummary {
  id: string;
  topicId: string;
  topicKey: string;
  revision: number;
  version: number;
  changeClass: ChangeClass;
  status: RevisionStatus;
  title: string;
  publicNote: string;
  proposedAt: string;
  proposedByName: string | null;
  approvedByName: string | null;
  /** True when the ladder changed, so the reviewer knows to expect rung work. */
  ladderChanged: boolean;
}

export interface RevisionForReview extends RevisionSummary {
  shortTitle: string | null;
  questionText: string;
  rationale: string;
  reviewRef: string | null;
  rungMap: Record<string, number | 'invalidated'> | null;
  currentRevision: number;
  currentVersion: number;
  currentTitle: string;
  currentShortTitle: string | null;
  currentQuestionText: string;
  rungs: RungPair[];
  /**
   * Set when publishing would be refused, with the reason, so the UI can explain
   * it BEFORE the reviewer clicks rather than surfacing a 422 afterwards.
   */
  publishBlockedReason: string | null;
}

// ---------------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------------

/**
 * Open proposals, newest first. This is the review queue.
 * Deliberately excludes published/superseded/rejected — those belong to the
 * public record and to history, not to a queue of work.
 */
export async function listOpenRevisions(): Promise<RevisionSummary[]> {
  const { rows } = await pool.query(
    `SELECT r.id, r.topic_id, t.topic_key, r.revision, r.version,
            r.change_class::text AS change_class, r.status::text AS status,
            r.title, r.public_note, r.proposed_at,
            pu.display_name AS proposed_by_name,
            au.display_name AS approved_by_name,
            (r.rung_map IS NOT NULL) AS ladder_changed
     FROM inform.compass_topic_revisions r
     JOIN inform.compass_topics t ON t.id = r.topic_id
     LEFT JOIN public.users pu ON pu.id = r.proposed_by
     LEFT JOIN public.users au ON au.id = r.approved_by
     WHERE r.status IN ('draft', 'approved')
     ORDER BY r.proposed_at DESC`
  );
  return rows.map(mapSummary);
}

/**
 * One proposal, paired against the live revision and ready to render.
 *
 * The rung pairing is a FULL OUTER JOIN on rung value rather than a positional
 * zip: a proposal is required to carry exactly five rungs (the propose RPC
 * enforces it), but pairing by value means a malformed row surfaces as a visible
 * gap instead of silently shifting every rung by one.
 */
export async function getRevisionForReview(
  revisionId: string
): Promise<RevisionForReview | null> {
  const { rows } = await pool.query(
    `SELECT r.id, r.topic_id, t.topic_key, r.revision, r.version,
            r.change_class::text AS change_class, r.status::text AS status,
            r.title, r.short_title, r.question_text,
            r.rationale, r.public_note, r.review_ref, r.rung_map, r.proposed_at,
            pu.display_name AS proposed_by_name,
            au.display_name AS approved_by_name,
            cur.id           AS current_id,
            cur.revision     AS current_revision,
            cur.version      AS current_version,
            cur.title        AS current_title,
            cur.short_title  AS current_short_title,
            cur.question_text AS current_question_text
     FROM inform.compass_topic_revisions r
     JOIN inform.compass_topics t ON t.id = r.topic_id
     LEFT JOIN public.users pu ON pu.id = r.proposed_by
     LEFT JOIN public.users au ON au.id = r.approved_by
     JOIN inform.compass_topic_revisions cur
       ON cur.topic_id = r.topic_id AND cur.is_current
     WHERE r.id = $1`,
    [revisionId]
  );

  const row = rows[0];
  if (!row) return null;

  // Each side is narrowed to its own revision in a CTE BEFORE the join. Putting
  // the revision filter in the join/WHERE instead leaves the left side
  // unconstrained, so every proposed rung pairs with the same-numbered rung of
  // all 44 topics and the WHERE then discards the wrong survivors — a rung can
  // vanish from the result entirely. Narrow first, then join.
  const { rows: rungRows } = await pool.query(
    `WITH cur AS (
       SELECT value, text, description
       FROM inform.compass_stance_revisions WHERE topic_revision_id = $1
     ), prop AS (
       SELECT value, text, description
       FROM inform.compass_stance_revisions WHERE topic_revision_id = $2
     )
     SELECT COALESCE(c.value, p.value) AS value,
            -- Capitalize the first letter for display, matching the voter read
            -- path (ADR 0006 / #217). Applied to both sides identically, so the
            -- unchanged-vs-reworded comparison below is unaffected. Stored text
            -- stays lowercase, verb-first.
            upper(left(c.text, 1)) || substr(c.text, 2) AS current_text,
            upper(left(p.text, 1)) || substr(p.text, 2) AS proposed_text,
            c.description AS current_description, p.description AS proposed_description
     FROM cur c
     FULL OUTER JOIN prop p ON p.value = c.value
     ORDER BY 1`,
    [row.current_id, revisionId]
  );

  const rungMap = (row.rung_map ?? null) as RevisionForReview['rungMap'];

  const rungs: RungPair[] = rungRows.map((r) => {
    const value = Number(r.value);
    const mapped = rungMap ? rungMap[String(value)] : undefined;
    const textSame = r.current_text === r.proposed_text;
    const descSame = r.current_description === r.proposed_description;

    let disposition: RungDisposition;
    let movesTo: number | null = value;

    if (mapped === 'invalidated') {
      disposition = 'replaced';
      movesTo = null;
    } else if (typeof mapped === 'number' && mapped !== value) {
      disposition = 'moved';
      movesTo = mapped;
    } else if (textSame && descSame) {
      disposition = 'unchanged';
    } else {
      disposition = 'reworded';
    }

    return {
      value,
      currentText: r.current_text ?? null,
      proposedText: r.proposed_text ?? null,
      currentDescription: r.current_description ?? null,
      proposedDescription: r.proposed_description ?? null,
      disposition,
      movesTo,
    };
  });

  return {
    ...mapSummary({ ...row, ladder_changed: rungMap !== null }),
    shortTitle: row.short_title ?? null,
    questionText: row.question_text,
    rationale: row.rationale,
    reviewRef: row.review_ref ?? null,
    rungMap,
    currentRevision: Number(row.current_revision),
    currentVersion: Number(row.current_version),
    currentTitle: row.current_title,
    currentShortTitle: row.current_short_title ?? null,
    currentQuestionText: row.current_question_text,
    rungs,
    publishBlockedReason: publishBlockedReason(rungMap),
  };
}

/**
 * The public record for one topic: every revision that has ever been live,
 * newest first. Excludes drafts and rejects — CA_0011's RLS withholds them from
 * anon reads, and this path must not be the hole in that.
 */
export async function getTopicRevisionHistory(topicKey: string) {
  const { rows } = await pool.query(
    `SELECT r.id, r.revision, r.version, r.change_class::text AS change_class,
            r.status::text AS status, r.is_current,
            r.title, r.short_title, r.question_text, r.public_note, r.published_at
     FROM inform.compass_topic_revisions r
     JOIN inform.compass_topics t ON t.id = r.topic_id
     WHERE t.topic_key = $1
       AND r.status IN ('published', 'superseded')
     ORDER BY r.revision DESC`,
    [topicKey]
  );
  return rows.map((r) => ({
    id: r.id,
    revision: Number(r.revision),
    version: Number(r.version),
    changeClass: r.change_class as ChangeClass,
    status: r.status as RevisionStatus,
    isCurrent: r.is_current,
    title: r.title,
    shortTitle: r.short_title ?? null,
    questionText: r.question_text,
    publicNote: r.public_note,
    publishedAt: r.published_at,
  }));
}

// ---------------------------------------------------------------------------
// Writes — all via SECURITY DEFINER RPCs from CA_0015
// ---------------------------------------------------------------------------

export async function approveRevision(revisionId: string, actorId: string): Promise<void> {
  const { error } = await adminRpc(
    'admin_approve_topic_revision',
    { p_revision_id: revisionId, p_actor_id: actorId },
    'inform'
  );
  // Rethrow the RPC's own message unchanged — the route maps its NAMED: prefix
  // to a status code and shows the rest to a human reviewer.
  if (error) throw new Error(error.message);
}

export async function rejectRevision(
  revisionId: string,
  actorId: string,
  reason: string
): Promise<void> {
  const { error } = await adminRpc(
    'admin_reject_topic_revision',
    { p_revision_id: revisionId, p_actor_id: actorId, p_reason: reason },
    'inform'
  );
  if (error) throw new Error(error.message);
}

export async function publishRevision(
  revisionId: string,
  actorId: string
): Promise<{ published_revision: number; published_version: number; superseded_revision: number }> {
  const { data, error } = await adminRpc(
    'admin_publish_topic_revision',
    { p_revision_id: revisionId, p_actor_id: actorId },
    'inform'
  );
  if (error) throw new Error(error.message);
  return data as { published_revision: number; published_version: number; superseded_revision: number };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Mirrors the refusal in admin_publish_topic_revision so the UI can warn up
 * front. Kept as a plain function rather than a second query because it must
 * stay in lockstep with the RPC — if these two ever disagree, the RPC wins and
 * the reviewer sees a 422 they were not warned about.
 */
function publishBlockedReason(
  rungMap: Record<string, number | 'invalidated'> | null
): string | null {
  if (!rungMap) return null;
  const moved = Object.entries(rungMap)
    .filter(([k, v]) => String(v) !== k)
    .map(([k, v]) => (v === 'invalidated' ? `rung ${k} removed` : `rung ${k} → ${v}`));
  if (moved.length === 0) return null;
  return (
    `This change moves or removes rungs (${moved.join(', ')}). Publishing is blocked ` +
    `because existing recorded stances point at rung positions, and the machinery to ` +
    `move them has not been built yet. Reword the rungs in place, or ask an engineer ` +
    `to build the re-pointing step first.`
  );
}

function mapSummary(r: Record<string, unknown>): RevisionSummary {
  return {
    id: r.id as string,
    topicId: r.topic_id as string,
    topicKey: r.topic_key as string,
    revision: Number(r.revision),
    version: Number(r.version),
    changeClass: r.change_class as ChangeClass,
    status: r.status as RevisionStatus,
    title: r.title as string,
    publicNote: r.public_note as string,
    proposedAt: String(r.proposed_at),
    proposedByName: (r.proposed_by_name as string) ?? null,
    approvedByName: (r.approved_by_name as string) ?? null,
    ladderChanged: Boolean(r.ladder_changed),
  };
}
