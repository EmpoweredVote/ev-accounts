import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
vi.mock('../lib/db.js', () => ({
  pool: { query: poolQueryMock, connect: vi.fn() },
}));

// compassService pulls in the Supabase clients at import time, which this unit
// test has no business needing. Stubbed, as the sibling route tests do.
vi.mock('../lib/supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAdmin: {},
  supabaseAnon: { schema: () => ({ from: () => ({ select: () => ({}) }) }) },
  createUserClient: vi.fn(),
  requestDb: vi.fn(),
}));

import { getSelectedTopicRecalibrationFlags } from '../lib/compassService.js';

const USER = '11111111-1111-4111-8111-111111111111';
const TOPIC_A = '22222222-2222-4222-8222-222222222222';
const TOPIC_B = '33333333-3333-4333-8333-333333333333';

/**
 * WHY THIS FILE EXISTS.
 *
 * 🔴 SUPPRESSION WITHOUT THIS IS ANSWERS VANISHING WITH NO EXPLANATION.
 * CC_0062 stops showing an answer whose rung moved or was invalidated, so the
 * spoke goes blank. The only thing that has ever surfaced a recalibration flag
 * is GET /compass/my-lenses, and the client narrows it further still — it builds
 * its flag map from the ACTIVE custom lens only. So the explanation reached a
 * user who (a) owns a custom lens, (b) put the affected topic in it, and (c) has
 * that lens selected right now.
 *
 * Measured against prod at a simulated changeover: 7 answers are suppressed
 * across 5 users, and the lens path reaches ZERO of them — not one of the 5 has
 * the affected topic inside a custom lens. Every one of them would have watched
 * an answer disappear and been told nothing.
 *
 * A user's SELECTED topics are the spokes on their compass — the thing they are
 * actually looking at — so that is the set the flags have to cover. Of the 7,
 * two sit on a currently selected spoke; the other five are on topics the user
 * answered but does not currently show, where nothing visibly vanishes and the
 * flag arrives when they put the topic back.
 */

/** Route the two reads by SQL so the tests do not depend on call order. */
function mockReads(selected: string[] | null, flagRows: unknown[]) {
  poolQueryMock.mockImplementation(async (sql: string) => {
    if (String(sql).includes('inform_profiles')) {
      return { rows: [{ selected_topic_ids: selected }] };
    }
    return { rows: flagRows };
  });
}

function flagRow(over: Record<string, unknown> = {}) {
  return {
    topic_id: TOPIC_A,
    value: '3',
    disposition: 'moved',
    answered_revision_id: 'rev-v1',
    effective_revision_id: 'rev-v2',
    answered_version: 1,
    effective_version: 2,
    public_note: 'The scale was rebuilt.',
    ...over,
  };
}

beforeEach(() => vi.clearAllMocks());

describe('getSelectedTopicRecalibrationFlags — the compass the user is looking at', () => {
  it('flags the topics the user has selected, with no lens involved', async () => {
    mockReads([TOPIC_A, TOPIC_B], [flagRow()]);

    const flags = await getSelectedTopicRecalibrationFlags(USER);

    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      topicId: TOPIC_A,
      reason: 'question_revised',
      disposition: 'moved',
    });
  });

  it('asks about exactly the selected topics', async () => {
    mockReads([TOPIC_A, TOPIC_B], []);

    await getSelectedTopicRecalibrationFlags(USER);

    const flagCall = poolQueryMock.mock.calls.find((c) =>
      String(c[0]).includes('compass_answer_dispositions')
    );
    expect(flagCall?.[1]).toEqual([USER, [TOPIC_A, TOPIC_B]]);
  });

  it('reads the selection from where every user has a row', async () => {
    // Migration 1850 moved the selection off connected_profiles, which only
    // Connected-tier users have. Reusing getSelectedTopics is what keeps this
    // from re-learning that the wrong way — see compass.selectedTopics.test.ts.
    mockReads([TOPIC_A], []);

    await getSelectedTopicRecalibrationFlags(USER);

    const sqls = poolQueryMock.mock.calls.map((c) => String(c[0])).join('\n');
    expect(sqls).toContain('inform.inform_profiles');
    expect(sqls).not.toContain('connected_profiles');
  });

  it('says nothing, and asks nothing, when the compass is empty', async () => {
    mockReads([], []);

    expect(await getSelectedTopicRecalibrationFlags(USER)).toEqual([]);

    const flagCall = poolQueryMock.mock.calls.find((c) =>
      String(c[0]).includes('compass_answer_dispositions')
    );
    expect(flagCall).toBeUndefined();
  });

  it('survives a user with no selection stored at all', async () => {
    // A null column, not an empty array — an Inform-tier user who has never
    // saved a compass. getSelectedTopics normalises it; this pins that it does.
    mockReads(null, []);

    expect(await getSelectedTopicRecalibrationFlags(USER)).toEqual([]);
  });

  it('reports a suppressed answer and a kept one differently', async () => {
    // The distinction the UI needs: `moved` blanked the spoke, `reworded` did
    // not. Both say question_revised, so `reason` alone cannot tell them apart.
    mockReads(
      [TOPIC_A, TOPIC_B],
      [flagRow({ disposition: 'moved' }), flagRow({ topic_id: TOPIC_B, disposition: 'reworded' })]
    );

    const flags = await getSelectedTopicRecalibrationFlags(USER);
    const byTopic = new Map(flags.map((f) => [f.topicId, f]));

    expect(byTopic.get(TOPIC_A)?.disposition).toBe('moved');
    expect(byTopic.get(TOPIC_B)?.disposition).toBe('reworded');
    expect(byTopic.get(TOPIC_A)?.reason).toBe(byTopic.get(TOPIC_B)?.reason);
  });
});
