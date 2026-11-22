import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// WHY THIS FILE EXISTS.
//
// `clearCompassAnswer` was written without the season join. It passed its route
// tests, typechecked, and would have shipped — check-answer-season-consumers is
// what stopped it, and it was right to. Unconstrained, the statement clears the
// user's answer to that topic in EVERY season, destroying a closed season's
// record.
//
// That gate reads source text, so it protects the repo but says nothing about
// what the statement actually DOES. These tests assert the shape directly, and
// the params alongside it, so the property survives a rewrite that happens to
// keep the gate quiet.
// ---------------------------------------------------------------------------

const queryMock = vi.hoisted(() => vi.fn());

vi.mock('./db.js', () => ({ pool: { query: queryMock } }));
vi.mock('./supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));
vi.mock('./cache.js', () => ({ cache: { get: vi.fn(), set: vi.fn(), wrap: vi.fn() } }));

import { clearCompassAnswer } from './compassService.js';

const USER = '11111111-1111-4111-8111-111111111111';
const TOPIC = '22222222-2222-4222-8222-222222222222';

/** Whitespace-insensitive, so reformatting the literal does not fail these. */
const sql = () => String(queryMock.mock.calls[0][0]).replace(/\s+/g, ' ').trim();

beforeEach(() => {
  vi.clearAllMocks();
  queryMock.mockResolvedValue({ rowCount: 1, rows: [] });
});

describe('clearCompassAnswer', () => {
  it('confines the clear to the OPEN season', async () => {
    await clearCompassAnswer(USER, TOPIC);

    // The join is the whole safeguard: without it a closed season's answer goes
    // too, and seasons exist precisely to make that impossible.
    expect(sql()).toMatch(/join inform\.seasons|from inform\.seasons/i);
    expect(sql()).toMatch(/s\.id = r\.season_id/i);
    expect(sql()).toMatch(/s\.status = 'open'/i);
  });

  it('soft-deletes rather than removing the row', async () => {
    await clearCompassAnswer(USER, TOPIC);

    // reset_compass_answers takes the same line: "Hard deletes are not used —
    // preserves data for recovery and audit." Every read already filters on
    // deleted_at, so a soft delete is invisible to callers and recoverable.
    expect(sql()).toMatch(/set deleted_at = now\(\)/i);
    expect(sql()).not.toMatch(/delete\s+from/i);
  });

  it('scopes to the one user and the one topic, and skips rows already cleared', async () => {
    await clearCompassAnswer(USER, TOPIC);

    expect(sql()).toMatch(/r\.user_id = \$1/i);
    expect(sql()).toMatch(/r\.topic_id = \$2/i);
    // Without this a repeated cancel restamps deleted_at and reports a row
    // cleared that was already gone, so the route's `cleared` count stops
    // meaning anything.
    expect(sql()).toMatch(/r\.deleted_at is null/i);
    expect(queryMock.mock.calls[0][1]).toEqual([USER, TOPIC]);
  });

  it('reports how many rows it cleared, and 0 is not an error', async () => {
    queryMock.mockResolvedValue({ rowCount: 0, rows: [] });
    await expect(clearCompassAnswer(USER, TOPIC)).resolves.toBe(0);
  });

  it('survives a driver that reports no rowCount at all', async () => {
    queryMock.mockResolvedValue({ rows: [] });
    await expect(clearCompassAnswer(USER, TOPIC)).resolves.toBe(0);
  });
});
