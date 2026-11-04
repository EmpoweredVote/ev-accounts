#!/usr/bin/env node
/**
 * election-transition-status.mjs — what is left to do on the 2026-11-03 transition, computed
 * from production rather than typed by anyone.
 *
 * WHY A SCRIPT AND NOT A SPREADSHEET. The program works 2,159 races across weeks. A hand-kept
 * checklist and the database drift apart, and the whole point is catching what slipped: a seat
 * nobody looked at is indistinguishable from a seat where the incumbent won, because both look
 * like "no change". Every number here is derived, so it cannot overstate progress.
 *
 * 🔴 THREE MEASUREMENT RULES THAT ARE EASY TO GET WRONG, AND WERE:
 *
 *   1. STANCE COVERAGE COMES FROM inform.politician_answers, NOT FROM
 *      politicians.last_stances_researched_at. Measured 2026-11-04: 4,822 politicians have
 *      answer rows; only 431 carry that timestamp. The flag is unusable as coverage. And per
 *      the repo's @zero-scope rule this asks whether research HAPPENED, so blanks (value = 0)
 *      COUNT -- blanking says the ladder moved, not that the reading was undone.
 *
 *   2. "STILL STANDING" IS isStillStanding() BELOW, NOT essentials.is_live_candidate().
 *      That function returns TRUE for `won` AND `lost` alike, deliberately (migration 1582
 *      says so in capitals, because past elections must still render their full field). Using
 *      it here would mean recording losers never shrinks the headshot and stance gap counts to
 *      the winners, and those counts would measure the wrong population for ever.
 *
 *   3. THIS IS AN OFFICE-ROOTED READ, so it de-duplicates on the OFFICE. A politician-rooted
 *      read needs DISTINCT ON (p.id) instead; the right key is opposite in each direction.
 *
 * Read-only. It never writes.
 */
import 'dotenv/config';
import { Pool } from 'pg';
import { pathToFileURL } from 'node:url';

/** Map a districts.district_type to the tier the program works in. */
export function levelOf(districtType) {
  if (!districtType) return 'unknown';
  if (districtType === 'NATIONAL_UPPER' || districtType === 'NATIONAL_LOWER') return 'federal';
  if (districtType.startsWith('STATE')) return 'state';
  if (['SCHOOL', 'LOCAL', 'COUNTY', 'LOCAL_EXEC'].includes(districtType)) return 'local';
  // JUDICIAL and anything new: say so rather than guessing a tier.
  return 'unknown';
}

/**
 * Is this candidate still in contention?
 *
 * 🔴 Deliberately NOT essentials.is_live_candidate — see rule 2 in the header.
 */
export function isStillStanding(row) {
  const r = row?.result ?? null;
  if (r === null) return true;
  return !['lost', 'not_nominated', 'withdrew'].includes(r);
}

/**
 * Which of the five seat states this race sits at.
 *
 *   1 not looked at   no result recorded
 *   2 called          result = won, certainty = called
 *   3 certified       result = won, certainty = certified
 *   4 seated          a future-dated term exists for the winner
 *   5 sworn in        that term has started
 *
 * The 4/5 boundary is read off the CALENDAR, never off a stored flag — the whole transition
 * model exists so that nothing has to be flipped on the day.
 */
export function seatState(row) {
  if (row?.result !== 'won') return 1;

  const termStart = row.winnerTermStart ?? null;
  if (termStart) {
    const today = row.today ?? new Date().toISOString().slice(0, 10);
    return today >= termStart ? 5 : 4;
  }

  return row.resultCertainty === 'certified' ? 3 : 2;
}

const LEVEL_SQL = `
  CASE
    WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER') THEN 'federal'
    WHEN d.district_type LIKE 'STATE%' THEN 'state'
    WHEN d.district_type IN ('SCHOOL','LOCAL','COUNTY','LOCAL_EXEC') THEN 'local'
    ELSE 'unknown'
  END`;

/**
 * Compute the whole status set for one election date.
 *
 * @param {import('pg').Pool|import('pg').Client} client
 * @param {{electionDate?: string, levels?: string[], today?: string}} opts
 */
export async function buildStatus(client, opts = {}) {
  const electionDate = opts.electionDate ?? '2026-11-03';
  const today = opts.today ?? new Date().toISOString().slice(0, 10);

  const { rows } = await client.query(
    `
    WITH live AS (
      SELECT rc.race_id, rc.politician_id, rc.full_name, rc.photo_url, rc.result,
             rc.result_certainty
        FROM essentials.race_candidates rc
    ),
    -- 🔴 A RACE CAN HAVE MORE THAN ONE WINNER, AND PICKING ONE HIDES THE REST.
    -- An earlier version took DISTINCT ON (race_id) ordered by politician_id — one winner per
    -- race, chosen by UUID order. Production already holds 7 races with several 'won' rows, in
    -- two legitimate shapes: a PRIMARY (Maine 2026-06-09 returns a winner per party ballot) and
    -- a MULTI-SEAT AT-LARGE council (Glendale and Beverly Hills elect 3). Waves 3 and 5 are 532
    -- local races where at-large councils are common, so the dropped winners — and their
    -- headshot and stance gaps — would have been invisible. That is exactly the hiding this
    -- tracker exists to prevent.
    winner AS (
      SELECT l.race_id,
             count(*)                                   AS winner_count,
             array_agg(l.politician_id)                 AS politician_ids,
             string_agg(l.full_name, ', ' ORDER BY l.full_name) AS full_names,
             -- Mixed provenance across a multi-seat race reads as the weaker of the two.
             CASE WHEN bool_or(l.result_certainty IS DISTINCT FROM 'certified')
                  THEN 'called' ELSE 'certified' END    AS result_certainty,
             bool_or(l.photo_url IS NULL AND NOT EXISTS (
               SELECT 1 FROM essentials.politicians wp
                WHERE wp.id = l.politician_id AND wp.photo_custom_url IS NOT NULL)) AS any_no_headshot,
             bool_or(NOT EXISTS (
               SELECT 1 FROM inform.politician_answers pa
                WHERE pa.politician_id = l.politician_id))                          AS any_no_stances
        FROM live l WHERE l.result = 'won'
       GROUP BY l.race_id
    )
    -- 🔴 KEYED ON THE RACE, NOT THE OFFICE. An earlier version used DISTINCT ON (o.id), which
    -- looked right -- the repo's rule is that office-rooted reads de-duplicate on o.id -- and
    -- silently lost 5 races: the 6 races with NO office all share a NULL key and collapsed into
    -- one row. It also would have hidden a second race on one office (a special alongside a
    -- regular), which this tracker must show as two pieces of work.
    -- The unit here is the RACE. The address-search de-dup rule is about seats, not races.
    SELECT DISTINCT ON (r.id)
           r.id              AS race_id,
           o.id              AS office_id,
           ${LEVEL_SQL}      AS level,
           d.district_type   AS district_type,
           COALESCE(o.representing_state, e.state) AS state,
           o.title           AS title,
           r.position_name   AS position_name,
           och.politician_id AS current_holder_id,
           hp.full_name      AS current_holder_name,
           och.term_end      AS current_holder_term_end,
           w.winner_count    AS winner_count,
           w.full_names      AS winner_name,
           w.result_certainty AS result_certainty,
           -- 🔴 MEASURED FROM THE ELECTION DATE, NOT FROM TODAY. An earlier version filtered
           -- term_start > $2::date (today), which made this value ALWAYS in the future by
           -- construction — so seatState's today >= termStart could never be true and state
           -- 5 was unreachable. Worse, on the morning a term started the subquery stopped
           -- matching, returned NULL, and the seat fell BACKWARDS from "seated" to "certified"
           -- on the very day it was sworn in. Anchoring on the election date makes both states
           -- reachable and lets the date comparison in seatState do its job.
           (SELECT min(t.term_start) FROM essentials.office_terms t
             WHERE t.office_id = o.id AND t.politician_id = ANY(w.politician_ids)
               AND t.term_start >= e.election_date)    AS winner_term_start,
           -- A multi-seat race is seated only when EVERY winner has a term.
           (SELECT count(DISTINCT t.politician_id) FROM essentials.office_terms t
             WHERE t.office_id = o.id AND t.politician_id = ANY(w.politician_ids)
               AND t.term_start >= e.election_date)    AS winners_seated,
           (SELECT count(*) FROM live l WHERE l.race_id = r.id)  AS candidate_rows,
           (SELECT count(*) FROM live l WHERE l.race_id = r.id
              AND (l.result IS NULL OR l.result NOT IN ('lost','not_nominated','withdrew')))
                                                        AS live_candidates,
           -- Gap flags are computed across EVERY winner of the race, in the winner CTE, so a
           -- multi-seat council reports a gap when any of its winners has one.
           w.any_no_headshot AS winner_no_headshot,
           w.any_no_stances  AS winner_no_stances
      FROM essentials.elections e
      JOIN essentials.races r      ON r.election_id = e.id
      LEFT JOIN essentials.offices o   ON o.id = r.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians hp ON hp.id = och.politician_id
      LEFT JOIN winner w  ON w.race_id = r.id
     WHERE e.election_date = $1::date
     ORDER BY r.id
    `,
    [electionDate],
  );

  const wanted = opts.levels ?? null;
  const seats = rows
    .map((row) => {
      const winnerTermStart = row.winner_term_start
        ? new Date(row.winner_term_start).toISOString().slice(0, 10)
        : null;
      return {
        raceId: row.race_id,
        officeId: row.office_id,
        level: row.level ?? 'unknown',
        districtType: row.district_type,
        state: row.state,
        title: row.title,
        positionName: row.position_name,
        currentHolder: row.current_holder_id
          ? { id: row.current_holder_id, name: row.current_holder_name }
          : null,
        currentHolderTermEnd: row.current_holder_term_end
          ? new Date(row.current_holder_term_end).toISOString().slice(0, 10)
          : null,
        winnerCount: Number(row.winner_count ?? 0),
        winner: row.winner_count ? { name: row.winner_name } : null,
        resultCertainty: row.result_certainty ?? null,
        seatState: seatState({
          result: row.winner_count ? 'won' : null,
          resultCertainty: row.result_certainty,
          // 🔴 A multi-seat race is seated only when EVERY winner has a term. Passing a term
          // start while some winners are unseated would report a half-filled council as done.
          winnerTermStart:
            Number(row.winners_seated ?? 0) === Number(row.winner_count ?? 0) ? winnerTermStart : null,
          today,
        }),
        flags: {
          noCandidateRows: Number(row.candidate_rows) === 0,
          noOffice: row.office_id === null,
          noHeadshot: Boolean(row.winner_count) && row.winner_no_headshot === true,
          noStances: Boolean(row.winner_count) && row.winner_no_stances === true,
          // Some winners seated, some not — a partly-filled multi-seat body.
          partlySeated:
            Boolean(row.winner_count) &&
            Number(row.winners_seated ?? 0) > 0 &&
            Number(row.winners_seated) < Number(row.winner_count),
          // A predecessor whose term already ends is an overwrite hazard when seating.
          holderTermEnds: row.current_holder_term_end !== null,
        },
        liveCandidates: Number(row.live_candidates),
      };
    })
    .filter((s) => (wanted ? wanted.includes(s.level) : true));

  const totals = { byLevel: {}, byState: {}, flags: { noCandidateRows: 0, noOffice: 0, noHeadshot: 0, noStances: 0, holderTermEnds: 0, partlySeated: 0 } };
  for (const s of seats) {
    const lv = (totals.byLevel[s.level] ??= { total: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 });
    lv.total += 1;
    lv[s.seatState] += 1;
    const st = (totals.byState[s.state ?? '??'] ??= { total: 0, done: 0 });
    st.total += 1;
    if (s.seatState >= 4) st.done += 1;
    for (const [k, v] of Object.entries(s.flags)) if (v) totals.flags[k] = (totals.flags[k] ?? 0) + 1;
  }

  return { generatedAt: new Date().toISOString(), electionDate, today, seats, totals };
}

// 🔴 COMPARE RESOLVED URLS, NOT A FILENAME SUFFIX. The sibling script had this same bug:
// any importer whose own filename ends with this one's would have run the CLI, opened a pool
// against DATABASE_URL and written JSON to stdout. A suffix is not an identity.
const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  const argv = process.argv.slice(2);
  const arg = (name, dflt) => {
    const i = argv.indexOf(name);
    return i === -1 ? dflt : argv[i + 1];
  };
  const electionDate = arg('--election-date', '2026-11-03');
  const levels = arg('--levels', null);
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    const status = await buildStatus(pool, {
      electionDate,
      levels: levels ? levels.split(',') : null,
    });
    process.stdout.write(JSON.stringify(status, null, 2));
  } finally {
    await pool.end();
  }
}
