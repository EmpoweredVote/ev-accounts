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

/** The open season's number if the topic has one, else the highest season_number present (null if none). */
function resolveDefaultSeason(rows: Pick<SeasonRow, 'season_number' | 'status'>[]): number | null {
  if (rows.length === 0) return null;
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

export type ChangeClass = 'editorial' | 'clarifying' | 'substantive' | null;

/** A chair in ladder order. Its 1-5 number never leaves the API: array order carries the ladder. */
export interface Chair {
  text: string;
  description: string | null;
  supportingPoints: string[];
  examplePerspectives: string[];
  changeSince: 'carried' | 'reworded' | null;
}

export interface SeasonView {
  season: SeasonSummary;
  questionText: string;
  changeClass: ChangeClass;
  seasonNote: string | null;
  topicNote: string | null;
  rationale: string | null;
  isFallback: boolean;
  chairs: Chair[];
}

interface DetailRow {
  season_number: number;
  season_name: string;
  question_text: string;
  change_class: ChangeClass;
  season_note: string | null;
  topic_note: string | null;
  rationale: string | null;
  // Read only to decide changeSince; never copied into the response (its values are the raw 1-5 chair numbers).
  rung_map: unknown;
}

/**
 * True only for exactly {"1":1,"2":2,"3":3,"4":4,"5":5}. Deliberately identity-only: the map's direction is
 * undocumented, so a permutation cannot yield a correct marker. A wrong marker is worse than none.
 */
function isIdentityRungMap(m: unknown): boolean {
  if (typeof m !== 'object' || m === null || Array.isArray(m)) return false;
  const o = m as Record<string, unknown>;
  if (Object.keys(o).length !== 5) return false;
  return [1, 2, 3, 4, 5].every((n) => o[String(n)] === n);
}

interface ChairRow {
  text: string;
  description: string | null;
  supporting_points: string[] | null;
  example_perspectives: string[] | null;
}

seasonsRouter.get('/communities/:id/seasons/:number', optionalAuth, async (req: Request, res: Response) => {
  const notFound = (code: string, message: string) => res.status(404).json({ error: { code, message } });

  let topicId: string | null = null;
  try {
    const { rows } = await pool.query('SELECT topic_id FROM connect.communities WHERE id = $1', [req.params.id]);
    topicId = rows[0]?.topic_id ?? null;
  } catch {
    // a malformed id throws (22P02): treated as not found
  }
  if (!topicId) { notFound('COMMUNITY_NOT_FOUND', 'Community not found'); return; }

  const userId = (req as Request & { userId?: string }).userId;
  let includeDrafts = false;
  if (userId) {
    try {
      includeDrafts = checkRole(await getCachedUserRoles(userId), 'maven');
    } catch {
      includeDrafts = false;
    }
  }

  const requested = Number.parseInt(String(req.params.number), 10);
  if (includeDrafts) res.set('Cache-Control', 'private, no-store');

  try {
    // A draft is invisible to a non-maven, so it is simply absent here and falls back like any unknown number.
    const { rows: visible } = await pool.query(
      'SELECT season_number, season_name, status, opened_at, closed_at FROM connect.get_season_list($1, $2)',
      [topicId, includeDrafts]
    ) as { rows: SeasonRow[] };

    const match = Number.isNaN(requested) ? undefined : visible.find((r) => r.season_number === requested);
    const isFallback = !match;
    const target = match ?? visible.find((r) => r.season_number === resolveDefaultSeason(visible));
    if (!target) { notFound('SEASON_NOT_FOUND', 'Season not found'); return; }

    // Keyed on the RESOLVED season so arbitrary :number values cannot grow the keyspace.
    const key = `fc:season:${topicId}:${target.season_number}:${isFallback}:${includeDrafts}`;
    if (!includeDrafts) {
      const cached = await cache.get<unknown>(key);
      if (cached !== null) { res.json(cached); return; }
    }

    const { rows: detail } = await pool.query(
      'SELECT season_number, season_name, question_text, change_class, season_note, topic_note, rationale, rung_map FROM connect.get_season_detail($1, $2, $3)',
      [topicId, target.season_number, includeDrafts]
    ) as { rows: DetailRow[] };
    const d = detail[0];
    if (!d) { notFound('SEASON_NOT_FOUND', 'Season not found'); return; }

    // The open season reads the live stances (complete); closed seasons read their revisions.
    // Ordering is explicit, in SQL and again in JS: with the numbers stripped, row order is all that carries the ladder.
    let chairRows: ChairRow[];
    if (target.status === 'open') {
      const { rows } = await pool.query(
        'SELECT position, text, supporting_points, description, example_perspectives FROM connect.get_stances_for_community($1) ORDER BY position ASC',
        [req.params.id]
      );
      chairRows = [...rows].sort((a, b) => a.position - b.position);
    } else {
      const { rows } = await pool.query(
        'SELECT ordinal, text, description, supporting_points, example_perspectives FROM connect.get_season_chairs($1, $2, $3) ORDER BY ordinal ASC',
        [topicId, target.season_number, includeDrafts]
      );
      chairRows = [...rows].sort((a, b) => a.ordinal - b.ordinal);
    }

    // Markers only when this season's rung_map is exactly identity; compared with the previous season in the visible list.
    let previousTexts: string[] | null = null;
    if (isIdentityRungMap(d.rung_map)) {
      const prev = visible
        .filter((r) => r.season_number < target.season_number)
        .sort((a, b) => b.season_number - a.season_number)[0];
      if (prev) {
        if (prev.status === 'open') {
          const { rows } = await pool.query(
            'SELECT position, text FROM connect.get_stances_for_community($1) ORDER BY position ASC',
            [req.params.id]
          );
          previousTexts = [...rows].sort((a, b) => a.position - b.position).map((r) => r.text);
        } else {
          const { rows } = await pool.query(
            'SELECT ordinal, text FROM connect.get_season_chairs($1, $2, $3) ORDER BY ordinal ASC',
            [topicId, prev.season_number, includeDrafts]
          );
          previousTexts = [...rows].sort((a, b) => a.ordinal - b.ordinal).map((r) => r.text);
        }
      }
    }
    const changeSince = (i: number, text: string): Chair['changeSince'] => {
      const before = previousTexts?.[i];
      if (before === undefined) return null;
      return before === text ? 'carried' : 'reworded';
    };

    const view: SeasonView = {
      season: {
        number: target.season_number,
        name: target.season_name,
        status: target.status,
        openedAt: target.opened_at,
        closedAt: target.closed_at,
      },
      questionText: d.question_text,
      changeClass: d.change_class ?? null,
      seasonNote: d.season_note ?? null,
      topicNote: d.topic_note ?? null,
      rationale: includeDrafts ? (d.rationale ?? null) : null,
      isFallback,
      chairs: chairRows.map((c, i): Chair => ({
        text: c.text,
        description: c.description ?? null,
        supportingPoints: c.supporting_points ?? [],
        examplePerspectives: c.example_perspectives ?? [],
        changeSince: changeSince(i, c.text),
      })),
    };
    const body = { data: view };
    if (!includeDrafts) await cache.set(key, body, TTL.SEASONS).catch(() => {});
    res.json(body);
  } catch (err) {
    res.status(500).json({ error: { code: 'SEASON_FETCH_FAILED', message: (err as Error).message } });
  }
});
