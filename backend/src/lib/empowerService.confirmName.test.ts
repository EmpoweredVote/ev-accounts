import { describe, it, expect, vi, beforeEach } from 'vitest';

// empowerService.ts pulls in supabase.js, db.js and compassService.js at module scope.
// Without these mocks, supabase.js's real env validation calls process.exit(1) under
// vitest — mirrors the pattern in connect.idVault.test.ts / profile.visibility.scope.test.ts.
//
// The mock shape below matches the ACTUAL call chains in confirmEmpowerment/runPreflight:
//   - adminRpc('run_empower_preflight', {...})
//   - supabaseAdmin.schema('connect').from('connected_profiles').select(...).eq(...).single()
//   - supabaseAdmin.schema('empower').rpc('execute_empowerment', {...})
// `schema()` branches on the schema name so each chain gets its own builder, and the
// `rpc` / `single` / `adminRpc` spies are declared via vi.hoisted so the vi.mock factory
// (itself hoisted above these imports by vitest) can close over them.
const rpc = vi.hoisted(() => vi.fn());
const single = vi.hoisted(() => vi.fn());
const adminRpc = vi.hoisted(() => vi.fn());

vi.mock('./supabase.js', () => ({
  adminRpc,
  supabaseAdmin: {
    schema: (schemaName: string) => {
      if (schemaName === 'connect') {
        return {
          from: () => ({
            select: () => ({
              eq: () => ({ single }),
            }),
          }),
        };
      }
      if (schemaName === 'empower') {
        return { rpc };
      }
      throw new Error(`unexpected schema in test: ${schemaName}`);
    },
  },
}));

const cacheGet = vi.hoisted(() => vi.fn());
const cacheSet = vi.hoisted(() => vi.fn());
const cacheDel = vi.hoisted(() => vi.fn());
vi.mock('./cache.js', () => ({ cache: { get: cacheGet, set: cacheSet, del: cacheDel } }));

const poolQuery = vi.hoisted(() => vi.fn());
vi.mock('./db.js', () => ({ pool: { query: poolQuery } }));

vi.mock('./compassService.js', () => ({ getCompassCompleteness: vi.fn() }));

import { confirmEmpowerment, runPreflight } from './empowerService.js';

describe('confirmEmpowerment — confirmed name', () => {
  beforeEach(() => {
    rpc.mockReset();
    single.mockReset();
    adminRpc.mockReset();
    cacheGet.mockReset();
    cacheSet.mockReset();
    cacheDel.mockReset();
    poolQuery.mockReset();
  });

  it('prefers the confirmed name over the (null) DB value for execute_empowerment', async () => {
    cacheGet.mockResolvedValue('ada-lovelace-a3b4');
    // supabaseAdmin.schema('connect').from('connected_profiles')… returns null legal_name
    single.mockResolvedValue({ data: { id: 'cp-1', legal_name: null }, error: null });
    rpc.mockResolvedValue({ data: { id: 'ep-1' }, error: null });
    poolQuery.mockResolvedValue({ rows: [] });

    await confirmEmpowerment('user-1', ['legal_name_public'], 'Ada Lovelace');

    const call = rpc.mock.calls.find((c) => c[0] === 'execute_empowerment');
    expect(call?.[1].p_legal_name).toBe('Ada Lovelace');
  });

  it('falls back to the DB legal_name when no confirmed name is given', async () => {
    cacheGet.mockResolvedValue('grace-hopper-c9d2');
    single.mockResolvedValue({ data: { id: 'cp-2', legal_name: 'Grace Hopper' }, error: null });
    rpc.mockResolvedValue({ data: { id: 'ep-2' }, error: null });
    poolQuery.mockResolvedValue({ rows: [] });

    await confirmEmpowerment('user-2', ['legal_name_public']);

    const call = rpc.mock.calls.find((c) => c[0] === 'execute_empowerment');
    expect(call?.[1].p_legal_name).toBe('Grace Hopper');
  });

  it('falls back to the DB legal_name when the confirmed name is an empty string', async () => {
    // Regression: an unfilled form field must not defeat the DB fallback. '' is
    // truthy for `??` (only null/undefined trigger it), so without normalization
    // this would send p_legal_name: '' instead of the real DB name.
    cacheGet.mockResolvedValue('grace-hopper-c9d2');
    single.mockResolvedValue({ data: { id: 'cp-3', legal_name: 'Grace Hopper' }, error: null });
    rpc.mockResolvedValue({ data: { id: 'ep-3' }, error: null });
    poolQuery.mockResolvedValue({ rows: [] });

    await confirmEmpowerment('user-3', ['legal_name_public'], '');

    const call = rpc.mock.calls.find((c) => c[0] === 'execute_empowerment');
    expect(call?.[1].p_legal_name).toBe('Grace Hopper');
  });
});

describe('runPreflight — confirmed name', () => {
  beforeEach(() => {
    rpc.mockReset();
    single.mockReset();
    adminRpc.mockReset();
    cacheGet.mockReset();
    cacheSet.mockReset();
    cacheDel.mockReset();
    poolQuery.mockReset();
  });

  it('falls back to the DB legal_name when the confirmed name is an empty string', async () => {
    // Regression: an empty confirmed name must not reach reserveSlug/summary as
    // '' — it must fall through to the DB legal_name, same as null/undefined.
    adminRpc.mockResolvedValue({
      data: {
        eligible: true,
        connected_profile: { legal_name: 'Grace Hopper', candidate_role: 'city_council' },
        empowered_profile: null,
        compass_completeness: { required: 5, answered: 5, percent: 100, complete: true },
        is_demoted: false,
      },
      error: null,
    });
    cacheSet.mockResolvedValue(undefined);

    const result = await runPreflight('user-4', '');

    expect(result.eligible).toBe(true);
    if (result.eligible) {
      expect(result.summary.legal_name).toBe('Grace Hopper');
      // The slug is generated from the name that fed it — an empty confirmed
      // name must not have produced a malformed (e.g. leading-hyphen) slug.
      expect(result.summary.slug_preview.startsWith('grace-hopper-')).toBe(true);
    }
  });
});
