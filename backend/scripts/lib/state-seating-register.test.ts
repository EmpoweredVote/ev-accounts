/**
 * The register is the queue the remaining state bodies are worked from: one row per
 * (state, district_type), ordered so the body with the nearest deadline is next.
 *
 * 🔴 THE SORT IS THE WHOLE POINT AND IT IS EASY TO GET BACKWARDS. 70 of the 73 bodies have no
 * cited start date yet. Sorting on a missing date puts them wherever the language's comparison
 * happens to put a null — in JS, before every real date — so the entire undated backlog would
 * jump ahead of the one body with a December deadline. An undated body has no deadline to be
 * late for; it sinks.
 *
 * Pure: no database. The counts come from classifyWave, which has its own tests.
 */
import { describe, it, expect } from 'vitest';
import { buildRegister } from './state-seating-register.mjs';

/** One winner row, as WAVE_SELECTION_SQL returns it. */
function row(over: Record<string, unknown> = {}) {
  return {
    office_id: 'o1',
    politician_id: 'p1',
    is_reelection: false,
    winner_count: 1,
    swearing_in_date: null as string | null,
    basis: null as string | null,
    next_term_start: null as string | null,
    is_vacant: false,
    certainty: 'called',
    label: 'a seat',
    state: 'xx',
    district_type: 'STATE_LOWER',
    ...over,
  };
}

describe('buildRegister', () => {
  it('makes one row per (state, district_type)', () => {
    const reg = buildRegister([
      row({ state: 'wi', district_type: 'STATE_LOWER', office_id: 'a' }),
      row({ state: 'wi', district_type: 'STATE_UPPER', office_id: 'b' }),
      row({ state: 'ma', district_type: 'STATE_LOWER', office_id: 'c' }),
    ]);
    expect(reg.length).toBe(3);
    expect(reg.map((r) => `${r.state}/${r.district_type}`).sort()).toEqual([
      'ma/STATE_LOWER',
      'wi/STATE_LOWER',
      'wi/STATE_UPPER',
    ]);
  });

  // 🔴 The failure this file exists to prevent.
  it('puts a dated pair before an undated one however large the undated one is', () => {
    const big = Array.from({ length: 200 }, (_, i) =>
      row({ state: 'ma', district_type: 'STATE_LOWER', office_id: `m${i}` }),
    );
    const small = [
      row({ state: 'la', district_type: 'STATE_BOARD', office_id: 'l1', swearing_in_date: '2027-01-01', basis: 'statute' }),
    ];
    const reg = buildRegister([...big, ...small]);
    expect(reg[0].state).toBe('la');
    expect(reg[1].state).toBe('ma');
  });

  it('orders two dated pairs by date, soonest first', () => {
    const reg = buildRegister([
      row({ state: 'al', district_type: 'STATE_BOARD_EDUCATION', office_id: 'a', swearing_in_date: '2027-01-18', basis: 'statute' }),
      row({ state: 'ne', district_type: 'STATE_BOARD', office_id: 'b', swearing_in_date: '2027-01-07', basis: 'statute' }),
    ]);
    expect(reg.map((r) => r.state)).toEqual(['ne', 'al']);
  });

  it('orders two undated pairs by office count, largest first', () => {
    const reg = buildRegister([
      row({ state: 'co', district_type: 'STATE_LOWER', office_id: 'c1' }),
      row({ state: 'az', district_type: 'STATE_LOWER', office_id: 'a1' }),
      row({ state: 'az', district_type: 'STATE_LOWER', office_id: 'a2' }),
    ]);
    expect(reg.map((r) => r.state)).toEqual(['az', 'co']);
  });

  it('marks a pair done when every office in it already carries a next term', () => {
    const reg = buildRegister([
      row({ state: 'wi', office_id: 'a', next_term_start: '2027-01-04', swearing_in_date: '2027-01-04', basis: 'statute' }),
      row({ state: 'wi', office_id: 'b', next_term_start: '2027-01-04', swearing_in_date: '2027-01-04', basis: 'statute' }),
    ]);
    expect(reg[0].status).toBe('done');
    expect(reg[0].remaining).toBe(0);
  });

  // ⚠ A part-seated body is still work. Calling it done because SOME of it is seated is how the
  // last three Indiana seats sat unseated behind 24 that were.
  it('counts a partly-seated pair as queued, with its remainder', () => {
    const reg = buildRegister([
      row({ state: 'in', office_id: 'a', next_term_start: '2026-11-04', swearing_in_date: '2026-11-04', basis: 'statute' }),
      row({ state: 'in', office_id: 'b', swearing_in_date: '2026-11-04', basis: 'statute' }),
    ]);
    expect(reg[0].status).toBe('queued');
    expect(reg[0].offices).toBe(2);
    expect(reg[0].remaining).toBe(1);
  });

  it('carries the blocker counts a wave has to clear before it can ship', () => {
    const reg = buildRegister([
      row({ state: 'md', office_id: 'a', winner_count: 2, politician_id: null }),
      row({ state: 'md', office_id: 'a', winner_count: 2 }),
    ]);
    expect(reg[0].multi_winner_offices).toBe(1);
    expect(reg[0].winners_without_record).toBe(1);
    expect(reg[0].offices).toBe(1);
    expect(reg[0].winners).toBe(2);
  });

  it('reports the cited date only when every office in the pair agrees on one', () => {
    const reg = buildRegister([
      row({ state: 'tx', office_id: 'a', swearing_in_date: '2027-01-12', basis: 'statute' }),
      row({ state: 'tx', office_id: 'b', swearing_in_date: '2027-01-26', basis: 'statute' }),
    ]);
    expect(reg[0].start_date).toBeNull();
  });

  // 🔴 FOUND BY THE WHOLE-BRANCH REVIEW. A body with one dated office out of sixty was reporting
  // that date as the body's, which sorted it ahead of every undated body as though it had a
  // deadline. The queue is the thing this file exists to get right.
  it('does not treat a part-dated body as dated, or let it jump the queue', () => {
    const reg = buildRegister([
      row({ state: 'tx', district_type: 'STATE_LOWER', office_id: 't1', swearing_in_date: '2027-01-12', basis: 'statute' }),
      row({ state: 'tx', district_type: 'STATE_LOWER', office_id: 't2' }),
      row({ state: 'la', district_type: 'STATE_BOARD', office_id: 'l1', swearing_in_date: '2027-02-01', basis: 'statute' }),
    ]);
    expect(reg[0].state).toBe('la');
    expect(reg[1].start_date).toBeNull();
    expect(reg[1].offices_without_date).toBe(1);
  });

  it('totals the whole pass so a re-cut cannot silently lose a seat', () => {
    const reg = buildRegister([
      row({ state: 'wi', office_id: 'a' }),
      row({ state: 'ma', office_id: 'b' }),
      row({ state: 'ma', office_id: 'c' }),
    ]);
    expect(reg.reduce((n, r) => n + r.offices, 0)).toBe(3);
  });
});
