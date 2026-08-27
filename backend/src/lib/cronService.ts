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
 * at job start via the cron_upsert_lapse_run RPC. If the row already exists
 * (i.e. the job already ran today), the function returns immediately — no
 * duplicate notifications or demotions.
 *
 * PRIORITY ORDER:
 * Day 31 users are processed first (demotion). Sets are built so that a user
 * at day 31 is excluded from day-30 and day-25 notification paths, and a user
 * at day 30 is excluded from the day-25 path.
 */

import { supabaseAdmin, adminRpc } from './supabase.js';
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
  const { data: inserted, error: upsertError } = await adminRpc('cron_upsert_lapse_run', {
    p_run_date: today,
  });

  if (upsertError) throw new Error(upsertError.message);

  if (!inserted) {
    console.log(`[cron] Calibration lapse already ran for ${today} — skipping`);
    return;
  }

  let warned25 = 0, warned30 = 0, demoted = 0;

  try {
    // Fetch all three thresholds via the updated get_calibration_lapsed_users RPC.
    //
    // 🔴 THE ERROR IS LOAD-BEARING — do not go back to destructuring `data` alone.
    // A failing RPC returns `data: null`, which `?? []` turns into zero lapsed users. The
    // job then recorded warned_25=0, warned_30=0, demoted=0 and logged level:info: a dead
    // detector and a healthy-looking run are the same signal. Nobody is wrongly demoted, so
    // the direction is safe — the silence is the defect. Throwing hands the failure to the
    // catch below, which writes cron_record_lapse_error instead of a clean zero row.
    //
    // An EMPTY array with NO error still means what it says: nobody lapsed today.
    const [day25Res, day30Res, day31Res] = await Promise.all([
      supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 25 }),
      supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 30 }),
      supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 31 }),
    ]);

    for (const [threshold, res] of [[25, day25Res], [30, day30Res], [31, day31Res]] as const) {
      if (res.error) {
        throw new Error(
          `get_calibration_lapsed_users(${threshold}) failed: ${res.error.message}`
        );
      }
    }

    const { data: day25Data } = day25Res;
    const { data: day30Data } = day30Res;
    const { data: day31Data } = day31Res;

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
        await adminRpc('insert_notification', {
          p_user_id: user.user_id,
          p_type: 'demotion_confirmed',
          p_payload: {
            reason: 'calibration_lapse',
            overdue_topic_ids: user.overdue_topic_ids,
            days_overdue: user.days_overdue,
            message:
              'Your Empowered status has been revoked due to uncalibrated topics. Complete calibration and re-empower to restore your status.',
          },
        });
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
      await adminRpc('insert_notification', {
        p_user_id: user.user_id,
        p_type: 'calibration_warning_30',
        p_payload: {
          overdue_topic_ids: user.overdue_topic_ids,
          days_overdue: user.days_overdue,
          message:
            'Final warning: calibrate your outstanding topics before the next daily check or your Empowered status will be revoked.',
        },
      });
      warned30++;
    }

    // -----------------------------------------------------------------------
    // Day 25: Warning (exclude users at day 30 or day 31)
    // -----------------------------------------------------------------------
    for (const user of day25Users) {
      if (day31Set.has(user.user_id)) continue;
      if (day30Set.has(user.user_id)) continue;
      await adminRpc('insert_notification', {
        p_user_id: user.user_id,
        p_type: 'calibration_warning_25',
        p_payload: {
          overdue_topic_ids: user.overdue_topic_ids,
          days_overdue: user.days_overdue,
          message:
            'You have uncalibrated topics that require attention. Calibrate within the next 6 days to maintain your Empowered status.',
        },
      });
      warned25++;
    }

    // Update run record with final stats
    await adminRpc('cron_update_lapse_run', {
      p_run_date: today,
      p_warned_25: warned25,
      p_warned_30: warned30,
      p_demoted: demoted,
    });
  } catch (err) {
    await adminRpc('cron_record_lapse_error', {
      p_run_date: today,
      p_error: String(err),
    });
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
