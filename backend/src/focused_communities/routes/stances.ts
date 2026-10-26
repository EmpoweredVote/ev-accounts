import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { cacheMiddleware, TTL } from '../middleware/cache.js';

export const stancesRouter = Router();

stancesRouter.get('/communities/:id/stances', cacheMiddleware(TTL.STANCES), async (req: Request, res: Response) => {
  const communityId = req.params.id;

  // Verify community exists first (a malformed id throws and is treated as not found)
  let found = false;
  try {
    const { rowCount } = await pool.query('SELECT 1 FROM connect.communities WHERE id = $1', [communityId]);
    found = rowCount === 1;
  } catch {
    // a malformed id throws (22P02): treated as not found, as before
  }

  if (!found) {
    res.status(404).json({
      error: { code: 'COMMUNITY_NOT_FOUND', message: 'Community not found' },
    });
    return;
  }

  // Cross-schema join lives in a SECURITY DEFINER function (connect schema), so this role
  // needs only EXECUTE on it — not read access to the topic tables it joins.
  let rows: Array<{
    position: number;
    text: string;
    supporting_points: string[] | null;
    description: string | null;
    example_perspectives: string[] | null;
  }>;
  try {
    ({ rows } = await pool.query(
      'SELECT position, text, supporting_points, description, example_perspectives FROM connect.get_stances_for_community($1)',
      [communityId]
    ));
  } catch (err) {
    res.status(500).json({
      error: { code: 'STANCES_FETCH_FAILED', message: (err as Error).message },
    });
    return;
  }

  const stances = rows.map((s) => ({
    position: s.position,
    text: s.text,
    supportingPoints: s.supporting_points ?? [],
    description: s.description ?? '',
    examplePerspectives: s.example_perspectives ?? [],
  }));

  res.json({ data: stances });
});
