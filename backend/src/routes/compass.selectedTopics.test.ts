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

import { saveSelectedTopics } from '../lib/compassService.js';

const USER = '11111111-1111-4111-8111-111111111111';
const TOPICS = ['22222222-2222-4222-8222-222222222222'];

beforeEach(() => vi.clearAllMocks());

/**
 * WHY THIS FILE EXISTS.
 *
 * A user's compass lives on connect.connected_profiles. An account without that
 * row — an Inform-tier user who never completed the Connect flow — has nowhere
 * to store one, so the UPDATE matches zero rows and the compass is discarded.
 *
 * PUT /compass/selected-topics answered 200 [] in that case, for parity with the
 * retired Go backend. The caller was told its write succeeded when nothing had
 * been written. Measured against prod on 2026-08-29: 9 of 23 accounts had no
 * profile row, and 2 of those had already answered compass questions — their
 * answers persisted (inform.compass_responses is not tier-gated) while their
 * choice of which questions to answer silently did not.
 *
 * The route now answers 409 NOT_CONNECTED. These tests pin the signal the route
 * depends on, so it cannot quietly become truthy again.
 */
describe('saveSelectedTopics — the signal behind 409 NOT_CONNECTED', () => {
  it('reports false when no profile row was updated', async () => {
    // UPDATE ... RETURNING id matched nothing: there is no profile to store on.
    poolQueryMock.mockResolvedValue({ rows: [] });

    await expect(saveSelectedTopics('token', USER, TOPICS)).resolves.toBe(false);
  });

  it('reports true when a profile row was updated', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: 'profile-1' }] });

    await expect(saveSelectedTopics('token', USER, TOPICS)).resolves.toBe(true);
  });

  it('scopes the write to the caller and stores the ids as jsonb', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: 'profile-1' }] });

    await saveSelectedTopics('token', USER, TOPICS);

    const [sql, params] = poolQueryMock.mock.calls[0];
    // pool.query runs as the service role with no RLS, so the WHERE clause is
    // the only thing keeping one user out of another's profile.
    expect(String(sql)).toContain('WHERE user_id = $1');
    expect(String(sql)).toContain('connect.connected_profiles');
    expect(params[0]).toBe(USER);
    expect(params[1]).toBe(JSON.stringify(TOPICS));
  });

  it('still reports false for an empty selection with no profile', async () => {
    // Clearing a compass is a real intent, and it fails the same way. Answering
    // 200 to a clear that did not happen is the same lie in a quieter costume.
    poolQueryMock.mockResolvedValue({ rows: [] });

    await expect(saveSelectedTopics('token', USER, [])).resolves.toBe(false);
  });
});
