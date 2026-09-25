import { vi, describe, it, expect, beforeEach } from 'vitest';
import type { VerifiedRow } from './researchVerifier.js';

const mockQuery = vi.fn().mockResolvedValue({ rows: [] });
// A transaction client (pool.connect()): its own query mock, so a test can tell what ran inside
// the transaction from what ran on the pool. Default: every statement succeeds with rowCount 1.
const mockClientQuery = vi.fn().mockResolvedValue({ rows: [], rowCount: 1 });
const mockRelease = vi.fn();
const mockConnect = vi.fn(async () => ({ query: mockClientQuery, release: mockRelease }));
vi.mock('./db.js', () => ({
  pool: { query: mockQuery, connect: mockConnect },
}));

import { buildEvidenceRowsForInsert, buildReviewRowForInsert } from './researchEvidenceService.js';

const exampleRow: VerifiedRow = {
  stance: { full_name: 'Brad Sherman', politician_id: '', topic_key: 'healthcare', value: 2, reasoning: 'public option' },
  verifiedSources: [
    {
      url: 'https://a.example',
      snippets: [
        { snippet: 'snippet text one', snippet_index: 0, verdict: { verdict: 'verified', matchOffset: 100 }, matchedSpan: 'text one' },
        { snippet: 'snippet text two', snippet_index: 1, verdict: { verdict: 'snippet_not_found' } },
      ],
    },
  ],
  failedSources: [],
};

describe('buildEvidenceRowsForInsert', () => {
  it('flattens verified-only snippets per source for DB insert', () => {
    const rows = buildEvidenceRowsForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
    });
    expect(rows).toEqual([
      {
        politician_id: '11111111-1111-1111-1111-111111111111',
        topic_id: '22222222-2222-2222-2222-222222222222',
        source_url: 'https://a.example',
        // I6: the matched on-page span, never the full snippet.
        snippet: 'text one',
        snippet_index: 0,
        batch_id: '2026-04-30-test',
      },
    ]);
  });
  it('I6: a verified snippet with no matched span is not published', () => {
    const noSpan: VerifiedRow = { ...exampleRow, verifiedSources: [{ url: 'https://a.example', snippets: [
      { snippet: 'snippet text one', snippet_index: 0, verdict: { verdict: 'verified', matchOffset: 100 } }] }] };
    expect(buildEvidenceRowsForInsert({ row: noSpan, politicianId: 'p', topicId: 't', batchId: 'b' })).toEqual([]);
  });
});

describe('buildReviewRowForInsert', () => {
  it('captures every snippet verdict in the evidence jsonb', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: '11111111-1111-1111-1111-111111111111',
      topicId: '22222222-2222-2222-2222-222222222222',
      batchId: '2026-04-30-test',
      threshold: 2,
      reResearchAttempted: true,
    });
    expect(review.batch_id).toBe('2026-04-30-test');
    expect(review.politician_id).toBe('11111111-1111-1111-1111-111111111111');
    expect(review.topic_key).toBe('healthcare');
    expect(review.proposed_value).toBe(2);
    expect(review.threshold).toBe(2);
    expect(review.re_research_attempted).toBe(true);
    expect(review.verified_source_count).toBe(1);
    const ev = review.evidence as any[];
    expect(ev[0].url).toBe('https://a.example');
    expect(ev[0].snippets).toHaveLength(2);
    expect(ev[0].snippets[1].verdict).toBe('snippet_not_found');
  });

  it('uses unresolved_politician status when politicianId is null', () => {
    const review = buildReviewRowForInsert({
      row: exampleRow,
      politicianId: null,
      topicId: null,
      batchId: 'b',
      threshold: 2,
      reResearchAttempted: false,
    });
    expect(review.status).toBe('unresolved_politician');
    expect(review.full_name_raw).toBe('Brad Sherman');
  });
});

describe('accumulateEvidence', () => {
  beforeEach(() => mockQuery.mockClear());

  it('is exported as accumulateEvidence (replaceEvidence is gone)', async () => {
    const mod = await import('./researchEvidenceService.js');
    expect(typeof (mod as any).accumulateEvidence).toBe('function');
    expect((mod as any).replaceEvidence).toBeUndefined();
  });

  it('uses INSERT ON CONFLICT DO NOTHING — no DELETE', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    await accumulateEvidence([{
      politician_id: '11111111-1111-1111-1111-111111111111',
      topic_id: '22222222-2222-2222-2222-222222222222',
      source_url: 'https://a.example',
      snippet: 'test snippet',
      snippet_index: 0,
      batch_id: 'test-batch',
    }]);
    const sqls = mockQuery.mock.calls.map((c: any[]) => String(c[0]).toUpperCase());
    expect(sqls.some(s => s.includes('ON CONFLICT') && s.includes('DO NOTHING'))).toBe(true);
    expect(sqls.some(s => s.startsWith('DELETE'))).toBe(false);
  });

  it('returns without querying when rows array is empty', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    expect(await accumulateEvidence([])).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  // I9 (partial): report what was really inserted — the season-less unique index drops a snippet
  // already stored for the pair, and that must not be counted as written.
  it('returns the number of rows actually inserted (sum of rowCount), not the number attempted', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    const r = { politician_id: 'p', topic_id: 't', source_url: 'u', snippet: 's', snippet_index: 0, batch_id: 'b' };
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 0 });
    expect(await accumulateEvidence([r, { ...r, snippet_index: 1 }])).toBe(1);
  });

  it('writes on the caller\'s transaction client when given one, not on the pool', async () => {
    const { accumulateEvidence } = await import('./researchEvidenceService.js');
    const client = { query: vi.fn().mockResolvedValue({ rows: [], rowCount: 1 }) };
    const n = await accumulateEvidence([{ politician_id: 'p', topic_id: 't', source_url: 'u', snippet: 's', snippet_index: 0, batch_id: 'b' }], client);
    expect(n).toBe(1);
    expect(client.query).toHaveBeenCalledTimes(1);
    expect(mockQuery).not.toHaveBeenCalled();
  });
});

// I1: re-running a batch must never resurrect a row a person already decided.
describe('upsertReviewRow', () => {
  beforeEach(() => mockQuery.mockClear());
  const reviewInsert = {
    batch_id: 'b', politician_id: 'p', full_name_raw: 'Jane Doe', topic_id: 't', topic_key: 'healthcare',
    proposed_value: 2, proposed_reasoning: 'r', evidence: [], verified_source_count: 1, threshold: 1,
    status: 'pending' as const, re_research_attempted: false,
    topic_revision_id: 'rev-a', season_id: 'season-2',
    served_revision_id: 'rev-a3', queue_reasons: ['review-all-mode'], evidence_type: 'record',
  };
  it('updates only rows still undecided — the ON CONFLICT DO UPDATE carries a status guard', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert, { ladderColumns: true });
    const sql = String(mockQuery.mock.calls[0][0]);
    const guard = /WHERE\s+inform\.stance_research_review\.status\s+IN\s*\(\s*'pending'\s*,\s*'unresolved_politician'\s*\)/;
    expect(sql).toMatch(guard);
    expect(sql.search(guard)).toBeGreaterThan(sql.indexOf('DO UPDATE'));
  });
  it('reports whether it wrote: false when the existing row was already decided', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 0 });
    expect(await upsertReviewRow(reviewInsert, { ladderColumns: true })).toBe(true);
    expect(await upsertReviewRow(reviewInsert, { ladderColumns: true })).toBe(false);
  });

  // CA_0264: the row remembers the ladder it was researched against — and a re-run refreshes it.
  it('writes topic_revision_id + season_id (insert and refresh) when the CA_0264 columns exist', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert, { ladderColumns: true });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(String(sql)).toMatch(/re_research_attempted,\s*topic_revision_id, season_id\)/);
    expect(String(sql)).toContain('$13, $14');
    expect(String(sql)).toContain('topic_revision_id = EXCLUDED.topic_revision_id');
    expect(String(sql)).toContain('season_id = EXCLUDED.season_id');
    expect((params as unknown[]).slice(12)).toEqual(['rev-a', 'season-2']);
  });
  it('omits them — the pre-CA_0264 INSERT, unchanged — when the columns do not exist yet', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert, { ladderColumns: false });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(String(sql)).not.toContain('topic_revision_id');
    expect(String(sql)).not.toContain('season_id');
    expect(params).toHaveLength(12);
  });
  // CA_0285 (not applied yet): the queue write names the new columns only once they exist.
  it('writes served_revision_id, queue_reasons (text[]) and evidence_type when CA_0285 is applied', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert, { columns: new Set(['topic_revision_id', 'season_id', 'served_revision_id', 'queue_reasons', 'evidence_type'] as const) });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(String(sql)).toMatch(/topic_revision_id, season_id, served_revision_id, queue_reasons, evidence_type\)/);
    expect(String(sql)).toContain('$13, $14, $15, $16::text[], $17');
    expect(String(sql)).toContain('queue_reasons = EXCLUDED.queue_reasons');
    expect((params as unknown[]).slice(12)).toEqual(['rev-a', 'season-2', 'rev-a3', ['review-all-mode'], 'record']);
  });
  it('before CA_0285 (only CA_0264 applied) writes exactly the CA_0264 INSERT', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await upsertReviewRow(reviewInsert, { columns: new Set(['topic_revision_id', 'season_id'] as const) });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(String(sql)).not.toContain('served_revision_id');
    expect(String(sql)).not.toContain('queue_reasons');
    expect(params).toHaveLength(14);
  });
  it('probes information_schema for the columns once, when the caller does not say', async () => {
    const { upsertReviewRow } = await import('./researchEvidenceService.js');
    mockQuery
      .mockResolvedValueOnce({ rows: [{ column_name: 'topic_revision_id' }, { column_name: 'season_id' }] }) // probe
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })    // upsert 1
      .mockResolvedValueOnce({ rows: [], rowCount: 1 });   // upsert 2 (probe cached)
    await upsertReviewRow(reviewInsert);
    await upsertReviewRow(reviewInsert);
    const sqls = mockQuery.mock.calls.map((c: any[]) => String(c[0]));
    expect(sqls.filter((q) => q.includes('information_schema.columns'))).toHaveLength(1);
    expect(sqls[1]).toContain('topic_revision_id');
    expect(sqls[2]).toContain('topic_revision_id');
  });
});

describe('buildReviewRowForInsert — ladder revision (CA_0264)', () => {
  it('carries the bundle revision and the open season; null when not given', () => {
    const base = { row: exampleRow, politicianId: 'p', topicId: 't', batchId: 'b', threshold: 1, reResearchAttempted: false };
    expect(buildReviewRowForInsert({ ...base, topicRevisionId: 'rev-a', seasonId: 's2' }))
      .toMatchObject({ topic_revision_id: 'rev-a', season_id: 's2' });
    expect(buildReviewRowForInsert(base)).toMatchObject({ topic_revision_id: null, season_id: null });
  });
});

describe('ladderState', () => {
  // C1: a clarifying publish moves the served text without moving the pin — that is a change too.
  it.each([
    ['s1', 's1', false],
    ['s1', 's3', true],
    [null, 's3', false],               // row queued before CA_0285: served unknown, pin decides
  ])('same pin, row served %j vs open served %j → changed=%j', async (rowServed, openServed, changed) => {
    const { ladderState } = await import('./researchEvidenceService.js');
    expect(ladderState('rev-a', 'rev-a', rowServed, openServed).ladderChanged).toBe(changed);
  });
  it.each([
    ['rev-a', 'rev-a', false, false],
    ['rev-a', 'rev-b', false, true],
    ['rev-a', null, false, true],       // the open season no longer asks the topic
    [null, 'rev-b', true, false],       // legacy row: unknown, not "changed"
    [null, null, true, false],
  ])('row %j vs open pin %j → unknown=%j changed=%j', async (rowRev, openRev, unknown, changed) => {
    const { ladderState } = await import('./researchEvidenceService.js');
    expect(ladderState(rowRev, openRev)).toMatchObject({ ladderRevisionUnknown: unknown, ladderChanged: changed });
  });
});

// I5: the reviewer sees what approving would replace — including an editor's blank.
describe('review reads carry the open-season current value', () => {
  beforeEach(() => mockQuery.mockClear());
  it('selects the pair\'s OPEN-season answer, marked as a site that counts blanks', async () => {
    const { getResearchReviewById, listPendingResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [] });
    await getResearchReviewById('x');
    await listPendingResearchReview();
    for (const [sql] of mockQuery.mock.calls) {
      expect(String(sql)).toContain('@zero-scope: counts-blanks');
      expect(String(sql)).toMatch(/inform\.politician_answers[\s\S]*s\.status = 'open'/);
      // CA_0264: the open season's current pin for the topic, beside the row's own revision.
      expect(String(sql)).toContain('AS open_topic_revision_id');
      expect(String(sql)).toMatch(/inform\.season_questions[\s\S]*s\.status = 'open'[\s\S]*\) open_pin ON true/);
      // C1: and its SERVED revision (ADR 0006), through the shared resolver.
      expect(String(sql)).toContain('AS open_served_revision_id');
      expect(String(sql)).toMatch(/e\.status IN \('published', 'superseded'\)[\s\S]*WHERE pin\.id = open_pin\.topic_revision_id/);
      // I2: what voters see — the newest PUBLISHED season (not the open one), blanks included.
      expect(String(sql)).toMatch(/s\.status <> 'draft'[\s\S]*\) shown ON true/);
      expect(String(sql)).toContain('AS shown_value');
    }
  });
  it('I2: maps the displayed (voter-visible) value, its season and served rung text; a 0 stays a blank', async () => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], current_value: null, shown_value: '3', shown_season_number: 1, shown_text: 'rung three', shown_history_text: 'old rung three' }] });
    const r = await getResearchReviewById('x');
    expect(r?.currentValue).toBeNull();
    expect(r?.displayed).toEqual({ value: 3, seasonNumber: 1, text: 'rung three', historyText: 'old rung three' });
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'y', evidence: [], shown_value: '0', shown_season_number: 2, shown_text: null }] });
    expect((await getResearchReviewById('y'))?.displayed).toEqual({ value: 0, seasonNumber: 2, text: null, historyText: null });
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'z', evidence: [] }] });
    expect((await getResearchReviewById('z'))?.displayed).toBeNull();
  });
  // N1 (re-review 2026-09-24): voters read the value against the OPEN season's served ladder.
  it('N1: an S1 answer on a topic whose version changed is shown with the OPEN season\'s served text', async () => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockClear();
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getResearchReviewById('x');
    const sql = String(mockQuery.mock.calls[0][0]);
    // The displayed rung joins the open season's served revision, never the answer's own pin.
    expect(sql).toMatch(/shown_sr\s+ON shown_sr\.topic_revision_id = open_eff\.id AND shown_sr\.value = shown\.value/);
    expect(sql).not.toMatch(/shown_sr\.topic_revision_id = shown_eff\.id/);
    // The answer's own ladder is kept only as history.
    expect(sql).toMatch(/shown_hist_sr\.topic_revision_id = shown_eff\.id/);
    // Mapping: S1 value 5 on climate-change, S2 v2 ladder text first, S1 v1 text as history.
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], shown_value: '5', shown_season_number: 1,
      shown_text: 'S2 served chair 5', shown_history_text: 'S1 chair 5', open_topic_revision_id: 'pin-s2' }] });
    expect((await getResearchReviewById('x'))?.displayed).toEqual(
      { value: 5, seasonNumber: 1, text: 'S2 served chair 5', historyText: 'S1 chair 5' });
  });
  it('N1: a topic the open season does not ask (S1-only, e.g. immigration) shows nothing', async () => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockClear();
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await getResearchReviewById('x');
    expect(String(mockQuery.mock.calls[0][0]))
      .toMatch(/CASE WHEN open_pin\.topic_revision_id IS NULL THEN NULL ELSE shown\.value END AS shown_value/);
    // As the database returns it for such a row: shown_value NULL.
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], shown_value: null, shown_season_number: 1,
      shown_text: null, shown_history_text: 'S1 immigration chair 4', open_topic_revision_id: null }] });
    expect((await getResearchReviewById('x'))?.displayed).toBeNull();
  });
  it('CA_0285: maps queue_reasons and evidence_type; null before the migration', async () => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], queue_reasons: ['statement-evidence', 'gate-medium'], evidence_type: 'statement' }] });
    expect(await getResearchReviewById('x')).toMatchObject({ queueReasons: ['statement-evidence', 'gate-medium'], evidenceType: 'statement' });
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'y', evidence: [] }] });
    expect(await getResearchReviewById('y')).toMatchObject({ queueReasons: null, evidenceType: null });
  });
  it.each([
    ['3', 3], ['0', 0], [null, null],
  ])('maps current_value %j to currentValue %j (0 is a blank, not "none")', async (raw, want) => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], current_value: raw }] });
    expect((await getResearchReviewById('x'))?.currentValue).toBe(want);
  });

  // Task 5, requirement 2: the list view groups by (topic, body/chamber) — the body comes from a
  // DISTINCT-ON-deduped join, never a plain politician-rooted one (CLAUDE.md — that fans out).
  it('joins the politician\'s current office body via a DISTINCT ON subquery, and maps body_label', async () => {
    const { getResearchReviewById, listPendingResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [] });
    await getResearchReviewById('x');
    await listPendingResearchReview();
    for (const [sql] of mockQuery.mock.calls) {
      expect(String(sql)).toMatch(/DISTINCT ON\s*\(\s*och\.politician_id\s*\)/);
      expect(String(sql)).toContain('essentials.office_current_holder');
      expect(String(sql)).toContain('AS body_label');
    }
  });
  it('maps body_label to bodyLabel, null when the politician holds no current office', async () => {
    const { getResearchReviewById } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], body_label: 'State Senate' }] });
    expect((await getResearchReviewById('x'))?.bodyLabel).toBe('State Senate');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'y', evidence: [], body_label: null }] });
    expect((await getResearchReviewById('y'))?.bodyLabel).toBeNull();
  });
});

// Task 5, requirement 1: the detail page reads the full ladder (question + five rungs) for the
// row's own revision, or the open season's pin for a legacy row — from the versioned source only.
describe('getResearchReviewWithLadder', () => {
  beforeEach(() => mockQuery.mockClear());

  const fiveRungs = [1, 2, 3, 4, 5].map((value) => ({ served_id: 'rev-a3', question_text: 'How much regulation?', value, text: `rung ${value}` }));

  it('reads the row\'s OWN revision when known, and marks it not using the open pin', async () => {
    const { getResearchReviewWithLadder } = await import('./researchEvidenceService.js');
    mockQuery
      .mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], topic_revision_id: 'rev-a', open_topic_revision_id: 'rev-a' }] })
      .mockResolvedValueOnce({ rows: fiveRungs });
    const result = await getResearchReviewWithLadder('x');
    const [ladderSql, ladderParams] = mockQuery.mock.calls[1];
    expect(String(ladderSql)).toContain('inform.compass_topic_revisions');
    expect(String(ladderSql)).toContain('inform.compass_stance_revisions');
    // C1: the SERVED revision of the row's pin, resolved by version — not the pin's own rungs.
    expect(String(ladderSql)).toMatch(/e\.version\s+=\s+pin\.version[\s\S]*e\.status IN \('published', 'superseded'\)[\s\S]*ORDER BY e\.revision DESC/);
    expect(ladderParams).toEqual(['rev-a']);
    expect(result?.ladder).toEqual({
      revisionId: 'rev-a3',
      pinRevisionId: 'rev-a',
      questionText: 'How much regulation?',
      rungs: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })),
      usingOpenPin: false,
    });
  });

  it('falls back to the open season\'s pin for a legacy row (revision unknown), and says so', async () => {
    const { getResearchReviewWithLadder } = await import('./researchEvidenceService.js');
    mockQuery
      .mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], topic_revision_id: null, open_topic_revision_id: 'rev-b' }] })
      .mockResolvedValueOnce({ rows: fiveRungs });
    const result = await getResearchReviewWithLadder('x');
    expect(mockQuery.mock.calls[1][1]).toEqual(['rev-b']);
    expect(result?.ladder?.usingOpenPin).toBe(true);
    expect(result?.ladder?.pinRevisionId).toBe('rev-b');
  });
  it('returns ladder: null when the served revision does not carry exactly five rungs', async () => {
    const { getResearchReviewWithLadder } = await import('./researchEvidenceService.js');
    mockQuery
      .mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], topic_revision_id: 'rev-a', open_topic_revision_id: 'rev-a' }] })
      .mockResolvedValueOnce({ rows: fiveRungs.slice(0, 4) });
    expect((await getResearchReviewWithLadder('x'))?.ladder).toBeNull();
  });

  it('returns ladder: null when neither the row\'s revision nor the open pin is known', async () => {
    const { getResearchReviewWithLadder } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'x', evidence: [], topic_revision_id: null, open_topic_revision_id: null }] });
    const result = await getResearchReviewWithLadder('x');
    expect(result?.ladder).toBeNull();
    expect(mockQuery).toHaveBeenCalledTimes(1); // no ladder query attempted
  });

  it('returns null (not found) without querying the ladder', async () => {
    const { getResearchReviewWithLadder } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [] });
    expect(await getResearchReviewWithLadder('missing')).toBeNull();
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });
});

describe('writeVerifiedStance', () => {
  it('writes the answer then the context through the season-aware SQL, in param order', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } = await import('./seasonService.js');
    const before = mockQuery.mock.calls.length;
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: ['u'], editorId: 'e' });
    const calls = mockQuery.mock.calls.slice(before);
    expect(calls[0]).toEqual([UPSERT_ANSWER_SQL, ['p', 't', 3, 'e']]);
    expect(calls[1]).toEqual([UPSERT_CONTEXT_SQL, ['p', 't', 'r', ['u'], 'e']]);
  });
  it('refuses to report success when the open season wrote nothing', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });
    await expect(writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: [], editorId: null }))
      .rejects.toThrow();
  });
  it('writes on the caller\'s transaction client when given one, not on the pool', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    const client = { query: vi.fn().mockResolvedValue({ rows: [], rowCount: 1 }) };
    const before = mockQuery.mock.calls.length;
    await writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: ['u'], editorId: 'e' }, client);
    expect(client.query).toHaveBeenCalledTimes(2);
    expect(mockQuery.mock.calls.length).toBe(before);
  });
});

// A 25-word page span inside a longer researcher snippet (I6).
const SPAN = 'Jane Doe voted yes on House Bill 1001 in 2025 because she believes every family deserves affordable coverage and lower prescription costs at the pharmacy counter';
const FULL_SNIPPET = `At a town hall she said: ${SPAN} — her words.`;

describe('resolveResearchReview — citations written on approval, not at queue time (R1)', () => {
  const reviewRow = {
    id: 'rev-1',
    batch_id: 'batch-1',
    politician_id: 'p1',
    full_name_raw: 'Jane Doe',
    topic_id: 't1',
    topic_key: 'healthcare',
    proposed_value: 3,
    proposed_reasoning: 'reasoning text',
    evidence: [
      {
        url: 'https://a.example',
        snippets: [
          { snippet_index: 0, snippet: FULL_SNIPPET, verdict: 'verified', matched_span: SPAN },
          { snippet_index: 1, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
        ],
      },
    ],
    verified_source_count: 1,
    threshold: 1,
    status: 'pending',
    re_research_attempted: false,
    created_at: '2026-01-01T00:00:00Z',
  };

  beforeEach(() => {
    mockQuery.mockClear(); mockClientQuery.mockClear(); mockConnect.mockClear(); mockRelease.mockClear();
  });

  // Adapted for I6: the read runs on the pool; every write runs on ONE transaction client,
  // between BEGIN and COMMIT. The assertions about what is written, and in what order, are the
  // same as before the transaction existed.
  it('inserts exactly one politician_context_evidence row, for the verified snippet only, after the answer and context writes', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } = await import('./seasonService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });     // getResearchReviewById (pool)
    // client: BEGIN, UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, evidence insert, UPDATE, COMMIT — all
    // resolve with the default { rows: [], rowCount: 1 }.

    await resolveResearchReview('rev-1', 'editor-1');

    expect(mockQuery).toHaveBeenCalledTimes(1); // only the read is outside the transaction
    const calls = mockClientQuery.mock.calls;
    expect(calls).toHaveLength(6);
    expect(calls[0][0]).toBe('BEGIN');
    expect(calls[1][0]).toBe(UPSERT_ANSWER_SQL);
    expect(calls[2][0]).toBe(UPSERT_CONTEXT_SQL);
    expect(String(calls[4][0])).toContain("SET status = 'resolved'");
    expect(calls[5][0]).toBe('COMMIT');
    expect(mockRelease).toHaveBeenCalledTimes(1);

    const evidenceCalls = calls.filter((c) => String(c[0]).includes('politician_context_evidence'));
    expect(evidenceCalls).toHaveLength(1);
    // I6: the matched span is published, never the researcher's full snippet.
    expect(evidenceCalls[0][1]).toEqual(['p1', 't1', 'https://a.example', SPAN, 0, 'batch-1']);

    // The evidence write comes after both the answer and the context write.
    const evidenceCallIndex = calls.findIndex((c) => String(c[0]).includes('politician_context_evidence'));
    const contextCallIndex = calls.findIndex((c) => c[0] === UPSERT_CONTEXT_SQL);
    expect(evidenceCallIndex).toBeGreaterThan(contextCallIndex);
  });

  // I6 (ruling 2026-09-24): no publishable span, no machine citation.
  it.each([
    ['no matched_span (queued before 2026-09-24)', undefined],
    ['a span under 25 words', 'Jane Doe voted yes on House Bill 1001'],
    ['a span that is not a run of the snippet', `${SPAN} plus words the snippet never had`],
  ])('does not publish a verified snippet with %s, and refuses the row when it was the only citation', async (_label, span) => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const row = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: FULL_SNIPPET, verdict: 'verified', ...(span ? { matched_span: span } : {}) }] }] };
    mockQuery.mockResolvedValueOnce({ rows: [row] });
    await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'INCOMPLETE' });
    expect(mockConnect).not.toHaveBeenCalled();
  });

  // I5: the status UPDATE carries the pending guard and a 0-row result rolls the approval back.
  it('resolves only a still-pending row: 0 rows on the guarded UPDATE is CONFLICT and rolls back', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
    mockClientQuery.mockImplementation(async (sql: string) =>
      (String(sql).includes("SET status = 'resolved'") ? { rows: [], rowCount: 0 } : { rows: [], rowCount: 1 }));
    let sqls: string[];
    try {
      await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'CONFLICT' });
      sqls = mockClientQuery.mock.calls.map((c) => String(c[0]));
    } finally {
      mockClientQuery.mockReset();
      mockClientQuery.mockResolvedValue({ rows: [], rowCount: 1 });
    }
    // The stance was written inside the transaction, and the rollback undoes it.
    expect(sqls[0]).toBe('BEGIN');
    expect(sqls).toContain('ROLLBACK');
    expect(sqls).not.toContain('COMMIT');
  });
  it("the resolve UPDATE is guarded by AND status = 'pending'", async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
    await resolveResearchReview('rev-1', 'editor-1');
    const upd = mockClientQuery.mock.calls.map((c) => String(c[0])).find((q) => q.includes("SET status = 'resolved'"));
    expect(upd).toMatch(/WHERE id = \$1 AND status = 'pending'/);
  });

  // I6: one transaction — a failed context write leaves no value, no citation, no status change.
  it('rolls back when the context write throws: no evidence insert, no status UPDATE, no COMMIT', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
    mockClientQuery
      .mockResolvedValueOnce({ rows: [], rowCount: null })          // BEGIN
      .mockResolvedValueOnce({ rows: [], rowCount: 1 })             // UPSERT_ANSWER_SQL
      .mockRejectedValueOnce(new Error('context write failed'));    // UPSERT_CONTEXT_SQL

    await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toThrow('context write failed');

    const sqls = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sqls).toContain('ROLLBACK');
    expect(sqls).not.toContain('COMMIT');
    expect(sqls.some((s) => s.includes('politician_context_evidence'))).toBe(false);
    expect(sqls.some((s) => s.includes('UPDATE inform.stance_research_review'))).toBe(false);
    expect(mockQuery).toHaveBeenCalledTimes(1); // nothing was written on the pool either
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });

  // I2: no approval without a citation.
  it('refuses (INCOMPLETE) a row with no machine-verified and no human-verified source, before writing', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await expect(resolveResearchReview('rev-1', 'editor-1', [])).rejects.toMatchObject({
      code: 'INCOMPLETE',
      message: 'No verified or human-verified source — a stance cannot be published without a citation',
    });
    expect(mockConnect).not.toHaveBeenCalled();
  });
  it('accepts the same row when the reviewer ticked a source by hand', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await resolveResearchReview('rev-1', 'editor-1', ['https://a.example']);
    expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
  });

  // Approval input validation (2026-09-23 polish pass), service-side defence in depth: a blank
  // humanVerifiedUrls entry must not itself satisfy "no source → INCOMPLETE" below.
  it("drops blank/whitespace-only humanVerifiedUrls entries — [''] does not count as a source", async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await expect(resolveResearchReview('rev-1', 'editor-1', [''])).rejects.toMatchObject({
      code: 'INCOMPLETE',
      message: 'No verified or human-verified source — a stance cannot be published without a citation',
    });
    expect(mockConnect).not.toHaveBeenCalled();
  });
  it('keeps a valid http(s) URL and drops blank/non-http(s) entries from humanVerifiedUrls', async () => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    const unverified = { ...reviewRow, evidence: [{ url: 'https://a.example', snippets: [
      { snippet_index: 0, snippet: 'not found snippet text', verdict: 'snippet_not_found' },
    ] }] };
    mockQuery.mockResolvedValueOnce({ rows: [unverified] });
    await resolveResearchReview('rev-1', 'editor-1',
      ['', '   ', 'not-a-url', 'javascript:alert(1)', '  https://b.example  ']);
    const evidenceCalls = mockClientQuery.mock.calls.filter((c) => String(c[0]).includes('politician_context_evidence'));
    expect(evidenceCalls).toHaveLength(1);
    expect(evidenceCalls[0][1]).toEqual(['p1', 't1', 'https://b.example', '[Human verified during review]', 'human-review-rev-1']);
  });
  it.each([7, 2.5])('refuses (INCOMPLETE) a valueOverride of %j that is not an integer 1-5', async (bad) => {
    const { resolveResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
    await expect(resolveResearchReview('rev-1', 'editor-1', [], bad)).rejects.toMatchObject({
      code: 'INCOMPLETE',
      message: 'valueOverride must be an integer 1-5',
    });
    expect(mockConnect).not.toHaveBeenCalled();
  });

  // CA_0264: approval refuses a row whose ladder was re-pinned after it was researched.
  describe('ladder revision check', () => {
    it('approves a row whose revision matches the open pin, and reports it as known', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, topic_revision_id: 'rev-a', open_topic_revision_id: 'rev-a' }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).resolves.toEqual({ ladderRevisionUnknown: false });
      expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
    });
    it('refuses (CONFLICT) a row whose revision differs from the open pin, before writing', async () => {
      const { resolveResearchReview, LADDER_CHANGED_MESSAGE } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, topic_revision_id: 'rev-a', open_topic_revision_id: 'rev-b' }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({
        code: 'CONFLICT',
        message: 'the ladder changed since this row was researched — re-research it',
      });
      expect(LADDER_CHANGED_MESSAGE).toBe('the ladder changed since this row was researched — re-research it');
      expect(mockConnect).not.toHaveBeenCalled();
    });
    it('refuses (CONFLICT) a known revision when the open season no longer asks the topic', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, topic_revision_id: 'rev-a', open_topic_revision_id: null }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'CONFLICT' });
      expect(mockConnect).not.toHaveBeenCalled();
    });
    it('allows a legacy row (revision NULL) and flags it as ladder revision unknown', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, topic_revision_id: null, open_topic_revision_id: 'rev-b' }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).resolves.toEqual({ ladderRevisionUnknown: true });
      expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
    });
    it('treats a row read before CA_0264 is applied (no column at all) as a legacy row', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      // `r.*` simply has no topic_revision_id key before the migration.
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, open_topic_revision_id: 'rev-b' }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).resolves.toEqual({ ladderRevisionUnknown: true });
    });
  });

  // Task 5, requirement 3: a value override that is not accompanied by a changed reasoning is an
  // unevidenced claim — the public "why" would still argue the OLD chair for the NEW value.
  describe('value override requires a changed reasoning', () => {
    it('refuses (INCOMPLETE) a changed valueOverride with no reasoningOverride at all', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [reviewRow] }); // reviewRow.proposed_value === 3
      await expect(resolveResearchReview('rev-1', 'editor-1', [], 4)).rejects.toMatchObject({
        code: 'INCOMPLETE',
        message: 'valueOverride differs from the proposed value — reasoningOverride must be present and explain the new value',
      });
      expect(mockConnect).not.toHaveBeenCalled();
    });
    it('refuses (INCOMPLETE) a changed valueOverride whose reasoningOverride equals the old reasoning', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
      await expect(resolveResearchReview('rev-1', 'editor-1', [], 4, '  reasoning text  ')).rejects.toMatchObject({
        code: 'INCOMPLETE',
      });
      expect(mockConnect).not.toHaveBeenCalled();
    });
    it('accepts a changed valueOverride with a genuinely different reasoningOverride', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
      await resolveResearchReview('rev-1', 'editor-1', [], 4, 'new reasoning explaining the higher chair');
      expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
    });
    it('does not require a reasoningOverride when valueOverride equals the proposed value', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
      await resolveResearchReview('rev-1', 'editor-1', [], 3); // reviewRow.proposed_value === 3
      expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
    });
    it('does not require a reasoningOverride when valueOverride is absent (re-approving as proposed)', async () => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [reviewRow] });
      await resolveResearchReview('rev-1', 'editor-1');
      expect(mockClientQuery.mock.calls.map((c) => String(c[0]))).toContain('COMMIT');
    });
  });

  // M10: only a pending row can be approved.
  it.each(['resolved', 'rejected', 'superseded', 'unresolved_politician'])(
    'refuses (CONFLICT) a %s row, before writing', async (status) => {
      const { resolveResearchReview } = await import('./researchEvidenceService.js');
      mockQuery.mockResolvedValueOnce({ rows: [{ ...reviewRow, status }] });
      await expect(resolveResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'CONFLICT' });
      expect(mockConnect).not.toHaveBeenCalled();
    });
});

// I5 (final review 2026-09-24): rejecting an already-resolved row used to flip it to rejected while
// its published stance stayed live, and drop it from export-written-ledger's audit.
describe('rejectResearchReview — only a pending row', () => {
  beforeEach(() => mockQuery.mockReset());
  it("guards the UPDATE with AND status = 'pending' and succeeds on 1 row", async () => {
    const { rejectResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await rejectResearchReview('rev-1', 'editor-1', 'why');
    expect(String(mockQuery.mock.calls[0][0])).toMatch(/WHERE id = \$1 AND status = 'pending'/);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });
  it('fails loudly with CONFLICT when the row is already resolved', async () => {
    const { rejectResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 }).mockResolvedValueOnce({ rows: [{ status: 'resolved' }] });
    await expect(rejectResearchReview('rev-1', 'editor-1')).rejects.toMatchObject({ code: 'CONFLICT' });
  });
  it('fails with NOT_FOUND when the id names no row', async () => {
    const { rejectResearchReview } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 }).mockResolvedValueOnce({ rows: [] });
    await expect(rejectResearchReview('nope', 'editor-1')).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});

describe('validStoredSpan (I6)', () => {
  it('accepts a >= 25-word whole-word run of the snippet; refuses anything else', async () => {
    const { validStoredSpan } = await import('./researchEvidenceService.js');
    expect(validStoredSpan(FULL_SNIPPET, SPAN)).toBe(SPAN);
    expect(validStoredSpan(FULL_SNIPPET, undefined)).toBeNull();
    expect(validStoredSpan(FULL_SNIPPET, 'Jane Doe voted')).toBeNull();
    expect(validStoredSpan(FULL_SNIPPET, `${SPAN} extra`)).toBeNull();
  });
});
