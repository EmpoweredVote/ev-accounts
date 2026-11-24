/**
 * Derive one seating wave: the numbers a migration's P1 pre-check pins itself to, and the list
 * of what is blocking the body if anything is.
 *
 * ── WHY A SCRIPT AND NOT 73 HAND COUNTS ─────────────────────────────────────────────────────
 *
 * 1,286 state offices hold a 2026 winner and no scheduled term, across 73 (state, district_type)
 * bodies. Every one of them ships as a CC_0453-shaped migration, and that file refuses to run
 * unless the selection it derives still matches a digest and three counts recorded in its header.
 * Those four values have to come from somewhere, and a number typed by hand agrees with itself
 * however wrong it is — which is the exact failure CC_0453's own header was written to avoid.
 *
 * ── THE DIGEST IS A CONTRACT WITH POSTGRES, NOT A HASH ──────────────────────────────────────
 *
 * `selectionDigest` must produce, in JS, the string this expression produces in SQL:
 *
 *   md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':'
 *                  || is_reelection::text,
 *                  '|' ORDER BY office_id::text, politician_id::text))
 *
 * exported below as SELECTION_DIGEST_SQL so the migration, the control and this module cannot
 * drift apart by retyping. Three details are load-bearing, and all three differ from CC_0453:
 *
 *   🔴 THE SORT KEY IS (office, politician), NOT office ALONE. CC_0453 sorted on the office
 *      because its P3 guaranteed one winner per office. 71 state offices carry two or three —
 *      a multi-seat race attaches every winner to one office row — so the office ties, and
 *      string_agg's order among tied keys is UNSPECIFIED. The same selection could digest two
 *      ways on two runs, and P1 would report that the data had moved when nothing had.
 *
 *   🔴 A MISSING WINNER RENDERS AS '-'. 211 winner rows have no politicians record. In Postgres
 *      `a || NULL || b` is NULL and string_agg SKIPS a NULL element entirely, so a bare render
 *      would compute a string Postgres never produces — and only on the rows where it matters.
 *      COALESCE is CC_0453's own idiom; it uses it for holders_md5 two tables up.
 *
 *   🔴 A BOOLEAN IS 'true'/'false'. Postgres never renders one as 1/0, and neither does this.
 *
 * ⚠ The JS and the SQL agreeing is a CONTROL run against production, not a test. A test cannot
 * prove two engines agree; it can only pin what this side does. See scripts/README or the
 * plan's Task 1 step 8.
 *
 * ── WHAT THIS REFUSES TO DO ─────────────────────────────────────────────────────────────────
 *
 * 🔴 IT REPORTS AND NEVER REFUSES. A blocked body returns its counts alongside its blockers. A
 * report that stopped at the first problem would hide the other six, and a body would be fixed
 * one round trip at a time. The migration is what refuses.
 */
import { createHash } from 'node:crypto';

/**
 * One winner row, as WAVE_SELECTION_SQL returns it.
 *
 * @typedef {object} WinnerRow
 * @property {string} office_id
 * @property {string|null} politician_id   null when the winner has no politicians record
 * @property {boolean} is_reelection
 * @property {number} winner_count         winners on THIS office's race, not seats in the body
 * @property {string|null} swearing_in_date 'YYYY-MM-DD', already a string — see the note below
 * @property {string|null} basis           'statute' | 'published' | 'estimated'
 * @property {string|null} next_term_start 'YYYY-MM-DD' when the office is already scheduled
 * @property {boolean} is_vacant
 * @property {string|null} certainty       'called' | 'certified'
 * @property {string|null} label           the district's label, for a readable blocker
 */

/**
 * @typedef {object} Blocker
 * @property {'multi_winner'|'winner_no_record'|'no_date'|'date_estimated'|'date_disagrees'|'already_scheduled'|'flagged_vacant'} kind
 * @property {string} office_id
 * @property {string} detail
 */

/**
 * The digest expression, as SQL. A migration's P1 pastes this over its own selection table and
 * compares the result with the value this module computed when the file was written.
 */
export const SELECTION_DIGEST_SQL =
  "md5(string_agg(office_id::text || ':' || COALESCE(politician_id::text, '-') || ':' " +
  "|| is_reelection::text, '|' ORDER BY office_id::text, politician_id::text))";

/**
 * One row per WINNER, not per office, so a multi-seat race is visible rather than collapsed.
 *
 * $1 = lower-case state, or NULL for every state (a nationwide district_type)
 * $2 = text[] of district types
 * $3 = election date
 *
 * 🔴 EVERY DATE IS `to_char`ed IN SQL. node-postgres parses OID 1082 into a JS Date at LOCAL
 *    midnight, so a date read as an object and sliced yields the day before for anyone west of
 *    UTC. The read paths were fixed this way in CC_0458's PR; this is the same trap.
 *
 * 🔴 `is_reelection` REQUIRES BOTH IDS. A winner with no record gives SQL NULL, and
 *    `NULL IS NOT DISTINCT FROM NULL` is TRUE — so on a vacant seat an unidentified winner would
 *    read as a re-election of nobody, and p_allow_reelection would be switched off for a seat
 *    that needs the guard most.
 */
export const WAVE_SELECTION_SQL = `
SELECT o.id::text                                        AS office_id,
       (win.value ->> 'id')                              AS politician_id,
       (win.value ->> 'name')                            AS winner_name,
       ((win.value ->> 'id') IS NOT NULL
         AND och.politician_id::text = (win.value ->> 'id'))
                                                         AS is_reelection,
       w.winner_count                                    AS winner_count,
       to_char(si.swearing_in_date, 'YYYY-MM-DD')        AS swearing_in_date,
       si.basis                                          AS basis,
       to_char(nx.term_start, 'YYYY-MM-DD')              AS next_term_start,
       o.is_vacant                                       AS is_vacant,
       w.certainty                                       AS certainty,
       d.label                                           AS label,
       lower(d.state)                                    AS state,
       d.district_type                                   AS district_type
  FROM essentials.office_pending_winner w
  JOIN essentials.offices   o ON o.id = w.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.office_swearing_in     si ON si.office_id = o.id
                                                AND si.election_date = $3::date
  LEFT JOIN essentials.office_next_term       nx ON nx.office_id = o.id
 WHERE ($1::text IS NULL OR lower(d.state) = $1::text)
   AND d.district_type = ANY($2::text[])
   AND w.election_date = $3::date
 ORDER BY o.id::text, (win.value ->> 'id')
`;

/** The three fields the digest is computed over, rendered as Postgres renders them. */
function digestKey(r) {
  return `${r.office_id}:${r.politician_id ?? '-'}:${r.is_reelection ? 'true' : 'false'}`;
}

/**
 * Sort exactly as `ORDER BY office_id::text, politician_id::text` does: ascending, and a NULL
 * politician last, which is Postgres' default for ASC.
 */
function digestOrder(a, b) {
  if (a.office_id !== b.office_id) return a.office_id < b.office_id ? -1 : 1;
  if (a.politician_id === b.politician_id) return 0;
  if (a.politician_id === null || a.politician_id === undefined) return 1;
  if (b.politician_id === null || b.politician_id === undefined) return -1;
  return a.politician_id < b.politician_id ? -1 : 1;
}

/**
 * @param {Pick<WinnerRow,'office_id'|'politician_id'|'is_reelection'>[]} rows
 * @returns {string} the md5 a migration's P1 pins itself to
 */
export function selectionDigest(rows) {
  const ordered = [...rows].sort(digestOrder);
  return createHash('md5').update(ordered.map(digestKey).join('|')).digest('hex');
}

/**
 * @param {WinnerRow[]} rows
 * @returns {{rows: number, reelections: number, newHolders: number, termStart: string|null,
 *            called: number, certified: number, digest: string, blockers: Blocker[]}}
 */
export function classifyWave(rows) {
  const blockers = [];
  const push = (kind, r, detail) => blockers.push({ kind, office_id: r.office_id, detail });

  for (const r of rows) {
    const where = r.label ? `${r.label}` : r.office_id;
    if (r.winner_count > 1) {
      push('multi_winner', r, `${where}: ${r.winner_count} winners on one office row — the race is multi-seat, so the winner-to-seat mapping is not in the data. Ruling A applies.`);
    }
    if (r.politician_id === null || r.politician_id === undefined) {
      push('winner_no_record', r, `${where}: "${r.winner_name ?? 'unnamed winner'}" has no politicians row. Nobody can be seated who does not exist.`);
    }
    if (!r.swearing_in_date) {
      push('no_date', r, `${where}: no office_swearing_in row for this election. Source and cite the body's start date first.`);
    } else if (r.basis === 'estimated') {
      push('date_estimated', r, `${where}: the date's basis is "estimated". An estimate may not seat anybody — a term start is a legal fact.`);
    }
    if (r.next_term_start) {
      push('already_scheduled', r, `${where}: already carries a term starting ${r.next_term_start}. Seating again would stack a second one.`);
    }
    if (r.is_vacant) {
      push('flagged_vacant', r, `${where}: flagged is_vacant. A FUTURE-dated seating must leave the flag alone; only a term that has already begun clears it.`);
    }
  }

  // 🔴 A TERM START IS NAMED ONLY WHEN **EVERY** OFFICE IN THE BODY CARRIES A DATE, NOT WHEN THE
  // DATES THAT EXIST HAPPEN TO AGREE. Taking the distinct non-null dates alone means a body where
  // one office of sixty has been dated reports that date as the wave's, raises no disagreement,
  // prints a ready-to-paste pin block, and sorts ahead of every undated body in the register as
  // though it had a deadline. CC_0463 dated 3 of Indiana's 100 House offices, so the part-dated
  // body is a shape this work has already created once.
  const dates = [...new Set(rows.map((r) => r.swearing_in_date).filter(Boolean))].sort();
  const everyRowDated = rows.length > 0 && rows.every((r) => Boolean(r.swearing_in_date));
  if (dates.length > 1) {
    for (const r of rows) {
      if (r.swearing_in_date && r.swearing_in_date !== dates[0]) {
        push('date_disagrees', r, `${r.label ?? r.office_id}: starts ${r.swearing_in_date}, while others in this wave start ${dates[0]}. Two dates is two bodies; split the wave.`);
      }
    }
  }

  const reelections = rows.filter((r) => r.is_reelection).length;
  return {
    rows: rows.length,
    // 🔴 WINNERS AND OFFICES ARE DIFFERENT NUMBERS AND THE PIN NEEDS BOTH. They are equal only
    // while every office has one winner; 71 state offices carry two or three, because a
    // multi-seat race attaches all its winners to one office row. A pin stating one count is
    // read as winners by P1 and as offices by the post-verify, and is wrong in one of them.
    offices: new Set(rows.map((r) => r.office_id)).size,
    reelections,
    newHolders: rows.length - reelections,
    termStart: dates.length === 1 && everyRowDated ? dates[0] : null,
    called: rows.filter((r) => r.certainty === 'called').length,
    certified: rows.filter((r) => r.certainty === 'certified').length,
    digest: selectionDigest(rows),
    blockers,
  };
}

/**
 * The pin block a migration opens with, in CC_0453's shape.
 *
 * @param {string} slot e.g. 'CC_0461'
 * @param {ReturnType<typeof classifyWave>} s
 */
export function pinBlockSql(slot, s) {
  const prefix = slot.toLowerCase().replace(/[^a-z0-9]/g, '');
  if (!s.termStart) {
    throw new Error(
      `${slot}: this wave has no single term start, so it cannot be pinned. Every office must ` +
        `carry a date and they must agree — resolve the no_date or date_disagrees blockers ` +
        `first. A migration pinned to one of two dates would seat half its rows at the wrong ` +
        `one, and a body part of which is dated is not a body with a deadline.`,
    );
  }
  return [
    `CREATE TEMP TABLE ${prefix}_pin ON COMMIT DROP AS`,
    `SELECT ${s.rows} AS expect_winners,`,
    `       ${s.offices} AS expect_offices,`,
    `       ${s.reelections} AS expect_reelections,`,
    `       ${s.newHolders} AS expect_new,`,
    `       '${s.digest}' AS expect_digest,`,
    `       DATE '${s.termStart}' AS expect_term_start;`,
    `-- called ${s.called} · certified ${s.certified} at the time this was captured (Ruling B).`,
    s.offices === s.rows
      ? `-- winners = offices here, so the two pins are equal. They are NOT in general.`
      : `-- ⚠ ${s.rows} winners across ${s.offices} offices. P1 counts WINNERS; the post-verify `
        + `counts OFFICES. Read REGISTER.md Ruling A before writing this wave.`,
  ].join('\n');
}
