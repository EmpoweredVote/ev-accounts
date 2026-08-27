import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import {
  currentSeasonId, latestAnsweredSeason, assertWritten,
  UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL,
  isSeasonWriteError, SeasonWriteError,
  WRITABLE_TOPIC_IDS_SQL, writableTopicIds,
} from './seasonService.js';

beforeEach(() => mockQuery.mockReset());

describe('currentSeasonId', () => {
  it('returns the id of the one open season', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 'season-2' }] });
    expect(await currentSeasonId()).toBe('season-2');
  });

  // The whole point. Season 1 exists and is CLOSED, so this is the live state
  // of production today, not a hypothetical. Picking the newest season instead
  // would silently write season-2 answers into a closed season 1 and
  // reintroduce exactly the ambiguity seasons exist to remove.
  it('throws when no season is open, rather than falling back to the newest', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(currentSeasonId()).rejects.toThrow('no open season');
  });

  it('names the fix in the error, because a caller cannot open a season', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(currentSeasonId()).rejects.toThrow(/inform\.seasons/);
  });

  // Guarded by the seasons_one_open partial unique index, so this is
  // unreachable through the database. Asserted anyway: if the index is ever
  // dropped, the failure must be loud here rather than an arbitrary pick.
  it('throws when more than one season is open', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 'a' }, { id: 'b' }] });
    await expect(currentSeasonId()).rejects.toThrow('more than one open season');
  });

  it('resolves at read time — it does not cache across calls', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'season-1' }] });
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'season-2' }] });
    expect(await currentSeasonId()).toBe('season-1');
    expect(await currentSeasonId()).toBe('season-2');
    expect(mockQuery).toHaveBeenCalledTimes(2);
  });

  it('asks the database for the open season, not for the highest number', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 'season-2' }] });
    await currentSeasonId();
    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/status\s*=\s*'open'/);
    expect(sql).not.toMatch(/ORDER BY\s+number/i);
  });
});

describe('latestAnsweredSeason', () => {
  it('returns the newest season in which this person answered this topic', async () => {
    mockQuery.mockResolvedValue({ rows: [{ season_id: 's2', number: 2 }] });
    expect(await latestAnsweredSeason('pol-1', 'topic-1'))
      .toEqual({ seasonId: 's2', number: 2 });
  });

  // A person may simply not have been researched this season. That is an
  // absence, not an error — the read path falls back to what they last said.
  it('returns null when this person has no answer on this topic', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    expect(await latestAnsweredSeason('pol-1', 'topic-1')).toBeNull();
  });

  it('orders by season number descending and takes exactly one row', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await latestAnsweredSeason('pol-1', 'topic-1');
    const sql = mockQuery.mock.calls[0][0] as string;
    expect(sql).toMatch(/ORDER BY\s+s\.number\s+DESC/i);
    expect(sql).toMatch(/LIMIT 1/i);
  });

  it('passes both ids as parameters rather than interpolating them', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await latestAnsweredSeason('pol-1', 'topic-1');
    expect(mockQuery.mock.calls[0][1]).toEqual(['pol-1', 'topic-1']);
  });
});

describe('the write shape', () => {
  // These SQL constants exist so six call sites cannot disagree. The tests pin
  // the three properties that make them safe, because a future edit that breaks
  // any one of them looks harmless in a diff.
  it('takes the pin from the season, never from the caller', () => {
    for (const sql of [UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL]) {
      expect(sql).toMatch(/sq\.topic_revision_id/);
      // No positional parameter may supply the revision.
      expect(sql).not.toMatch(/topic_revision_id\s*=\s*\$/);
    }
  });

  it('sources the season from status=open, so a closed season writes nothing', () => {
    for (const sql of [UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL]) {
      expect(sql).toMatch(/status\s*=\s*'open'/);
    }
  });

  it('conflicts on the three-column key, not the bare pair', () => {
    for (const sql of [UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL]) {
      expect(sql).toMatch(/ON CONFLICT \(politician_id, topic_id, season_id\)/);
    }
  });

  it('is one statement, so the season cannot close between read and write', () => {
    for (const sql of [UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL]) {
      expect(sql.match(/INSERT INTO/g)).toHaveLength(1);
      expect(sql).not.toMatch(/;/);
    }
  });

  it('stamps an editor and an updated_at', () => {
    for (const sql of [UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL]) {
      expect(sql).toMatch(/editor_id/);
      expect(sql).toMatch(/updated_at\s*=\s*now\(\)/);
    }
  });
});

describe('assertWritten', () => {
  it('does nothing when rows were written', async () => {
    await expect(assertWritten(1, 'topic-1')).resolves.toBeUndefined();
    expect(mockQuery).not.toHaveBeenCalled();
  });

  // Zero rows has two causes needing opposite fixes. Collapsing them into one
  // message would send the reader to the wrong place.
  it('blames the missing open season when none is open', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '0', pinned: '0' }] });
    await expect(assertWritten(0, 'topic-1')).rejects.toThrow('no open season');
  });

  it('blames the question set when a season is open but does not ask this topic', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '1', pinned: '0' }] });
    await expect(assertWritten(0, 'topic-1'))
      .rejects.toThrow(/not in the open season's question set/);
  });

  it('does not claim to know the cause when both look fine', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '1', pinned: '1' }] });
    await expect(assertWritten(0, 'topic-1')).rejects.toThrow(/unknown reason/);
  });
});

// A season refusal reaches an HTTP handler that has to choose a status code. It
// can only choose correctly if the error is DISTINGUISHABLE from a genuine
// failure — otherwise every refusal is a 500 saying "an unexpected error
// occurred", which is what shipped and what hid the live outage from operators.
describe('SeasonWriteError — refusals must be tellable from real failures', () => {
  it('tags the no-open-season refusal with a reason and the topic', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '0', pinned: '0' }] });
    const err = await assertWritten(0, 'topic-1').catch((e: unknown) => e);
    expect(isSeasonWriteError(err)).toBe(true);
    expect((err as SeasonWriteError).reason).toBe('NO_OPEN_SEASON');
    expect((err as SeasonWriteError).topicId).toBe('topic-1');
  });

  it('tags the not-in-this-season refusal with its own distinct reason', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '1', pinned: '0' }] });
    const err = await assertWritten(0, 'topic-9').catch((e: unknown) => e);
    expect(isSeasonWriteError(err)).toBe(true);
    expect((err as SeasonWriteError).reason).toBe('TOPIC_NOT_IN_SEASON');
    expect((err as SeasonWriteError).topicId).toBe('topic-9');
  });

  // 🔴 The unknown case must NOT be tagged. Tagging it would tell an operator to
  // go open a season while a season is already open, sending them to fix
  // something that is not broken.
  it('leaves the unknown-cause failure as a plain Error', async () => {
    mockQuery.mockResolvedValue({ rows: [{ open_seasons: '1', pinned: '1' }] });
    const err = await assertWritten(0, 'topic-1').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(Error);
    expect(isSeasonWriteError(err)).toBe(false);
  });

  it('does not mistake an unrelated error for a season refusal', () => {
    expect(isSeasonWriteError(new Error('connection terminated'))).toBe(false);
    expect(isSeasonWriteError(null)).toBe(false);
    expect(isSeasonWriteError({ reason: 'NO_OPEN_SEASON' })).toBe(false);
  });
});

// The pre-flight and the write must answer the same question. When they drift,
// the validator either rejects writes the database would accept, or waves
// through writes that fail deeper down where the caller learns nothing useful.
describe('writableTopicIds — the pre-flight must not drift from the write', () => {
  const runner = { query: mockQuery };

  // 🔴 STRUCTURAL GUARD. Both statements resolve the season the same way. This
  // is the assertion that fails if someone "tidies" one of them.
  it('sources its FROM clause from the same open-season join as the upsert', () => {
    const seasonJoin =
      /FROM inform\.season_questions sq\s+JOIN inform\.seasons s ON s\.id = sq\.season_id AND s\.status = 'open'/;
    expect(WRITABLE_TOPIC_IDS_SQL).toMatch(seasonJoin);
    expect(UPSERT_ANSWER_SQL).toMatch(seasonJoin);
  });

  // It must NOT read compass_topics_promoted: that view additionally inner-joins
  // compass_topics_current, so it answers "what do we ask", not "what may be
  // recorded". Nor is_live, which is the bug this replaced.
  it('does not gate on is_live or on the promoted view', () => {
    expect(WRITABLE_TOPIC_IDS_SQL).not.toMatch(/is_live/);
    expect(WRITABLE_TOPIC_IDS_SQL).not.toMatch(/compass_topics_promoted/);
  });

  it('returns the writable subset', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 't1' }, { id: 't3' }] });
    const writable = await writableTopicIds(runner, ['t1', 't2', 't3']);
    expect([...writable].sort()).toEqual(['t1', 't3']);
  });

  it('short-circuits on an empty request without querying', async () => {
    const writable = await writableTopicIds(runner, []);
    expect(writable.size).toBe(0);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  // 🔴 The distinction that makes the 422 honest. All-topics-rejected because
  // the server has no open season is NOT the caller sending bad ids, and
  // reporting it as "these 44 ids are invalid" sends them to debug their own
  // correct request.
  it('throws NO_OPEN_SEASON rather than calling every topic invalid', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] })                        // nothing writable
      .mockResolvedValueOnce({ rows: [{ open_seasons: '0' }] });  // ...because none open

    const err = await writableTopicIds(runner, ['t1', 't2']).catch((e: unknown) => e);
    expect(isSeasonWriteError(err)).toBe(true);
    expect((err as SeasonWriteError).reason).toBe('NO_OPEN_SEASON');
  });

  // The mirror case: a season IS open, it just does not ask these. That is a
  // caller problem and must come back as an ordinary empty set, so the route
  // can name the offending ids in a 422.
  it('returns an empty set when a season is open but asks none of these', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [{ open_seasons: '1' }] });

    const writable = await writableTopicIds(runner, ['t1']);
    expect(writable.size).toBe(0);
  });

  // Today every topic is both is_live and in season 1, so the old check and the
  // new one agree on all 44 rows and no live data can tell them apart. This is
  // the divergence that arrives with season 2, asserted now rather than found
  // later: a topic dropped from the season is NOT writable even though it is
  // still is_live, still exists, and still holds answers from season 1.
  it('refuses a still-live topic that the open season dropped', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'kept' }] });
    const writable = await writableTopicIds(runner, ['kept', 'dropped-but-still-live']);

    expect(writable.has('kept')).toBe(true);
    expect(writable.has('dropped-but-still-live')).toBe(false);
  });
});
