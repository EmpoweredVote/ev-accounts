/**
 * Season composition — types and the ONE derivation of carried/changed/
 * dropped/added, shared by the compose grid and the board presentation view
 * so the two can never disagree.
 *
 * Types mirror backend/src/lib/seasonCompositionService.ts (the admin app has
 * no shared types package; TopicsPage duplicates its Topic type the same way).
 */

export interface SeasonRow {
  id: string;
  number: number;
  name: string;
  status: 'draft' | 'open' | 'closed';
  opened_at: string | null;
  closed_at: string | null;
  public_note: string;
  question_count: number;
}

export interface RevisionContent {
  revision_id: string;
  revision: number;
  title: string;
  short_title: string;
  question_text: string;
  ladder: { value: number; text: string }[];
}

export interface SeasonMembership {
  question_number: number;
  display_order: number;
  pin: RevisionContent;
}

export interface CompositionTopic {
  topic_id: string;
  topic_key: string;
  current: RevisionContent | null;
  in_open: SeasonMembership | null;
  in_draft: SeasonMembership | null;
  distribution: Record<number, number>;
  answer_total: number;
}

export interface CompositionPayload {
  open_season: SeasonRow | null;
  draft_season: SeasonRow | null;
  topics: CompositionTopic[];
}

export type TopicStatus = 'carried' | 'changed' | 'dropped' | 'added' | 'available';

export interface Classified {
  topic: CompositionTopic;
  status: TopicStatus;
  /** Draft pin lags the current published revision — re-pin is available. */
  pin_is_stale: boolean;
}

/**
 * With no draft, the open season IS the composition: everything it asks is
 * `carried` and nothing can be dropped or added — the presentation view of
 * Season 1 alone.
 */
export function classifyTopic(t: CompositionTopic, hasDraft: boolean): Classified {
  const pinStale = Boolean(
    hasDraft && t.in_draft && t.current
    && t.in_draft.pin.revision_id !== t.current.revision_id,
  );
  let status: TopicStatus;
  if (t.in_open && t.in_draft) {
    status = t.in_open.pin.revision_id === t.in_draft.pin.revision_id ? 'carried' : 'changed';
  } else if (t.in_open) {
    status = hasDraft ? 'dropped' : 'carried';
  } else if (t.in_draft) {
    status = 'added';
  } else {
    status = 'available';
  }
  return { topic: t, status, pin_is_stale: pinStale };
}

export function classifyAll(topics: CompositionTopic[], hasDraft: boolean): Classified[] {
  return topics.map((t) => classifyTopic(t, hasDraft));
}

export function statCounts(rows: Classified[]): {
  carried: number; changed: number; dropped: number; added: number;
} {
  const counts = { carried: 0, changed: 0, dropped: 0, added: 0 };
  for (const r of rows) {
    if (r.status !== 'available') counts[r.status] += 1;
  }
  return counts;
}
