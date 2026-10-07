/**
 * coderQueue — turns a coded batch's consensus into the EXISTING publish path: one
 * inform.stance_research_review row per unanimous chair, approved by a person on the review page
 * (resolveResearchReview), which writes answer + context + one politician_context_evidence row per
 * source. No new table (operator, 2026-10-06): the review table already carries the spec §4.5
 * columns (consensus_value, unanimous, codebook_version, office_id), and stance_coder_labels.review_id
 * links the labels back.
 *
 * Every row is QUEUED, never auto-published: no stratum is certified yet (spec §7 P3), and
 * review-all is the standing ruling (2026-09-22). The would-publish rows carry the queue reason
 * `stratum-uncertified` (spec §1.7).
 *
 * Pure: no DB, no network.
 */
import { normalizeText, MIN_SNIPPET_WORDS } from '../../src/lib/researchVerifier.js';
import type { EvidenceTier } from './evidenceTier.js';
import type { CoderRow, Passage, QuoteLabel } from './coderLabel.js';
import type { RowReport } from './codingReport.js';

export interface SnapshotInfo { url: string; source_kind: string; snapshot_text: string }

/** One source on a review row. `date` + `date_precision` are copied to politician_context_evidence. */
export interface CoderEvidenceEntry {
  url: string;
  snapshot_id: string;
  date: string | null;
  date_precision: 'day' | 'month' | 'year' | null;
  snippets: { snippet_index: number; snippet: string; verdict: 'verified'; matched_span: string }[];
}

/**
 * A coder date (YYYY | YYYY-MM | YYYY-MM-DD, validated by coderLabel.isCoderDate) as a SQL date plus
 * its precision. A year-only date is YYYY-01-01 with precision 'year' — never an invented day.
 */
export function coderDateToSql(d: string | null | undefined): { date: string; precision: 'day' | 'month' | 'year' } | null {
  if (!d) return null;
  if (/^\d{4}$/.test(d)) return { date: `${d}-01-01`, precision: 'year' };
  if (/^\d{4}-\d{2}$/.test(d)) return { date: `${d}-01`, precision: 'month' };
  if (/^\d{4}-\d{2}-\d{2}$/.test(d)) return { date: d, precision: 'day' };
  return null;
}

/**
 * The text approval publishes for a source (I6): an on-page window of the snapshot around the
 * coder's verbatim span, widened to MIN_SNIPPET_WORDS words, in the page's own words and case.
 * null when the span cannot be located, or the snapshot is shorter than the minimum.
 */
export function publishableWindow(snapshotText: string, span: string, minWords = MIN_SNIPPET_WORDS): string | null {
  // Words are compared without punctuation at their ends: a span that stops at "Behning" must
  // match the page's "Behning," — the coder quoted the words, not the comma after them.
  const word = (t: string) => normalizeText(t).replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, '');
  const tokens = snapshotText.split(/\s+/).filter(Boolean);
  const norm = tokens.map(word);
  const target = span.split(/\s+/).map(word).filter(Boolean);
  if (target.length === 0 || tokens.length < minWords) return null;
  let start = -1;
  for (let i = 0; i + target.length <= norm.length && start < 0; i++) {
    if (target.every((w, k) => norm[i + k] === w)) start = i;
  }
  if (start < 0) return null;
  let lo = start;
  let hi = start + target.length; // exclusive
  while (hi - lo < minWords) {
    if (lo > 0) lo--;
    if (hi - lo < minWords && hi < tokens.length) hi++;
  }
  return tokens.slice(lo, hi).join(' ');
}

/** The coder's verbatim spans for a passage, best first: the operative text, the act, then quotes. */
function spansFor(p: Passage, quotes: QuoteLabel[]): string[] {
  const q = quotes.filter((x) => x.snapshot_id === p.snapshot_id)
    .sort((a, b) => Number(b.v8_quotable) - Number(a.v8_quotable))
    .map((x) => x.text);
  return [p.provision_quote, p.actor_quote, ...q].filter((s): s is string => typeof s === 'string' && s.trim().length > 0);
}

export function evidenceEntries(row: CoderRow, sharedIds: readonly string[], snapshots: ReadonlyMap<string, SnapshotInfo>): CoderEvidenceEntry[] {
  const out: CoderEvidenceEntry[] = [];
  for (const p of row.passages) {
    if (!sharedIds.includes(p.snapshot_id)) continue;
    const snap = snapshots.get(p.snapshot_id);
    if (!snap) continue;
    const window = spansFor(p, row.quotes).map((s) => publishableWindow(snap.snapshot_text, s)).find((w) => w !== null) ?? null;
    const d = coderDateToSql(p.date);
    out.push({
      url: snap.url, snapshot_id: p.snapshot_id, date: d?.date ?? null, date_precision: d?.precision ?? null,
      snippets: window ? [{ snippet_index: 0, snippet: window, verdict: 'verified', matched_span: window }] : [],
    });
  }
  return out;
}

export interface CoderReviewRow {
  batch_id: string;
  politician_id: string;
  office_id: string;
  full_name_raw: string;
  topic_id: string;
  topic_key: string;
  season_id: string;
  served_revision_id: string;
  proposed_value: number;
  proposed_reasoning: string;
  evidence: CoderEvidenceEntry[];
  verified_source_count: number;
  queue_reasons: string[];
  evidence_type: 'record' | 'statement';
  codebook_version: string;
  consensus_value: number;
  evidence_tier: EvidenceTier | null;
  /** Sources with no publishable window. Approval will not list them unless a person adds the URL. */
  unpublishable: string[];
}

/**
 * The review row for one coded topic, or null when the batch does not propose a chair. Only a
 * unanimous chair is queued: a split, a missing coder or a source request goes back to the coder
 * loop (spec §1.5), and a unanimous blank writes nothing (codingReport `unanimous-blank-no-write`).
 */
export function buildCoderReviewRow(i: {
  batchId: string; seasonId: string; codebookVersion: string;
  seat: { politician_id: string; office_id: string; full_name: string };
  topic: { topic_id: string; topic_key: string; served_revision_id: string };
  report: RowReport;
  consensusRow: CoderRow;
  snapshots: ReadonlyMap<string, SnapshotInfo>;
}): CoderReviewRow | null {
  const o = i.report.outcome;
  if (o.kind !== 'unanimous-chair') return null;
  const evidence = evidenceEntries(i.consensusRow, o.shared_sources, i.snapshots);
  const reasons = [...i.report.shadow_reasons];
  if (i.report.shadow === 'would-publish-if-certified') reasons.push('stratum-uncertified');
  return {
    batch_id: i.batchId, politician_id: i.seat.politician_id, office_id: i.seat.office_id, full_name_raw: i.seat.full_name,
    topic_id: i.topic.topic_id, topic_key: i.topic.topic_key, season_id: i.seasonId,
    served_revision_id: i.topic.served_revision_id,
    proposed_value: o.value, consensus_value: o.value, proposed_reasoning: i.consensusRow.reasoning,
    evidence, verified_source_count: evidence.filter((e) => e.snippets.length > 0).length,
    queue_reasons: reasons,
    evidence_type: i.report.stratum.evidence_class === 'record' ? 'record' : 'statement',
    codebook_version: i.codebookVersion,
    evidence_tier: i.report.evidence_tier,
    unpublishable: evidence.filter((e) => e.snippets.length === 0).map((e) => e.url),
  };
}
