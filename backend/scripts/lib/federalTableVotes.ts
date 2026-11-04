/**
 * federalTableVotes.ts — pair a census-reviewed federal roll call with one roll call in essentials.legislative_votes.
 *
 * The source store keeps a federal roll call under its instrument (`US-HJRES-44-2023`, date, totals). The table
 * keeps one row per member per roll call. This turns table rows into one record per roll call, then finds the
 * one that is the store's vote: same Congress, same bill, same date, totals within one. Rows are grouped by
 * roll call whoever voted, so a member's earlier House vote is found even after they moved to the Senate.
 * When no roll call fits, or more than one does, the answer says so; it never picks. Pure: no database, no network.
 */
import type { Vote } from './sourceStore.js';

export type TableVoteRow = {
  politician_id: string;
  external_vote_id: string;
  bill_number: string;
  congress: string;
  vote_date: string; // YYYY-MM-DD
  vote_question: string;
  position: 'yea' | 'nay' | 'present' | 'not_voting' | string;
  yea_count: number;
  nay_count: number;
};

export type TableRollCall = {
  external_vote_id: string;
  bill_number: string;
  congress: string;
  date: string;
  question: string;
  rc: number | null;
  yes: number;
  no: number;
  positions: Map<string, string>; // politician_id -> table position
};

export type MatchResult = { kind: 'one'; roll: TableRollCall } | { kind: 'none' } | { kind: 'many'; candidates: string[] };

/** `US-HJRES-44-2023` -> Congress 118, bill `HJRES 44`. Null for any id that is not a federal instrument. */
export function instrumentBill(instrumentId: string): { congress: string; bill_number: string } | null {
  const m = /^US-([A-Z]+)-(\d+)-(\d{4})$/.exec(instrumentId);
  if (!m) return null;
  const year = Number(m[3]);
  return { congress: String(Math.floor((year - 1789) / 2) + 1), bill_number: `${m[1]} ${m[2]}` };
}

/** One record per external_vote_id; `rc` is the trailing `RC# <n>` of the question, else null. */
export function groupRollCalls(rows: TableVoteRow[]): TableRollCall[] {
  const byId = new Map<string, TableRollCall>();
  for (const r of rows) {
    let roll = byId.get(r.external_vote_id);
    if (!roll) {
      const rc = /RC#\s*(\d+)\s*$/.exec(r.vote_question);
      roll = {
        external_vote_id: r.external_vote_id,
        bill_number: r.bill_number,
        congress: r.congress,
        date: r.vote_date,
        question: r.vote_question,
        rc: rc ? Number(rc[1]) : null,
        yes: r.yea_count,
        no: r.nay_count,
        positions: new Map(),
      };
      byId.set(r.external_vote_id, roll);
    }
    roll.positions.set(r.politician_id, r.position);
  }
  return [...byId.values()];
}

/** The one table roll call that is this store vote, or why there is not one. Totals may differ by one. */
export function matchRollCall(
  vote: Pick<Vote, 'date' | 'yes' | 'no'>,
  bill: { congress: string; bill_number: string },
  rolls: TableRollCall[],
): MatchResult {
  const fits = rolls.filter(
    (r) =>
      r.congress === bill.congress &&
      r.bill_number === bill.bill_number &&
      r.date === vote.date &&
      Math.abs(vote.yes - r.yes) <= 1 &&
      Math.abs(vote.no - r.no) <= 1,
  );
  if (fits.length === 1) return { kind: 'one', roll: fits[0] };
  if (fits.length === 0) return { kind: 'none' };
  return { kind: 'many', candidates: fits.map((r) => r.external_vote_id) };
}

/** A table position as an act. Not voting is no act; present is an abstention. */
export function tableAct(position: string): 'yea' | 'nay' | 'abstain' | null {
  if (position === 'yea') return 'yea';
  if (position === 'nay') return 'nay';
  if (position === 'present') return 'abstain';
  return null;
}
