import { describe, it, expect } from 'vitest';
import { buildCoderPrompt, shuffleSeeded, seedFor, type SeatContext, type PromptTopic } from './coderPrompt.js';
import type { SnapshotRecord } from './snapshotSources.js';
import type { S1Lead } from './s1Leads.js';

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
  it('never receives an S1 lead — its reasoning cannot reach the prompt, and no parameter accepts one', () => {
    const lead: S1Lead = {
      topic_id: 't1', topic_key: 'trans-athletes', season_number: 1, value: 4, pin_revision_id: 'r1',
      reasoning: 'S1-LEAD-MARKER (a prior season answer — must never anchor a coder)', sources: [], seed: 'fresh',
    };
    // Built through the same inputs build-coder-inputs.ts assembles for a real prompt: SeatContext +
    // PromptTopic[] + SnapshotRecord[] — none of them carry an S1Lead, so there is no field anywhere
    // in this call that could smuggle `lead.reasoning` through, even by accident.
    const p = buildCoderPrompt({ codebookMd: '# CODEBOOK', seat, topics: [topic], snapshots: snaps, slot: 1, seed: 1, labelPath: '/b/labels/coder-1.json' });
    expect(p).not.toContain(lead.reasoning);
    expect(p).not.toContain('S1-LEAD-MARKER');

    // Type-level guard: buildCoderPrompt's parameter object has no field for a lead today. If a
    // later change adds one (an `s1Leads` property, say), the excess-property check below starts
    // passing, TypeScript reports the `@ts-expect-error` as unused, and the direct tsc run in the
    // brief (which covers this file) turns red — catching the regression before it ships.
    // @ts-expect-error buildCoderPrompt accepts no s1Leads/leads parameter — adding one must break this.
    buildCoderPrompt({ codebookMd: '# CODEBOOK', seat, topics: [topic], snapshots: snaps, slot: 1, seed: 1, labelPath: '/b/labels/coder-1.json', s1Leads: [lead] });
  });
});
