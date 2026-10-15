/**
 * POST /admin/flags/:flagId/thank — the admin thanks a reporter whose broken-question
 * report turned out to be right.
 *
 * Drives the real express router via supertest; only the DB layer and the gem ledger
 * are mocked. The behaviours worth guarding are all about NOT paying twice and NOT
 * lying about whether payment happened:
 *
 *   - the stamp is written only after the ledger accepted the credit, so a crash
 *     between the two leaves a retryable flag rather than a thanked-but-unpaid one
 *   - a replay never reaches the ledger at all
 *   - a refusal (deleted account, ineligible tier, ledger down) leaves no stamp
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const dbExecute = vi.hoisted(() => vi.fn());
const dbSelect = vi.hoisted(() => vi.fn());
const awardFlagThanksGem = vi.hoisted(() => vi.fn());

const ADMIN_ID = 'aaaaaaaa-0000-4000-8000-00000000000a';
const REPORTER_ID = '4f3a9c1e-0000-4000-8000-000000000001';

// requireAuth normally resolves a Supabase JWT; stand in for an authenticated admin.
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: any, _res: unknown, next: () => void) => {
    req.userId = ADMIN_ID;
    next();
  },
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireSuperAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

// config/supabase.js constructs a client at import time and throws without env vars.
vi.mock('../config/supabase.js', () => ({ supabaseAdmin: {} }));
vi.mock('../db/index.js', () => ({ db: { execute: dbExecute, select: dbSelect } }));
vi.mock('../services/progressionService.js', () => ({ awardFlagThanksGem }));

const { router } = await import('./admin.js');

function app() {
  const a = express();
  a.use(express.json());
  a.use('/admin', router);
  return a;
}

/** A flag row as the lookup query returns it. */
function flagRow(over: Record<string, unknown> = {}) {
  return {
    id: 4812,
    user_id: REPORTER_ID,
    question_id: 77,
    thanked_at: null,
    eligible: true,
    ...over,
  };
}

describe('POST /admin/flags/:flagId/thank', () => {
  beforeEach(() => {
    dbExecute.mockReset();
    awardFlagThanksGem.mockReset();
    awardFlagThanksGem.mockResolvedValue(undefined);
  });

  it('credits the reporter and stamps the flag', async () => {
    dbExecute
      .mockResolvedValueOnce({ rows: [flagRow()] })   // lookup
      .mockResolvedValueOnce({ rows: [] });            // stamp

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(awardFlagThanksGem).toHaveBeenCalledWith(REPORTER_ID, 4812);
    expect(dbExecute).toHaveBeenCalledTimes(2);
  });

  it('rejects a flag id that is not a number', async () => {
    const res = await request(app()).post('/admin/flags/not-a-number/thank');

    expect(res.status).toBe(400);
    expect(awardFlagThanksGem).not.toHaveBeenCalled();
  });

  it('404s an unknown flag without touching the ledger', async () => {
    dbExecute.mockResolvedValueOnce({ rows: [] });

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(404);
    expect(awardFlagThanksGem).not.toHaveBeenCalled();
  });

  it('refuses an Inform-tier reporter, who cannot receive this gem', async () => {
    dbExecute.mockResolvedValueOnce({ rows: [flagRow({ eligible: false })] });

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('TIER_INELIGIBLE');
    expect(awardFlagThanksGem).not.toHaveBeenCalled();
  });

  it('answers a replay without a second credit', async () => {
    const already = '2026-10-13T12:00:00.000Z';
    dbExecute.mockResolvedValueOnce({ rows: [flagRow({ thanked_at: already })] });

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(200);
    expect(res.body.alreadyThanked).toBe(true);
    expect(awardFlagThanksGem).not.toHaveBeenCalled();
    expect(dbExecute).toHaveBeenCalledTimes(1); // lookup only — no second stamp
  });

  it('409s when the reporter has since deleted their account', async () => {
    dbExecute.mockResolvedValueOnce({ rows: [flagRow()] });
    awardFlagThanksGem.mockRejectedValue(
      Object.assign(new Error('Account has been deleted'), { code: 'ACCOUNT_DELETED' })
    );

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(409);
    expect(dbExecute).toHaveBeenCalledTimes(1); // not stamped
  });

  it('leaves the flag unstamped when the ledger fails, so it can be retried', async () => {
    dbExecute.mockResolvedValueOnce({ rows: [flagRow()] });
    awardFlagThanksGem.mockRejectedValue(new Error('connect.credit_gems timed out'));

    const res = await request(app()).post('/admin/flags/4812/thank');

    expect(res.status).toBe(502);
    expect(dbExecute).toHaveBeenCalledTimes(1);
  });

  it('records which admin gave the gem', async () => {
    dbExecute
      .mockResolvedValueOnce({ rows: [flagRow()] })
      .mockResolvedValueOnce({ rows: [] });

    await request(app()).post('/admin/flags/4812/thank');

    // The stamp carries the acting admin's id as a bound parameter.
    const stamp = dbExecute.mock.calls[1][0];
    expect(JSON.stringify(stamp.queryChunks ?? stamp)).toContain(ADMIN_ID);
  });
});

/**
 * The detail panel is where the admin decides WHO to thank, so each flag entry has
 * to carry a name, whether the button should be live, and whether it already fired.
 *
 * NOTE ON COVERAGE: which name wins (Empowered legal_name over Connected handle,
 * and a demoted Empowered profile falling back to its handle) is decided by a
 * COALESCE in SQL, which no mock can exercise — these tests cover the mapping from
 * result row to response field only. The resolution order itself needs a database.
 */
describe('GET /admin/flags/:questionId/detail — reporter identity', () => {
  /** Minimal stand-in for drizzle's chained select builder. */
  function chain(result: unknown[]) {
    const builder: any = {};
    for (const method of ['from', 'leftJoin', 'innerJoin', 'where', 'groupBy', 'orderBy']) {
      builder[method] = () => builder;
    }
    builder.limit = () => Promise.resolve(result);
    return builder;
  }

  beforeEach(() => {
    dbExecute.mockReset();
    dbSelect.mockReset();
    dbSelect.mockReturnValue(chain([{ id: 77, externalId: 'hou-087', text: 'q', collectionNames: [] }]));
  });

  it('returns each reporter name, eligibility and thanked state', async () => {
    dbExecute.mockResolvedValueOnce({
      rows: [
        {
          id: 4812, user_id: REPORTER_ID, reasons: ['wrong-answer'],
          elaboration_text: "it's 2019", created_at: '2026-10-12T00:00:00.000Z',
          display_name: 'Mara Quinn', eligible: true, thanked_at: null,
        },
        {
          id: 4813, user_id: 'bbbbbbbb-0000-4000-8000-00000000000b', reasons: [],
          elaboration_text: null, created_at: '2026-10-11T00:00:00.000Z',
          display_name: 'dpark@example.com', eligible: false,
          thanked_at: '2026-10-13T12:00:00.000Z',
        },
      ],
    });

    const res = await request(app()).get('/admin/flags/77/detail');

    expect(res.status).toBe(200);
    expect(res.body.flags[0]).toMatchObject({
      id: 4812, displayName: 'Mara Quinn', eligible: true, thankedAt: null,
    });
    expect(res.body.flags[1]).toMatchObject({
      id: 4813, displayName: 'dpark@example.com', eligible: false,
      thankedAt: '2026-10-13T12:00:00.000Z',
    });
  });

  it('keeps the reporter id a string, not a number', async () => {
    // The panel typed this as `number` while the column is a uuid — the Thank button
    // is the first thing here that acts on a person, so the type has to be honest.
    dbExecute.mockResolvedValueOnce({
      rows: [{
        id: 4812, user_id: REPORTER_ID, reasons: [], elaboration_text: null,
        created_at: '2026-10-12T00:00:00.000Z', display_name: 'Mara Quinn',
        eligible: true, thanked_at: null,
      }],
    });

    const res = await request(app()).get('/admin/flags/77/detail');

    expect(typeof res.body.flags[0].userId).toBe('string');
    expect(res.body.flags[0].userId).toBe(REPORTER_ID);
  });
});
