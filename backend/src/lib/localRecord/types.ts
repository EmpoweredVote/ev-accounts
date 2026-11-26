// Shared types for the Bloomington city-council voting-record module.
// Later modules (minutes parser, feed reader, checker, writer) import from here.

/** City scope key, e.g. 'place:1805860'. */
export type CityScope = string;

/** A side a council member can take on a vote. */
export type Side = 'yes' | 'no' | 'abstain';

/** A member's recorded position on one roll call. */
export type Position = 'yea' | 'nay' | 'present' | 'absent' | 'not_voting';

/** Vote counts exactly as the minutes or feed print them. */
export interface PrintedTally {
  yes: number;
  no: number;
  abstain: number;
}

/** One name on the meeting's attendance list. */
export interface AttendanceEntry {
  nameAsPrinted: string;
  absent: boolean;
}

/**
 * A note about a member leaving or returning to the room.
 * `at` is the event index the note is placed before; null means it could not be placed.
 */
export type MeetingNote =
  | {
      kind: 'arrived' | 'left' | 'out_of_room' | 'returned';
      nameAsPrinted: string;
      at: number | null;
    };

/** One roll-call vote as printed in the minutes. */
export interface MinutesRollCall {
  /** Position among events in the document. */
  index: number;
  /** Normalised item number, e.g. 'App Ord 2026-02', 'Ord 21-23', 'Res 2026-09'. */
  itemNumber: string;
  /** 'Final passage' | 'Amendment 03' | 'Reasonable Condition 04' | 'Veto override' (numbers two zero-padded digits) */
  question: string;
  tally: PrintedTally;
  /** Only the sides whose names the minutes print. */
  named: { side: Side; names: string[] }[];
  /** Notes printed inside the vote, e.g. '(Volan out of the room)'. `at` is this index. */
  inlineNotes: MeetingNote[];
  outcome: 'passed' | 'failed';
  /** Verbatim sentence, kept for exceptions and audit. */
  sentence: string;
}

/** The result of reading one set of minutes. */
export interface MinutesParse {
  meetingDate: string;
  attendance: AttendanceEntry[];
  notes: MeetingNote[];
  rollCalls: MinutesRollCall[];
  /** Roll-call-looking sentences the parser did not understand. */
  unparsed: string[];
}

/** One item from the city's legislation feed. */
export interface FeedItem {
  feedId: number;
  type: 'Ordinance' | 'Resolution' | 'Appropriation Ordinance';
  number: string;
  itemNumber: string;
  title: string;
  synopsis: string | null;
  status: string;
  /** null = the feed has no Final action; tally null = Final exists but its counts could not be read. */
  final: {
    date: string;
    outcome: 'passed' | 'failed' | 'vetoed';
    tally: PrintedTally | null;
  } | null;
  pageUrl: string;
}

/** A member's vote after matching the printed name to a known politician. */
export interface ResolvedVote {
  politicianId: string;
  nameAsPrinted: string;
  position: Position;
  /** True when the position was worked out from the tally, not printed by name. */
  workedOut: boolean;
}

/**
 * Why a vote could not be confirmed. Must match the database CHECK list from Task 1.
 */
export const EXCEPTION_CAUSES = [
  'unknown_name',
  'not_seated',
  'tally_mismatch',
  'unplaced_note',
  'outcome_conflict',
  'unknown_item',
  'feed_missing_final',
  'file_changed',
  'control_failed',
  'unparsed_roll_call',
  'inventory_disagrees',
  'spot_check_failed',
  // Formal Minutes disagree with a vote already confirmed from the Memorandum.
  'minutes_disagree',
] as const;

export type ExceptionCause = (typeof EXCEPTION_CAUSES)[number];

/** Outcome of checking one roll call against the feed. */
export type CheckResult =
  | { ok: true; votes: ResolvedVote[]; feedDisagreement: string | null }
  | { ok: false; cause: ExceptionCause; detail: string };
