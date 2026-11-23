import { describe, it, expect } from 'vitest';

import {
  findMultiDeleteOwners,
  findOrphanHardDeletes,
  parseAckArgs,
} from './check-lens-durability.mjs';

/**
 * The nightly's judgement is pure and is tested here directly, with no database.
 * The SQL that feeds it is exercised by `--selftest`, which plants removal rows
 * in a transaction against production, watches the check go red, acks them,
 * watches it go green, and then rolls back and proves the rollback took.
 *
 * 🔴 WHAT THIS IS GUARDING. On 2026-11-22 a short `PUT /api/compass/my-lenses`
 * payload was measured destroying the lenses it omitted: three lenses stored,
 * one survivor, HTTP 200, and no record anywhere that the other two had ever
 * existed. The guard added since closes that one path. It does not close the
 * next one, and the whole point of this check is that it does not need to know
 * what the next one is — it watches the OUTCOME (lenses disappearing) rather
 * than the route.
 *
 * ⚠ THE FAILURE MODE THAT MATTERS IS THE FALSE GREEN. A tripwire that reads
 * healthy while lenses vanish is worse than no tripwire, because it is actively
 * consulted and actively wrong. Every case below pins one direction of the
 * decision, and the cases that assert SILENCE matter as much as the ones that
 * assert noise: a check that fires on ordinary use gets muted within a week,
 * and a muted check is a false green with extra steps.
 *
 * ⚠ MEASURED 2026-11-22: production holds 3 live lenses across 3 owners, each
 * owner holding exactly one. That is why the first case below is written the
 * way it is — under today's data the ONLY deletion any current owner can make
 * is a single-lens deletion, so if a single deletion fired, this check would be
 * red on every ordinary use and would be ignored by the end of the week.
 */

/**
 * Shorthand so each case reads as its claim and not as object literals.
 *
 * 🔴 `acked` DEFAULTS TO FALSE AND IS THE SEVENTH ARGUMENT FOR A REASON. The
 * finders see EVERY removal in the window, acknowledged or not, because
 * acknowledgement governs what ALERTS and never what is COUNTED. See the block
 * above `findMultiDeleteOwners` in the script.
 */
const row = (
  id: string,
  owner_id: string,
  lens_key: string,
  op: 'soft_delete' | 'hard_delete',
  created_at: string,
  owner_exists: boolean,
  acked = false,
) => ({ id, owner_id, lens_key, op, created_at, owner_exists, acked });

describe('findMultiDeleteOwners', () => {
  it('is silent when an owner removed exactly one lens', () => {
    // Both — all three, as of 2026-11-22 — current owners hold exactly one lens.
    // The only deletion either can make must not fire.
    const rows = [row('h1', 'owner-a', 'my-lens', 'soft_delete', '2026-11-20T10:00:00Z', true)];
    expect(findMultiDeleteOwners(rows)).toEqual([]);
  });

  it('fires when one owner removed two different lenses', () => {
    const rows = [
      row('h1', 'owner-a', 'lens-one', 'soft_delete', '2026-11-20T10:00:00Z', true),
      row('h2', 'owner-a', 'lens-two', 'soft_delete', '2026-11-20T10:00:01Z', true),
    ];
    const found = findMultiDeleteOwners(rows);
    expect(found).toHaveLength(1);
    expect(found[0].ownerId).toBe('owner-a');
    // Both keys and both history ids, because the failure message has to answer
    // "what did we lose and whose was it" without a follow-up query.
    expect(found[0].keys).toEqual(['lens-one', 'lens-two']);
    expect(found[0].ids).toEqual(['h1', 'h2']);
    expect(found[0].firstAt).toBe('2026-11-20T10:00:00Z');
    expect(found[0].lastAt).toBe('2026-11-20T10:00:01Z');
    // Nothing is acked yet, so everything still needs acking.
    expect(found[0].unackedIds).toEqual(['h1', 'h2']);
  });

  it('still fires when one of the two removals is already acknowledged', () => {
    // 🔴 THE CASE THAT MADE THE ACK A FLAG RATHER THAN A WHERE CLAUSE. An owner
    // holds two lenses and deletes one on Monday; an operator acks it as
    // ordinary tidying. On Thursday a bug soft-deletes the second. If the ack
    // removed Monday's row from the GROUPING set, Thursday's run would see one
    // row, one distinct key, and report green — while that owner lost both
    // lenses inside the same window. That is the exact shape this condition
    // exists to catch, and nothing else in the script could tell it apart from
    // the benign case.
    const rows = [
      row('mon', 'owner-a', 'lens-one', 'soft_delete', '2026-11-16T10:00:00Z', true, true),
      row('thu', 'owner-a', 'lens-two', 'soft_delete', '2026-11-19T10:00:00Z', true, false),
    ];
    const found = findMultiDeleteOwners(rows);
    expect(found).toHaveLength(1);
    // The WHOLE group is reported, acked row included. Monday is the context
    // that makes Thursday alarming, so hiding it would be hiding the finding.
    expect(found[0].keys).toEqual(['lens-one', 'lens-two']);
    expect(found[0].ids).toEqual(['mon', 'thu']);
    expect(found[0].firstAt).toBe('2026-11-16T10:00:00Z');
    // ...but only the unacked row is offered to the ack command, because acking
    // an already-acked id is refused and would make the printed line fail.
    expect(found[0].unackedIds).toEqual(['thu']);
  });

  it('is silent when every removal in the group is acknowledged', () => {
    // A human has looked at both and said so. This is what stops one reviewed
    // incident holding the nightly red for seven consecutive mornings.
    const rows = [
      row('h1', 'owner-a', 'lens-one', 'soft_delete', '2026-11-16T10:00:00Z', true, true),
      row('h2', 'owner-a', 'lens-two', 'soft_delete', '2026-11-19T10:00:00Z', true, true),
    ];
    expect(findMultiDeleteOwners(rows)).toEqual([]);
  });

  it('counts a soft_delete and the cascade hard_delete of the SAME key once', () => {
    // Two history rows, one lens. A soft delete later purged is ONE lens leaving,
    // not two, and counting rows instead of keys would make every purge look like
    // a destruction event.
    const rows = [
      row('h1', 'owner-a', 'same-lens', 'soft_delete', '2026-11-20T10:00:00Z', true),
      row('h2', 'owner-a', 'same-lens', 'hard_delete', '2026-11-21T10:00:00Z', true),
    ];
    expect(findMultiDeleteOwners(rows)).toEqual([]);
  });

  it('ignores an owner whose account no longer exists', () => {
    // owner_exists: false — that is condition 2's business, and an account
    // deletion legitimately removes every lens the account held at once.
    const rows = [
      row('h1', 'gone', 'lens-one', 'hard_delete', '2026-11-20T10:00:00Z', false),
      row('h2', 'gone', 'lens-two', 'hard_delete', '2026-11-20T10:00:00Z', false),
      row('h3', 'gone', 'lens-three', 'hard_delete', '2026-11-20T10:00:00Z', false),
    ];
    expect(findMultiDeleteOwners(rows)).toEqual([]);
  });

  it('does not group two different owners together', () => {
    // One removal each. Two people each tidying up one lens on the same evening
    // is ordinary use; if that fired, the check would be red most weeks.
    const rows = [
      row('h1', 'owner-a', 'lens-one', 'soft_delete', '2026-11-20T10:00:00Z', true),
      row('h2', 'owner-b', 'lens-two', 'soft_delete', '2026-11-20T10:00:05Z', true),
    ];
    expect(findMultiDeleteOwners(rows)).toEqual([]);
  });
});

describe('findOrphanHardDeletes', () => {
  it('fires on a hard_delete whose owner still exists', () => {
    // The only legitimate hard delete is the account-deletion cascade. A row
    // that left the table while its owner is still here left it some other way:
    // a hand-written DELETE, a migration, or a path nobody has thought of yet.
    const rows = [row('h1', 'owner-a', 'lens-one', 'hard_delete', '2026-11-20T10:00:00Z', true)];
    expect(findOrphanHardDeletes(rows)).toEqual([rows[0]]);
  });

  it('is silent on a hard_delete whose owner is gone', () => {
    // The cascade. Sanctioned, expected, and the reason this condition needs the
    // join on public.users at all.
    const rows = [row('h1', 'gone', 'lens-one', 'hard_delete', '2026-11-20T10:00:00Z', false)];
    expect(findOrphanHardDeletes(rows)).toEqual([]);
  });

  it('is silent on a soft_delete', () => {
    // That is the sanctioned path, and it is recoverable, which is the whole
    // point of having made deletion reversible.
    const rows = [row('h1', 'owner-a', 'lens-one', 'soft_delete', '2026-11-20T10:00:00Z', true)];
    expect(findOrphanHardDeletes(rows)).toEqual([]);
  });

  it('is silent on a hard_delete that has been acknowledged', () => {
    // Unlike condition 1, there is no group here and so no context to preserve:
    // one row, one judgement, and a human has made it.
    const rows = [row('h1', 'owner-a', 'lens-one', 'hard_delete', '2026-11-20T10:00:00Z', true, true)];
    expect(findOrphanHardDeletes(rows)).toEqual([]);
  });
});

describe('parseAckArgs', () => {
  it('takes the space-separated note', () => {
    expect(parseAckArgs(['h1', '--note', 'a bug ate it'])).toEqual({
      ids: ['h1'], note: 'a bug ate it', error: null,
    });
  });

  it('takes the equals-separated note too', () => {
    // 🔴 THE REGRESSION. This spelling used to fall through the generic
    // "skip anything starting with --" branch: the ack was still written, the
    // operator was told "acked 1", and the reason they typed was gone. The
    // entire value of an acknowledgement is the name and the reason on it.
    expect(parseAckArgs(['h1', '--note=a bug ate it'])).toEqual({
      ids: ['h1'], note: 'a bug ate it', error: null,
    });
  });

  it('takes several ids with the note in any position', () => {
    expect(parseAckArgs(['--note=why', 'h1', 'h2', 'h3'])).toEqual({
      ids: ['h1', 'h2', 'h3'], note: 'why', error: null,
    });
  });

  it('allows no note at all', () => {
    expect(parseAckArgs(['h1'])).toEqual({ ids: ['h1'], note: null, error: null });
  });

  it('refuses a flag it does not understand rather than ignoring it', () => {
    // Ignoring it is how the --note= bug happened in the first place.
    const r = parseAckArgs(['h1', '--force']);
    expect(r.ids).toEqual([]);
    expect(r.error).toContain('--force');
  });

  it('refuses a trailing --note with no value', () => {
    // 🔴 A further spelling of the same defect: note stayed null and the ack was
    // written with no reason at all.
    const r = parseAckArgs(['h1', '--note']);
    expect(r.ids).toEqual([]);
    expect(r.error).toContain('no text');
  });

  it('refuses --note followed by another flag rather than eating it as the note', () => {
    const r = parseAckArgs(['h1', '--note', '--force']);
    expect(r.ids).toEqual([]);
    expect(r.note).toBeNull();
    expect(r.error).toContain('no text');
  });

  it('refuses an empty note', () => {
    expect(parseAckArgs(['h1', '--note=']).error).toContain('no text');
  });
});
