/**
 * cronService — calibration lapse job logic.
 *
 * Identifies Empowered users who have not calibrated new live topics and
 * dispatches notifications at three thresholds:
 *   Day 25 — warning notification (overdue topics listed)
 *   Day 30 — final warning notification (demotion imminent)
 *   Day 31 — automatic demotion via execute_demotion RPC
 *
 * IDEMPOTENCY (CRON-04):
 * A row is INSERTed into calibration_lapse_runs with ON CONFLICT DO NOTHING
 * at job start. If the row already exists (i.e. the job already ran today),
 * the function returns immediately — no duplicate notifications or demotions.
 *
 * PRIORITY ORDER:
 * Day 31 users are processed first (demotion). Sets are built so that a user
 * at day 31 is excluded from day-30 and day-25 notification paths, and a user
 * at day 30 is excluded from the day-25 path.
 */

import { pool } from './db.js';
import { supabaseAdmin } from './supabase.js';
import { executeDemotion } from './empowerService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface LapsedUser {
  user_id: string;
  overdue_topic_ids: string[];
  days_overdue: number;
}

// ---------------------------------------------------------------------------
// runCalibrationLapseJob
// ---------------------------------------------------------------------------

export async function runCalibrationLapseJob(): Promise<void> {
  const today = new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
  const jobStart = Date.now();

  // CRON-04: Idempotency — abort if already ran today
  const { rowCount } = await pool.query(
    'INSERT INTO public.calibration_lapse_runs (run_date) VALUES ($1) ON CONFLICT (run_date) DO NOTHING',
    [today]
  );
  if (rowCount === 0) {
    console.log(`[cron] Calibration lapse already ran for ${today} — skipping`);
    return;
  }

  let warned25 = 0, warned30 = 0, demoted = 0;

  try {
    // Fetch all three thresholds via the updated get_calibration_lapsed_users RPC
    const { data: day25Data } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 25 });
    const { data: day30Data } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 30 });
    const { data: day31Data } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 31 });

    const day25Users: LapsedUser[] = day25Data ?? [];
    const day30Users: LapsedUser[] = day30Data ?? [];
    const day31Users: LapsedUser[] = day31Data ?? [];

    // Build sets for deduplication — higher thresholds exclude from lower ones
    const day31Set = new Set(day31Users.map((u) => u.user_id));
    const day30Set = new Set(day30Users.map((u) => u.user_id));

    // -----------------------------------------------------------------------
    // Day 31: Demotion (highest priority — process first)
    // -----------------------------------------------------------------------
    for (const user of day31Users) {
      try {
        await executeDemotion(user.user_id, {
          reason: 'calibration_lapse',
          overdue_topics: user.overdue_topic_ids,
          days_overdue: user.days_overdue,
          triggered_by: 'cron',
        });
        await pool.query(
          `INSERT INTO public.notifications (user_id, type, payload) VALUES ($1, $2, $3)`,
          [
            user.user_id,
            'demotion_confirmed',
            JSON.stringify({
              reason: 'calibration_lapse',
              overdue_topic_ids: user.overdue_topic_ids,
              days_overdue: user.days_overdue,
              message:
                'Your Empowered status has been revoked due to uncalibrated topics. Complete calibration and re-empower to restore your status.',
            }),
          ]
        );
        demoted++;
      } catch (err) {
        console.error(`[cron] Failed to demote user ${user.user_id}:`, err);
      }
    }

    // -----------------------------------------------------------------------
    // Day 30: Final warning (exclude users already processed at day 31)
    // -----------------------------------------------------------------------
    for (const user of day30Users) {
      if (day31Set.has(user.user_id)) continue;
      await pool.query(
        `INSERT INTO public.notifications (user_id, type, payload) VALUES ($1, $2, $3)`,
        [
          user.user_id,
          'calibration_warning_30',
          JSON.stringify({
            overdue_topic_ids: user.overdue_topic_ids,
            days_overdue: user.days_overdue,
            message:
              'Final warning: calibrate your outstanding topics before the next daily check or your Empowered status will be revoked.',
          }),
        ]
      );
      warned30++;
    }

    // -----------------------------------------------------------------------
    // Day 25: Warning (exclude users at day 30 or day 31)
    // -----------------------------------------------------------------------
    for (const user of day25Users) {
      if (day31Set.has(user.user_id)) continue;
      if (day30Set.has(user.user_id)) continue;
      await pool.query(
        `INSERT INTO public.notifications (user_id, type, payload) VALUES ($1, $2, $3)`,
        [
          user.user_id,
          'calibration_warning_25',
          JSON.stringify({
            overdue_topic_ids: user.overdue_topic_ids,
            days_overdue: user.days_overdue,
            message:
              'You have uncalibrated topics that require attention. Calibrate within the next 6 days to maintain your Empowered status.',
          }),
        ]
      );
      warned25++;
    }

    // Update run record with final stats
    await pool.query(
      `UPDATE public.calibration_lapse_runs
       SET finished_at = now(), users_warned_25 = $2, users_warned_30 = $3, users_demoted = $4
       WHERE run_date = $1`,
      [today, warned25, warned30, demoted]
    );
  } catch (err) {
    await pool.query(
      'UPDATE public.calibration_lapse_runs SET error_message = $2 WHERE run_date = $1',
      [today, String(err)]
    );
    console.error('[cron] Calibration lapse job failed:', err);
    throw err;
  }

  console.log(
    JSON.stringify({
      level: 'info',
      job: 'calibration-lapse',
      run_date: today,
      warned25,
      warned30,
      demoted,
      duration_ms: Date.now() - jobStart,
    })
  );
}
