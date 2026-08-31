import { Router } from 'express';
import { pool } from '../lib/db.js';
import { requireServiceKey } from '../middleware/serviceKeyAuth.js';
import { optionalAuth } from '../middleware/auth.js';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/trivia/collections
// Public read (optionalAuth). Proxies CTC's public collections list so the
// Essentials frontend can discover which communities have a Civic Trivia
// Championship collection (and build ?collection=<slug> deep-links) without a
// cross-origin call to the CTC backend — mirrors the /treasury/cities pattern.
//
// Response: { collections: [{ id, name, slug, tier, localeName, localeCode,
//   themeColor, questionCount }] } — trimmed to what Essentials consumes.
//
// Cached in-memory (5 min) so we do not wake CTC's Render backend on every
// results-page load; on upstream failure we serve stale cache, else an empty
// list (never a 5xx — a missing chip degrades gracefully).
// ---------------------------------------------------------------------------
const CTC_COLLECTIONS_URL =
  (process.env.CTC_BACKEND_URL || 'https://civic-trivia-backend.onrender.com').replace(
    /\/+$/,
    ''
  ) + '/api/game/collections';

const COLLECTIONS_TTL_MS = 5 * 60 * 1000;
let collectionsCache: { at: number; data: unknown[] } | null = null;

router.get('/collections', optionalAuth, async (_req, res) => {
  const now = Date.now();
  if (collectionsCache && now - collectionsCache.at < COLLECTIONS_TTL_MS) {
    return res.status(200).json({ collections: collectionsCache.data });
  }

  try {
    const upstream = await fetch(CTC_COLLECTIONS_URL, {
      signal: AbortSignal.timeout(10_000),
      headers: { Accept: 'application/json' },
    });

    if (!upstream.ok) {
      console.error(`[GET /api/trivia/collections] upstream ${upstream.status}`);
      return res.status(200).json({ collections: collectionsCache?.data ?? [] });
    }

    const body: unknown = await upstream.json();
    const raw = Array.isArray(body)
      ? body
      : (body as { collections?: unknown })?.collections;
    const list = Array.isArray(raw) ? raw : [];

    const collections = list
      .filter((c): c is Record<string, unknown> => !!c && typeof (c as any).slug === 'string')
      .map((c) => ({
        id: c.id,
        name: c.name,
        slug: c.slug,
        tier: c.tier,
        localeName: c.localeName,
        localeCode: c.localeCode,
        themeColor: c.themeColor,
        questionCount: c.questionCount,
      }));

    collectionsCache = { at: now, data: collections };
    return res.status(200).json({ collections });
  } catch (err) {
    console.error('[GET /api/trivia/collections] error:', err);
    return res.status(200).json({ collections: collectionsCache?.data ?? [] });
  }
});

// GET /api/trivia/leaderboard-profiles?user_ids=uuid1,uuid2,...
// Auth: TRIVIA_SERVICE_KEY (X-Service-Key header, service-to-service)
// Returns: pseudonym, total_xp, level per user_id for CTC leaderboard display.
// Level is computed inline via connect.calculate_level IMMUTABLE function
// (CROSS JOIN LATERAL — one SQL round-trip regardless of user count).
// Max 100 user_ids per request to keep query cost bounded.
router.get(
  '/leaderboard-profiles',
  requireServiceKey,
  async (req, res) => {
    const raw = req.query.user_ids as string | undefined;
    if (!raw) {
      return res.status(400).json({ error: 'user_ids query param required' });
    }
    const userIds = raw
      .split(',')
      .map((id) => id.trim())
      .filter((id) => id.length > 0);
    if (userIds.length === 0) {
      return res.status(400).json({ error: 'user_ids must contain at least one UUID' });
    }
    if (userIds.length > 100) {
      return res.status(400).json({ error: 'user_ids max 100 per request' });
    }

    try {
      // LEFT JOIN connect.connected_profiles to handle users who exist in
      // public.users but have not yet enrolled at Connected tier.
      // connected_profiles has no pseudonym column; current_level is stored directly.
      //
      // ⚠ deleted_at belongs in the ON clause, not the WHERE. In the WHERE it
      // would turn the LEFT JOIN back into an inner join and drop the user row
      // outright; in the ON it degrades a deleted profile to the same shape as a
      // never-enrolled one, which is what the COALESCEs below already handle.
      const result = await pool.query(
        `SELECT
           u.id                           AS user_id,
           u.display_name,
           NULL::text                     AS pseudonym,
           COALESCE(cp.total_xp, 0)      AS total_xp,
           COALESCE(cp.current_level, 1) AS level
         FROM public.users u
         LEFT JOIN connect.connected_profiles cp
                ON cp.user_id = u.id AND cp.deleted_at IS NULL
         WHERE u.id = ANY($1::uuid[])`,
        [userIds]
      );

      return res.json({ profiles: result.rows });
    } catch (err) {
      console.error('[GET /api/trivia/leaderboard-profiles] error:', err);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }
);

export default router;
