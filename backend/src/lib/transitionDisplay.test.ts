import { describe, it, expect } from 'vitest';
import { mapTransitionFields, BLANK_TRANSITION_FIELDS } from './transitionDisplay.js';

describe('mapTransitionFields', () => {
  it('returns a dated successor unchanged, with the date trimmed to a day', () => {
    const t = mapTransitionFields({
      incoming_holder_id: 'p1',
      incoming_holder_name: 'Nithya Raman',
      incoming_on: new Date('2026-12-14T00:00:00Z'),
    });
    expect(t.incoming_on).toBe('2026-12-14');
    expect(t.pending_winner).toBeNull();
  });

  it('builds a pending winner from the view columns', () => {
    const t = mapTransitionFields({
      pending_election_date: '2026-11-03',
      pending_certainty: 'called',
      pending_seats: 1,
      pending_winners: [{ id: 'p2', name: 'Sam Rivera' }],
    });
    expect(t.pending_winner).toEqual({
      election_date: '2026-11-03',
      certainty: 'called',
      seats: 1,
      winners: [{ id: 'p2', name: 'Sam Rivera' }],
    });
  });

  // Review Focus 4: 23 offices carry an older general (back to 2026-05-02). The card must name
  // the month the election was actually held in, never November's.
  it('keeps the election date the view gave it, whatever month that is', () => {
    const t = mapTransitionFields({
      pending_election_date: '2026-05-02',
      pending_certainty: 'certified',
      pending_seats: 1,
      pending_winners: [{ id: null, name: 'Greg Wims' }],
    });
    expect(t.pending_winner?.election_date).toBe('2026-05-02');
    expect(t.pending_winner?.winners[0].id).toBeNull();
  });

  it('treats any certainty that is not "certified" as "called"', () => {
    expect(
      mapTransitionFields({
        pending_election_date: '2026-11-03',
        pending_certainty: null,
        pending_seats: 1,
        pending_winners: [{ id: 'p3', name: 'A B' }],
      }).pending_winner?.certainty
    ).toBe('called');
  });

  it('returns a null pending_winner when the view produced no row', () => {
    expect(mapTransitionFields({}).pending_winner).toBeNull();
    expect(mapTransitionFields({}).seat_group).toBeNull();
  });

  it('builds the seat group from its four columns', () => {
    const t = mapTransitionFields({
      group_id: 'd1|c1',
      group_offices: 3,
      group_winners: 3,
      group_seated: 3,
    });
    expect(t.seat_group).toEqual({ group_id: 'd1|c1', offices: 3, winners: 3, seated: 3 });
  });

  it('BLANK_TRANSITION_FIELDS is every field null', () => {
    expect(Object.values(BLANK_TRANSITION_FIELDS).every((v) => v === null)).toBe(true);
  });
});
