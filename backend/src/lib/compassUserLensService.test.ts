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
  getRecalibrationFlags,
  getAllRecalibrationFlags,
  replaceUserLenses,
  findUnknownTopicIds,
} from './compassUserLensService.js';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const USER = 'user-1';
const TOPIC = '11111111-1111-4111-8111-111111111111';

/**
 * One row of inform.compass_answer_dispositions, joined to the two revisions for
 * their versions and editorial's note.
 *
 * ⚠ THE DISPOSITION IS AN INPUT HERE, NOT SOMETHING THIS SERVICE DERIVES.
 * CC_0061 owns the editorial rule; this file owns only the translation of its
 * four words into the wire contract. A test here that asserted on rung text or
 * rung_map would be re-testing SQL through a mock — that proof lives in the
 * migration's own probe (fresh=78 reworded=89 moved=6 invalidated=1).
 */
function dispositionRow(over: Record<string, unknown> = {}) {
  return {
    topic_id: TOPIC,
    // numeric arrives from pg as a string; the service must normalise it.
    value: '3',
    disposition: 'reworded',
    answered_revision_id: 'rev-v1',
    effective_revision_id: 'rev-v2',
    answered_version: 1,
    effective_version: 2,
    public_note: 'We rewrote this question to better reflect the trade-off.',
    ...over,
  };
}

function mockRows(rows: unknown[]) {
  poolQueryMock.mockResolvedValue({ rows });
}

beforeEach(() => {
  vi.clearAllMocks();
});

// ---------------------------------------------------------------------------
// getRecalibrationFlags — it reads the rule, it does not reimplement it
// ---------------------------------------------------------------------------

describe('recalibration — one source of truth', () => {
  it('asks the disposition view, scoped to the one user', async () => {
    mockRows([]);

    await getRecalibrationFlags(USER, [TOPIC]);

    const [sql, params] = poolQueryMock.mock.calls[0] ?? [];
    expect(String(sql)).toContain('inform.compass_answer_dispositions');
    expect(String(sql)).toContain('user_id = $1');
    expect(params).toEqual([USER, [TOPIC]]);
  });

  it('never compares rungs itself — CC_0061 owns that', async () => {
    // 🔴 The regression this guards. Two implementations of one editorial rule
    // is how the suppression path and the prompt path come to disagree about
    // the same answer. One query, and it never touches the stance snapshots.
    mockRows([dispositionRow()]);

    await getRecalibrationFlags(USER, [TOPIC]);

    expect(poolQueryMock).toHaveBeenCalledTimes(1);
    const issued = poolQueryMock.mock.calls.map(c => String(c[0])).join('\n');
    expect(issued).not.toContain('compass_stance_revisions');
    expect(issued).not.toContain('rung_map');
  });

  it('de-duplicates the topic list it was handed', async () => {
    mockRows([]);

    await getRecalibrationFlags(USER, [TOPIC, TOPIC]);

    expect(poolQueryMock.mock.calls[0]?.[1]).toEqual([USER, [TOPIC]]);
  });

  it('asks for nothing when the lens is empty', async () => {
    expect(await getRecalibrationFlags(USER, [])).toEqual([]);
    expect(poolQueryMock).not.toHaveBeenCalled();
  });
});

describe('getAllRecalibrationFlags — every answer, not just the ones on screen', () => {
  // 🔴 WHY THIS EXISTS. Scoping flags to the SELECTED topics covered only 12 of
  // the 96 non-fresh answers at the changeover — `invalidated` 0 of 1, `moved` 2
  // of 6. The other 84 sit on topics the user answered but does not currently
  // show, and an answer set aside off-screen is still an answer set aside.
  it('asks the view for the whole user, with no topic filter', async () => {
    mockRows([]);

    await getAllRecalibrationFlags(USER);

    const [sql, params] = poolQueryMock.mock.calls[0] ?? [];
    expect(String(sql)).toContain('inform.compass_answer_dispositions');
    expect(String(sql)).toContain('user_id = $1');
    // No ANY($2) — the whole point is the absence of the topic predicate.
    expect(String(sql)).not.toContain('topic_id = ANY');
    expect(params).toEqual([USER]);
  });

  it('translates the dispositions exactly as the scoped read does', async () => {
    mockRows([dispositionRow({ disposition: 'moved' })]);

    const flags = await getAllRecalibrationFlags(USER);

    expect(flags[0]).toMatchObject({
      topicId: TOPIC,
      reason: 'question_revised',
      disposition: 'moved',
      currentValue: 3,
    });
  });

  it('is still silent about a fresh answer', async () => {
    mockRows([dispositionRow({ disposition: 'fresh' })]);
    expect(await getAllRecalibrationFlags(USER)).toEqual([]);
  });

  it('still reports a topic the season does not ask', async () => {
    mockRows([
      dispositionRow({
        disposition: 'fresh',
        effective_revision_id: null,
        effective_version: null,
      }),
    ]);

    expect((await getAllRecalibrationFlags(USER))[0]?.reason).toBe('not_asked_this_season');
  });

  // The two reads must not drift: one query, one translation, one filter that
  // is either present or absent.
  it('shares its translation with the scoped read', async () => {
    const row = dispositionRow({ disposition: 'invalidated' });

    mockRows([row]);
    const all = await getAllRecalibrationFlags(USER);
    vi.clearAllMocks();
    mockRows([row]);
    const scoped = await getRecalibrationFlags(USER, [TOPIC]);

    expect(all).toEqual(scoped);
  });
});

describe('recalibration — fresh is silent', () => {
  it('says nothing when the answer still means what it meant', async () => {
    mockRows([dispositionRow({ disposition: 'fresh' })]);

    expect(await getRecalibrationFlags(USER, [TOPIC])).toEqual([]);
  });

  it('says nothing about an answer that was never stamped with a revision', async () => {
    // CC_0061 resolves an unstamped answer to 'fresh' itself. Nagging someone
    // because of a NULL we wrote is worse than missing a genuine revision.
    mockRows([
      dispositionRow({
        disposition: 'fresh',
        answered_revision_id: null,
        answered_version: null,
      }),
    ]);

    expect(await getRecalibrationFlags(USER, [TOPIC])).toEqual([]);
  });
});

describe('recalibration — the four dispositions, translated', () => {
  it('flags a reworded question and keeps the value', async () => {
    mockRows([dispositionRow({ disposition: 'reworded' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      topicId: TOPIC,
      reason: 'question_revised',
      disposition: 'reworded',
      currentValue: 3,
      answeredVersion: 1,
      effectiveVersion: 2,
    });
  });

  it('flags a moved rung as a revision, and carries the word that suppresses it', async () => {
    // moved and reworded share a reason on the wire but NOT a fate: the caller
    // suppresses on `disposition`, so it has to survive the translation.
    mockRows([dispositionRow({ disposition: 'moved' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags[0]).toMatchObject({ reason: 'question_revised', disposition: 'moved' });
  });

  it('reports a rung that no longer exists as an invalidated answer', async () => {
    mockRows([dispositionRow({ disposition: 'invalidated' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags[0]).toMatchObject({ reason: 'answer_invalidated', disposition: 'invalidated' });
  });

  it('never calls a reworded answer invalidated', async () => {
    // 🔴 CC_0061 bug 1, held shut from this side too. The old rule reported
    // 'invalidated' when ANY rung in the neighbourhood was invalidated, not the
    // user's own — telling someone their stated view no longer exists when
    // their own rung was untouched. Only the word 'invalidated' may say that.
    mockRows([dispositionRow({ disposition: 'reworded' })]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags).toHaveLength(1);
    expect(flags[0]?.reason).not.toBe('answer_invalidated');
  });

  it("carries editorial's own words so the UI need not invent them", async () => {
    mockRows([dispositionRow()]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags[0]?.publicNote).toBe(
      'We rewrote this question to better reflect the trade-off.'
    );
  });

  it('reports an absent note as an empty string, not null', async () => {
    mockRows([dispositionRow({ public_note: null })]);

    expect((await getRecalibrationFlags(USER, [TOPIC]))[0]?.publicNote).toBe('');
  });

  it('reports a topic the open season does not ask, rather than dropping it', async () => {
    // The view LEFT JOINs the season's pins, so a dropped topic arrives with no
    // effective revision — and 'fresh', because nothing changed under them. It
    // is simply not on the board, and that must be said rather than inferred.
    mockRows([
      dispositionRow({
        disposition: 'fresh',
        effective_revision_id: null,
        effective_version: null,
        public_note: null,
      }),
    ]);

    const flags = await getRecalibrationFlags(USER, [TOPIC]);

    expect(flags).toHaveLength(1);
    expect(flags[0]).toMatchObject({
      reason: 'not_asked_this_season',
      effectiveVersion: null,
    });
  });

  it('normalises a null value rather than coercing it to zero', async () => {
    mockRows([dispositionRow({ value: null, disposition: 'reworded' })]);

    expect((await getRecalibrationFlags(USER, [TOPIC]))[0]?.currentValue).toBeNull();
  });

  it('keeps a write-in half value intact', async () => {
    mockRows([dispositionRow({ value: '2.5' })]);

    expect((await getRecalibrationFlags(USER, [TOPIC]))[0]?.currentValue).toBe(2.5);
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
