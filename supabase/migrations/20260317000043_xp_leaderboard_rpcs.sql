-- =============================================================================
-- Migration 043: XP Leaderboard RPCs
-- =============================================================================
-- Two SECURITY DEFINER functions for the CTC leaderboard feature:
--
--   connect.get_xp_leaderboard(p_window, p_limit)
--     Returns the top N Connected users ranked by CTC XP.
--     p_window = 'alltime' (default) or 'week' (rolling 168 hours).
--     Only users with CTC XP > 0 appear. Ranked by DENSE_RANK so ties
--     share the same rank without gaps.
--
--   connect.get_my_xp_rank(p_user_id, p_window)
--     Returns the calling user's rank, XP totals, and the XP gap to the
--     player directly above them. Returns no rows if the user has never
--     earned CTC XP (unranked).
-- =============================================================================


-- ---------------------------------------------------------------------------
-- connect.get_xp_leaderboard
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION connect.get_xp_leaderboard(
  p_window TEXT    DEFAULT 'alltime',
  p_limit  INTEGER DEFAULT 25
)
RETURNS TABLE (
  rank         BIGINT,
  user_id      UUID,
  username     TEXT,
  level        INTEGER,
  total_xp     BIGINT,
  weekly_xp    BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH ctc_totals AS (
    SELECT
      xt.user_id,
      SUM(xt.amount)                                                            AS total_xp,
      SUM(CASE WHEN xt.created_at > now() - interval '168 hours'
               THEN xt.amount ELSE 0 END)                                       AS weekly_xp
    FROM connect.xp_transactions xt
    WHERE xt.source = 'civic_trivia_championship_score'
    GROUP BY xt.user_id
  ),
  ranked AS (
    SELECT
      DENSE_RANK() OVER (
        ORDER BY
          CASE WHEN p_window = 'week' THEN ct.weekly_xp
               ELSE ct.total_xp
          END DESC
      )                       AS rank,
      cp.user_id,
      cp.display_name         AS username,
      cp.current_level        AS level,
      ct.total_xp,
      ct.weekly_xp
    FROM connect.connected_profiles cp
    INNER JOIN ctc_totals ct ON ct.user_id = cp.user_id
    WHERE cp.account_standing = 'active'
      AND (
        (p_window = 'week' AND ct.weekly_xp  > 0) OR
        (p_window != 'week' AND ct.total_xp  > 0)
      )
  )
  SELECT rank, user_id, username, level, total_xp, weekly_xp
  FROM ranked
  ORDER BY rank
  LIMIT p_limit;
$$;


-- ---------------------------------------------------------------------------
-- connect.get_my_xp_rank
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION connect.get_my_xp_rank(
  p_user_id UUID,
  p_window  TEXT DEFAULT 'alltime'
)
RETURNS TABLE (
  rank            BIGINT,
  user_id         UUID,
  username        TEXT,
  level           INTEGER,
  total_xp        BIGINT,
  weekly_xp       BIGINT,
  xp_to_next_rank BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH ctc_totals AS (
    SELECT
      xt.user_id,
      SUM(xt.amount)                                                            AS total_xp,
      SUM(CASE WHEN xt.created_at > now() - interval '168 hours'
               THEN xt.amount ELSE 0 END)                                       AS weekly_xp
    FROM connect.xp_transactions xt
    WHERE xt.source = 'civic_trivia_championship_score'
    GROUP BY xt.user_id
  ),
  ranked AS (
    SELECT
      DENSE_RANK() OVER (
        ORDER BY
          CASE WHEN p_window = 'week' THEN ct.weekly_xp
               ELSE ct.total_xp
          END DESC
      )                       AS rank,
      cp.user_id,
      cp.display_name         AS username,
      cp.current_level        AS level,
      ct.total_xp,
      ct.weekly_xp
    FROM connect.connected_profiles cp
    INNER JOIN ctc_totals ct ON ct.user_id = cp.user_id
    WHERE cp.account_standing = 'active'
  ),
  my_row AS (
    SELECT * FROM ranked WHERE user_id = p_user_id
  ),
  next_xp AS (
    -- Smallest XP total strictly greater than the calling user's XP
    SELECT MIN(
      CASE WHEN p_window = 'week' THEN r.weekly_xp ELSE r.total_xp END
    ) AS xp
    FROM ranked r
    WHERE
      CASE WHEN p_window = 'week' THEN r.weekly_xp ELSE r.total_xp END
      >
      (SELECT CASE WHEN p_window = 'week' THEN weekly_xp ELSE total_xp END FROM my_row)
  )
  SELECT
    mr.rank,
    mr.user_id,
    mr.username,
    mr.level,
    mr.total_xp,
    mr.weekly_xp,
    GREATEST(0, COALESCE(nx.xp, 0) - CASE WHEN p_window = 'week' THEN mr.weekly_xp ELSE mr.total_xp END) AS xp_to_next_rank
  FROM my_row mr
  LEFT JOIN next_xp nx ON true;
$$;
