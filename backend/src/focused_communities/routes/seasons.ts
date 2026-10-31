import { Router } from 'express';
import type { Request, Response } from 'express';
import { pool } from '../config/database.js';
import { cache } from '../../lib/cache.js';
import { optionalAuth } from '../../middleware/auth.js';
import { getCachedUserRoles, checkRole } from '../../lib/roleService.js';
import { TTL } from '../middleware/cache.js';

export const seasonsRouter = Router();

export type SeasonStatus = 'open' | 'closed' | 'draft';

export interface SeasonSummary {
  number: number;
  name: string;
  status: SeasonStatus;
  openedAt: string | null;
  closedAt: string | null;
}

interface SeasonRow {
  season_number: number;
  season_name: string;
  status: SeasonStatus;
  opened_at: string | null;
  closed_at: string | null;
}

/** The open season's number if the topic has one, else the highest season_number present. */
function resolveDefaultSeason(rows: Pick<SeasonRow, 'season_number' | 'status'>[]): number {
  const open = rows.find((r) => r.status === 'open');
  if (open) return open.season_number;
  return Math.max(...rows.map((r) => r.season_number));
}

seasonsRouter.get('/communities/:id/seasons', optionalAuth, async (req: Request, res: Response) => {
  const notFound = () => res.status(404).json({
    error: { code: 'COMMUNITY_NOT_FOUND', message: 'Community not found' },
  });

  let topicId: string | null = null;
  try {
    const { rows } = await pool.query('SELECT topic_id FROM connect.communities WHERE id = $1', [req.params.id]);
    topicId = rows[0]?.topic_id ?? null;
  } catch {
    // a malformed id throws (22P02): treated as not found
  }
  if (!topicId) { notFound(); return; }

  // Maven is a predicate here, not a guard: guests get a normal 200 without drafts.
  const userId = (req as Request & { userId?: string }).userId;
  let includeDrafts = false;
  if (userId) {
    try {
      includeDrafts = checkRole(await getCachedUserRoles(userId), 'maven');
    } catch {
      includeDrafts = false;
    }
  }

  // The shared cache never holds draft-bearing responses.
  const key = `fc:seasons:${topicId}:${includeDrafts}`;
  if (includeDrafts) {
    res.set('Cache-Control', 'private, no-store');
  } else {
    const cached = await cache.get<unknown>(key);
    if (cached !== null) { res.json(cached); return; }
  }

  let rows: SeasonRow[];
  try {
    ({ rows } = await pool.query(
      'SELECT season_number, season_name, status, opened_at, closed_at FROM connect.get_season_list($1, $2)',
      [topicId, includeDrafts]
    ));
  } catch (err) {
    res.status(500).json({ error: { code: 'SEASONS_FETCH_FAILED', message: (err as Error).message } });
    return;
  }

  if (rows.length === 0) { notFound(); return; }

  const sorted = [...rows].sort((a, b) => a.season_number - b.season_number);
  const body = {
    data: sorted.map((s): SeasonSummary => ({
      number: s.season_number,
      name: s.season_name,
      status: s.status,
      openedAt: s.opened_at,
      closedAt: s.closed_at,
    })),
    meta: { defaultSeason: resolveDefaultSeason(sorted) },
  };

  if (!includeDrafts) await cache.set(key, body, TTL.SEASONS).catch(() => {});
  res.json(body);
});
