/**
 * topicPrepUpdate — the text the season topic-prep skill posts as an update on a topic's Story
 * (Monday Backlog board) at the end of each stage. Pure and plain text: Monday updates do not
 * render Markdown tables, so every field is one `Label: value` line in a fixed order. The skill
 * and the runner can then scan any two updates side by side. No party names appear here.
 * Status labels are the board's real ones ("In Progress", "Blocked", "Done").
 */

export type TopicPrepState = {
  topicKey: string;
  stage: '0a' | '0' | '1' | '2' | '3' | '4' | 'done' | 'parked';
  path?: 'source' | 'wording';
  /** null (shown as —) before the path ruling, or when no rate has been measured yet. */
  seatRateBefore?: number | null;
  seatRateAfter?: number | null;
  blockedOn: 'ruling' | 'sources' | 'dispute' | 'nothing';
  nextStep: string;
  owed: string[];
  disputesOpen: number;
  expertQueue: number;
  revisionId?: string;
  researchFolder: string;
};

export type StatusLabel = 'In Progress' | 'Blocked' | 'Done';

const DASH = '—';

export function storyName(topicKey: string): string {
  return `S3 topic prep — ${topicKey}`;
}

export function statusLabel(s: TopicPrepState): StatusLabel {
  if (s.stage === 'done') return 'Done';
  if (s.blockedOn !== 'nothing' || s.stage === 'parked') return 'Blocked';
  return 'In Progress';
}

function pct(r: number | null | undefined): string {
  return r == null ? DASH : `${Math.round(r * 100)}%`;
}

export function formatUpdate(s: TopicPrepState): string {
  const owed = s.owed.length === 0 ? ['Owed: none'] : ['Owed:', ...s.owed.map((o) => `- ${o}`)];
  return [
    `Stage: ${s.stage}`,
    `Path: ${s.path ?? DASH}`,
    `Seat rate: ${pct(s.seatRateBefore)} → ${pct(s.seatRateAfter)}`,
    `Blocked on: ${s.blockedOn}`,
    `Next: ${s.nextStep}`,
    ...owed,
    `Disputes open: ${s.disputesOpen}`,
    `Expert queue: ${s.expertQueue}`,
    `Revision: ${s.revisionId ?? DASH}`,
    `Folder: ${s.researchFolder}`,
  ].join('\n');
}

const escapeHtml = (t: string) => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/**
 * The same update for Monday's `create_update`, which takes HTML: each line escaped and joined with
 * `<br>`, so the plain-text layout survives (the voting-rights run joined lines by hand).
 */
export function formatUpdateHtml(s: TopicPrepState): string {
  return formatUpdate(s).split('\n').map(escapeHtml).join('<br>');
}
