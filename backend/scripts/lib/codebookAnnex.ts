/**
 * codebookAnnex — renders a per-topic annex SKELETON (codebook Part C) from the served ladder.
 * It copies the rung text verbatim and leaves every judgment field as `_fill:` for a person. It never
 * infers orientation or evidence guidance: those are rulings, not derivations (stance-program P4).
 */
import { existsSync } from 'node:fs';
import { join } from 'node:path';

export interface AnnexTopic {
  topic_id: string;
  topic_key: string;
  served_revision_id: string;
  question_text: string;
  stances: { value: number; text: string }[];
  roles?: { level: string; evidence_basis?: string | null }[];
}

export function renderAnnexSkeleton(t: AnnexTopic, season: string): string {
  const asked = [...new Set((t.roles ?? []).map((r) => r.level))].sort();
  const ownWords = [...new Set((t.roles ?? []).filter((r) => r.evidence_basis === 'own-words').map((r) => r.level))].sort();
  const rungs = [...t.stances]
    .sort((a, b) => a.value - b.value)
    .map((s) => [
      `${s.value}. "${s.text}"`,
      '   - Operative clauses: _fill: ',
      '   - Establishing evidence looks like: _fill: ',
      '   - Levels that hold a lever: _fill: ',
      '   - Known chair-shaped instruments: _fill: ',
      '   - Commonly confused with: _fill: ',
    ].join('\n'));
  return [
    `# ${t.topic_key} — served revision ${t.served_revision_id} (${season})`,
    '',
    `Question: ${t.question_text}`,
    'Orientation: UNSET — standard | inverted | off-axis, set by a person (stance-program §12.3 P4 is owed).',
    'Levels with a lever: _fill: (per rung, below; records and own words count here)',
    `Asked at: ${asked.join(', ') || 'none recorded'} (compass_topic_roles)${ownWords.length ? `. Own words only at: ${ownWords.join(', ')}` : ''}`,
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

/**
 * The annex a coder prompt pastes in. A non-open season (a bundle whose batch dir carries
 * season.json) reads `annex/season<N>/<topic_key>.md` when that file exists: a topic whose pin in
 * that season is a new revision has its own annex there, and the root file describes the open
 * season's ladder. With no such file, or for the open season (`season` null or status open), it is
 * the root file — exactly what the open season has always read.
 */
export function coderAnnexPath(
  repoRoot: string,
  topicKey: string,
  season: { number: number; status: string } | null,
  exists: (p: string) => boolean = existsSync,
): string {
  if (season && season.status !== 'open') {
    const p = join(repoRoot, 'docs', 'codebook', 'annex', `season${season.number}`, `${topicKey}.md`);
    if (exists(p)) return p;
  }
  return annexPath(repoRoot, topicKey);
}
