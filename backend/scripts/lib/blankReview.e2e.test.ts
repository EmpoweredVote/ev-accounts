/**
 * End to end on a fixture batch (spec 2026-10-07-season2-blank-review-design.md §4): a blank in
 * research.csv → stance-gate (the real script) → stances.csv → verifier → decidePublish → review row
 * → approval. The database is mocked, so the read-path half is pinned where the read path lives:
 * compassService.test.ts "filters value 0 AFTER the collapse, so a blank in the newest season wins".
 */
import { vi, describe, it, expect, beforeAll } from 'vitest';
import { mkdtempSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';

const { mockQuery, mockClientQuery } = vi.hoisted(() => ({ mockQuery: vi.fn(), mockClientQuery: vi.fn() }));
vi.mock('../../src/lib/db.js', () => ({
  pool: { query: mockQuery, connect: async () => ({ query: mockClientQuery, release: () => undefined }) },
}));

import { parseStancesCsv, parseEvidenceCsv } from '../../src/lib/stanceResearchCsv.js';
import { verifyEvidence } from '../../src/lib/researchVerifier.js';
import { decidePublish } from './stancePublishPolicy.js';
import { checkBlankExaminedFallback, type GateFinding } from './stanceGate.js';
import { buildReviewRowForInsert, resolveResearchReview } from '../../src/lib/researchEvidenceService.js';
import { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } from '../../src/lib/seasonService.js';

const PAGE = 'Roll call on HB 1001 in 2025. Representative Jane Doe voted yes on HB 1001, the bill that funds a '
  + 'public health insurance option for state employees and their families, and she said nothing further on the floor '
  + 'about how far coverage should go or who should pay for it, according to the House Journal for that day.';
const SNIP = PAGE.split(' ').slice(5, 40).join(' ');
const S1_URL = 'https://iga.example/journal/2025-02-03';

let dir: string;
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), 'blank-e2e-'));
  writeFileSync(join(dir, 'topics.json'), JSON.stringify([{
    topic_id: 't1', topic_key: 'healthcare', topic_revision_id: 'rev-1', served_revision_id: 'rev-1', question_number: 1,
    title: 'Healthcare', question_text: '?', stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })),
    applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, applies_school: false,
  }]));
  writeFileSync(join(dir, 'politicians.json'), JSON.stringify([{ full_name: 'Jane Doe', politician_id: 'p1', level: 'state', race_id: null }]));
  writeFileSync(join(dir, 'research.csv'),
    'full_name,topic_key,value,blank_reason,evidence_type,reasoning,source_url_1,source_url_2,source_url_3,source_url_4,quote_text,quote_deidentified,editor_note\n'
    + `Jane Doe,healthcare,0,direction-only,blank,"HB 1001 shows support for a public option but cannot tell rung 1 from rung 2.",${S1_URL},,,,,,\n`);
  writeFileSync(join(dir, 'evidence.csv'), `full_name,topic_key,source_url,snippet,snippet_index\nJane Doe,healthcare,${S1_URL},"${SNIP}",1\n`);
  const run = spawnSync('npx', ['tsx', 'scripts/stance-gate.ts', '--dir', dir], { encoding: 'utf8' });
  if (run.status !== 0) throw new Error(`stance-gate exited ${run.status}: ${run.stdout}${run.stderr}`);
}, 60_000);

describe('a blank from research.csv to an approved value-0 row', () => {
  it('runs through gate → verify → policy → queue → approval', async () => {
    // Gate: clean, and stances.csv carries the blank and its reason.
    const gate = JSON.parse(readFileSync(join(dir, 'gate-findings.json'), 'utf8')) as { findings: GateFinding[]; summary: { high: number } };
    expect(gate.summary.high).toBe(0);
    const stances = parseStancesCsv(readFileSync(join(dir, 'stances.csv'), 'utf8'));
    expect(stances[0]).toMatchObject({ value: 0, blank_reason: 'direction-only', evidence_type: 'blank', source_urls: [S1_URL] });

    // Verify against a fake page.
    const { pushable, needsReResearch } = await verifyEvidence({
      stanceRows: stances, evidenceRows: parseEvidenceCsv(readFileSync(join(dir, 'evidence.csv'), 'utf8')),
      fetcher: async () => ({ ok: true, text: PAGE }), threshold: 1,
      politicianNames: { 'Jane Doe': { fullName: 'Jane Doe', lastName: 'Doe' } },
    });
    const row = [...pushable, ...needsReResearch][0];
    expect(row.verifiedSources).toHaveLength(1);

    // Voters see a Season 1 chair 2 that cites S1_URL; the blank examined it, so no fallback finding.
    expect(checkBlankExaminedFallback({ row: stances[0] as never, displayedValue: 2, fallbackSources: [S1_URL], fetchable: () => true })).toBeNull();
    const decision = decidePublish({
      proposedValue: 0, verifiedSourceCount: row.verifiedSources.length, threshold: 1, gateFindings: gate.findings,
      politicianResolved: true, existingOpenSeasonValue: null, displayedValue: 2, autoPushEnabled: true,
    });
    expect(decision).toEqual({ action: 'review', reasons: ['blank-replaces-published-chair'] });

    // Queue row.
    const queued = buildReviewRowForInsert({ row, politicianId: 'p1', topicId: 't1', batchId: 'e2e', threshold: 1,
      reResearchAttempted: false, queueReasons: ['blank-replaces-published-chair'] });
    expect(queued).toMatchObject({ proposed_value: 0, proposed_blank_reason: 'direction-only', evidence_type: 'blank' });

    // Approval, reading the queued row back as the service would.
    mockQuery.mockResolvedValueOnce({ rows: [{ ...queued, id: 'rev-e2e', status: 'pending', created_at: '2026-10-07T12:00:00Z',
      shown_value: '2', shown_season_number: 1 }] });
    mockClientQuery.mockImplementation(async (sql: string) =>
      String(sql).includes("FROM inform.seasons WHERE status = 'open'") ? { rows: [{ number: 2 }], rowCount: 1 } : { rows: [], rowCount: 1 });
    await resolveResearchReview('rev-e2e', 'editor-1');
    const calls = mockClientQuery.mock.calls;
    expect(calls.find((c) => c[0] === UPSERT_ANSWER_SQL)![1]).toEqual(['p1', 't1', 0, 'editor-1']);
    expect(calls.find((c) => c[0] === UPSERT_CONTEXT_SQL)![1][2]).toMatch(/^Blank in Season 2 \(direction-only\) — researched on 2026-10-07\. /);
    expect(calls.filter((c) => String(c[0]).includes('politician_context_evidence'))).toHaveLength(1);
    expect(calls.at(-1)![0]).toBe('COMMIT');
  });
});
