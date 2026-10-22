/**
 * stage5Prefill.ts — Stage 5 step 2: saved findings from roll calls already in the source store.
 *
 * For every vote the topic's census reviewed (`stage0/gates.tsv`), each member matched to a person on the
 * Stage 5 roster becomes one record finding, with no new search. The census gate for that vote goes in the
 * finding's note, so the coder sees it; the census itself decided nothing here. Members with no
 * politician id are returned as `unmatched`, for the identity check (official member lists, never surname
 * alone). A matched member who is not on the roster has left office and is skipped. Absent and recused
 * are not acts. No search entry is written: a vote on file saves the record search, not the own-words
 * search (design §5 step 3). Pure: no database, no network.
 */
import { findingId, type Finding, type Instrument, type PersonFindings, type Vote } from './sourceStore.js';
import type { RosterRow } from './stage5Roster.js';

export type GateRow = { instrument_id: string; vote_date: string; body: string; motion: string; gate: string };
export type UnmatchedVote = { instrument_id: string; date: string; body: string; motion: string; name: string; vote: string };
export type SkippedVote = { instrument_id: string; vote_date: string; body: string; motion: string; reason: string };

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
): { findings: PersonFindings[]; unmatched: UnmatchedVote[]; skipped: SkippedVote[] } {
  const onRoster = new Set(roster.map((r) => r.politician_id));
  const byId = new Map(instruments.map((i) => [i.id, i]));
  const people = new Map<string, Finding[]>();
  const unmatched: UnmatchedVote[] = [];
  const skipped: SkippedVote[] = [];

  for (const g of gates) {
    const inst = byId.get(g.instrument_id);
    const skip = (reason: string) => skipped.push({ instrument_id: g.instrument_id, vote_date: g.vote_date, body: g.body, motion: g.motion, reason });
    if (!inst) { skip('instrument not in the store'); continue; }
    const tags = subjects[inst.id];
    if (!tags?.length) throw new Error(`${inst.id}: no subjects given (add it to the --subjects file, in plain words)`);
    if (!inst.urls.length) { skip('instrument has no URL'); continue; }
    const vote = findVote(inst, g);
    if (!vote) { skip('no single store vote matches this body, motion or date'); continue; }

    for (const m of vote.members) {
      if (!ACTS.has(m.vote)) continue;
      if (!m.politician_id) {
        unmatched.push({ instrument_id: inst.id, date: vote.date, body: vote.body, motion: vote.motion, name: m.name, vote: m.vote });
        continue;
      }
      if (!onRoster.has(m.politician_id)) continue;
      const base = {
        kind: 'record' as const, url: inst.urls[0], date: vote.date, date_precision: 'day' as const,
        instrument_id: inst.id, act: m.vote as Finding['act'], motion: vote.motion,
        note: `${vote.body}, ${vote.motion}, ${vote.date}: ${m.vote} (tally ${vote.yes}–${vote.no}); census gate: ${g.gate || 'none'}.`,
        subjects: tags, topic_keys: [topicKey], provenance: inst.provenance,
      };
      const list = people.get(m.politician_id) ?? [];
      list.push({ id: findingId(base), ...base });
      people.set(m.politician_id, list);
    }
  }

  const findings = [...people.entries()].map(([politician_id, list]) => ({ politician_id, findings: list, searches: [] }));
  return { findings, unmatched, skipped };
}
