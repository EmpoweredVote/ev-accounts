import type { EventKind } from './eventKinds.js';

export interface EventEntityState {
  eventKind: EventKind;
  chamberId: string | null;
}

/**
 * Validate a meeting's event-entity state.
 *
 * There are currently no hard requirements:
 *  - races are derived from a meeting's linked candidates by the pipeline and
 *    stored in meetings.event_races (not set here);
 *  - chamber_id is optional for council/school_board — a multi-seat body
 *    (e.g. Bloomington Common Council = 7 per-seat chambers sharing one slug)
 *    has no single chamber to pin, so a missing chamber must not block.
 *
 * Kept as the single place to reintroduce entity rules if that changes.
 */
export function validateEventEntities(
  _state: EventEntityState
): string | null {
  return null;
}
