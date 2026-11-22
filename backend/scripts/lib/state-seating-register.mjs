/**
 * Group the whole state-seating pass into its research units and order them into a queue.
 *
 * ── WHY A (state, district_type) PAIR IS THE UNIT ───────────────────────────────────────────
 *
 * A start date is a fact about a BODY, not about a seat. Wisconsin's 121 offices take one
 * citation; Maine's 149 House seats take one more. 1,286 offices collapse to 73 pairs across 42
 * states, which is what makes the remaining work finite: an average of 18 seats per citation.
 *
 * ── 🔴 THE SORT, WHICH IS EASY TO GET BACKWARDS ─────────────────────────────────────────────
 *
 * Waves run by start date, soonest first, so no wave is ever late for its own state. But 70 of
 * the 73 bodies have NO cited date yet, and sorting on a missing value puts it wherever the
 * language happens to put a null — in JS, `null < '2027-01-01'` is true, so the entire undated
 * backlog would jump ahead of the one body with a real deadline. An undated body has no deadline
 * to be late for. It sinks below every dated one, and among themselves the undated are ordered
 * largest first, because a 149-seat body is more citations' worth of value than a 1-seat one.
 *
 * ── ⚠ A PART-SEATED BODY IS STILL WORK ──────────────────────────────────────────────────────
 *
 * `done` means every office in the pair is scheduled, not that some are. Indiana House is the
 * worked example: 24 of its seats were seated by CA_0374 and CA_0396 and three were not, because
 * those three were re-elections that `seat_officeholder` refuses by default. A register that
 * called the body done would have buried them.
 */
import { classifyWave } from './seating-wave.mjs';

/**
 * @param {import('./seating-wave.mjs').WinnerRow[]} rows every winner row in the pass, each
 *        carrying `state` and `district_type`
 * @returns {{state: string, district_type: string, offices: number, winners: number,
 *            reelections: number, winners_without_record: number, multi_winner_offices: number,
 *            flagged_vacant_offices: number, start_date: string|null, scheduled: number,
 *            remaining: number, status: 'done'|'queued'}[]} ordered queue
 */
export function buildRegister(rows) {
  const groups = new Map();
  for (const r of rows) {
    const key = `${r.state}/${r.district_type}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(r);
  }

  const out = [];
  for (const [key, group] of groups) {
    const [state, district_type] = key.split('/');
    const s = classifyWave(group);
    const offices = new Set(group.map((r) => r.office_id));
    const scheduled = new Set(group.filter((r) => r.next_term_start).map((r) => r.office_id));
    const kinds = (k) => new Set(s.blockers.filter((b) => b.kind === k).map((b) => b.office_id)).size;

    out.push({
      state,
      district_type,
      offices: offices.size,
      winners: group.length,
      reelections: s.reelections,
      winners_without_record: s.blockers.filter((b) => b.kind === 'winner_no_record').length,
      multi_winner_offices: kinds('multi_winner'),
      flagged_vacant_offices: kinds('flagged_vacant'),
      // `termStart` is null unless every office in the pair agrees on one date — a body holding
      // two answers is two bodies, and the wave that seats it would pin the wrong one.
      start_date: s.termStart,
      scheduled: scheduled.size,
      remaining: offices.size - scheduled.size,
      status: scheduled.size === offices.size ? 'done' : 'queued',
    });
  }

  return out.sort(compareQueue);
}

/** Dated before undated; then by date; then by size, largest first; then by name, for stability. */
function compareQueue(a, b) {
  const aDated = a.start_date !== null;
  const bDated = b.start_date !== null;
  if (aDated !== bDated) return aDated ? -1 : 1;
  if (aDated && a.start_date !== b.start_date) return a.start_date < b.start_date ? -1 : 1;
  if (a.offices !== b.offices) return b.offices - a.offices;
  if (a.state !== b.state) return a.state < b.state ? -1 : 1;
  return a.district_type < b.district_type ? -1 : 1;
}

/** The register as a markdown table, for `backend/data/state-seating-2026/REGISTER.md`. */
export function registerTable(reg) {
  const head =
    '| # | state | body | offices | winners | re-elected | no record | multi-seat | start date | status |\n' +
    '|---|---|---|---|---|---|---|---|---|---|';
  const lines = reg.map((r, i) =>
    `| ${i + 1} | ${r.state.toUpperCase()} | ${r.district_type} | ${r.offices} | ${r.winners} | ` +
    `${r.reelections} | ${r.winners_without_record || '—'} | ${r.multi_winner_offices || '—'} | ` +
    `${r.start_date ?? '—'} | ${r.status === 'done' ? '✅ done' : `${r.remaining} left`} |`);
  return [head, ...lines].join('\n');
}
