import { describe, it, expect } from 'vitest';
import {
  ENFORCED_ABOVE, holdersMatch, classifyReservation, HISTORICAL_HOLDER,
} from './migration-reservations.mjs';

// The allocator makes double allocation impossible, but only for people who ASK it. This is the
// half that makes asking compulsory: a number taken by hand is invisible to the table, so the
// next `steward slot` call hands it out again — the 1681 collision, rebuilt on top of the fix.
//
// 🔴 THE ROLLOUT SEQUENCE IS THE WHOLE RISK HERE. "Fail on an unreserved slot" would red-wall
//    every branch already in flight, which is why the design made it a warning first. It is
//    made safe by a per-namespace GRANDFATHER CEILING instead of by a date: at or below the
//    seeded ceiling a slot predates the allocator and needs no row; above it, you asked.

const row = (over: Record<string, unknown> = {}) =>
  ({ namespace: 'CC', num: 73, state: 'reserved', claimed_by: 'chris@empowered.vote',
     purpose: 'a thing', branch: 'feat/x', filename: null, ...over });

const call = (over: Record<string, unknown> = {}) => classifyReservation({
  slot: { ns: 'CC', num: '73', key: 'CC_73' },
  filename: 'CC_0073_a_thing.sql',
  author: 'chris@empowered.vote',
  row: row(),
  ...over,
});

describe('holdersMatch', () => {
  it('matches the same address whatever the case or spacing', () => {
    expect(holdersMatch('Chris@Empowered.Vote', ' chris@empowered.vote ')).toBe(true);
  });

  it('does not match two different people', () => {
    expect(holdersMatch('chris@empowered.vote', 'someone@else.org')).toBe(false);
  });

  // 🔴 THIS IS THE FALSE-FAILURE THE CHECK WOULD OTHERWISE SHIP WITH. A reservation records
  //    `git config user.email`, but the COMMIT this runs against in CI can carry GitHub's
  //    noreply form of the same person: 171 migration commits in this repo are authored by
  //    `34817036+chrisandrewsedu@users.noreply.github.com`. Comparing those two strings says
  //    "reserved by someone else" about a slot its own holder is committing.
  it('recognises GitHub noreply as the same person as their ordinary address', () => {
    expect(holdersMatch('34817036+chrisandrewsedu@users.noreply.github.com',
      'chrisandrewsedu@gmail.com')).toBe(true);
    expect(holdersMatch('chrisandrewsedu@users.noreply.github.com',
      'chrisandrewsedu@empowered.vote')).toBe(true);
  });

  // The relaxation is bounded to the noreply domain. Matching local parts generally would make
  // chris@empowered.vote and chris@example.com the same person, which they are not.
  it('does not match local parts when neither side is a noreply address', () => {
    expect(holdersMatch('chris@empowered.vote', 'chris@example.com')).toBe(false);
  });

  it('treats a missing holder as nobody, not as a wildcard', () => {
    expect(holdersMatch(null, 'chris@empowered.vote')).toBe(false);
    expect(holdersMatch('', '')).toBe(false);
  });
});

describe('classifyReservation', () => {
  it('passes a slot reserved by the author committing it', () => {
    const v = call();
    expect(v.verdict).toBe('yours');
    expect(v.ok).toBe(true);
  });

  it('passes a slot of yours that sync has already marked written', () => {
    expect(call({ row: row({ state: 'written', filename: 'CC_0073_a_thing.sql' }) }).ok).toBe(true);
  });

  it('fails a slot reserved by somebody else — the collision, caught before merge', () => {
    const v = call({ row: row({ claimed_by: 'someone@else.org' }) });
    expect(v.ok).toBe(false);
    expect(v.verdict).toBe('other-holder');
    expect(v.message).toMatch(/someone@else\.org/);
  });

  it('names both addresses when it fails, so a wrong identity is diagnosable', () => {
    const v = call({ row: row({ claimed_by: 'someone@else.org' }) });
    expect(v.message).toMatch(/chris@empowered\.vote/);
  });

  // A seeded row means the number is already spent on history. The ref scan catches this too,
  // and that redundancy is the point: the allocator is one detector, the scan is the other.
  it('fails a slot that history already holds', () => {
    const v = call({ row: row({ state: 'written', claimed_by: HISTORICAL_HOLDER }) });
    expect(v.ok).toBe(false);
    expect(v.verdict).toBe('historical');
  });

  // Reserving a number and not using it is explicitly harmless — CLAUDE.md says holes cost
  // nothing. Re-using an abandoned one is not, because the reason it was abandoned is not
  // recorded anywhere the next reader will look, and a fresh number is one command away.
  it('fails a slot that was abandoned rather than quietly reviving it', () => {
    const v = call({ row: row({ state: 'abandoned' }) });
    expect(v.ok).toBe(false);
    expect(v.verdict).toBe('abandoned');
  });

  describe('when the slot has no row at all', () => {
    it('fails above the grandfather ceiling — you took a number without asking', () => {
      const v = call({ row: null, slot: { ns: 'CC', num: '90', key: 'CC_90' } });
      expect(v.ok).toBe(false);
      expect(v.verdict).toBe('unreserved');
      expect(v.message).toMatch(/steward .* -- slot CC/);
    });

    it('passes at or below the ceiling — that slot predates the allocator', () => {
      const v = call({ row: null, slot: { ns: 'CC', num: '40', key: 'CC_40' } });
      expect(v.ok).toBe(true);
      expect(v.verdict).toBe('legacy');
    });

    it('treats the ceiling itself as legacy, not as the first enforced number', () => {
      const at = ENFORCED_ABOVE.CC;
      expect(call({ row: null, slot: { ns: 'CC', num: String(at), key: `CC_${at}` } }).ok).toBe(true);
      expect(call({ row: null, slot: { ns: 'CC', num: String(at + 1), key: `CC_${at + 1}` } }).ok).toBe(false);
    });

    // 🔴 A NAMESPACE NOBODY HAS SEEDED IS ENFORCED FROM ZERO. Defaulting an unknown namespace
    //    to "no ceiling, everything legacy" would make inventing a prefix the way around the
    //    allocator, and the whole check would be one filename rename away from silence.
    it('enforces an unknown namespace from its first number', () => {
      const v = call({ row: null, slot: { ns: 'ZZ', num: '1', key: 'ZZ_1' } });
      expect(v.ok).toBe(false);
      expect(v.verdict).toBe('unreserved');
    });

    it('enforces the shared plain sequence above its ceiling too', () => {
      const at = ENFORCED_ABOVE[''];
      expect(call({ row: null, slot: { ns: '', num: String(at), key: String(at) } }).ok).toBe(true);
      expect(call({ row: null, slot: { ns: '', num: String(at + 1), key: String(at + 1) } }).ok).toBe(false);
    });
  });

  it('tells the shared sequence to ask for a shared slot, not for a namespace', () => {
    const v = call({ row: null, slot: { ns: '', num: '9999', key: '9999' } });
    expect(v.message).toMatch(/-- slot shared/);
  });
});

describe('ENFORCED_ABOVE', () => {
  // These are measurements, not preferences. They are the max slot per namespace at the moment
  // the seed ran, which is also the point above which every number came from the allocator.
  it('records a ceiling for every namespace the seed found', () => {
    expect(Object.keys(ENFORCED_ABOVE).sort()).toEqual(['', 'CA', 'CC']);
  });
});
