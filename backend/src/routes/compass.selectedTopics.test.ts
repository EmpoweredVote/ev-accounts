import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('../lib/db.js', () => ({ pool: { query: poolQueryMock } }));

// compassService pulls in the Supabase clients at import time, which read env
// vars this unit test has no business needing. Stubbed, like the other service
// tests do — nothing under test here touches them.
vi.mock('../lib/supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAdmin: {},
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));

import { saveSelectedTopics, getSelectedTopics } from '../lib/compassService.js';

const USER = '11111111-1111-4111-8111-111111111111';
const TOPICS = ['22222222-2222-4222-8222-222222222222'];

beforeEach(() => vi.clearAllMocks());

/**
 * WHY THIS FILE EXISTS.
 *
 * A user's compass ANSWERS live in inform.compass_responses, which any
 * authenticated user can write to. Their SELECTION — which questions those
 * answers are about — used to live on connect.connected_profiles, which only
 * Connected-tier users have a row in (`Profile absence = Inform tier`,
 * middleware/auth.ts). So an Inform-tier user could answer questions all day and
 * never keep their compass, and PUT /compass/selected-topics answered 200 to
 * every one of those lost writes.
 *
 * Measured against prod 2026-08-29: 9 of 23 accounts had no connected profile,
 * two of them holding 34 and 20 answers.
 *
 * Migration 1850 moves the selection to inform.inform_profiles, which migration
 * 084's trigger creates for every user. These tests pin that the write goes to
 * the new home and cannot miss.
 */
describe('saveSelectedTopics — writes where every user has a row', () => {
  it('upserts into inform.inform_profiles, not the Connected-tier profile', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ user_id: USER }] });

    await saveSelectedTopics(USER, TOPICS);

    const [sql, params] = poolQueryMock.mock.calls[0];
    expect(String(sql)).toContain('inform.inform_profiles');
    expect(String(sql)).not.toContain('connected_profiles');
    // ON CONFLICT is what makes the write unconditional. A bare UPDATE matches
    // nothing when the row is missing, which is exactly how the compass used to
    // vanish. Unlike connected_profiles, creating an inform_profiles row is not a
    // tier promotion — which is why the storage moved here.
    expect(String(sql)).toContain('ON CONFLICT (user_id)');
    expect(params[0]).toBe(USER);
    expect(params[1]).toBe(JSON.stringify(TOPICS));
  });

  it('reports success when a row was written', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ user_id: USER }] });
    await expect(saveSelectedTopics(USER, TOPICS)).resolves.toBe(true);
  });

  it('still reports false if the write somehow touches nothing', async () => {
    // The upsert should make this unreachable. The route answers 409 on false
    // rather than assuming it cannot happen — a silent 200 for a write that did
    // not land is the bug this whole change exists to remove.
    poolQueryMock.mockResolvedValue({ rows: [] });
    await expect(saveSelectedTopics(USER, TOPICS)).resolves.toBe(false);
  });

  it('stores an empty selection as an empty array, not null', async () => {
    // Clearing a compass is a real intent and must be stored, not skipped.
    poolQueryMock.mockResolvedValue({ rows: [{ user_id: USER }] });

    await saveSelectedTopics(USER, []);

    expect(poolQueryMock.mock.calls[0][1][1]).toBe('[]');
  });
});

describe('getSelectedTopics', () => {
  it('returns the stored selection', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ selected_topic_ids: TOPICS }] });
    await expect(getSelectedTopics(USER)).resolves.toEqual(TOPICS);
  });

  it('returns [] for a user with no row', async () => {
    poolQueryMock.mockResolvedValue({ rows: [] });
    await expect(getSelectedTopics(USER)).resolves.toEqual([]);
  });

  it('returns [] rather than null when the column is null', async () => {
    // The column is NOT NULL DEFAULT '[]', but a row predating the migration
    // could still surface null through a stale cache or a rollback.
    poolQueryMock.mockResolvedValue({ rows: [{ selected_topic_ids: null }] });
    await expect(getSelectedTopics(USER)).resolves.toEqual([]);
  });

  it('scopes the read to the caller', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ selected_topic_ids: [] }] });

    await getSelectedTopics(USER);

    const [sql, params] = poolQueryMock.mock.calls[0];
    expect(String(sql)).toContain('WHERE user_id = $1');
    expect(params[0]).toBe(USER);
  });
});
