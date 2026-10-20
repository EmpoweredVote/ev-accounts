/**
 * gatePrescreen.ts — which votes can never seat a politician, before any rewording (season topic prep).
 *
 * A vote that trips a gate cannot evidence a chair, so counting it as a candidate source inflates the
 * expected seat rate. The pilots found four shapes (S3 equity + library pilots, 2026-10): a bill with
 * more than one subject; a small body acting on consent, on someone else's motion, or on a higher-law
 * duty; a lopsided vote in a large body (nobody chose); and a sponsor of a filed version that is not
 * the topic's version. Pure, so the cases are testable without a database.
 */
import type { Vote } from './sourceStore';

export interface GateOpts {
  /** The body moved this itself (false: it acted on another body's motion). */
  ownMotion: boolean;
  /** The body was carrying out a duty set by a higher law. */
  higherLawDuty: boolean;
  /** The instrument covers more than one subject. */
  multiSubject: boolean;
}

/** Bodies this size or smaller are "small": every member's vote is a personal choice, so process gates apply. */
const SMALL_BODY = 10;
/** In a large body, a No share below this means the vote was near-unanimous. */
const NEAR_UNANIMOUS_NO_SHARE = 0.1;

/** The first gate that applies to this vote, or null when it can evidence a chair. */
export function gateForVote(v: Vote, opts: GateOpts): string | null {
  if (opts.multiSubject) return 'multi-subject';
  const size = v.body_size ?? v.yes + v.no + (v.absent ?? 0);
  if (size <= SMALL_BODY) {
    if (v.kind === 'consent' || v.kind === 'en-bloc' || !opts.ownMotion) return 'consent';
    if (opts.higherLawDuty) return 'higher-law-duty';
    return null;
  }
  const cast = v.yes + v.no;
  if (cast > 0 && v.no / cast < NEAR_UNANIMOUS_NO_SHARE) return 'near-unanimous';
  return null;
}

/** A sponsor whose filed version is not the topic's version evidences nothing about the topic. */
export function gateForSponsor(filedVersionMatchesTopic: boolean): 'off-version-sponsor' | null {
  return filedVersionMatchesTopic ? null : 'off-version-sponsor';
}
