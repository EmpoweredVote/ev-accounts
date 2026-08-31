import { vi, describe, it, expect, beforeEach } from 'vitest';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

/**
 * Records the filters each guard applies, so the test can assert on the QUERY
 * rather than on a stubbed answer. What matters here is that both guards ask the
 * same question of the same table — a stubbed row cannot show that.
 */
const calls = vi.hoisted(() => [] as Array<{ table: string; filters: string[] }>);

const makeBuilder = vi.hoisted(() => (calls: Array<{ table: string; filters: string[] }>) => {
  return (table: string, result: { data: unknown; error: unknown }) => {
    const record = { table, filters: [] as string[] };
    calls.push(record);
    const builder: Record<string, unknown> = {};
    builder.select = () => builder;
    builder.eq = (col: string) => { record.filters.push(`eq:${col}`); return builder; };
    builder.is = (col: string, val: unknown) => {
      record.filters.push(`is:${col}=${String(val)}`);
      return builder;
    };
    builder.maybeSingle = async () => result;
    return builder;
  };
});

const rowResult = vi.hoisted(() => ({ current: { data: null as unknown, error: null as unknown } }));

vi.mock('../lib/supabase.js', () => ({
  supabaseAdmin: {
    schema: () => ({
      from: (table: string) => makeBuilder(calls)(table, rowResult.current),
    }),
  },
}));

import { requireConnected, requireInform } from './tierGuards.js';

function res() {
  const out: { code?: number; body?: unknown } = {};
  return {
    status(c: number) { out.code = c; return this; },
    json(b: unknown) { out.body = b; return this; },
    out,
  } as never as { status: (c: number) => unknown; json: (b: unknown) => unknown; out: typeof out };
}

const req = { userId: 'user-1' } as never;

beforeEach(() => {
  calls.length = 0;
  rowResult.current = { data: null, error: null };
});

/**
 * WHY THIS FILE EXISTS.
 *
 * requireInform passes when the connected_profiles row is ABSENT; requireConnected
 * passes when it is PRESENT and verified. They are two halves of one question, so
 * any condition one of them counts and the other ignores produces a user BOTH
 * refuse — a limbo with no exit.
 *
 * The product has already shipped that state once: admin promotion inserted
 * verification_status='pending', which failed requireConnected while the row's
 * existence failed requireInform, locking the user out of 17 routes in social.ts
 * and 8 in empower.ts (fixed in migration 1851). deleted_at was the same trap
 * waiting to happen — neither guard filtered it.
 */
describe('tier guards agree about deleted_at', () => {
  it('requireConnected ignores a soft-deleted profile', async () => {
    rowResult.current = { data: null, error: null };
    const r = res();
    await requireConnected(req, r as never, () => {});

    const q = calls.find((c) => c.table === 'connected_profiles');
    expect(q?.filters).toContain('is:deleted_at=null');
  });

  it('requireInform ignores a soft-deleted profile', async () => {
    rowResult.current = { data: null, error: null };
    let passed = false;
    await requireInform(req, res() as never, () => { passed = true; });

    const q = calls.find((c) => c.table === 'connected_profiles');
    expect(q?.filters).toContain('is:deleted_at=null');
    // No live row => Inform. A soft-deleted Connected profile must return the
    // user to Inform, not strand them between tiers.
    expect(passed).toBe(true);
  });

  it('🔴 both guards filter the SAME columns, so neither can strand a user', async () => {
    await requireConnected(req, res() as never, () => {});
    const connectedFilters = [...(calls.find((c) => c.table === 'connected_profiles')?.filters ?? [])];

    calls.length = 0;
    await requireInform(req, res() as never, () => {});
    const informFilters = [...(calls.find((c) => c.table === 'connected_profiles')?.filters ?? [])];

    // If these ever diverge, some row satisfies one guard's idea of "exists" and
    // not the other's — and the user in that state is refused by both.
    expect(informFilters.sort()).toEqual(connectedFilters.sort());
  });

  it('requireConnected still refuses a live but unverified profile', async () => {
    // The 'pending' limbo itself: present, not verified. Still a 403 — this guard
    // is not what migration 1851 changed.
    rowResult.current = { data: { id: 'p1', verification_status: 'pending' }, error: null };
    const r = res();
    let passed = false;
    await requireConnected(req, r as never, () => { passed = true; });

    expect(passed).toBe(false);
    expect(r.out.code).toBe(403);
  });

  it('requireInform refuses a live Connected profile — it is exclusive, not a floor', async () => {
    rowResult.current = { data: { id: 'p1' }, error: null };
    const r = res();
    let passed = false;
    await requireInform(req, r as never, () => { passed = true; });

    expect(passed).toBe(false);
    expect(r.out.code).toBe(403);
  });
});
