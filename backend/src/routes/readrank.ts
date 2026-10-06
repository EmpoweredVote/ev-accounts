import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { getPlayableRaces, getRaceBlindQuotes, computeRaceMatch } from '../lib/readrankService.js';
import { findLocalities, validateLocalityQuery } from '../lib/readrankLocalities.js';
import type { JurisdictionGeoIds } from '../lib/essentialsService.js';

/**
 * Read & Rank router — blind candidate-match election tool.
 * Mounted at /api/readrank in index.ts. All routes public (the app uses plain
 * fetch). The reveal accepts POSTed verdicts so guests can reveal without auth.
 */

const router = Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type RaceListArgs = Parameters<typeof getPlayableRaces>;

/** Cap on politician ids per race-list call. An LA address resolves ~500; 2000 bounds
 *  the request (~80 KB, under express.json's 100 KB default) without truncating rosters. */
const MAX_POLITICIAN_IDS = 2000;

/**
 * Shared parser for GET (query string) and POST (JSON body) race-list requests.
 * Both accept the same fields; ids are comma-joined strings on GET and either an
 * array or a comma-joined string on POST. Invalid UUIDs are dropped, not rejected.
 */
function parseRaceListInput(src: Record<string, unknown>): RaceListArgs {
  // Matches the original GET parsing: absent/blank -> undefined; otherwise the valid UUIDs.
  const idList = (v: unknown): string[] | undefined => {
    if (typeof v === 'string') {
      return v.trim() ? v.split(',').map((s) => s.trim()).filter((s) => UUID_RE.test(s)) : undefined;
    }
    if (Array.isArray(v)) {
      return v.filter((s): s is string => typeof s === 'string').map((s) => s.trim()).filter((s) => UUID_RE.test(s));
    }
    return undefined;
  };

  const politicianIds = idList(src.politician_ids);

  // Optional jurisdiction GEOIDs (from the resolved address search) drive geographic
  // isLocal matching. Absent entirely -> undefined -> behavior unchanged (roster-only).
  const strParam = (v: unknown): string | null => (typeof v === 'string' && v.trim() ? v.trim() : null);
  const cd = strParam(src.cd);
  const sldu = strParam(src.sldu);
  const sldl = strParam(src.sldl);
  const county = strParam(src.county);
  const school = strParam(src.school);
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
  const embedRaceIds = idList(src.embed);
  // embed_local=1 inlines geometry for the user's own (isLocal) races — the located
  // ballot's "Your races" section — so its motifs don't lazy-load.
  const embedLocal = src.embed_local === '1' || src.embed_local === 'true' || src.embed_local === true;

  return [politicianIds, jurisdiction, embedRaceIds, embedLocal];
}

async function sendRaceList(res: Response, args: RaceListArgs, label: string): Promise<void> {
  try {
    const { races, counties } = await getPlayableRaces(...args);
    res.status(200).json({ races, counties });
  } catch (err) {
    console.error(`[${label}] error:`, err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
}

// GET /api/readrank/races[?politician_ids=uuid,uuid][&cd=..&sldu=..&sldl=..&county=..&school=..][&embed=uuid,uuid][&embed_local=1]
// Large rosters (an LA address resolves ~500 ids) overflow the URL — use POST.
router.get('/races', async (req: Request, res: Response): Promise<void> => {
  await sendRaceList(res, parseRaceListInput(req.query as Record<string, unknown>), 'GET /readrank/races');
});

// POST /api/readrank/races — same inputs as GET, in a JSON body, so a large
// politician_ids roster doesn't hit URL-length limits at the edge.
// Body: { politician_ids?: string[], cd?, sldu?, sldl?, county?, school?, embed?: string[], embed_local?: boolean }
router.post('/races', async (req: Request, res: Response): Promise<void> => {
  const body: unknown = req.body ?? {};
  if (typeof body !== 'object' || Array.isArray(body) || body === null) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Body must be a JSON object' });
    return;
  }
  const src = body as Record<string, unknown>;
  for (const key of ['politician_ids', 'embed'] as const) {
    const v = src[key];
    if (v !== undefined && !Array.isArray(v) && typeof v !== 'string') {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: `${key} must be an array of UUIDs` });
      return;
    }
    if (Array.isArray(v) && v.length > MAX_POLITICIAN_IDS) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: `${key} accepts at most ${MAX_POLITICIAN_IDS} ids` });
      return;
    }
  }
  await sendRaceList(res, parseRaceListInput(src), 'POST /readrank/races');
});

// GET /api/readrank/localities?q=<city>[&state=<USPS>] — city name -> incorporated place + county
router.get('/localities', async (req: Request, res: Response): Promise<void> => {
  const v = validateLocalityQuery(req.query.q, req.query.state);
  if (!v.ok) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: v.message });
    return;
  }
  try {
    const localities = await findLocalities(v.q, v.state);
    res.status(200).json({ localities });
  } catch (err) {
    console.error('[GET /readrank/localities] error:', err);
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
