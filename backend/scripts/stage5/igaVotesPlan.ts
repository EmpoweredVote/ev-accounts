/**
 * igaVotesPlan — pure decisions for iga-votes.ts (no I/O), so they can be tested.
 *
 * Found 2026-11-04 (gun-policy, Matt Pierce): a floor vote on a conference committee report
 * ("House - Rules Suspended. Conference Committee Report 1") was read as a committee vote and skipped,
 * and findings that print a date and tally but no roll-call number could not be mapped at all.
 */

/** One entry of a bill's `all_rollcalls` in the MyIGA API (only the fields used here). */
export interface ApiRollCall {
  rollcall_number?: string | number;
  chamber?: { name?: string };
  results?: { yea?: number; nay?: number };
  type?: string;
}

const CONFERENCE_REPORT = /conference committee report/i;

/** A committee vote has no floor roll call. A floor vote ON a conference committee report is not one. */
export function isCommitteeVote(motion: string): boolean {
  return /committee/i.test(motion) && !CONFERENCE_REPORT.test(motion);
}

/** Does the motion name a conference committee report? */
export const isConferenceReport = (motion: string): boolean => CONFERENCE_REPORT.test(motion);

/** "tally 74–26" (en dash or hyphen) in a finding's note → { yea, nay }. */
export function tallyOf(text: string): { yea: number; nay: number } | null {
  const m = /tally (\d+)\s*[–-]\s*(\d+)/.exec(text);
  return m ? { yea: Number(m[1]), nay: Number(m[2]) } : null;
}

/**
 * The roll-call number of the bill's one roll call in that chamber with that tally (and, when the finding names a
 * conference committee report, of that type). An exact tally wins; only when none matches exactly is a roll call
 * within one vote on each count accepted, because a finding's tally often comes from LegiScan, whose totals can
 * differ from the official count by one (STAGE5 step 7). The person's own vote is still cross-checked against the
 * PDF line afterwards. Null when none or several fit: never guess. The API gives some counts as text ("0").
 */
export function pickRollCall(
  list: ApiRollCall[], chamber: 'H' | 'S', tally: { yea: number; nay: number }, conferenceReport: boolean,
): string | null {
  const name = chamber === 'H' ? 'House' : 'Senate';
  const pool = list.filter((r) => r.chamber?.name === name && r.rollcall_number != null
    && (!conferenceReport || CONFERENCE_REPORT.test(String(r.type ?? ''))));
  const within = (d: number) => pool.filter((r) => Math.abs(Number(r.results?.yea) - tally.yea) <= d
    && Math.abs(Number(r.results?.nay) - tally.nay) <= d);
  const exact = within(0);
  const fits = exact.length ? exact : within(1);
  return fits.length === 1 ? String(fits[0].rollcall_number) : null;
}
