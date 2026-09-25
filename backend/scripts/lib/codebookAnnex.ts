/**
 * codebookAnnex — renders a per-topic annex SKELETON (codebook Part C) from the served ladder.
 * It copies the rung text verbatim and leaves every judgment field as `_fill:` for a person. It never
 * infers orientation or evidence guidance: those are rulings, not derivations (stance-program P4).
 */
import { join } from 'node:path';

export interface AnnexTopic {
  topic_id: string;
  topic_key: string;
  served_revision_id: string;
  question_text: string;
  stances: { value: number; text: string }[];
  roles?: { level: string }[];
}

export function renderAnnexSkeleton(t: AnnexTopic, season: string): string {
  const levels = [...new Set((t.roles ?? []).map((r) => r.level))].sort().join(', ') || 'none recorded';
  const rungs = [...t.stances]
    .sort((a, b) => a.value - b.value)
    .map((s) => [
      `${s.value}. "${s.text}"`,
      '   - Operative clauses: _fill: ',
      '   - Establishing evidence looks like: _fill: ',
      '   - Known chair-shaped instruments: _fill: ',
      '   - Commonly confused with: _fill: ',
    ].join('\n'));
  return [
    `# ${t.topic_key} — served revision ${t.served_revision_id} (${season})`,
    '',
    `Question: ${t.question_text}`,
    'Orientation: UNSET — standard | inverted | off-axis, set by a person (stance-program §12.3 P4 is owed).',
    `Levels with a role: ${levels}`,
    '',
    '## Rungs',
    '',
    ...rungs,
    '',
    '## Hard cases',
    '',
    '_fill: ',
    '',
  ].join('\n');
}

export const annexPath = (repoRoot: string, topicKey: string): string =>
  join(repoRoot, 'docs', 'codebook', 'annex', `${topicKey}.md`);
