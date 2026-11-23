/**
 * transitionDisplay — the ONE place a database row becomes the transition fields the API sends.
 *
 * 🔴 WHY THIS MODULE EXISTS: THIS FIELD FAMILY HAS ALREADY DRIFTED. CC_0341 added
 * incoming_holder_id / incoming_holder_name / incoming_on to getPoliticiansFlatList only, so for a
 * while /politicians reported incoming_on = '2027-01-05' for a Los Angeles judge while an LA
 * ADDRESS returned null for the same seat — two endpoints, same office, contradictory transition
 * state, and the null was indistinguishable from "nobody is coming". The fields are mapped at four
 * call sites and deliberately blanked at three more; seven copies of the same translation is how
 * that happens again. Every one of them now calls through here.
 *
 * The module is pure: it takes a row and returns fields. It opens no connection and knows no SQL,
 * so it is unit-tested without a database.
 */

/** One recorded winner. `id` is null for the 237 winner rows with no `politicians` record — they
 *  are named from `race_candidates` and have no profile page to link to. */
export interface PendingWinnerEntry {
  id: string | null;
  name: string;
}

/**
 * An election result for a seat that has NO dated term yet.
 *
 * 🔴 THIS IS NOT A TERM, AND THE READ PATH MUST NEVER LABEL IT AS ONE. A certified result records
 * who won an election; taking office is a separate, later event, and people decline, resign and die
 * in between. `certainty` is what keeps the claim honest: measured 2026-11-21, 1,943 of the 1,945
 * November winners are 'called' and 2 are 'certified', so almost every card ships on a count that
 * can still be reversed in the canvass and must say so.
 */
export interface PendingWinner {
  /** 'YYYY-MM-DD'. The election this result came from — NOT necessarily November. */
  election_date: string;
  certainty: 'called' | 'certified';
  /** Seats on the race that produced it. A multi-seat race attaches every winner to one office. */
  seats: number;
  winners: PendingWinnerEntry[];
}

/**
 * The three counts the multi-seat group display needs, for one (district, chamber).
 *
 * 🔴 The group-to-group arrow is permitted ONLY when offices = winners = seated. A staggered body
 * — five members with three seats up — would otherwise draw an arrow from five people to three and
 * tell a voter the body is shrinking.
 */
export interface SeatGroup {
  group_id: string;
  offices: number;
  winners: number;
  seated: number;
}

export interface TransitionFields {
  incoming_holder_id: string | null;
  incoming_holder_name: string | null;
  /** 'YYYY-MM-DD'. Non-null only when a DATED future term exists. */
  incoming_on: string | null;
  pending_winner: PendingWinner | null;
  seat_group: SeatGroup | null;
}

/**
 * For a read path that genuinely cannot source these fields.
 *
 * ⚠ Using this is a claim that the PATH does not know, never that the SEAT has no successor. The
 * two are indistinguishable to a caller, so a path that blanks them must not render a transition.
 */
export const BLANK_TRANSITION_FIELDS: TransitionFields = Object.freeze({
  incoming_holder_id: null,
  incoming_holder_name: null,
  incoming_on: null,
  pending_winner: null,
  seat_group: null,
});

/**
 * 🔴 A `date` COLUMN REACHES US AS A JS Date AT LOCAL MIDNIGHT, AND STRINGIFYING IT LOSES THE YEAR.
 * node-postgres parses OID 1082 into a Date, and `String(new Date('2021-01-14')).slice(0, 10)` is
 * "Thu Jan 14" — a weekday and no year. That is not hypothetical: it is what `incoming_on` served
 * live until the queries started formatting with `to_char(col, 'YYYY-MM-DD')`.
 *
 * The queries still do that, and they must: formatting in SQL means the value is a string before
 * it can ever become a Date. This function is the second line of defence, so that a query written
 * later without `to_char` degrades to a correct date instead of to a weekday. The Date branch reads
 * UTC parts, never local ones, or a caller west of UTC gets the day before.
 */
function toIsoDay(value: unknown): string | null {
  if (value === null || value === undefined || value === '') return null;
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null;
    return value.toISOString().slice(0, 10);
  }
  return String(value).slice(0, 10);
}

/**
 * `jsonb` normally arrives already parsed. A driver or pool configured otherwise hands back the
 * raw string, and an unguarded read would blank every card silently rather than erroring — so the
 * string case is handled rather than assumed away.
 */
function toWinners(value: unknown): PendingWinnerEntry[] {
  let raw: unknown = value;
  if (typeof raw === 'string') {
    try {
      raw = JSON.parse(raw);
    } catch {
      return [];
    }
  }
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((w): w is Record<string, unknown> => !!w && typeof w === 'object')
    .map((w) => ({
      id: (w.id as string | null) ?? null,
      name: String(w.name ?? ''),
    }));
}

function toCount(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

/**
 * Map one database row to the transition fields. Every read path that selects the transition
 * columns calls this; a path that does not select them gets BLANK_TRANSITION_FIELDS instead.
 *
 * Column names, as the shared queries alias them:
 *   incoming_holder_id · incoming_holder_name · incoming_on      (essentials.office_next_term)
 *   pending_election_date · pending_certainty · pending_seats
 *   pending_winners                                              (essentials.office_pending_winner)
 *   group_id · group_offices · group_winners · group_seated      (essentials.district_seat_group)
 */
export function mapTransitionFields(row: Record<string, unknown>): TransitionFields {
  const electionDate = toIsoDay(row.pending_election_date);
  const winners = toWinners(row.pending_winners);

  // A result with no date or no names is not a result we can show. Both are required, so the
  // absence of either yields null rather than a half-rendered card.
  const pending_winner: PendingWinner | null =
    electionDate && winners.length > 0
      ? {
          election_date: electionDate,
          certainty: row.pending_certainty === 'certified' ? 'certified' : 'called',
          seats: toCount(row.pending_seats),
          winners,
        }
      : null;

  const groupId = row.group_id;
  const seat_group: SeatGroup | null =
    groupId === null || groupId === undefined || groupId === ''
      ? null
      : {
          group_id: String(groupId),
          offices: toCount(row.group_offices),
          winners: toCount(row.group_winners),
          seated: toCount(row.group_seated),
        };

  return {
    incoming_holder_id: (row.incoming_holder_id as string | null) ?? null,
    incoming_holder_name: (row.incoming_holder_name as string | null) ?? null,
    incoming_on: toIsoDay(row.incoming_on),
    pending_winner,
    seat_group,
  };
}
