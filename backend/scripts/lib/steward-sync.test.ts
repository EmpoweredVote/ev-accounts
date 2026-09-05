import { describe, it, expect } from 'vitest';
import { reconcile, STALE_DAYS } from './steward-sync.mjs';

// §5 of the design: "`steward sync` reconciles: reservations that now have a matching file on a
// ref become `written`; reservations older than fourteen days with no file are flagged for
// cleanup." Shipped as insert-only seeding; the reconciliation half was never built, so a
// reservation stayed `reserved` forever — CC_0074 sat on the board as outstanding while its
// migration was merged to master.
//
// 🔴 THIS IS THE FIRST CODE THAT REWRITES AN EXISTING SLOT ROW, and the seeder's rule was
//    "a slot already present is NEVER rewritten" — because it could be a live reservation
//    somebody is relying on. That rule is not being broken so much as satisfied from the other
//    side: a promotion only happens when a FILE EXISTS for that slot, which is proof the
//    reservation was used. Everything without that proof is REPORTED, never written.

const gitSlot = (namespace: string, num: number, filename: string) =>
  ({ namespace, num, key: namespace ? `${namespace}_${num}` : String(num), filename, refs: ['master'] });

const now = Date.parse('2026-09-04T20:00:00Z');
const daysAgo = (d: number) => new Date(now - d * 86400000);

const row = (over: Record<string, unknown> = {}) => ({
  namespace: 'CC', num: 74, state: 'reserved', claimed_by: 'chris@empowered.vote',
  purpose: 'senate pilot', filename: null, claimed_at: daysAgo(1), ...over,
});

describe('reconcile', () => {
  it('promotes a reservation whose file now exists on a ref', () => {
    const r = reconcile([gitSlot('CC', 74, 'CC_0074_senate_pilot.sql')], [row()], now);
    expect(r.promote).toHaveLength(1);
    expect(r.promote[0].filename).toBe('CC_0074_senate_pilot.sql');
    expect(r.promote[0].namespace).toBe('CC');
    expect(r.promote[0].num).toBe(74);
  });

  it('leaves a reservation alone while its file does not exist yet', () => {
    const r = reconcile([], [row()], now);
    expect(r.promote).toEqual([]);
    expect(r.stale).toEqual([]);          // one day old: still in flight
  });

  // The design's number, and it is a REPORT, not an action: a fourteen-day-old reservation may
  // still belong to a long-running branch, and abandoning somebody else's slot on a timer is
  // the kind of helpfulness that loses work.
  it('flags a reservation with no file once it passes the stale threshold', () => {
    const r = reconcile([], [row({ claimed_at: daysAgo(STALE_DAYS + 1) })], now);
    expect(r.stale).toHaveLength(1);
    expect(r.promote).toEqual([]);
  });

  it('does not flag one that is exactly at the threshold, only past it', () => {
    expect(reconcile([], [row({ claimed_at: daysAgo(STALE_DAYS) })], now).stale).toEqual([]);
    expect(reconcile([], [row({ claimed_at: daysAgo(STALE_DAYS + 0.01) })], now).stale).toHaveLength(1);
  });

  it('never flags a written or abandoned row as stale, however old', () => {
    const old = { claimed_at: daysAgo(400) };
    expect(reconcile([], [row({ ...old, state: 'written' })], now).stale).toEqual([]);
    expect(reconcile([], [row({ ...old, state: 'abandoned' })], now).stale).toEqual([]);
  });

  it('fills in a filename the seed never recorded', () => {
    const r = reconcile([gitSlot('CC', 74, 'CC_0074_x.sql')],
      [row({ state: 'written', filename: null })], now);
    expect(r.fillFilename).toHaveLength(1);
    expect(r.fillFilename[0].filename).toBe('CC_0074_x.sql');
    expect(r.promote).toEqual([]);
  });

  it('says nothing about a row that already agrees with git', () => {
    const r = reconcile([gitSlot('CC', 74, 'CC_0074_x.sql')],
      [row({ state: 'written', filename: 'CC_0074_x.sql' })], now);
    expect(r.promote).toEqual([]);
    expect(r.fillFilename).toEqual([]);
    expect(r.drift).toEqual([]);
  });

  // 🔴 A DISAGREEMENT IS REPORTED, NEVER SILENTLY OVERWRITTEN. CLAUDE.md forbids renaming an
  //    applied migration, because the number is embedded in production data — so a slot whose
  //    filename has changed is either that forbidden rename or two files sharing a slot, and
  //    both want a human. Writing git's answer over the table's would erase the evidence.
  it('reports a filename that disagrees with git rather than overwriting it', () => {
    const r = reconcile([gitSlot('CC', 74, 'CC_0074_renamed.sql')],
      [row({ state: 'written', filename: 'CC_0074_original.sql' })], now);
    expect(r.drift).toHaveLength(1);
    expect(r.drift[0].was).toBe('CC_0074_original.sql');
    expect(r.drift[0].now).toBe('CC_0074_renamed.sql');
    expect(r.fillFilename).toEqual([]);
  });

  // 🔴 THE HIGHEST-SIGNAL FINDING HERE. A slot deliberately abandoned that now carries a file
  //    means somebody reused a dead number — check:reservations fails that at PR time, but only
  //    for a file ADDED on a branch. A file that reached master another way is invisible to it.
  it('reports a file occupying a slot that was abandoned', () => {
    const r = reconcile([gitSlot('CC', 71, 'CC_0071_someone_reused_it.sql')],
      [row({ num: 71, state: 'abandoned' })], now);
    expect(r.conflict).toHaveLength(1);
    expect(r.conflict[0].filename).toBe('CC_0071_someone_reused_it.sql');
    expect(r.promote).toEqual([]);
  });

  it('matches slots by namespace as well as number', () => {
    const r = reconcile([gitSlot('CA', 74, 'CA_0074_other_author.sql')], [row()], now);
    expect(r.promote).toEqual([]);        // CA_74 is not CC_74
  });

  it('matches the shared sequence, whose namespace is the empty string', () => {
    const r = reconcile([gitSlot('', 1853, '1853_x.sql')],
      [row({ namespace: '', num: 1853 })], now);
    expect(r.promote).toHaveLength(1);
  });

  it('handles an empty table and an empty repo without inventing work', () => {
    const r = reconcile([], [], now);
    expect(r).toEqual({ promote: [], fillFilename: [], stale: [], drift: [], conflict: [] });
  });

  it('reads claimed_at as an ISO string as readily as a Date', () => {
    const r = reconcile([], [row({ claimed_at: daysAgo(STALE_DAYS + 1).toISOString() })], now);
    expect(r.stale).toHaveLength(1);
  });

  // An unreadable claim date must not become "old enough to abandon". Unknown age is not old.
  it('never calls a row with an unreadable claim date stale', () => {
    expect(reconcile([], [row({ claimed_at: null })], now).stale).toEqual([]);
    expect(reconcile([], [row({ claimed_at: 'not a date' })], now).stale).toEqual([]);
  });

  it('carries the holder through, so a report can name who to ask', () => {
    const r = reconcile([], [row({ claimed_at: daysAgo(30), claimed_by: 'candrews@empowered.vote' })], now);
    expect(r.stale[0].claimed_by).toBe('candrews@empowered.vote');
  });
});
