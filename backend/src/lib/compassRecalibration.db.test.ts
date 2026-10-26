/**
 * Decision 0011's regression test: a MATERIAL version bump on a topic must raise
 * a recalibration flag for a person who answered the older revision.
 *
 * 🔴 WHY THIS HITS A REAL DATABASE. Every link in the chain is SQL: CC_0067's
 * trigger stamps answered_revision_id on write, CC_0061's view decides the
 * disposition, and the open season's pin decides the effective revision. The
 * mocked tests in compassUserLensService.test.ts feed the disposition in as an
 * input, so they stay green if the stamp stops being written — which is exactly
 * how this mechanism switched itself off between 2026-08-21 and 2026-09-04:
 * every answer NULL, CC_0061 reading NULL as "fresh", nothing flagged, nothing
 * failing.
 *
 * HOW IT IS SAFE TO POINT AT PROD. Opt-in only: it runs when
 * COMPASS_DB_TEST_URL is set, never on DATABASE_URL, so neither CI nor a dev's
 * `npm test` reaches a database by accident. Each case runs inside ONE
 * transaction that always ends in ROLLBACK, on a throwaway topic it creates
 * itself. Nothing it writes is ever visible to another connection.
 *
 *   COMPASS_DB_TEST_URL="$DATABASE_URL" npx vitest run src/lib/compassRecalibration.db.test.ts
 *
 * PROVING IT BITES. SIMULATE_PRE_CC_0067=1 disables the stamping trigger inside
 * the same rolled-back transaction, which is the write path as it was before
 * CC_0067. The material-bump case must then FAIL. That lever takes a brief
 * table lock on inform.compass_responses (released at ROLLBACK), so it is off
 * by default.
 */
import { vi, describe, it, expect, beforeAll, afterAll } from 'vitest';
import pg from 'pg';

const DB_URL = process.env.COMPASS_DB_TEST_URL;
const SIMULATE_PRE_CC_0067 = process.env.SIMULATE_PRE_CC_0067 === '1';

// The service reads through lib/db.ts's pool. Route it onto the test's own
// client, so the TypeScript path sees the uncommitted rows in this transaction.
const holder = vi.hoisted(() => ({ client: null as null | { query: (...a: unknown[]) => unknown } }));
vi.mock('./db.js', () => ({
  pool: { query: (...a: unknown[]) => holder.client!.query(...a) },
}));

import { getRecalibrationFlags } from './compassUserLensService.js';

type Q = (sql: string, params?: unknown[]) => Promise<{ rows: Record<string, unknown>[] }>;

/** A published revision with five rungs; `rung3` lets a case reword the user's own rung. */
async function insertRevision(
  q: Q,
  topicId: string,
  revision: number,
  version: number,
  changeClass: 'substantive' | 'clarifying',
  rung3: string
): Promise<string> {
  const { rows } = await q(
    `INSERT INTO inform.compass_topic_revisions
       (topic_id, revision, version, change_class, title, question_text, rationale,
        public_note, status, is_current, published_at)
     VALUES ($1, $2, $3, $4, 'Regression 0011', 'Regression 0011 question?',
             'regression test fixture', 'regression test fixture', 'published', true, now())
     RETURNING id`,
    [topicId, revision, version, changeClass]
  );
  const id = rows[0].id as string;
  await q(
    `INSERT INTO inform.compass_stance_revisions (topic_revision_id, value, text)
     SELECT $1, v, CASE WHEN v = 3 THEN $2 ELSE 'rung ' || v END
       FROM generate_series(1, 5) v`,
    [id, rung3]
  );
  return id;
}

/** Retire the current revision so the next one can become current. */
async function supersede(q: Q, revisionId: string): Promise<void> {
  await q(
    `UPDATE inform.compass_topic_revisions SET status = 'superseded', is_current = false WHERE id = $1`,
    [revisionId]
  );
}

/**
 * Pin a revision for the topic in the open season. Moving a pin is what a
 * season rollover does; season_pin_is_immutable forbids UPDATE, so the
 * simulated rollover replaces the row.
 */
async function pin(q: Q, seasonId: string, topicId: string, revisionId: string): Promise<void> {
  await q(`DELETE FROM inform.season_questions WHERE season_id = $1 AND topic_id = $2`, [seasonId, topicId]);
  await q(
    `INSERT INTO inform.season_questions (season_id, topic_id, topic_revision_id, question_number, display_order)
     SELECT $1, $2, $3,
            coalesce(max(question_number), 0) + 1, coalesce(max(display_order), 0) + 1
       FROM inform.season_questions WHERE season_id = $1`,
    [seasonId, topicId, revisionId]
  );
}

describe.skipIf(!DB_URL)('decision 0011 — a version bump re-asks the person who answered', () => {
  let client: pg.Client;
  let q: Q;

  beforeAll(async () => {
    client = new pg.Client({ connectionString: DB_URL, ssl: { rejectUnauthorized: false } });
    await client.connect();
    holder.client = client as unknown as { query: (...a: unknown[]) => unknown };
    q = (sql, params) => client.query(sql, params as unknown[]) as unknown as ReturnType<Q>;
  });

  afterAll(async () => {
    await client?.end();
  });

  /**
   * Answer rung 3 against v1, then move the season to a second revision, and
   * return what the answer was stamped with and the flags it now raises.
   * Always rolled back.
   */
  async function answerThenRevise(next: { version: number; changeClass: 'substantive' | 'clarifying' }) {
    await q('BEGIN');
    try {
      await q(`SET LOCAL lock_timeout = '3s'`);
      await q(`SET LOCAL statement_timeout = '20s'`);
      if (SIMULATE_PRE_CC_0067) {
        await q(`ALTER TABLE inform.compass_responses DISABLE TRIGGER compass_responses_stamp_revision`);
      }

      const season = await q(`SELECT id FROM inform.seasons WHERE status = 'open'`);
      expect(season.rows, 'an open season is required').toHaveLength(1);
      const seasonId = season.rows[0].id as string;

      // Any real account: the answer row is never committed, so it is never theirs.
      const user = await q(`SELECT id FROM public.users LIMIT 1`);
      const userId = user.rows[0].id as string;

      const topic = await q(
        `INSERT INTO inform.compass_topics (topic_key, title, question_text)
         SELECT 'regression-0011-' || u, 'Regression 0011 ' || u, 'Regression 0011 question?'
           FROM (SELECT gen_random_uuid()::text AS u) x
         RETURNING id`
      );
      const topicId = topic.rows[0].id as string;

      const v1 = await insertRevision(q, topicId, 1, 1, 'substantive', 'rung 3, as first written');
      await pin(q, seasonId, topicId, v1);

      // The person answers. No revision is passed: the write path must stamp it.
      const answered = await q(
        `INSERT INTO inform.compass_responses (user_id, topic_id, value, updated_at)
         VALUES ($1, $2, 3, now())
         RETURNING answered_revision_id`,
        [userId, topicId]
      );

      await supersede(q, v1);
      const v2 = await insertRevision(
        q, topicId, 2, next.version, next.changeClass, 'rung 3, materially rewritten'
      );
      await pin(q, seasonId, topicId, v2);

      const flags = await getRecalibrationFlags(userId, [topicId]);
      return { v1, v2, stamped: answered.rows[0].answered_revision_id as string | null, flags };
    } finally {
      await q('ROLLBACK');
    }
  }

  it('a material (version-bumping) revision raises a question_revised flag', async () => {
    const { v1, v2, stamped, flags } = await answerThenRevise({ version: 2, changeClass: 'substantive' });

    expect(flags, 'no recalibration flag was raised for the older answer').toHaveLength(1);
    expect(flags[0]).toMatchObject({
      reason: 'question_revised',
      disposition: 'reworded',
      answeredVersion: 1,
      effectiveVersion: 2,
      effectiveRevisionId: v2,
    });

    // The link that broke before CC_0067: the answer must carry the revision it
    // was given against, or CC_0061 can only ever say "fresh".
    expect(stamped, 'answered_revision_id was not stamped on write').toBe(v1);
  });

  it('a clarifying revision (same version) raises nothing', async () => {
    // ADR 0006 §2: clarifying and editorial revisions keep the version, so the
    // same rewritten rung must NOT re-ask. Guards the opposite failure — a
    // mechanism that nags on every copy edit.
    const { flags } = await answerThenRevise({ version: 1, changeClass: 'clarifying' });
    expect(flags).toEqual([]);
  });
});
