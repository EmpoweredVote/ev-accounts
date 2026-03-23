import { Router } from 'express';
import { pool } from '../lib/db.js';
import { requireServiceKey } from '../middleware/serviceKeyAuth.js';

const router = Router();

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
      const result = await pool.query(
        `SELECT
           u.id                           AS user_id,
           u.display_name,
           NULL::text                     AS pseudonym,
           COALESCE(cp.total_xp, 0)      AS total_xp,
           COALESCE(cp.current_level, 1) AS level
         FROM public.users u
         LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
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
