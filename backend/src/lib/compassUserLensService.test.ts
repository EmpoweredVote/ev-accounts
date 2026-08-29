import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const poolQueryMock = vi.hoisted(() => vi.fn());
const clientQueryMock = vi.hoisted(() => vi.fn());
const clientReleaseMock = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({
  pool: {
    query: poolQueryMock,
    connect: vi.fn(async () => ({ query: clientQueryMock, release: clientReleaseMock })),
  },
}));

import {
  rungNeighbourhood,
  getRecalibrationFlags,
  replaceUserLenses,
  findUnknownTopicIds,
} from './compassUserLensService.js';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const USER = 'user-1';
const TOPIC = '11111111-1111-4111-8111-111111111111';

/** An answer stamped against v1 while the open season now serves v2. */
function staleCandidate(over: Record<string, unknown> = {}) {
  return {
    topic_id: TOPIC,
    value: 3,
    answered_revision_id: 'rev-v1',
    answered_version: 1,
    effective_revision_id: 'rev-v2',
    effective_version: 2,
    public_note: 'We rewrote this question to better reflect the trade-off.',
    ...over,
  };
}

/** One rung, same on both sides. */
function rung(value: number, over: Record<string, unknown> = {}) {
  return {
    value,
    old_text: `stance ${value}`,
    new_text: `stance ${value}`,
    old_description: null,
    new_description: null,
    mapped: String(value),
    ...over,
  };
}

/**
 * getRecalibrationFlags issues the candidate query first, then one rung
 * comparison per topic that survived the version check. Dispatching on the SQL
 * keeps the tests from depending on call order.
 */
function mockQueries(candidates: unknown[], rungs: unknown[]) {
  poolQueryMock.mockImplementation(async (sql: string) => {
    if (sql.includes('compass_stance_revisions')) return { rows: rungs };
    return { rows: candidates };
  });
}

beforeEach(() => {
  vi.clearAllMocks();
});

// ---------------------------------------------------------------------------
// rungNeighbourhood
// ---------------------------------------------------------------------------

describe('rungNeighbourhood — which rungs bear on an answer', () => {
  it('takes the rung either side of a whole-number answer', () => {
    expect(rungNeighbourhood(3)).toEqual([2, 3, 4]);
  });

  it('spans both rungs a write-in sits between, plus their neighbours', () => {
    // 2.5 is a write-in BETWEEN rungs 2 and 3, so both are "their answer" and
    // the neighbours sit outside them.
    expect(rungNeighbourhood(2.5)).toEqual([1, 2, 3, 4]);
  });

  it('clamps at the bottom of the ladder', () => {
    expect(rungNeighbourhood(1)).toEqual([1, 2]);
    expect(rungNeighbourhood(0.5)).toEqual([1, 2]);
  });

  it('clamps at the top of the ladder', () => {
    expect(rungNeighbourhood(5)).toEqual([4, 5]);
    expect(rungNeighbourhood(5.5)).toEqual([4, 5]);
  });

  it('falls back to the whole ladder when there is no value to centre on', () => {
    expect(rungNeighbourhood(null)).toEqual([1, 2, 3, 4, 5]);
  });
});

// ---------------------------------------------------------------------------
// getRecalibrationFlags — the rule
// ---------------------------------------------------------------------------

describe('recalibration — an unchanged question never prompts', () => {
  it('says nothing when the version did not move', async () => {
    // The editorial/clarifying case. ADR 0006 §2: those do not bump version, so
    // they resolve to the same version the answer was stamped against and can
    // never raise a flag.
    mockQueries([staleCandidate({ answered_version: 2, effective_version: 2 })], []);

    expect(await getRecalibrationFlags(USER, [TOPIC])).toEqual([]);
  });

  it('says nothing across a version bump when the nearby rungs are untouched', async () => {
    // The narrowing Chris asked for: a substantive revision elsewhere on the
    // ladder does not invalidate a calibration made at rung 3.
    mockQueries([staleCandidate()], [rung(2), rung(3), rung(4)]);

    expect(await getRecalibrationFlags(USER, [TOPIC])).toEqual([]);
  });

  it('does not nag an answer that was never stamped with a revision', async () => {
    mockQueries([staleCandidate({ answered_revision_id: null, answered_version: null })], []);

    expect(await getRecalibrationFlags(USER, [TOPIC])).toEqual([]);
  });

  it('asks for nothing when the lens is empty', async () => {
    expect(await getRecalibrationFlags(USER, [])).toEqual([]);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });
});

describe('recalibration — a changed question prompts, and says why', () => {
  it('flags a reworded rung the user is sitting on', async () => {
    mockQueries(
      [staleCandidate()],
      [rung(2), rung(3, { new_text: 'stance 3, rewritten' }), rung(4)]
    );

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      topicId: TOPIC,
      reason: 'question_revised',
      currentValue: 3,
      answeredVersion: 1,
      effectiveVersion: 2,
    });
  });

  it('flags a change to the rung beside their answer, not just their own', async () => {
    mockQueries(
      [staleCandidate()],
      [rung(2), rung(3), rung(4, { new_text: 'stance 4, rewritten' })]
    );

    const flags = await getRecalibrationFlags(USER, [TOPIC]);
    expect(flags).toHaveLength(1);
    expect(flags[0]?.reason).toBe('question_revised');
  });

  it("carries editorial's own words so the UI need not invent them", async () => {
    mockQueries([staleCandidate()], [rung(3, { new_text: 'moved' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);
    expect(flags[0]?.publicNote).toBe(
      'We rewrote this question to better reflect the trade-off.'
    );
  });

  it('distinguishes a rung that no longer exists from one that was reworded', async () => {
    mockQueries([staleCandidate()], [rung(3, { mapped: 'invalidated' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);
    expect(flags[0]?.reason).toBe('answer_invalidated');
  });

  it('treats a rung that moved position as a change even when its words did not', async () => {
    // rung_map is the only thing that can see this; the text is identical.
    mockQueries([staleCandidate()], [rung(3, { mapped: '4' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);
    expect(flags[0]?.reason).toBe('question_revised');
  });

  it('reports a topic the open season does not ask, rather than dropping it', async () => {
    mockQueries(
      [staleCandidate({ effective_revision_id: null, effective_version: null, public_note: null })],
      []
    );

    const flags = await getRecalibrationFlags(USER, [TOPIC]);
    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      reason: 'not_asked_this_season',
      effectiveVersion: null,
    });
  });
});

// ---------------------------------------------------------------------------
// findUnknownTopicIds
// ---------------------------------------------------------------------------

describe('findUnknownTopicIds — existence, not season membership', () => {
  it('short-circuits on an empty list', async () => {
    expect(await findUnknownTopicIds([])).toEqual([]);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });

  it('returns only the ids that name nothing', async () => {
    poolQueryMock.mockResolvedValue({ rows: [{ id: 'missing-id' }] });
    expect(await findUnknownTopicIds([TOPIC, 'missing-id'])).toEqual(['missing-id']);
  });
});

// ---------------------------------------------------------------------------
// replaceUserLenses
// ---------------------------------------------------------------------------

describe('replaceUserLenses — whole-set replace, atomically', () => {
  const LENS = { key: 'u_7f3a91', name: 'My lens', topic_ids: [TOPIC] };

  it('deletes the lenses the caller no longer sends', async () => {
    clientQueryMock.mockResolvedValue({ rows: [] });
    poolQueryMock.mockResolvedValue({ rows: [] });

    await replaceUserLenses(USER, [LENS]);

    const deleteCall = clientQueryMock.mock.calls.find(c => String(c[0]).includes('DELETE'));
    expect(deleteCall).toBeDefined();
    // Scoped to the owner AND to the keys that survived — never a blanket delete.
    expect(String(deleteCall?.[0])).toContain('owner_id = $1');
    expect(deleteCall?.[1]).toEqual([USER, ['u_7f3a91']]);
  });

  it('rolls back and releases the client when a write fails', async () => {
    clientQueryMock.mockImplementation(async (sql: string) => {
      if (String(sql).includes('INSERT')) throw new Error('constraint violation');
      return { rows: [] };
    });

    await expect(replaceUserLenses(USER, [LENS])).rejects.toThrow('constraint violation');

    const issued = clientQueryMock.mock.calls.map(c => String(c[0]));
    expect(issued).toContain('ROLLBACK');
    expect(issued).not.toContain('COMMIT');
    expect(clientReleaseMock).toHaveBeenCalled();
  });

  it('refuses a key another owner already holds, instead of silently dropping it', async () => {
    // Verified against prod: ON CONFLICT DO UPDATE whose owner_id predicate
    // fails updates nothing, inserts nothing, and raises nothing — row_count 0.
    // Without this check the caller gets a 200 and a lens list short one lens.
    poolQueryMock.mockResolvedValue({ rows: [{ key: 'u_7f3a91' }] });

    await expect(replaceUserLenses(USER, [LENS])).rejects.toMatchObject({
      code: 'LENS_KEY_TAKEN',
      keys: ['u_7f3a91'],
    });

    // It must fail BEFORE opening a transaction.
    expect(clientQueryMock).not.toHaveBeenCalled();
  });

  it('trims the name so a lens cannot be saved as whitespace', async () => {
    clientQueryMock.mockResolvedValue({ rows: [] });
    poolQueryMock.mockResolvedValue({ rows: [] });

    await replaceUserLenses(USER, [{ ...LENS, name: '  My lens  ' }]);

    const insert = clientQueryMock.mock.calls.find(c => String(c[0]).includes('INSERT'));
    expect(insert?.[1]?.[2]).toBe('My lens');
  });
});
