/**
 * senateRollCall — point a senate.gov roll-call citation at the same vote on LegiScan.
 *
 * senate.gov's firewall answers 403 to EmpoweredVoteBot on the roll-call pages and XML files
 * (two machines, 2026-10-29), and api.congress.gov has no Senate vote endpoint. LegiScan holds every
 * US Senate roll call with full voter names, and its `desc` ends with senate.gov's own number
 * ("On Passage of the Bill S. 5 RC# 7"). The LegiScan lane (legiscanEvidence.ts) already verifies a
 * US roll call line and prints no party, so a senate.gov citation only needs its LegiScan address.
 *
 * A senate.gov URL names congress, session and vote number but not the bill. Voteview's public
 * roll-call file (voteview.com, UCLA) gives the bill and date for that vote; LegiScan's bill record
 * then lists the roll call with that date and "RC# <n>". Season 3 voting-rights (2026-11-02): all 7
 * cited senate.gov votes mapped, and all 13 senator lines verified.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */
type Json = any;

export interface SenateVoteRef { congress: number; session: number; vote: number }

// .../roll_call_votes/vote1192/vote_119_2_00057.htm (or .xml), and the older roll_call_lists form.
const SENATE_VOTE_URL = /^https?:\/\/(?:www\.)?senate\.gov\/legislative\/LIS\/roll_call_(?:votes|lists)\/vote\d+\/vote_(\d{2,3})_([12])_(\d{5})\.(?:htm|xml)$/i;

export function parseSenateVoteUrl(url: string): SenateVoteRef | null {
  const m = SENATE_VOTE_URL.exec(url.trim().replace(/[?#].*$/, ''));
  return m ? { congress: Number(m[1]), session: Number(m[2]), vote: Number(m[3]) } : null;
}

/** The year a Congress's first session began (the 119th: 2025). LegiScan names US sessions by that year. */
export function congressStartYear(congress: number): number {
  return 1789 + 2 * (congress - 1);
}

// Voteview bill prefixes → LegiScan's. The longest prefix is tried first (SCONRES before S).
const BILL_PREFIX: Array<[string, string]> = [
  ['SCONRES', 'SCR'], ['HCONRES', 'HCR'], ['SJRES', 'SJR'], ['HJRES', 'HJR'], ['SRES', 'SR'], ['HRES', 'HR'],
  ['S', 'SB'], ['HR', 'HB'],
];

/** "S2747" → "SB2747", "SCONRES33" → "SCR33", "HR22" → "HB22". Null for nominations, treaties and the like. */
export function legiscanBillNumber(voteviewBill: string): string | null {
  const m = /^([A-Z]+)(\d+)$/.exec(voteviewBill.trim().toUpperCase());
  if (!m) return null;
  const hit = BILL_PREFIX.find(([vv]) => vv === m[1]);
  return hit ? `${hit[1]}${m[2]}` : null;
}

/** One row of Voteview's S<congress>_rollcalls.csv, the fields this needs. */
export interface VoteviewRollCall { session: number; clerk_rollnumber: number; date: string; bill_number: string }

/** The Voteview row for a senate.gov vote, or null. */
export function voteviewRow(rows: VoteviewRollCall[], ref: SenateVoteRef): VoteviewRollCall | null {
  return rows.find((r) => r.session === ref.session && r.clerk_rollnumber === ref.vote) ?? null;
}

/**
 * The LegiScan roll call on a bill record that is this Senate vote: chamber S, the same date, and a
 * desc that ends with "RC# <n>". Exactly one must match; anything else is null.
 */
export function pickLegiscanRollCall(bill: Json, date: string, vote: number): Json | null {
  const rc = new RegExp(String.raw`\bRC# ${vote}$`);
  const hits = (bill?.votes ?? []).filter((v: Json) => v?.chamber === 'S' && v?.date === date && rc.test(String(v?.desc ?? '').trim()));
  return hits.length === 1 ? hits[0] : null;
}
