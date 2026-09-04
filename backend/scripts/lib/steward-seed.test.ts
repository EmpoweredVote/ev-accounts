import { describe, it, expect } from 'vitest';
import { slotsToSeed, HISTORICAL_HOLDER } from './steward-seed.mjs';

// Seeding runs more than once: the design has `steward sync` re-scan git and
// reconcile. So the interesting behaviour is not "insert 1,851 rows" — it is what
// happens on the SECOND run, when the table already holds rows and some of them are
// LIVE RESERVATIONS someone is relying on.
//
// 🔴 A re-seed that overwrote a live reservation would be worse than no steward at
// all: it would silently hand a number to two people while telling both it was theirs.

const hist = (namespace: string, num: number, filename: string) =>
  ({ namespace, num, key: namespace ? `${namespace}_${num}` : String(num), filename, refs: ['master'] });

describe('slotsToSeed', () => {
  it('returns every historical slot when the table is empty', () => {
    const rows = slotsToSeed([hist('CC', 1, 'CC_0001_a.sql'), hist('', 47, '047_b.sql')], []);
    expect(rows).toHaveLength(2);
  });

  it('marks seeded rows as written and attributes them to history, not a person', () => {
    const [row] = slotsToSeed([hist('CC', 1, 'CC_0001_a.sql')], []);
    expect(row.state).toBe('written');
    expect(row.claimed_by).toBe(HISTORICAL_HOLDER);
  });

  it('carries the filename through, so a seeded row says what occupies the slot', () => {
    const [row] = slotsToSeed([hist('CC', 1, 'CC_0001_a.sql')], []);
    expect(row.filename).toBe('CC_0001_a.sql');
  });

  it('skips a slot the table already holds, so re-running adds nothing', () => {
    const all = [hist('CC', 1, 'CC_0001_a.sql'), hist('CC', 2, 'CC_0002_b.sql')];
    expect(slotsToSeed(all, [{ namespace: 'CC', num: 1 }, { namespace: 'CC', num: 2 }])).toHaveLength(0);
  });

  it('adds only the slots that appeared since the last run', () => {
    const all = [hist('CC', 1, 'CC_0001_a.sql'), hist('CC', 2, 'CC_0002_b.sql')];
    const rows = slotsToSeed(all, [{ namespace: 'CC', num: 1 }]);
    expect(rows.map((r) => r.num)).toEqual([2]);
  });

  it('🔴 never re-seeds a slot someone has reserved, whatever its state', () => {
    // CC_2 is reserved by a live session and has no file yet. It must survive untouched.
    const rows = slotsToSeed([hist('CC', 2, 'CC_0002_b.sql')], [{ namespace: 'CC', num: 2 }]);
    expect(rows).toHaveLength(0);
  });

  it('treats the bare namespace as its own space, so 1500 and CA_1500 both seed', () => {
    const rows = slotsToSeed([hist('', 1500, '1500_a.sql'), hist('CA', 1500, 'CA_1500_b.sql')], []);
    expect(rows).toHaveLength(2);
  });
});
