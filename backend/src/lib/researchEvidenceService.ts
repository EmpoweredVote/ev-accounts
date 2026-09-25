/**
 * researchEvidenceService — helpers for the stance research verification pipeline.
 * Pure data-shaping functions (buildEvidenceRowsForInsert, buildReviewRowForInsert)
 * plus DB-executing functions (accumulateEvidence, upsertReviewRow).
 */

import type { VerifiedRow } from './researchVerifier.js';
// A value import is safe: researchVerifier imports nothing (no db.js), unlike seasonService below.
import { normalizeText, MIN_SNIPPET_WORDS } from './researchVerifier.js';
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
  /**
   * CA_0285 (not applied yet; written only once the columns exist — see reviewOptionalColumns).
   * served_revision_id: the SERVED revision (ADR 0006) whose rung text the researcher was shown.
   * queue_reasons: why decidePublish queued the row (statement-evidence, gate-medium, value-change,
   *   review-all-mode, unresolved-politician, below-threshold).
   * evidence_type: record | statement, from research.csv.
   */
  served_revision_id: string | null;
  queue_reasons: string[] | null;
  evidence_type: string | null;
}

/**
 * The text a verified snippet may be PUBLISHED as (I6, ruling 2026-09-24): its matched on-page
 * span, never the researcher's full snippet. null = no publishable span, so it is not a citation.
 */
function publishableSpan(snip: { matchedSpan?: string }): string | null {
  const t = snip.matchedSpan?.trim();
  return t ? t : null;
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
      const span = publishableSpan(snip);
      if (snip.verdict.verdict === 'verified' && span) {
        out.push({
          politician_id: args.politicianId,
          topic_id: args.topicId,
          source_url: src.url,
          // I6: the matched span only — the snippet's unmatched words are never published.
          snippet: span,
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
      // I6: stored beside the full snippet; approval publishes this, never `snippet`.
      matched_span: snip.verdict.verdict === 'verified' ? publishableSpan(snip) ?? undefined : undefined,
      // proximity | section — which rule tied the snippet to the politician (ruling 2026-09-24).
      rule: snip.verdict.verdict === 'verified' ? snip.verdict.rule : undefined,
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
  /** The bundle's served_revision_id for this row's topic (topics.json). */
  servedRevisionId?: string | null;
  /** decidePublish's reasons for queueing this row. */
  queueReasons?: string[] | null;
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
    served_revision_id: args.servedRevisionId ?? null,
    queue_reasons: args.queueReasons ?? null,
    evidence_type: args.row.stance.evidence_type?.trim() || null,
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
      /** I6: the matched on-page span — the only text approval publishes. Absent on rows queued before 2026-09-24. */
      matched_span?: string;
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
  /**
   * I2: what VOTERS SEE for this pair right now — the newest PUBLISHED season's answer (the read
   * path's collapse, seasonService.newestAnswerLateral), which is the Season 1 chair when the open
   * season holds none. value 0 = a blank (no chair shown). null = nothing shown, including a topic the
   * open season does not ask. `text` is that rung on the OPEN season's served ladder — what voters
   * read (N1); `historyText` is the same rung on the ladder the answer was recorded against. Approving this row replaces what voters see, even when currentValue is null.
   */
  displayed: { value: number; seasonNumber: number; text: string | null; historyText: string | null } | null;
  /** CA_0285: why the row was queued, and its evidence class. null = not recorded (legacy, or before CA_0285). */
  queueReasons: string[] | null;
  evidenceType: string | null;
  /** CA_0285: the served revision the researcher was shown. null = not recorded. */
  servedRevisionId: string | null;
  /** The served revision of the open season's current pin — the rung text voters read now. */
  openServedRevisionId: string | null;
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
  /**
   * The body/chamber of the politician's CURRENT office (task 5) — e.g. "State Senate", or the
   * office title when there is no chamber (a mayor, an executive seat). null when the politician
   * holds no current office, or the row has no politician_id yet (unresolved_politician).
   * Computed via a DISTINCT-ON-deduped join (CLAUDE.md: a politician-rooted
   * essentials.office_current_holder join fans out over two offices one person holds), so this is
   * ONE deliberately chosen office per politician, never a second result row.
   */
  bodyLabel: string | null;
}

/** One rung of a ladder, read from the versioned source (never the frozen `compass_stances`). */
export interface LadderRung {
  value: number;
  text: string;
}

/**
 * The full ladder text for one `compass_topic_revisions` row: the question and its five rungs,
 * read from `inform.compass_topic_revisions` / `inform.compass_stance_revisions` — the versioned
 * source `check:ladder-text` requires (never the frozen `compass_topics.question_text` /
 * `compass_stances.text`, which CA_0012 stopped maintaining).
 */
export interface LadderInfo {
  /** The SERVED revision whose text this is (ADR 0006) — not the pin. */
  revisionId: string;
  /** The pin it was resolved from. */
  pinRevisionId: string;
  questionText: string;
  rungs: LadderRung[];
  /**
   * true = the row's OWN revision is unknown (a legacy row, queued before CA_0264), so this is the
   * open season's CURRENT pin shown instead, labelled accordingly by the caller. false = this is
   * the exact revision the row was researched against.
   */
  usingOpenPin: boolean;
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
 * The review reads' joins, built lazily: seasonService is imported dynamically in this module
 * (a static import pulls db.js in before the tests' mock is installed), so these cannot be
 * module-scope constants.
 *
 *   open_pin / open_eff — the open season's CURRENT pin for the row's topic and its SERVED
 *     revision (ADR 0006). At most one row: one open season, season_questions' PK (season_id,
 *     topic_id). Names NO CA_0264/CA_0285 column: the row's own ids come through `r.*`, so these
 *     reads work before those migrations are applied (undefined → null = "unknown").
 *   shown / shown_eff / shown_sr — I2: what voters see now. newestAnswerLateral is the read path's
 *     own collapse (newest PUBLISHED season), so a pair with only a Season 1 answer shows the S1
 *     chair, and an S2 value-0 blank shows as the blank it is — never the S1 chair behind it.
 */
async function reviewReadJoins(): Promise<string> {
  const { servedRevisionLateral, newestAnswerLateral } = await import('./seasonService.js');
  return `
  LEFT JOIN LATERAL (
    SELECT sq.topic_revision_id
      FROM inform.season_questions sq
      JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     WHERE sq.topic_id = r.topic_id
  ) open_pin ON true
  LEFT JOIN ${servedRevisionLateral('open_pin.topic_revision_id', 'open_eff')} ON true
  -- @zero-scope: counts-blanks — a 0 here is a blank voters see; the reviewer must see it as one.
  ${newestAnswerLateral('r.politician_id', 'r.topic_id', 'shown')}
  -- N1 (re-review 2026-09-24): voters read the displayed value against the OPEN season's served
  -- ladder (getCompassTopics keys stances on the promoted topic's effective revision), NOT against
  -- the ladder of the season the answer was written in. So the rung text comes from open_eff.
  LEFT JOIN inform.compass_stance_revisions shown_sr
    ON shown_sr.topic_revision_id = open_eff.id AND shown_sr.value = shown.value
  -- History only: the same value's text on the ladder the answer was recorded against.
  LEFT JOIN ${servedRevisionLateral('shown.topic_revision_id', 'shown_eff')} ON true
  LEFT JOIN inform.compass_stance_revisions shown_hist_sr
    ON shown_hist_sr.topic_revision_id = shown_eff.id AND shown_hist_sr.value = shown.value`;
}

const REVIEW_READ_COLUMNS = `
  open_pin.topic_revision_id::text AS open_topic_revision_id,
  open_eff.id::text AS open_served_revision_id,
  -- A topic the open season does not ask is not on the voter compass at all: nothing is shown.
  CASE WHEN open_pin.topic_revision_id IS NULL THEN NULL ELSE shown.value END AS shown_value,
  shown.season_number AS shown_season_number, shown_sr.text AS shown_text,
  shown_hist_sr.text AS shown_history_text`;

/**
 * The row's politician's CURRENT office body/chamber (task 5, list-view cohort grouping).
 *
 * 🔴 A politician-rooted join into `essentials.office_current_holder` fans out — the view is one
 * row per OFFICE, and the exclusion constraint on `office_terms` cannot see one person holding
 * TWO offices (see CLAUDE.md, "Officeholder occupancy"). So this is a `DISTINCT ON
 * (och.politician_id)` subquery, deduped to ONE office per politician BEFORE it ever joins `r` —
 * the same fix `essentialsService.ts` uses for the identical shape (`getPoliticians`).
 * `COALESCE(ch.name, o.title)`: most offices sit in a chamber ("State Senate", "City Council");
 * a single-holder office (mayor, a statewide executive seat) has no chamber, so its own title is
 * the body. A vacant office is deprioritized (`is_vacant NULLS LAST`) but not excluded — the
 * subquery is keyed on the politician who WON it, and CLAUDE.md warns that a stale `is_vacant`
 * flag can sit beside a live term either way.
 */
const BODY_JOIN_SQL = `
  LEFT JOIN (
    SELECT DISTINCT ON (och.politician_id)
           och.politician_id, COALESCE(ch.name, o.title) AS body_label
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
     ORDER BY och.politician_id, o.is_vacant NULLS LAST, o.id
  ) body ON body.politician_id = r.politician_id`;

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
    displayed: row.shown_value === null || row.shown_value === undefined ? null : {
      value: Number(row.shown_value),
      seasonNumber: Number(row.shown_season_number),
      text: nullable(row.shown_text),
      historyText: nullable(row.shown_history_text),
    },
    queueReasons: Array.isArray(row.queue_reasons) ? row.queue_reasons.map(String) : null,
    evidenceType: nullable(row.evidence_type),
    ...ladderState(nullable(row.topic_revision_id), nullable(row.open_topic_revision_id),
      nullable(row.served_revision_id), nullable(row.open_served_revision_id)),
    seasonId: nullable(row.season_id),
    bodyLabel: nullable(row.body_label),
  };
}

/**
 * Does a ladder recorded at research time still match the open season's? Pure; shared by the
 * verifier's batch drift check and the review row's ladderState, so the two compare the same way.
 *
 *   pin    — must be equal (a re-pin, or a topic the open season dropped, is a different question).
 *   served — compared only when BOTH sides know it. A clarifying publish moves the served text
 *            without moving the pin, and research is judged against served text (C1), so a known
 *            served id that differs is a change. An unknown one (a row queued before CA_0285) is
 *            not evidence of a change, and falls back to the pin comparison alone.
 */
export function ladderMatches(
  recorded: { pin: string | null; served: string | null },
  open: { pin: string | null; served: string | null },
): boolean {
  if (recorded.pin === null || recorded.pin !== open.pin) return false;
  if (recorded.served !== null && recorded.served !== open.served) return false;
  return true;
}

/**
 * The row's ladder against the open season's. Pure, so the cases are testable alone:
 *   known + matches   → approvable;
 *   known + different → ladderChanged (a re-pin, a dropped topic, or a served-text publish since);
 *   unknown (null)    → ladderRevisionUnknown, approvable with the flag shown.
 */
export function ladderState(
  topicRevisionId: string | null, openTopicRevisionId: string | null,
  servedRevisionId: string | null = null, openServedRevisionId: string | null = null,
) {
  return {
    topicRevisionId,
    openTopicRevisionId,
    servedRevisionId,
    openServedRevisionId,
    ladderRevisionUnknown: topicRevisionId === null,
    ladderChanged: topicRevisionId !== null && !ladderMatches(
      { pin: topicRevisionId, served: servedRevisionId },
      { pin: openTopicRevisionId, served: openServedRevisionId }),
  };
}

export async function listPendingResearchReview(): Promise<ResearchReviewRow[]> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT r.*, ${CURRENT_VALUE_SQL}, ${REVIEW_READ_COLUMNS}, body.body_label
       FROM inform.stance_research_review r
       ${await reviewReadJoins()}
       ${BODY_JOIN_SQL}
      WHERE r.status = 'pending'
      ORDER BY r.full_name_raw, r.topic_key`,
  );
  return rows.map(mapReviewRow);
}

export async function getResearchReviewById(id: string): Promise<ResearchReviewRow | null> {
  const { pool } = await import('./db.js');
  const { rows } = await pool.query(
    `SELECT r.*, ${CURRENT_VALUE_SQL}, ${REVIEW_READ_COLUMNS}, body.body_label
       FROM inform.stance_research_review r
       ${await reviewReadJoins()}
       ${BODY_JOIN_SQL}
      WHERE r.id = $1`,
    [id],
  );
  return rows[0] ? mapReviewRow(rows[0]) : null;
}

/**
 * The SERVED ladder text for a pin (C1, final review 2026-09-24): the question and five rungs of
 * the latest published/superseded revision of the pin's version (ADR 0006) — the words voters read,
 * which on 13 of 60 open-season topics are not the pin's own. Read only from the versioned source
 * (`check:ladder-text`'s gate; see LadderInfo). null when the pin serves nothing, or the served
 * revision does not carry exactly five rungs — a partial ladder must not be shown as the ladder.
 */
async function fetchLadder(pinRevisionId: string, usingOpenPin: boolean): Promise<LadderInfo | null> {
  const { pool } = await import('./db.js');
  const { servedRevisionLateral } = await import('./seasonService.js');
  const { rows } = await pool.query<{ served_id: string; question_text: string; value: number; text: string }>(
    `SELECT eff.id::text AS served_id, eff.question_text, s.value, s.text
       FROM ${servedRevisionLateral('$1::uuid', 'eff')}
       JOIN inform.compass_stance_revisions s ON s.topic_revision_id = eff.id
      ORDER BY s.value`,
    [pinRevisionId],
  );
  if (rows.length !== 5) return null;
  return {
    revisionId: rows[0].served_id,
    pinRevisionId,
    questionText: rows[0].question_text,
    rungs: rows.map((r) => ({ value: r.value, text: r.text })),
    usingOpenPin,
  };
}

/**
 * The single-row read used by the admin DETAIL page (task 5, requirement 1): the review row plus
 * its ladder text. Deliberately a second function, not a `ladder` field folded into
 * `getResearchReviewById` — that function is also called by `resolveResearchReview` on every
 * approval, and an approval never needs to read the ladder wording, only compare its id (see
 * `ladderState`). Keeping the ladder fetch out of the shared function keeps that comparison at
 * its original one query.
 *
 * Reads the row's OWN revision when known; falls back to the open season's current pin
 * (`openTopicRevisionId`) for a legacy row (`ladderRevisionUnknown`), labelled `usingOpenPin` so
 * the page can say so ("(open season's ladder — this row's revision is unknown)"). null when
 * neither is known (no open season, or the open season does not ask this topic either).
 */
export async function getResearchReviewWithLadder(
  id: string,
): Promise<(ResearchReviewRow & { ladder: LadderInfo | null }) | null> {
  const row = await getResearchReviewById(id);
  if (!row) return null;
  const revisionForLadder = row.topicRevisionId ?? row.openTopicRevisionId;
  const ladder = revisionForLadder ? await fetchLadder(revisionForLadder, row.topicRevisionId === null) : null;
  return { ...row, ladder };
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

  // Task 5, requirement 3: a reviewer who changes the CHAIR must also write why — the public
  // "why this position?" text is the reasoning, and it must never assert the OLD chair's rationale
  // for a DIFFERENT value. Only checked when the value actually changes: re-approving the
  // proposed value with the proposed reasoning untouched is the ordinary case and needs no edit.
  if (valueOverride !== undefined && valueOverride !== null && valueOverride !== row.proposedValue) {
    const trimmedOverride = (reasoningOverride ?? '').trim();
    if (trimmedOverride === '' || trimmedOverride === row.proposedReasoning.trim()) {
      throw Object.assign(
        new Error('valueOverride differs from the proposed value — reasoningOverride must be present and explain the new value'),
        { code: 'INCOMPLETE' });
    }
  }

  const finalValue = valueOverride !== undefined && valueOverride !== null ? valueOverride : row.proposedValue;
  const finalReasoning = reasoningOverride || row.proposedReasoning;

  if (!row.politicianId || !row.topicId || finalValue === null) {
    throw Object.assign(new Error('Row is missing politician_id, topic_id, or value'), { code: 'INCOMPLETE' });
  }

  const cleanedHumanVerifiedUrls = cleanHumanVerifiedUrls(humanVerifiedUrls);

  // I6 (ruling 2026-09-24): a machine-verified snippet is published as its matched on-page span,
  // never as the researcher's full snippet. The span was derived at verification time (matchedSpan)
  // and is stored beside the snippet; here it is re-checked against the snippet it came from. A
  // verified snippet with no valid span (a row queued before 2026-09-24) is NOT a citation — its
  // page is not re-fetched on approval, so nothing can say which of its words were on the page.
  const publishable = (s: ResearchReviewRow['evidence'][number]['snippets'][number]): string | null =>
    s.verdict === 'verified' ? validStoredSpan(s.snippet, s.matched_span) : null;

  // All sources to attach: machine-verified + human-verified (deduped)
  const machineVerifiedUrls = row.evidence
    .filter((e) => e.snippets.some((s) => publishable(s) !== null))
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
      .filter((s) => publishable(s) !== null)
      .map((s) => ({
        politician_id: politicianId,
        topic_id: topicId,
        source_url: e.url,
        snippet: publishable(s) as string,
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

    // I5: only a row still pending may be resolved. The status check above ran before this
    // transaction, so a concurrent approve/reject can land in between; 0 rows here means someone
    // else decided the row first, and the throw rolls back this approval's stance write with it.
    const upd = await client.query(
      `UPDATE inform.stance_research_review
       SET status = 'resolved', resolved_at = NOW(), resolved_by = $2
       WHERE id = $1 AND status = 'pending'`,
      [id, resolvedBy],
    );
    if ((upd.rowCount ?? 0) !== 1) {
      throw Object.assign(
        new Error('Review row is no longer pending — another decision landed first; nothing was written'),
        { code: 'CONFLICT' });
    }
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

/**
 * Reject a pending review row.
 *
 * 🔴 I5: ONLY A PENDING ROW. Without `AND status = 'pending'`, rejecting a row someone had already
 * RESOLVED flipped it to rejected while the stance it published stayed live — and
 * export-written-ledger.ts selects `status = 'resolved'`, so that published chair silently left the
 * audit. 0 rows is loud: NOT_FOUND (→ 404) when the id names nothing, CONFLICT (→ 409) otherwise.
 */
export async function rejectResearchReview(id: string, resolvedBy: string, notes?: string): Promise<void> {
  const { pool } = await import('./db.js');
  const res = await pool.query(
    `UPDATE inform.stance_research_review
     SET status = 'rejected', resolved_at = NOW(), resolved_by = $2, notes = COALESCE($3, notes)
     WHERE id = $1 AND status = 'pending'`,
    [id, resolvedBy, notes ?? null],
  );
  if ((res.rowCount ?? 0) === 1) return;
  const { rows } = await pool.query<{ status: string }>(
    'SELECT status FROM inform.stance_research_review WHERE id = $1', [id]);
  if (rows.length === 0) throw Object.assign(new Error('Not found'), { code: 'NOT_FOUND' });
  throw Object.assign(
    new Error(`Review row is ${rows[0].status}, not pending — only a pending row can be rejected`),
    { code: 'CONFLICT' });
}

/**
 * A stored span is publishable only if it is still what matchedSpan guarantees: at least
 * MIN_SNIPPET_WORDS words, and a contiguous run of the snippet it was derived from (normalized).
 * Defence in depth against a hand-edited evidence jsonb. null = not publishable.
 */
export function validStoredSpan(snippet: string, span: string | undefined): string | null {
  const t = span?.trim();
  if (!t) return null;
  // Same normalizer as the verifier, padded so the run must sit on whole words.
  const norm = (x: string) => ` ${normalizeText(x)} `;
  const words = normalizeText(t).split(' ').filter(Boolean).length;
  if (words < MIN_SNIPPET_WORDS) return null;
  return norm(snippet).includes(norm(t)) ? t : null;
}

/**
 * Review-row columns added after the table was created, and the migration that adds each. The
 * queue write names only the ones that exist, so the code runs unchanged before and after each
 * apply (as Task 4 did for CA_0264).
 */
export const OPTIONAL_REVIEW_COLUMNS = {
  topic_revision_id: 'CA_0264', season_id: 'CA_0264',
  served_revision_id: 'CA_0285', queue_reasons: 'CA_0285', evidence_type: 'CA_0285',
} as const;
export type OptionalReviewColumn = keyof typeof OPTIONAL_REVIEW_COLUMNS;

let optionalColumnsProbe: Promise<ReadonlySet<OptionalReviewColumn>> | null = null;

/**
 * Which OPTIONAL_REVIEW_COLUMNS inform.stance_research_review carries. Probed once per process and
 * cached; a FAILED probe is not cached (it used to be — a rejected promise stayed in the cache and
 * failed every later call in the process).
 */
export function reviewOptionalColumns(): Promise<ReadonlySet<OptionalReviewColumn>> {
  optionalColumnsProbe ??= (async () => {
    const { pool } = await import('./db.js');
    const { rows } = await pool.query<{ column_name: string }>(
      `SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
          AND column_name = ANY($1::text[])`,
      [Object.keys(OPTIONAL_REVIEW_COLUMNS)],
    );
    return new Set(rows.map((r) => r.column_name as OptionalReviewColumn));
  })().catch((err) => { optionalColumnsProbe = null; throw err; });
  return optionalColumnsProbe;
}

/** CA_0264's topic_revision_id + season_id both exist. The verifier WARNs when false. */
export async function reviewLadderColumnsExist(): Promise<boolean> {
  const c = await reviewOptionalColumns();
  return c.has('topic_revision_id') && c.has('season_id');
}

/** CA_0285's served_revision_id + queue_reasons + evidence_type all exist. The verifier WARNs when false. */
export async function reviewReasonColumnsExist(): Promise<boolean> {
  const c = await reviewOptionalColumns();
  return c.has('served_revision_id') && c.has('queue_reasons') && c.has('evidence_type');
}

/**
 * Idempotent upsert into the review queue keyed on (batch_id, politician_id-or-name, topic_key).
 *
 * 🔴 The DO UPDATE touches only rows still UNDECIDED (pending / unresolved_politician). Without
 * that guard, re-running a batch reset a row a person had already rejected or resolved back to
 * `pending` (it copies EXCLUDED.status) — resurrecting a decision (I1).
 *
 * Writes each OPTIONAL_REVIEW_COLUMNS column that exists (a re-run refreshes them on an undecided
 * row, like every other research field). Pass `opts.columns` to skip the probe (the verifier
 * probes once and warns); `opts.ladderColumns` is the older boolean form for CA_0264's pair only.
 *
 * Returns true when a row was inserted or updated, false when the existing row was already
 * decided and was left alone.
 */
export async function upsertReviewRow(
  row: ReviewInsertRow,
  opts: { ladderColumns?: boolean; columns?: ReadonlySet<OptionalReviewColumn> } = {},
): Promise<boolean> {
  const { pool } = await import('./db.js');
  const present: ReadonlySet<OptionalReviewColumn> = opts.columns
    ?? (opts.ladderColumns === undefined ? await reviewOptionalColumns()
      : new Set<OptionalReviewColumn>(opts.ladderColumns ? ['topic_revision_id', 'season_id'] : []));
  const params: unknown[] = [
    row.batch_id, row.politician_id, row.full_name_raw, row.topic_id, row.topic_key,
    row.proposed_value, row.proposed_reasoning, JSON.stringify(row.evidence),
    row.verified_source_count, row.threshold, row.status, row.re_research_attempted,
  ];
  // Fixed order, so the SQL for a given set of columns is always the same text.
  const extra = (Object.keys(OPTIONAL_REVIEW_COLUMNS) as OptionalReviewColumn[]).filter((c) => present.has(c));
  const cast: Record<OptionalReviewColumn, string> = {
    topic_revision_id: '', season_id: '', served_revision_id: '', queue_reasons: '::text[]', evidence_type: '',
  };
  const placeholders = extra.map((c) => {
    params.push(row[c]);
    return `$${params.length}${cast[c]}`;
  });
  const res = await pool.query(
    `INSERT INTO inform.stance_research_review
       (batch_id, politician_id, full_name_raw, topic_id, topic_key,
        proposed_value, proposed_reasoning, evidence,
        verified_source_count, threshold, status, re_research_attempted${extra.length ? `,\n        ${extra.join(', ')}` : ''})
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10, $11, $12${placeholders.length ? `, ${placeholders.join(', ')}` : ''})
     ON CONFLICT (batch_id, COALESCE(politician_id::text, full_name_raw), topic_key)
     DO UPDATE SET
       proposed_value = EXCLUDED.proposed_value,
       proposed_reasoning = EXCLUDED.proposed_reasoning,
       evidence = EXCLUDED.evidence,
       verified_source_count = EXCLUDED.verified_source_count,
       threshold = EXCLUDED.threshold,
       status = EXCLUDED.status,
       re_research_attempted = EXCLUDED.re_research_attempted${extra.map((c) => `,\n       ${c} = EXCLUDED.${c}`).join('')}
     WHERE inform.stance_research_review.status IN ('pending', 'unresolved_politician')`,
    params,
  );
  return (res.rowCount ?? 0) > 0;
}
