// The writer: every write is an upsert, so a run can be repeated safely.
import { externalVoteId, type Queryable } from './store.js';
import { EXCEPTION_CAUSES } from './types.js';
import type { CheckResult, CityScope, ExceptionCause, FeedItem, MinutesRollCall } from './types.js';

/** Year of a feed number: '2026-02' -> 2026, '21-23' -> 2021. Falls back to the Final action's year. */
function numberYear(item: FeedItem): string {
  const m = /^(\d{4}|\d{2})-/.exec(item.number);
  if (m) return m[1].length === 4 ? m[1] : String(2000 + Number(m[1]));
  return item.final ? item.final.date.slice(0, 4) : 'unknown';
}

/** Sessions (one per number year), bills, and a pending roll call for each feed Final not yet confirmed. */
export async function writeFeed(
  db: Queryable,
  city: CityScope,
  items: FeedItem[],
): Promise<{ bills: number; pending: number }> {
  const sessionIds = new Map<string, string>();
  let bills = 0;
  let pending = 0;

  for (const item of items) {
    const year = numberYear(item);
    let sessionId = sessionIds.get(year);
    if (!sessionId) {
      const ext = `onboard-${year}`;
      // No unique index is known for sessions, so insert only when absent, then read the id back.
      await db.query(
        `INSERT INTO essentials.legislative_sessions (id, jurisdiction, name, external_id, is_current, source)
         SELECT gen_random_uuid(), $1, $2, $3, false, 'onboard'
         WHERE NOT EXISTS (
           SELECT 1 FROM essentials.legislative_sessions WHERE jurisdiction = $1 AND external_id = $3)`,
        [city, `${year} Common Council`, ext],
      );
      const found = await db.query(
        `SELECT id FROM essentials.legislative_sessions WHERE jurisdiction = $1 AND external_id = $2 ORDER BY id LIMIT 1`,
        [city, ext],
      );
      sessionId = found.rows[0].id as string;
      sessionIds.set(year, sessionId);
    }

    const bill = await db.query(
      `INSERT INTO essentials.legislative_bills AS b
         (id, session_id, external_id, jurisdiction, number, title, summary, raw_status, status_label,
          passed_at, url, source)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $7, $8, $9, 'onboard')
       ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
         session_id = EXCLUDED.session_id, number = EXCLUDED.number, title = EXCLUDED.title,
         summary = EXCLUDED.summary, raw_status = EXCLUDED.raw_status, status_label = EXCLUDED.status_label,
         passed_at = EXCLUDED.passed_at, url = EXCLUDED.url
       RETURNING id`,
      [
        sessionId, `onboard-${item.feedId}`, city, item.itemNumber, item.title, item.synopsis, item.status,
        item.final?.outcome === 'passed' ? item.final.date : null, item.pageUrl,
      ],
    );
    bills++;

    if (item.final) {
      const question = 'Final passage';
      const t = item.final.tally;
      await db.query(
        `INSERT INTO essentials.legislative_roll_calls AS r
           (id, city_scope, bill_id, external_vote_id, meeting_date, question, question_order, outcome,
            yes_count, no_count, abstain_count, state)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, 0, $6, $7, $8, $9, 'pending_minutes')
         ON CONFLICT (city_scope, external_vote_id) DO UPDATE SET
           outcome = EXCLUDED.outcome, yes_count = EXCLUDED.yes_count, no_count = EXCLUDED.no_count,
           abstain_count = EXCLUDED.abstain_count, meeting_date = EXCLUDED.meeting_date, updated_at = now()
         WHERE r.state = 'pending_minutes'`,
        [
          city, bill.rows[0].id, externalVoteId(city, item.final.date, item.itemNumber, question),
          item.final.date, question, item.final.outcome, t?.yes ?? null, t?.no ?? null, t?.abstain ?? null,
        ],
      );
      pending++;
    }
  }
  return { bills, pending };
}

/**
 * Confirm one roll call from a vote document (the Memorandum, later the formal Minutes). The roll call takes its
 * counts from that document; each member's vote is upserted with the name as printed. `meetingDate` is needed
 * because a parsed roll call does not carry it.
 */
export async function writeConfirmed(
  db: Queryable,
  city: CityScope,
  rc: MinutesRollCall,
  result: Extract<CheckResult, { ok: true }>,
  billId: string,
  meetingDate: string,
  voteDocId: string,
): Promise<void> {
  const xid = externalVoteId(city, meetingDate, rc.itemNumber, rc.question);
  const roll = await db.query(
    `INSERT INTO essentials.legislative_roll_calls AS r
       (id, city_scope, bill_id, external_vote_id, meeting_date, question, question_order, outcome,
        yes_count, no_count, abstain_count, not_present_count, state, confirmed_from, feed_disagreement)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'confirmed', $12, $13)
     ON CONFLICT (city_scope, external_vote_id) DO UPDATE SET
       bill_id = EXCLUDED.bill_id, meeting_date = EXCLUDED.meeting_date, question = EXCLUDED.question,
       question_order = EXCLUDED.question_order, outcome = EXCLUDED.outcome, yes_count = EXCLUDED.yes_count,
       no_count = EXCLUDED.no_count, abstain_count = EXCLUDED.abstain_count,
       not_present_count = EXCLUDED.not_present_count, state = 'confirmed',
       confirmed_from = EXCLUDED.confirmed_from, feed_disagreement = EXCLUDED.feed_disagreement,
       updated_at = now()
     RETURNING id`,
    [
      city, billId, xid, meetingDate, rc.question, rc.index, rc.outcome, rc.tally.yes, rc.tally.no,
      rc.tally.abstain, result.votes.filter((v) => v.position === 'absent').length, voteDocId,
      result.feedDisagreement,
    ],
  );
  const rollCallId: string = roll.rows[0].id;

  const rows = result.votes.map((v) => ({
    politicianId: v.politicianId, position: v.position, nameAsPrinted: v.nameAsPrinted, workedOut: v.workedOut,
  }));
  if (!rows.length) return;
  await db.query(
    `INSERT INTO essentials.legislative_votes
       (id, politician_id, bill_id, session_id, external_vote_id, vote_question, position, vote_date, result,
        yea_count, nay_count, source, roll_call_id, name_as_printed, worked_out, confirmed_from)
     SELECT gen_random_uuid(), v."politicianId", b.id, b.session_id, $2, $3, v.position, $4::date, $5,
            $6::int, $7::int, 'onboard-minutes', $8::uuid, v."nameAsPrinted", v."workedOut", $9::uuid
     FROM jsonb_to_recordset($10::jsonb)
            AS v("politicianId" uuid, position text, "nameAsPrinted" text, "workedOut" boolean)
     CROSS JOIN essentials.legislative_bills b
     WHERE b.id = $1::uuid
     ON CONFLICT (politician_id, bill_id, session_id, external_vote_id) DO UPDATE SET
       position = EXCLUDED.position, vote_question = EXCLUDED.vote_question, result = EXCLUDED.result,
       vote_date = EXCLUDED.vote_date, yea_count = EXCLUDED.yea_count, nay_count = EXCLUDED.nay_count,
       roll_call_id = EXCLUDED.roll_call_id, name_as_printed = EXCLUDED.name_as_printed,
       worked_out = EXCLUDED.worked_out, confirmed_from = EXCLUDED.confirmed_from`,
    [
      billId, xid, rc.question, meetingDate, rc.outcome, rc.tally.yes, rc.tally.no, rollCallId, voteDocId,
      JSON.stringify(rows),
    ],
  );
}

/**
 * Log something a person must look at. One row per (city, cause, subject). A resolved row stays resolved when the
 * detail is unchanged; if the detail changed, it is reopened and the old resolution is cleared.
 */
export async function recordException(
  db: Queryable,
  city: CityScope,
  runId: string,
  cause: ExceptionCause,
  subject: string,
  detail: unknown,
): Promise<void> {
  if (!(EXCEPTION_CAUSES as readonly string[]).includes(cause)) throw new Error(`Unknown exception cause "${cause}"`);
  await db.query(
    `INSERT INTO essentials.local_record_exceptions AS e (id, city_scope, run_id, cause, subject, detail)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5::jsonb)
     ON CONFLICT (city_scope, cause, subject) DO UPDATE SET
       run_id = EXCLUDED.run_id,
       status = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN 'open' ELSE e.status END,
       resolved_by = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN NULL ELSE e.resolved_by END,
       resolution = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN NULL ELSE e.resolution END,
       detail = EXCLUDED.detail`,
    [city, runId, cause, subject, JSON.stringify(detail)],
  );
}
