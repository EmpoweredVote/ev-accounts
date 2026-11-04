/**
 * The incumbency reconciler.
 *
 * `politicians.is_incumbent` is a CACHED FLAG and nothing recomputes it. It defaulted to true
 * until CA_0188, which created 1,817 active "incumbents" holding no seat. The truth is
 * `essentials.office_current_holder`: a person is an incumbent exactly while they resolve as the
 * current holder of at least one office TODAY.
 *
 * 🔴 THE RECONCILER ALONE IS NOT ENOUGH, AND THE OBVIOUS CONTROL HIDES IT. `stagingService`'s
 * promotion used to force `is_incumbent = true` on every ON CONFLICT update, so a scheduled
 * reconciler would be undone by the next promotion — while a control that plants drift, runs the
 * reconciler and watches it get fixed would still pass, because it never exercises the writer
 * that reverts it. The last test here guards that writer by its SQL text, which is the only
 * thing a mocked test can see.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { findDrift } from './reconcile-incumbency.mjs';

const holder = (id: string) => ({ politician_id: id });

describe('findDrift', () => {
  it('flags a politician marked incumbent who holds no current seat', () => {
    const drift = findDrift({
      politicians: [{ id: 'p1', is_incumbent: true, office_id: null }],
      currentHolders: [],
      raceCandidates: [],
    });
    expect(drift).toEqual([
      { politicianId: 'p1', column: 'politicians.is_incumbent', current: true, expected: false },
    ]);
  });

  it('flags a current holder marked is_incumbent = false', () => {
    const drift = findDrift({
      politicians: [{ id: 'p2', is_incumbent: false, office_id: null }],
      currentHolders: [holder('p2')],
      raceCandidates: [],
    });
    expect(drift).toEqual([
      { politicianId: 'p2', column: 'politicians.is_incumbent', current: false, expected: true },
    ]);
  });

  it('returns nothing when every cached value agrees', () => {
    const drift = findDrift({
      politicians: [
        { id: 'p1', is_incumbent: true, office_id: 'o1' },
        { id: 'p2', is_incumbent: false, office_id: null },
      ],
      currentHolders: [holder('p1')],
      raceCandidates: [],
    });
    expect(drift).toEqual([]);
  });

  it('counts a person who holds two seats once, not twice', () => {
    // 27 active people hold two or more current seats. A politician-rooted read fans out.
    const drift = findDrift({
      politicians: [{ id: 'p3', is_incumbent: false, office_id: null }],
      currentHolders: [holder('p3'), holder('p3')],
      raceCandidates: [],
    });
    expect(drift).toHaveLength(1);
  });

  it('reports race_candidates.is_incumbent separately from politicians.is_incumbent', () => {
    const drift = findDrift({
      politicians: [{ id: 'p4', is_incumbent: true, office_id: null }],
      currentHolders: [holder('p4')],
      raceCandidates: [{ id: 'rc1', politician_id: 'p4', is_incumbent: false }],
    });
    expect(drift).toEqual([
      { raceCandidateId: 'rc1', politicianId: 'p4', column: 'race_candidates.is_incumbent', current: false, expected: true },
    ]);
  });

  it('flags a deprecated office_id snapshot that points nowhere real', () => {
    const drift = findDrift({
      politicians: [{ id: 'p5', is_incumbent: false, office_id: 'o-stale' }],
      currentHolders: [],
      raceCandidates: [],
    });
    expect(drift).toContainEqual(
      { politicianId: 'p5', column: 'politicians.office_id', current: 'o-stale', expected: null },
    );
  });
});

describe('the staging promotion must not force is_incumbent back on', () => {
  // 🔴 A TEXT GUARD, because a mocked test cannot see the SQL. Without this, piece 5 of the
  // transition programme is undone by the next staging promotion and nothing reports it.
  const src = readFileSync(new URL('../src/lib/stagingService.ts', import.meta.url), 'utf8');

  it('does not set is_incumbent in the ON CONFLICT update', () => {
    const conflictBlock = src.slice(src.indexOf('ON CONFLICT (external_id) DO UPDATE SET'));
    const setList = conflictBlock.slice(0, conflictBlock.indexOf('`'));
    expect(setList).not.toMatch(/is_incumbent\s*=\s*true/);
  });

  it('still sets is_active in that update, so the guard is reading the right block', () => {
    // A positive control on the assertion above: if this fails, the slice is wrong and the
    // first test is passing vacuously rather than because the line is gone.
    const conflictBlock = src.slice(src.indexOf('ON CONFLICT (external_id) DO UPDATE SET'));
    const setList = conflictBlock.slice(0, conflictBlock.indexOf('`'));
    expect(setList).toMatch(/is_active\s*=\s*true/);
  });
});
