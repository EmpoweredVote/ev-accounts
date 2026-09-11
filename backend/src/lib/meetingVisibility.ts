/**
 * meetingVisibility — the single server-side gate deciding which meeting
 * statuses an unauthenticated (public) caller may see.
 *
 * WHY THIS FILE EXISTS:
 * The on-the-record US-House-floor weekly automation writes real floor meetings
 * to `meetings.meetings` with `status = 'draft'` for human review, then a human
 * flips them to `'published'`. A draft floor meeting resolves real House members
 * to a `politician_id`, so its transcript segments, votes, agenda items, speaker
 * appearances, roster aggregates, topic tags and full-text search hits are all
 * derived rows that could surface on live public pages before a human has
 * reviewed them. The on-the-record web app filters some surfaces client-side,
 * but not all — so ev-accounts is the authoritative gate and MUST exclude
 * non-public statuses server-side on every public meeting-derived read.
 * See on-the-record ev-cto decision 0017.
 *
 * The allowlist below is the whole policy. `draft`, `processing`, and any future
 * internal status are invisible to the public; only `published` (fully processed
 * transcripts/summaries/votes) and `scheduled` (agenda-only upcoming meetings)
 * are public.
 *
 * LEAVES ROOM FOR THE AUTHENTICATED ADMIN PATH (Project 2): the meeting read
 * functions accept `{ includeAllStatuses }`. A privileged, authenticated caller
 * passes `true` to see drafts; public reads leave it false/absent and the
 * allowlist applies. This task wires only the public exclusion.
 */

/**
 * Meeting statuses a public (unauthenticated) viewer may see. Everything else is
 * excluded server-side. This is an ALLOWLIST, not a denylist — a new internal
 * status is hidden by default rather than leaking until someone remembers to add
 * it to a blocklist.
 */
export const PUBLIC_MEETING_STATUSES = ['published', 'scheduled'] as const;

export type PublicMeetingStatus = (typeof PUBLIC_MEETING_STATUSES)[number];

export interface MeetingViewerOptions {
  /**
   * When true, a privileged (authenticated admin) caller bypasses the public
   * status allowlist and may see drafts. Public reads MUST leave this false or
   * absent. Reserved for the Project-2 admin panel; unused by public routes.
   */
  includeAllStatuses?: boolean;
}

// The allowlist rendered as a SQL literal list, e.g. `'published', 'scheduled'`.
// Built from the constant so the SQL can never drift from the policy. The values
// are compile-time constants (never user input), so embedding them as literals
// is injection-safe and — crucially — consumes no bind parameter, letting the
// clause drop into any query without disturbing its `$N` numbering.
const STATUS_LITERALS = PUBLIC_MEETING_STATUSES.map((s) => `'${s}'`).join(', ');

/**
 * SQL boolean fragment restricting a meetings-table read to publicly-visible
 * statuses. Pass the qualified status column (e.g. `m.status`); defaults to the
 * bare `status` for unaliased `meetings.meetings` queries.
 */
export function publicMeetingStatusClause(statusColumn = 'status'): string {
  return `${statusColumn} IN (${STATUS_LITERALS})`;
}

/**
 * SQL `EXISTS (...)` fragment gating a DERIVED row (a segment, vote, agenda item,
 * topic tag) on its parent meeting being publicly visible — for queries that read
 * a child table without already joining `meetings.meetings`.
 *
 * `meetingIdExpr` is a SQL expression naming the child's meeting-id — a column
 * reference (`s.meeting_id`) or a bind placeholder (`$1`). It is NEVER user
 * input; callers pass a literal fragment, so this is injection-safe.
 */
export function publicMeetingExistsClause(meetingIdExpr: string): string {
  return `EXISTS (SELECT 1 FROM meetings.meetings mv WHERE mv.id = ${meetingIdExpr} AND ${publicMeetingStatusClause('mv.status')})`;
}
