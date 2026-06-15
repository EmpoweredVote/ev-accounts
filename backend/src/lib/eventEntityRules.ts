import type { EventKind } from './eventKinds.js';

export interface EventEntityState {
  eventKind: EventKind;
  chamberId: string | null;
  raceId: string | null;
}

export function validateEventEntities(
  state: EventEntityState
): string | null {
  if (state.chamberId !== null && state.raceId !== null) {
    return 'chamberId and raceId cannot both be set';
  }

  if (
    (state.eventKind === 'council' ||
      state.eventKind === 'school_board') &&
    state.chamberId === null
  ) {
    return `chamberId is required for eventKind ${state.eventKind}`;
  }

  if (
    (state.eventKind === 'debate' || state.eventKind === 'forum') &&
    state.raceId === null
  ) {
    return `raceId is required for eventKind ${state.eventKind}`;
  }

  return null;
}
