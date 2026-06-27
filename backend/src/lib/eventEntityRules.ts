import type { EventKind } from './eventKinds.js';

export interface EventEntityState {
  eventKind: EventKind;
  chamberId: string | null;
}

export function validateEventEntities(
  state: EventEntityState
): string | null {
  if (
    (state.eventKind === 'council' || state.eventKind === 'school_board') &&
    state.chamberId === null
  ) {
    return `chamberId is required for eventKind ${state.eventKind}`;
  }
  return null;
}
