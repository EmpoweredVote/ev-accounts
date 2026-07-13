import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { getPlayableRaces, getRaceBlindQuotes, computeRaceMatch } from '../lib/readrankService.js';
import type { JurisdictionGeoIds } from '../lib/essentialsService.js';

/**
 * Read & Rank router — blind candidate-match election tool.
 * Mounted at /api/readrank in index.ts. All routes public (the app uses plain
 * fetch). The reveal accepts POSTed verdicts so guests can reveal without auth.
 */

const router = Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// GET /api/readrank/races[?politician_ids=uuid,uuid][&cd=..&sldu=..&sldl=..&county=..&school=..][&embed=uuid,uuid]
router.get('/races', async (req: Request, res: Response): Promise<void> => {
  let politicianIds: string[] | undefined;
  if (typeof req.query.politician_ids === 'string' && req.query.politician_ids.trim()) {
    politicianIds = req.query.politician_ids.split(',').map((s) => s.trim()).filter((s) => UUID_RE.test(s));
  }

  // Optional jurisdiction GEOIDs (from the resolved address search) drive geographic
  // isLocal matching. Absent entirely -> undefined -> behavior unchanged (roster-only).
  const strParam = (v: unknown): string | null => (typeof v === 'string' && v.trim() ? v.trim() : null);
  const cd = strParam(req.query.cd);
  const sldu = strParam(req.query.sldu);
  const sldl = strParam(req.query.sldl);
  const county = strParam(req.query.county);
  const school = strParam(req.query.school);
  let jurisdiction: JurisdictionGeoIds | undefined;
  if (cd || sldu || sldl || county || school) {
    jurisdiction = {
      congressional: cd,
      state_senate: sldu,
      state_house: sldl,
      county,
      school_district: school,
    };
  }

  // Optional: embed boundary geometry for these race ids (the caller renders them
  // immediately, e.g. a featured landing card, so their motif shouldn't lazy-load).
  let embedRaceIds: string[] | undefined;
  if (typeof req.query.embed === 'string' && req.query.embed.trim()) {
    embedRaceIds = req.query.embed.split(',').map((s) => s.trim()).filter((s) => UUID_RE.test(s));
  }

  try {
    const { races, counties } = await getPlayableRaces(politicianIds, jurisdiction, embedRaceIds);
    res.status(200).json({ races, counties });
  } catch (err) {
    console.error('[GET /readrank/races] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// GET /api/readrank/races/:raceId/quotes — blind, topic-grouped
router.get('/races/:raceId/quotes', async (req: Request, res: Response): Promise<void> => {
  const { raceId } = req.params as { raceId: string };
  if (!UUID_RE.test(raceId)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'raceId must be a valid UUID' });
    return;
  }
  try {
    const payload = await getRaceBlindQuotes(raceId);
    if (!payload) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'No playable quotes for this race' });
      return;
    }
    res.status(200).json(payload);
  } catch (err) {
    console.error('[GET /readrank/races/:raceId/quotes] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

// POST /api/readrank/races/:raceId/reveal — de-masked candidate ballot
const revealSchema = z.object({
  verdicts: z.array(z.object({
    quote_id: z.string().uuid(),
    supported: z.boolean(),
    rank: z.number().int().positive().nullable().default(null),
    session_size: z.number().int().nonnegative().optional(),
  })).max(500),
});

router.post('/races/:raceId/reveal', async (req: Request, res: Response): Promise<void> => {
  const { raceId } = req.params as { raceId: string };
  if (!UUID_RE.test(raceId)) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'raceId must be a valid UUID' });
    return;
  }
  const parsed = revealSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid body. Expected { verdicts: [{ quote_id, supported, rank }] }' });
    return;
  }
  const exposeScore = process.env.READRANK_EXPOSE_SCORE === 'true' && req.query.debug_score === '1';
  try {
    const result = await computeRaceMatch(
      raceId,
      parsed.data.verdicts.map((v) => ({ quote_id: v.quote_id, supported: v.supported, rank: v.rank })),
      exposeScore
    );
    if (!result) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Race not found' });
      return;
    }
    res.status(200).json(result);
  } catch (err) {
    console.error('[POST /readrank/races/:raceId/reveal] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
