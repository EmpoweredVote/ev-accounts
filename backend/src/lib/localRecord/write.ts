// The writer: every write is an upsert, so a run can be repeated safely.
import { externalVoteId, type Queryable } from './store.js';
import { sponsorSubject, type Sponsorship } from './sponsorships.js';
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
        sessionId, `onboard-${item.feedId}`, city, item.itemNumber, item.title, item.synopsis ?? '', item.status,
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
         WHERE r.state = 'pending_minutes'
           AND (r.outcome, r.yes_count, r.no_count, r.abstain_count, r.meeting_date)
               IS DISTINCT FROM (EXCLUDED.outcome, EXCLUDED.yes_count, EXCLUDED.no_count, EXCLUDED.abstain_count,
                                 EXCLUDED.meeting_date)`,
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
  /** What the vote rows record as their source. Only the owner-checked path passes anything else. */
  source: 'onboard-minutes' | 'owner-check' = 'onboard-minutes',
): Promise<void> {
  const xid = externalVoteId(city, meetingDate, rc.itemNumber, rc.question);
  // The upsert returns nothing when the row is already identical (no updated_at bump), so read the id back.
  const roll = await db.query(
    `WITH up AS (
       INSERT INTO essentials.legislative_roll_calls AS r
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
       WHERE (r.bill_id, r.meeting_date, r.question, r.question_order, r.outcome, r.yes_count, r.no_count,
              r.abstain_count, r.not_present_count, r.state, r.confirmed_from, r.feed_disagreement)
             IS DISTINCT FROM
             (EXCLUDED.bill_id, EXCLUDED.meeting_date, EXCLUDED.question, EXCLUDED.question_order,
              EXCLUDED.outcome, EXCLUDED.yes_count, EXCLUDED.no_count, EXCLUDED.abstain_count,
              EXCLUDED.not_present_count, EXCLUDED.state, EXCLUDED.confirmed_from, EXCLUDED.feed_disagreement)
       RETURNING id)
     SELECT id FROM up
     UNION ALL
     SELECT id FROM essentials.legislative_roll_calls WHERE city_scope = $1 AND external_vote_id = $3
     LIMIT 1`,
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
  if (rows.length) await db.query(
    `INSERT INTO essentials.legislative_votes
       (id, politician_id, bill_id, session_id, external_vote_id, vote_question, position, vote_date, result,
        yea_count, nay_count, source, roll_call_id, name_as_printed, worked_out, confirmed_from)
     SELECT gen_random_uuid(), v."politicianId", b.id, b.session_id, $2, $3, v.position, $4::date, $5,
            $6::int, $7::int, $11::text, $8::uuid, v."nameAsPrinted", v."workedOut", $9::uuid
     FROM jsonb_to_recordset($10::jsonb)
            AS v("politicianId" uuid, position text, "nameAsPrinted" text, "workedOut" boolean)
     CROSS JOIN essentials.legislative_bills b
     WHERE b.id = $1::uuid
     ON CONFLICT (politician_id, bill_id, session_id, external_vote_id) DO UPDATE SET
       position = EXCLUDED.position, vote_question = EXCLUDED.vote_question, result = EXCLUDED.result,
       vote_date = EXCLUDED.vote_date, yea_count = EXCLUDED.yea_count, nay_count = EXCLUDED.nay_count,
       roll_call_id = EXCLUDED.roll_call_id, source = EXCLUDED.source, name_as_printed = EXCLUDED.name_as_printed,
       worked_out = EXCLUDED.worked_out, confirmed_from = EXCLUDED.confirmed_from`,
    [
      billId, xid, rc.question, meetingDate, rc.outcome, rc.tally.yes, rc.tally.no, rollCallId, voteDocId,
      JSON.stringify(rows), source,
    ],
  );

  // The latest vote document governs: drop votes of this roll call that it no longer contains.
  await db.query(
    `DELETE FROM essentials.legislative_votes WHERE roll_call_id = $1::uuid AND politician_id <> ALL($2::uuid[])`,
    [rollCallId, rows.map((r) => r.politicianId)],
  );
}

/**
 * Log something a person must look at. One row per (city, cause, subject). A resolved row stays resolved when the
 * detail is unchanged; if the detail changed, it is reopened (opened_at restarts) and the old resolution is cleared.
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
    `INSERT INTO essentials.local_record_exceptions AS e (id, city_scope, run_id, cause, subject, detail, opened_at)
     VALUES (gen_random_uuid(), $1, $2, $3, $4, $5::jsonb, now())
     ON CONFLICT (city_scope, cause, subject) DO UPDATE SET
       run_id = EXCLUDED.run_id,
       opened_at = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail AND e.status = 'resolved'
                        THEN now() ELSE e.opened_at END,
       updated_at = now(),
       status = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN 'open' ELSE e.status END,
       resolved_by = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN NULL ELSE e.resolved_by END,
       resolution = CASE WHEN e.detail IS DISTINCT FROM EXCLUDED.detail THEN NULL ELSE e.resolution END,
       detail = EXCLUDED.detail`,
    [city, runId, cause, subject, JSON.stringify(detail ?? {})],
  );
}

/**
 * Write who sponsored and co-sponsored each item and amendment. Every row is an upsert on (bill, amendment, member).
 * Nothing is ever deleted: a stored member the source no longer names stays, and is raised as sponsor_disagrees.
 * Only subjects in `subjectsRead` are compared with what is stored.
 */
export async function writeSponsorships(
  db: Queryable,
  city: CityScope,
  runId: string,
  rows: Sponsorship[],
  opts: { subjectsRead: Set<string> },
): Promise<{ written: number; unknownItems: number; dropped: number }> {
  let written = 0;
  let unknownItems = 0;
  let dropped = 0;

  const bySubject = new Map<string, { itemNumber: string; label: string | null; rows: Sponsorship[] }>();
  for (const r of rows) {
    const subject = sponsorSubject(r.itemNumber, r.label);
    const g = bySubject.get(subject);
    if (g) g.rows.push(r);
    else bySubject.set(subject, { itemNumber: r.itemNumber, label: r.label, rows: [r] });
  }
  // A subject read from the source that produced no rows is still compared with what is stored.
  for (const subject of opts.subjectsRead) {
    if (bySubject.has(subject)) continue;
    const at = subject.indexOf(' / ');
    bySubject.set(subject, {
      itemNumber: at < 0 ? subject : subject.slice(0, at),
      label: at < 0 ? null : subject.slice(at + 3),
      rows: [],
    });
  }

  for (const [subject, group] of bySubject) {
    const bill = await db.query(
      `SELECT id FROM essentials.legislative_bills WHERE jurisdiction = $1 AND number = $2 AND source = 'onboard' LIMIT 2`,
      [city, group.itemNumber],
    );
    if (bill.rows.length > 1) {
      // (jurisdiction, number) is not unique: never guess which bill a sponsor belongs to.
      unknownItems++;
      dropped += group.rows.length;
      await recordException(db, city, runId, 'unknown_item', subject, { reason: 'ambiguous_bill', number: group.itemNumber });
      continue;
    }
    const billId: string | undefined = bill.rows[0]?.id;
    if (!billId) {
      unknownItems++;
      dropped += group.rows.length;
      await recordException(db, city, runId, 'unknown_item', subject, { itemNumber: group.itemNumber, reason: 'no_bill' });
      continue;
    }

    const count = new Map<string, number>();
    for (const r of group.rows) count.set(r.politicianId, (count.get(r.politicianId) ?? 0) + 1);

    for (const r of group.rows) {
      if ((count.get(r.politicianId) ?? 0) > 1) continue; // raised once below, per person
      if (!r.sourceDocumentId) {
        dropped++;
        await recordException(db, city, runId, 'sponsor_unresolved', subject, {
          reason: 'no_document',
          politicianId: r.politicianId,
          nameAsPrinted: r.nameAsPrinted,
          sourceKind: r.sourceKind,
        });
        continue;
      }
      await db.query(
        `INSERT INTO essentials.legislative_sponsorships AS s
           (id, city_scope, bill_id, amendment_label, politician_id, role, name_as_printed, sentence, source_kind,
            source_document_id)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (bill_id, coalesce(amendment_label, ''), politician_id) DO UPDATE SET
           role = EXCLUDED.role,
           name_as_printed = EXCLUDED.name_as_printed,
           sentence = EXCLUDED.sentence,
           source_kind = EXCLUDED.source_kind,
           source_document_id = EXCLUDED.source_document_id,
           updated_at = now()`,
        [city, billId, r.label, r.politicianId, r.role, r.nameAsPrinted, r.sentence, r.sourceKind, r.sourceDocumentId],
      );
      written++;
    }

    // One sponsor_disagrees row per subject (its key is city, cause, subject), so both findings share one detail.
    let disagree: Record<string, unknown> | null = null;
    const twice = [...count].filter(([, n]) => n > 1).map(([id]) => id);
    if (twice.length > 0) {
      dropped += group.rows.filter((r) => twice.includes(r.politicianId)).length;
      disagree = {
        reason: 'same_person_twice',
        people: twice.map((id) => {
          const mine = group.rows.filter((r) => r.politicianId === id);
          return { politicianId: id, roles: mine.map((r) => r.role), sentences: mine.map((r) => r.sentence) };
        }),
      };
    }

    if (opts.subjectsRead.has(subject)) {
      const stored = await db.query(
        `SELECT politician_id FROM essentials.legislative_sponsorships
         WHERE bill_id = $1 AND coalesce(amendment_label, '') = coalesce($2, '')`,
        [billId, group.label],
      );
      const missing = (stored.rows as { politician_id: string }[]).map((x) => x.politician_id).filter((id) => !count.has(id));
      if (missing.length > 0) disagree = { ...disagree, stored: missing, read: [...count.keys()] };
    }
    if (disagree) await recordException(db, city, runId, 'sponsor_disagrees', subject, disagree);
  }
  return { written, unknownItems, dropped };
}
