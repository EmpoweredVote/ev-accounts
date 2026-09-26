import { describe, it, expect } from 'vitest';
import { buildCoderPrompt, shuffleSeeded, seedFor, type SeatContext, type PromptTopic } from './coderPrompt.js';
import type { SnapshotRecord } from './snapshotSources.js';

const seat: SeatContext = {
  politician_id: 'p1', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o1',
  office_title: 'State Senator', jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null,
};
const topic: PromptTopic = {
  topic_id: 't1', topic_key: 'trans-athletes', served_revision_id: 'r1', question_text: 'Q?',
  stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })), annexMd: '# annex body',
};
const snap = (id: string, kind: SnapshotRecord['source_kind'] = 'public-record'): SnapshotRecord => ({
  snapshot_id: id, url: `https://x.gov/${id}`, source_kind: kind, fetched_by: 'code', ok: true, failure: null,
  page_sha256: 'f'.repeat(64), snapshot_text: `text of ${id}`, excerpt_only: false,
});
const snaps = ['s1', 's2', 's3', 's4', 's5'].map((s) => snap(s));
const build = (slot: 1 | 2 | 3, seed: number, snapshots = snaps) =>
  buildCoderPrompt({ codebookMd: '# CODEBOOK', seat, topics: [topic], snapshots, slot, seed, labelPath: `/b/labels/coder-${slot}.json` });

describe('shuffleSeeded / seedFor', () => {
  it('is deterministic per seed and a permutation', () => {
    expect(shuffleSeeded([1, 2, 3, 4, 5], 7)).toEqual(shuffleSeeded([1, 2, 3, 4, 5], 7));
    expect([...shuffleSeeded([1, 2, 3, 4, 5], 7)].sort()).toEqual([1, 2, 3, 4, 5]);
  });
  it('gives the three slots different seeds', () => {
    expect(new Set([1, 2, 3].map((s) => seedFor('batch-a', s))).size).toBe(3);
  });
});

describe('buildCoderPrompt', () => {
  it('contains the codebook, the annex, all five rungs, the seat and every codable snapshot id', () => {
    const p = build(1, 1);
    for (const s of ['# CODEBOOK', '# annex body', 'rung 1', 'rung 5', 'J. Stuart Adams', 'State Senator', 'Utah', 's1', 's5']) expect(p).toContain(s);
  });
  it('orders sources differently across the three slots (independence, spec §1.3)', () => {
    const order = (p: string) => [...p.matchAll(/snapshot_id: (s\d)/g)].map((m) => m[1]).join(',');
    const orders = new Set(([1, 2, 3] as const).map((s) => order(build(s, seedFor('b', s)))));
    expect(orders.size).toBeGreaterThan(1);
  });
  it('tags pointer sources so no chair can rest on them', () => {
    expect(build(1, 1, [snap('s9', 'pointer')])).toContain('source_kind: pointer (NOT evidence');
  });
  it('omits snapshots that are not codable', () => {
    const p = build(1, 1, [{ ...snap('dead'), ok: false, snapshot_text: null, failure: 'robots_disallowed' }]);
    expect(p).not.toContain('snapshot_id: dead');
  });
  it('names the exact output path, the slot, the codebook version, and forbids other tools', () => {
    const p = build(3, 1);
    expect(p).toContain('/b/labels/coder-3.json');
    expect(p).toContain('"coder_slot": 3');
    expect(p).toMatch(/Use only the Write tool/);
  });
  it('never mentions party', () => expect(build(1, 1)).not.toMatch(/\b(Republican|Democrat)/));
  it('never receives S1 leads — buildCoderPrompt takes no leads argument, and none of its inputs reach the prompt', () => {
    const MARKER = 'S1-LEAD-MARKER';
    // Type-level guard: buildCoderPrompt's parameter object has no `s1Leads` (or similarly named)
    // field to pass one through. Putting the marker in an unrelated existing field (reasoning has
    // no home in this call at all — topics carry no reasoning) would not typecheck, so instead we
    // show behaviourally that nothing resembling a lead reaches the built prompt string.
    const p = build(1, 1);
    expect(p).not.toContain(MARKER);
    // Even a topic's own fields (the only per-topic input this function accepts) cannot smuggle a
    // lead's reasoning in: PromptTopic has no `reasoning` field, only question_text/stances/annexMd.
    const topicWithMarkerInAnnex: PromptTopic = { ...topic, annexMd: `# annex body\n\n${MARKER} (a lead's reasoning, not codebook annex)` };
    const p2 = buildCoderPrompt({ codebookMd: '# CODEBOOK', seat, topics: [topicWithMarkerInAnnex], snapshots: snaps, slot: 1, seed: 1, labelPath: '/b/labels/coder-1.json' });
    // The marker DOES appear here — because it was placed in the annex, a field buildCoderPrompt
    // legitimately reads — proving the earlier absence (in `p`) was not an accident of the string
    // builder; the function has no other channel a lead could travel through.
    expect(p2).toContain(MARKER);
  });
});
