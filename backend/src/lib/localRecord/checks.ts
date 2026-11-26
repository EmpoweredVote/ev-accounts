// Who was in the room for each roll call, who voted which way, and the four checks a roll call must pass before
// its votes are written. A vote that cannot be proven fails with a cause; it is never guessed.
import { normaliseName, resolveName, type NameFile, type TermSpan } from './names.js';
import type {
  CheckResult,
  FeedItem,
  MeetingNote,
  MinutesParse,
  MinutesRollCall,
  Position,
  PrintedTally,
  ResolvedVote,
  Side,
} from './types.js';

export type NotPresentKind = MeetingNote['kind'] | 'absent';

export type PresentAtResult =
  | { present: string[]; notPresent: { name: string; kind: NotPresentKind }[] }
  | { error: 'unplaced_note'; detail: string };

/** True when two printed names are the same member. */
export type SameMember = (a: string, b: string) => boolean;

const sameByName: SameMember = (a, b) => normaliseName(a) === normaliseName(b);

/**
 * Members in the room at one roll call, by attendance name.
 *
 * Start from the attendance list. A member marked absent is out; a member with an arrival note is out until that
 * note (not yet arrived). Then, in order, every note placed at or before this roll call: `arrived` and `returned`
 * add, `left` removes for the rest of the meeting, `out_of_room` removes only for the roll call it is placed on
 * (out of the room is momentary). Then this roll call's own inline notes. A note with no place (`at === null`)
 * could affect any roll call, so it fails them all.
 *
 * `same` decides which attendance entry a note names. The default compares normalised names; `checkRollCall`
 * passes one that compares resolved politician ids.
 */
export function presentAt(parse: MinutesParse, rc: MinutesRollCall, same: SameMember = sameByName): PresentAtResult {
  const unplaced = [...parse.notes, ...rc.inlineNotes].find((n) => n.at === null);
  if (unplaced) {
    return {
      error: 'unplaced_note',
      detail: `${unplaced.kind} note for "${unplaced.nameAsPrinted}" could not be placed before a roll call`,
    };
  }

  const entries: { name: string; out: NotPresentKind | null }[] = parse.attendance.map((a) => ({
    name: a.nameAsPrinted,
    out: a.absent ? 'absent' : null,
  }));
  const find = (note: MeetingNote): { entry: (typeof entries)[number] } | { error: string } => {
    const hits = entries.filter((e) => same(e.name, note.nameAsPrinted));
    if (hits.length === 1) return { entry: hits[0] };
    if (hits.length === 0 && note.kind === 'arrived') {
      const entry = { name: note.nameAsPrinted, out: 'arrived' as NotPresentKind | null };
      entries.push(entry);
      return { entry };
    }
    return {
      error: `${note.kind} note for "${note.nameAsPrinted}" matches ${hits.length} attendance entries`,
    };
  };

  // A member who arrives during the meeting is not in the room before the arrival note.
  for (const n of parse.notes) {
    if (n.kind !== 'arrived') continue;
    const f = find(n);
    if ('error' in f) return { error: 'unplaced_note', detail: f.error };
    f.entry.out = 'arrived';
  }

  const apply = (n: MeetingNote): string | null => {
    const f = find(n);
    if ('error' in f) return f.error;
    // A return needs a member who was in the meeting; one marked absent or not yet arrived cannot return.
    if (n.kind === 'returned' && (f.entry.out === 'absent' || f.entry.out === 'arrived')) {
      return `returned note for "${n.nameAsPrinted}", who was ${f.entry.out === 'absent' ? 'absent' : 'not yet arrived'}`;
    }
    if (n.kind === 'arrived' || n.kind === 'returned') f.entry.out = null;
    else f.entry.out = n.kind;
    return null;
  };

  for (const n of parse.notes) {
    const at = n.at as number;
    if (at > rc.index) continue;
    // Out of the room lasts until the next roll call after the one the note is placed on.
    if (n.kind === 'out_of_room' && parse.rollCalls.some((r) => r.index >= at && r.index < rc.index)) continue;
    const err = apply(n);
    if (err) return { error: 'unplaced_note', detail: err };
  }
  for (const n of rc.inlineNotes) {
    // A note already in the meeting notes for this roll call was applied above, in order; do not apply it twice.
    const dup = parse.notes.some((m) => m.at === n.at && m.kind === n.kind && same(m.nameAsPrinted, n.nameAsPrinted));
    if (dup) continue;
    const err = apply(n);
    if (err) return { error: 'unplaced_note', detail: err };
  }

  return {
    present: entries.filter((e) => e.out === null).map((e) => e.name),
    notPresent: entries.filter((e) => e.out !== null).map((e) => ({ name: e.name, kind: e.out as NotPresentKind })),
  };
}

export interface CheckContext {
  names: NameFile;
  terms: TermSpan[];
  /** Members with a council term on the meeting date. */
  seatedCount: number;
  /** Feed items by normalised item number. */
  feed: Map<string, FeedItem>;
  /** Item numbers the feed lists. */
  knownItems: Set<string>;
}

const SIDE_POSITION: Record<Side, Position> = { yes: 'yea', no: 'nay', abstain: 'present' };
const SIDES: Side[] = ['yes', 'no', 'abstain'];

const fail = (cause: Extract<CheckResult, { ok: false }>['cause'], detail: string): CheckResult => ({
  ok: false,
  cause,
  detail,
});

const fmt = (t: PrintedTally): string => (t.abstain > 0 ? `${t.yes}-${t.no}-${t.abstain}` : `${t.yes}-${t.no}`);

/** Runs the four checks on one roll call, in order, and returns each member's position or the first failure. */
export function checkRollCall(rc: MinutesRollCall, parse: MinutesParse, ctx: CheckContext): CheckResult {
  const date = parse.meetingDate;
  const label = `${rc.itemNumber} ${rc.question}`;

  // Check 4: the item is one the feed knows.
  if (!ctx.knownItems.has(rc.itemNumber)) return fail('unknown_item', `${rc.itemNumber} is not in the feed`);

  // Check 2: every printed name is a member seated on the meeting date.
  const ids = new Map<string, string>();
  const printed = [
    ...parse.attendance.map((a) => a.nameAsPrinted),
    ...rc.named.flatMap((n) => n.names),
    // Every placed note: arrival notes after this roll call still decide who had not yet arrived.
    ...parse.notes.filter((n) => n.at !== null).map((n) => n.nameAsPrinted),
    ...rc.inlineNotes.map((n) => n.nameAsPrinted),
  ];
  for (const name of printed) {
    if (ids.has(name)) continue;
    const r = resolveName(name, date, ctx.names, ctx.terms);
    if ('error' in r) return fail(r.error === 'ambiguous' ? 'unknown_name' : r.error, `${label}: ${r.detail}`);
    ids.set(name, r.politicianId);
  }
  const idOf = (name: string) => ids.get(name) as string;

  const attendanceIds = parse.attendance.map((a) => idOf(a.nameAsPrinted));
  if (new Set(attendanceIds).size !== attendanceIds.length) {
    return fail('tally_mismatch', `${label}: the attendance lists a member twice`);
  }

  const room = presentAt(parse, rc, (a, b) => idOf(a) === idOf(b));
  if ('error' in room) return fail('unplaced_note', `${label}: ${room.detail}`);

  // Check 1: the tally closes, so every present member's side is known.
  const presentIds = room.present.map(idOf);
  const votes: ResolvedVote[] = [];
  const assigned = new Set<string>();
  const namedSides = new Set<Side>();
  for (const { side, names } of rc.named) {
    if (namedSides.has(side)) return fail('tally_mismatch', `${label}: ${side} side is named twice`);
    namedSides.add(side);
    if (names.length !== rc.tally[side]) {
      return fail('tally_mismatch', `${label}: ${names.length} names on the ${side} side, count ${rc.tally[side]}`);
    }
    for (const name of names) {
      const id = idOf(name);
      if (!presentIds.includes(id)) {
        return fail('tally_mismatch', `${label}: "${name}" voted ${side} but was not in the room`);
      }
      if (assigned.has(id)) return fail('tally_mismatch', `${label}: "${name}" is named more than once`);
      assigned.add(id);
      votes.push({ politicianId: id, nameAsPrinted: name, position: SIDE_POSITION[side], workedOut: false });
    }
  }

  const unnamed = SIDES.filter((s) => !namedSides.has(s));
  if (unnamed.includes('abstain') && rc.tally.abstain > 0) {
    return fail('tally_mismatch', `${label}: ${rc.tally.abstain} abstained but the minutes do not name them`);
  }
  const unnamedWithVotes = unnamed.filter((s) => rc.tally[s] > 0);
  if (unnamedWithVotes.length > 1) {
    return fail('tally_mismatch', `${label}: more than one side has votes and no names`);
  }
  const rest = room.present.filter((name) => !assigned.has(idOf(name)));
  const restCount = unnamedWithVotes.length === 1 ? rc.tally[unnamedWithVotes[0]] : 0;
  if (rest.length !== restCount) {
    return fail(
      'tally_mismatch',
      `${label}: ${rest.length} present and not named, but ${restCount} on the unnamed side`,
    );
  }
  for (const name of rest) {
    const side = unnamedWithVotes[0];
    votes.push({ politicianId: idOf(name), nameAsPrinted: name, position: SIDE_POSITION[side], workedOut: true });
  }

  const total = rc.tally.yes + rc.tally.no + rc.tally.abstain + room.notPresent.length;
  if (total !== ctx.seatedCount) {
    return fail(
      'tally_mismatch',
      `${label}: ${fmt(rc.tally)} plus ${room.notPresent.length} not present is ${total}, but ${ctx.seatedCount} are seated`,
    );
  }
  for (const { name, kind } of room.notPresent) {
    votes.push({
      politicianId: idOf(name),
      nameAsPrinted: name,
      position: kind === 'absent' ? 'absent' : 'not_voting',
      workedOut: false,
    });
  }

  // Check 3: final passage agrees with the feed's Final action.
  let feedDisagreement: string | null = null;
  if (rc.question === 'Final passage') {
    const final = ctx.feed.get(rc.itemNumber)?.final ?? null;
    // A Final action from another meeting is not this vote: no comparison.
    if (final && final.date === date) {
      // A vetoed item passed the council; the veto came after.
      const feedOutcome = final.outcome === 'vetoed' ? 'passed' : final.outcome;
      if (feedOutcome !== rc.outcome) {
        return fail('outcome_conflict', `${label}: feed says ${final.outcome}, minutes say ${rc.outcome}`);
      }
      const t = final.tally;
      if (t && (t.yes !== rc.tally.yes || t.no !== rc.tally.no || t.abstain !== rc.tally.abstain)) {
        feedDisagreement = `feed ${fmt(t)}, minutes ${fmt(rc.tally)}`;
      }
    }
  }

  return { ok: true, votes, feedDisagreement };
}
