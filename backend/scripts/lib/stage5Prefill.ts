/**
 * stage5Prefill.ts — Stage 5 step 2: saved findings from roll calls already in the source store.
 *
 * For every vote the topic's census reviewed (`stage0/gates.tsv`), each member matched to a person on the
 * Stage 5 roster becomes one record finding, with no new search. The census gate for that vote goes in the
 * finding's note, so the coder sees it; the census itself decided nothing here. Members with no
 * politician id are returned as `unmatched`, for the identity check (official member lists, never surname
 * alone). A matched member who is not on the roster has left office and is skipped. Absent and recused
 * are not acts. No search entry is written: a vote on file saves the record search, not the own-words
 * search (design §5 step 3).
 *
 * Federal roll calls can come from essentials.legislative_votes instead. When the caller passes those roll
 * calls (`table`), a census roll call on a `US-` bill is paired with exactly one of them (same Congress, bill,
 * date, totals within one); its positions, keyed by politician id, become the findings, with no name match.
 * The hand list is then only checked against it: a different act is `disagree`, a roster member the table
 * does not hold keeps the hand finding and is `handOnly`. When no table roll call fits, or more than one
 * does, that vote takes the hand path and is listed in `unmatchedRollCalls`; it never picks. Pure: no
 * database, no network.
 */
import { findingId, type Finding, type Instrument, type PersonFindings, type Vote } from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';
import { instrumentBill, matchRollCall, tableAct, type TableRollCall } from './federalTableVotes.js';

export type GateRow = { instrument_id: string; vote_date: string; body: string; motion: string; gate: string };
export type UnmatchedVote = { instrument_id: string; date: string; body: string; motion: string; name: string; vote: string };
export type SkippedVote = { instrument_id: string; vote_date: string; body: string; motion: string; reason: string };
/** How the hand lists compare with the table, for every federal roll call the table was asked about. */
export type CrossCheck = {
  disagree: Array<{ instrument_id: string; date: string; motion: string; politician_id: string; hand: string; table: string | null }>;
  handOnly: Array<{ instrument_id: string; date: string; motion: string; politician_id: string; hand: string }>;
  tableOnly: number; // table findings for people the hand list did not name by politician id
  matched: number; // distinct table roll calls used
  unmatchedRollCalls: SkippedVote[];
};

const ACTS = new Set(['yea', 'nay', 'abstain']);

/** Read the census `gates.tsv` (SKILL.md "gates.tsv columns"); only the columns pre-fill needs. */
export function parseGatesTsv(text: string): GateRow[] {
  const lines = text.split('\n').filter((l) => l.trim());
  const head = lines[0].split('\t');
  const col = (name: string) => {
    const i = head.indexOf(name);
    if (i < 0) throw new Error(`gates.tsv: missing column ${name}`);
    return i;
  };
  const c = { id: col('instrument_id'), date: col('vote_date'), body: col('body'), motion: col('motion'), gate: col('gate') };
  return lines.slice(1).map((l) => {
    const f = l.split('\t');
    return { instrument_id: f[c.id], vote_date: f[c.date] ?? '', body: f[c.body] ?? '', motion: f[c.motion] ?? '', gate: f[c.gate] ?? '' };
  });
}

/** The store vote a gates row describes: same body, then the same motion, else the one vote that body took that day. */
function findVote(inst: Instrument, g: GateRow): Vote | undefined {
  const sameBody = inst.votes.filter((v) => v.body === g.body);
  const byMotion = sameBody.filter((v) => v.motion === g.motion);
  if (byMotion.length === 1) return byMotion[0];
  const byDate = sameBody.filter((v) => v.date === g.vote_date);
  return byDate.length === 1 ? byDate[0] : undefined;
}

export function prefillFindings(
  instruments: Instrument[], gates: GateRow[], roster: RosterRow[], topicKey: string, subjects: Record<string, string[]>,
  table?: TableRollCall[],
): { findings: PersonFindings[]; unmatched: UnmatchedVote[]; skipped: SkippedVote[]; crosscheck: CrossCheck } {
  const onRoster = new Set(roster.map((r) => r.politician_id));
  const byId = new Map(instruments.map((i) => [i.id, i]));
  const people = new Map<string, Map<string, Finding>>();
  const wantedIds = new Set(gates.map((g) => g.instrument_id));
  // One finding per id per person: two census rows can resolve to the same store vote.
  const add = (pid: string, base: Omit<Finding, 'id'>) => {
    const id = findingId(base);
    const list = people.get(pid) ?? new Map<string, Finding>();
    if (!list.has(id)) list.set(id, { id, ...base } as Finding);
    people.set(pid, list);
  };
  const unmatched: UnmatchedVote[] = [];
  const skipped: SkippedVote[] = [];
  const crosscheck: CrossCheck = { disagree: [], handOnly: [], tableOnly: 0, matched: 0, unmatchedRollCalls: [] };
  // Two census rows can resolve to the same store vote: count each roll call and each person once.
  const usedRolls = new Set<string>();
  const checked = new Set<string>();
  const tableOnly = new Set<string>();

  for (const g of gates) {
    const inst = byId.get(g.instrument_id);
    const skip = (reason: string) => skipped.push({ instrument_id: g.instrument_id, vote_date: g.vote_date, body: g.body, motion: g.motion, reason });
    if (!inst) { skip('instrument not in the store'); continue; }
    const tags = subjects[inst.id];
    if (!tags?.length) throw new Error(`${inst.id}: no subjects given (add it to the --subjects file, in plain words)`);
    if (!inst.urls.length) { skip('instrument has no URL'); continue; }
    const vote = findVote(inst, g);
    if (!vote) { skip('no single store vote matches this body, motion or date'); continue; }

    const addVote = (pid: string, act: string, from = '') => add(pid, {
      kind: 'record' as const, url: inst.urls[0], date: vote.date, date_precision: 'day' as const,
      instrument_id: inst.id, act: act as Finding['act'], motion: vote.motion, gate_by_topic: { [topicKey]: g.gate || 'none' },
      note: `${vote.body}, ${vote.motion}, ${vote.date}: ${act} (tally ${vote.yes}–${vote.no}); census gate: ${g.gate || 'none'}.${from}`,
      subjects: tags, topic_keys: [topicKey], provenance: inst.provenance,
    });

    const roll = table && inst.id.startsWith('US-') && vote.kind === 'roll-call' ? tableRoll(inst.id, vote, g, table, crosscheck) : null;
    if (roll) {
      usedRolls.add(roll.external_vote_id);
      const from = ` positions from essentials.legislative_votes (${roll.external_vote_id}).`;
      const handIds = new Set(vote.members.flatMap((m) => (m.politician_id ? [m.politician_id] : [])));
      for (const [pid, position] of roll.positions) {
        const act = tableAct(position);
        if (!onRoster.has(pid) || !act) continue;
        addVote(pid, act, from);
        if (!handIds.has(pid)) tableOnly.add(`${roll.external_vote_id}|${pid}`);
      }
      for (const m of vote.members) {
        // The table cannot say which hand name it holds, so a hand member with an act and no politician id
        // keeps today's path: listed for the identity check. Once placed, the re-run cross-checks it like any other.
        if (!m.politician_id) {
          if (ACTS.has(m.vote)) unmatched.push({ instrument_id: inst.id, date: vote.date, body: vote.body, motion: vote.motion, name: m.name, vote: m.vote });
          continue;
        }
        if (!onRoster.has(m.politician_id)) continue;
        const key = `${roll.external_vote_id}|${m.politician_id}`;
        const at = { instrument_id: inst.id, date: vote.date, motion: vote.motion, politician_id: m.politician_id, hand: m.vote };
        if (!roll.positions.has(m.politician_id)) {
          if (ACTS.has(m.vote)) addVote(m.politician_id, m.vote);
          if (!checked.has(key)) crosscheck.handOnly.push(at);
        } else {
          const t = tableAct(roll.positions.get(m.politician_id)!);
          if (t !== (ACTS.has(m.vote) ? m.vote : null) && !checked.has(key)) crosscheck.disagree.push({ ...at, table: t });
        }
        checked.add(key);
      }
      continue;
    }

    for (const m of vote.members) {
      if (!ACTS.has(m.vote)) continue;
      if (!m.politician_id) {
        unmatched.push({ instrument_id: inst.id, date: vote.date, body: vote.body, motion: vote.motion, name: m.name, vote: m.vote });
        continue;
      }
      if (!onRoster.has(m.politician_id)) continue;
      addVote(m.politician_id, m.vote);
    }
  }
  crosscheck.matched = usedRolls.size;
  crosscheck.tableOnly = tableOnly.size;

  // Sponsorships are records too (codebook E1). The store keeps no filing date, so the bill's year stands in.
  for (const inst of instruments) {
    if (!wantedIds.has(inst.id) || !inst.urls.length) continue;
    const year = inst.id.slice(-4);
    for (const sp of inst.sponsors ?? []) {
      if (!sp.politician_id) {
        unmatched.push({ instrument_id: inst.id, date: year, body: '', motion: 'sponsor', name: sp.name, vote: sp.role });
        continue;
      }
      if (!onRoster.has(sp.politician_id)) continue;
      add(sp.politician_id, {
        kind: 'record' as const, url: inst.urls[0], date: year, date_precision: 'year' as const, instrument_id: inst.id,
        act: sp.role === 'author' ? 'author' : 'sponsor', motion: `${sp.role} sponsor${sp.version ? `, ${sp.version}` : ''}`,
        note: `${sp.role} sponsor of ${inst.id}${sp.version ? ` (${sp.version})` : ''}: ${inst.title}.`,
        subjects: subjects[inst.id], topic_keys: [topicKey], provenance: inst.provenance,
      });
    }
  }

  const findings = [...people.entries()].map(([politician_id, list]) => ({ politician_id, findings: [...list.values()], searches: [] }));
  return { findings, unmatched, skipped, crosscheck };
}

/** The one table roll call that is this store vote; else null, with the reason in `unmatchedRollCalls`. */
function tableRoll(instrumentId: string, vote: Vote, g: GateRow, table: TableRollCall[], crosscheck: CrossCheck): TableRollCall | null {
  const miss = (reason: string) => {
    crosscheck.unmatchedRollCalls.push({ instrument_id: instrumentId, vote_date: g.vote_date, body: g.body, motion: g.motion, reason });
    return null;
  };
  const bill = instrumentBill(instrumentId);
  if (!bill) return miss('table: not a bill id');
  const match = matchRollCall(vote, bill, table);
  if (match.kind === 'one') return match.roll;
  return miss(match.kind === 'none' ? 'table: no roll call' : `table: ${match.candidates.length} roll calls fit`);
}
