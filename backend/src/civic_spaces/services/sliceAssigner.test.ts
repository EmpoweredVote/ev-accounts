import { describe, it, expect, vi, beforeEach } from 'vitest'

// This suite exercises only the pure taxonomy exports, but importing sliceAssigner pulls in
// config/database → lib/env, whose top-level validation calls process.exit(1) when the app's
// env vars are absent (as they are under vitest). Mock env to an empty object so the import
// chain resolves — the same convention the engine's other unit tests use (see cache.test.ts,
// tokenIdentity.test.ts). No DB connection is opened at import time.
vi.mock('../../lib/env.js', () => ({ env: {} }))

// The connected-profile guard test drives upsertConnectedProfile, which calls pool.query. Mock
// the module's pool so no real connection is opened. Hoisted so the factory can reference it.
const { queryMock } = vi.hoisted(() => ({ queryMock: vi.fn() }))
vi.mock('../config/database.js', () => ({ pool: { query: queryMock } }))

import {
  SLICE_CAPACITY,
  SLICE_ASSIGNMENTS,
  upsertConnectedProfile,
  chooseOpenSlice,
  findActiveSliceForGeoid,
} from './sliceAssigner.js'
import type { AccountData } from './accountsApi.js'

type Jurisdiction = NonNullable<AccountData['jurisdiction']>

/**
 * Plano, TX — every level present.
 *
 * The district keys are here on purpose: they are what the assigner used to key slices
 * on, so a test that only supplied the new keys could not tell a correct mapping from
 * one that silently read nothing.
 */
const PLANO = {
  congressional_district: '4832',
  state_senate_district: '48008',
  state_house_district: '48070',
  county: '48085',
  school_district: '4835100',
  city_geoid: '4858016',
  state_geoid: '48',
  nation_geoid: 'US',
} as unknown as Jurisdiction

/** Arden, NC — unincorporated, and outside any school district boundary we hold. */
const ARDEN = {
  ...PLANO,
  county: '37021',
  state_geoid: '37',
  city_geoid: null,
  school_district: null,
} as unknown as Jurisdiction

function mapOf(j: Jurisdiction): Record<string, string | null> {
  return Object.fromEntries(SLICE_ASSIGNMENTS.map((a) => [a.sliceType, a.geoid(j)]))
}

describe('slice capacity', () => {
  it('is 6000, matching the enforce_slice_cap trigger', () => {
    // Two enforcement points must agree: this constant gates which slice the service
    // hands a member, and civic_spaces.enforce_slice_cap() rejects the insert at the
    // same number. If they drift, the service hands out a slice the database refuses.
    expect(SLICE_CAPACITY).toBe(6000)
  })
})

describe('slice assignment mapping', () => {
  it('maps a member onto governments, not districts', () => {
    expect(mapOf(PLANO)).toEqual({
      federal: 'US',
      state: '48',
      county: '48085',
      city: '4858016',
    })
  })

  it('never assigns on a congressional or legislative district', () => {
    // The defect this whole change exists to fix: `federal` was keyed on the member's
    // congressional district and `state` on their state senate district, so two
    // neighbours on opposite sides of a district line could not talk to each other
    // about the state they both live in.
    const geoids = Object.values(mapOf(PLANO))
    expect(geoids).not.toContain('4832')
    expect(geoids).not.toContain('48008')
    expect(geoids).not.toContain('48070')
    expect(geoids).not.toContain('4835100')
  })

  it('yields null for a level the jurisdiction lacks, rather than throwing', () => {
    // Arden, NC is unincorporated: no G4110 place covers it. Four spaces, not a crash.
    expect(mapOf(ARDEN).city).toBeNull()
    expect(mapOf(ARDEN).county).toBe('37021')
  })

  it('reads the geoid keys, not the geocoded name keys that sit beside them', () => {
    // 🔴 /api/account/me carries BOTH. `state` is the USPS code and `city` is a place
    // NAME -- 'NC' and 'ASHEVILLE' in production -- while the geoids live under
    // *_geoid. Both are truthy strings, so reading the wrong pair sails past the null
    // guard in assignUserToSlices and keys a slice on 'NC'.
    const decoy = {
      county: '37021',
      state: 'NC',
      city: 'ASHEVILLE',
      nation: 'United States',
      state_geoid: '37',
      city_geoid: '3702140',
      nation_geoid: 'US',
    } as unknown as Jurisdiction

    expect(mapOf(decoy)).toEqual({
      federal: 'US',
      state: '37',
      county: '37021',
      city: '3702140',
    })
  })
})

describe('slice assignment invariants', () => {
  it('names each slice type exactly once', () => {
    // A duplicate would assign the member twice and double-count the slice.
    const types = SLICE_ASSIGNMENTS.map((a) => a.sliceType)
    expect(new Set(types).size).toBe(types.length)
  })

  it('returns null, never throws, for a jurisdiction missing every level', () => {
    // assignUserToSlices skips a null geoid, but it can only do that if reading the key
    // produced a null instead of blowing up — a thrown accessor abandons the request
    // AFTER earlier levels were written, leaving the member with slices in the database
    // and a 500 saying it failed.
    const empty = {} as Jurisdiction

    for (const { sliceType, geoid } of SLICE_ASSIGNMENTS) {
      expect(() => geoid(empty), `${sliceType} threw on an empty jurisdiction`).not.toThrow()
      expect(geoid(empty) ?? null, `${sliceType} did not resolve to null`).toBeNull()
    }
  })

  it('reads every geoid from a distinct jurisdiction key', () => {
    // Two slice types reading the same key would silently collapse two civic spaces
    // into one.
    const read = SLICE_ASSIGNMENTS.map((a) => a.geoid(PLANO)).filter((v): v is string => !!v)
    expect(new Set(read).size).toBe(read.length)
  })
})

describe('upsertConnectedProfile display_name guard', () => {
  beforeEach(() => queryMock.mockReset())

  it('coalesces a blank name to a non-blank pseudonym', async () => {
    // The target column civic_spaces.connected_profiles.display_name is NOT NULL — a blank
    // must never reach it (watchlist #70).
    queryMock.mockResolvedValue({ rows: [] })
    await upsertConnectedProfile('user-123', '   ', 'active')
    const params = queryMock.mock.calls[0][1] as unknown[]
    expect(params[1]).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/) // deterministic AdjectiveAnimal
  })

  it('passes a real name through unchanged', async () => {
    queryMock.mockResolvedValue({ rows: [] })
    await upsertConnectedProfile('user-123', 'Explorer', 'active')
    const params = queryMock.mock.calls[0][1] as unknown[]
    expect(params[1]).toBe('Explorer')
  })
})

describe('placement: only the two newest slices are open (design §4.3)', () => {
  // 🔴 These assert against chooseOpenSlice, a PURE function, not against SQL through a
  // mocked pool. The rule used to live in a WHERE clause, and a mocked pool.query cannot
  // test a WHERE clause — the mock returns whatever the test hands it, so "picks slice 3"
  // would pass against any query text at all, including today's wrong one. Moving the
  // decision into TypeScript is what makes it provable; see the ruling in the 19-01 ledger.

  const row = (i: number, n: number) => ({
    id: `slice-${i}`,
    sibling_index: i,
    current_member_count: n,
  })

  it('P1 fills the SECOND-newest first, not the oldest with room', () => {
    // 1 and 2 are closed. 3 and 4 are open; 3 is the second-newest, so it fills first.
    expect(chooseOpenSlice([row(1, 6000), row(2, 6000), row(3, 3000), row(4, 3000)])).toBe('slice-3')
  })

  it('P2 moves on to the newest once the second-newest is full', () => {
    expect(chooseOpenSlice([row(1, 6000), row(2, 6000), row(3, 6000), row(4, 3000)])).toBe('slice-4')
  })

  it('P3 places into the only slice there is', () => {
    // A jurisdiction with one slice has no second-newest. max - 1 must not exclude it.
    expect(chooseOpenSlice([row(1, 3000)])).toBe('slice-1')
  })

  it('P5 does NOT place into an old slice that still has room', () => {
    // 🔴 The regression test. Slice 1 is half empty and today's `ORDER BY sibling_index ASC`
    // over the whole set chooses it — which is the entire behaviour this change removes.
    // A member placed there joins a closed room: the conversation has moved on, and the
    // two open slices are where everyone else is being put. P1-P4 all pass without this.
    expect(chooseOpenSlice([row(1, 500), row(2, 6000), row(3, 3000)])).toBe('slice-3')
  })

  it('returns none when both open slices are full, regardless of older room', () => {
    expect(chooseOpenSlice([row(1, 500), row(2, 6000), row(3, 6000)])).toBeNull()
  })

  it('ignores a slice sitting one over the cap, rather than treating it as room', () => {
    // current_member_count is trigger-maintained and can drift. `< CAPACITY`, never `!=`.
    expect(chooseOpenSlice([row(1, 6001), row(2, 6000)])).toBeNull()
  })
})

describe('placement: what findActiveSliceForGeoid does with the chooser', () => {
  beforeEach(() => queryMock.mockReset())

  const sliceRows = (rows: Array<[number, number]>) => ({
    rows: rows.map(([i, n]) => ({ id: `slice-${i}`, sibling_index: i, current_member_count: n })),
  })

  it('P4 creates sibling_index 1 when the jurisdiction has no slice at all', async () => {
    queryMock.mockResolvedValueOnce(sliceRows([]))
    queryMock.mockResolvedValueOnce({ rows: [{ id: 'slice-new' }] })

    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-new')

    const insert = queryMock.mock.calls.find((c) => /INSERT INTO slices/.test(c[0] as string))
    expect(insert, 'no INSERT was issued for an empty jurisdiction').toBeDefined()
    expect((insert as unknown[])[1]).toEqual(['city', '4858016', 1])
  })

  it('P6 returns null when both open slices are full, and creates nothing', async () => {
    // 🔴 The whole point of Task 4. The old code reached findOrCreateSiblingSlice here and
    // opened an EMPTY slice — a room with a cap's worth of neighbours next door and nobody
    // in it. Opening the next room is now the split's job, and a split carries people and a
    // conversation with it. This function's only remaining answer is "nowhere open".
    queryMock.mockResolvedValueOnce(sliceRows([[1, 6000], [2, 6000]]))

    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBeNull()

    const inserts = queryMock.mock.calls.filter((c) => /INSERT INTO slices/.test(c[0] as string))
    expect(inserts, 'an empty sibling was created').toHaveLength(0)
  })

  it('reads every slice for the jurisdiction, not just the ones with room', async () => {
    // The restriction is "the two highest sibling_index values", which cannot be computed
    // from a set already filtered by current_member_count — the newest slice is often the
    // full one, and filtering it out first silently shifts the window down.
    queryMock.mockResolvedValueOnce(sliceRows([[1, 6000], [2, 3000]]))

    await findActiveSliceForGeoid('city', '4858016')

    const sql = queryMock.mock.calls[0][0] as string
    expect(sql).not.toMatch(/current_member_count\s*</)
  })
})
