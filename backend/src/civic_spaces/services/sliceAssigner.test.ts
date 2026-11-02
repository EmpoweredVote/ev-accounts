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
  upsertSliceMember,
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
  beforeEach(() => {
    // 🔴 Braces, not an expression body. mockReset() returns the mock, and vitest treats
    // whatever a beforeEach returns as a cleanup function — so the arrow-expression form
    // hands vitest the mock itself and it gets CALLED, with no arguments, after every test.
    // Harmless while the mock had a blanket mockResolvedValue; a router that throws on an
    // unrouted query reports it as a query for `undefined`.
    queryMock.mockReset()
  })

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
  beforeEach(() => {
    // 🔴 Braces, not an expression body. mockReset() returns the mock, and vitest treats
    // whatever a beforeEach returns as a cleanup function — so the arrow-expression form
    // hands vitest the mock itself and it gets CALLED, with no arguments, after every test.
    // Harmless while the mock had a blanket mockResolvedValue; a router that throws on an
    // unrouted query reports it as a query for `undefined`.
    queryMock.mockReset()
  })

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

describe('a full frontier slice splits rather than opening an empty one', () => {
  beforeEach(() => {
    // 🔴 Braces, not an expression body. mockReset() returns the mock, and vitest treats
    // whatever a beforeEach returns as a cleanup function — so the arrow-expression form
    // hands vitest the mock itself and it gets CALLED, with no arguments, after every test.
    // Harmless while the mock had a blanket mockResolvedValue; a router that throws on an
    // unrouted query reports it as a query for `undefined`.
    queryMock.mockReset()
  })

  /**
   * Route by SQL text rather than by call order, and throw on anything unrouted — a mock
   * that returns a default for a query the test never modelled will happily prove whatever
   * the test hoped for.
   */
  function route(handlers: Array<[RegExp, (params: unknown[]) => unknown]>) {
    queryMock.mockImplementation(async (sql: string, params: unknown[] = []) => {
      for (const [re, fn] of handlers) if (re.test(sql)) return fn(params)
      throw new Error(`unrouted query in test: ${sql.replace(/\s+/g, ' ').trim()}`)
    })
  }

  const sliceFull = Object.assign(new Error('slice_full: slice is at capacity'), { code: 'P0001' })
  const rows = (r: unknown[]) => ({ rows: r })
  const slice = (i: number, n: number) => ({
    id: `slice-${i}`,
    sibling_index: i,
    current_member_count: n,
  })

  const calls = (re: RegExp) => queryMock.mock.calls.filter((c) => re.test(c[0] as string))

  /** city/4858016 with both open slices at the cap; the frontier is slice-2. */
  function fullJurisdiction() {
    const state = { split: false }
    let joins = 0
    route([
      [
        /INSERT INTO slice_members/,
        () => {
          joins += 1
          // The first attempt lands on the slice placement picked before it filled.
          if (joins === 1) throw sliceFull
          return rows([])
        },
      ],
      [/SELECT slice_type, geoid FROM slices/, () => rows([{ slice_type: 'city', geoid: '4858016' }])],
      [/is_splittable_slice_type/, () => rows([{ splittable: true }])],
      [/ORDER BY sibling_index DESC/, () => rows([state.split ? slice(3, 3000) : slice(2, 6000)])],
      [
        /split_slice/,
        () => {
          state.split = true
          return rows([{ split_slice: 'slice-3' }])
        },
      ],
      [
        /SELECT id, sibling_index, current_member_count FROM slices/,
        () =>
          rows(
            state.split
              ? [slice(1, 6000), slice(2, 3000), slice(3, 3000)]
              : [slice(1, 6000), slice(2, 6000)]
          ),
      ],
    ])
    return state
  }

  it('S1 calls split_slice on the frontier when slice_full comes back', async () => {
    fullJurisdiction()
    await upsertSliceMember('user-1', 'slice-2')

    const split = calls(/split_slice/)
    expect(split, 'split_slice was never called').toHaveLength(1)
    expect(split[0][1]).toEqual(['slice-2'])
  })

  it('S1b calls split_slice ONCE, into a result, never inside a predicate', async () => {
    // 🔴 split_slice is VOLATILE and it mutates. Called in a WHERE clause or a join
    // condition the planner evaluates it per row, which divides the jurisdiction more than
    // once — caught in the rehearsal, where the second call was refused by the frontier
    // guard and the double-split went unreported. The engine's call must be a bare SELECT.
    fullJurisdiction()
    await upsertSliceMember('user-1', 'slice-2')

    const sql = (calls(/split_slice/)[0][0] as string).replace(/\s+/g, ' ').trim()
    expect(sql).toBe('SELECT civic_spaces.split_slice($1)')
  })

  it('S2 joins the member to the SECOND-newest slice, not the one the split returned', async () => {
    // 🔴 split_slice returns the NEW slice (slice-3), and that is not where the member
    // goes. After a split the parent is the second-newest and fills first (§4.3), so the
    // newest keeps its room for the next arrivals. Seating the member in the returned
    // slice would fill the newest first — the design exactly inverted, and invisible,
    // because both answers are a real slice in the right jurisdiction.
    fullJurisdiction()
    await upsertSliceMember('user-1', 'slice-2')

    const join = calls(/INSERT INTO slice_members/).at(-1)!
    expect(join[1]).toEqual(['user-1', 'slice-2'])
    expect((join[1] as unknown[])[1]).not.toBe('slice-3')
  })

  it('S3 inserts no slice row of its own on the slice_full path', async () => {
    // Opening the next room is the split's job now. A sibling created here would be empty.
    fullJurisdiction()
    await upsertSliceMember('user-1', 'slice-2')

    expect(calls(/INSERT INTO slices/), 'an empty sibling was created').toHaveLength(0)
  })

  it('S4 does NOT split when a closed slice fills but an open one still has room', async () => {
    // 🔴 Review Focus 1. A member seated in a closed slice by the admin override can hit
    // slice_full there while the open pair is half empty. Splitting the frontier then would
    // divide a jurisdiction that had plenty of room, on the strength of a cap reached
    // somewhere else entirely. Placement just moves on.
    let joins = 0
    route([
      [
        /INSERT INTO slice_members/,
        () => {
          joins += 1
          if (joins === 1) throw sliceFull
          return rows([])
        },
      ],
      [/SELECT slice_type, geoid FROM slices/, () => rows([{ slice_type: 'city', geoid: '4858016' }])],
      [
        /SELECT id, sibling_index, current_member_count FROM slices/,
        () => rows([slice(1, 6000), slice(2, 6000), slice(3, 2000)]),
      ],
    ])

    await upsertSliceMember('user-1', 'slice-1')

    expect(calls(/split_slice/), 'a closed slice filling triggered a split').toHaveLength(0)
    expect(calls(/INSERT INTO slice_members/).at(-1)![1]).toEqual(['user-1', 'slice-3'])
  })

  it('S5 still gives up after three retries rather than splitting forever', async () => {
    // Without the ceiling a jurisdiction that refuses every insert divides once per attempt.
    route([
      [
        /INSERT INTO slice_members/,
        () => {
          throw sliceFull
        },
      ],
      [/SELECT slice_type, geoid FROM slices/, () => rows([{ slice_type: 'city', geoid: '4858016' }])],
      [/is_splittable_slice_type/, () => rows([{ splittable: true }])],
      [/ORDER BY sibling_index DESC/, () => rows([slice(2, 6000)])],
      [/split_slice/, () => rows([{ split_slice: 'slice-3' }])],
      [
        /SELECT id, sibling_index, current_member_count FROM slices/,
        () => rows([slice(1, 6000), slice(2, 3000)]),
      ],
    ])

    await expect(upsertSliceMember('user-1', 'slice-2')).rejects.toThrow(/Max retries exceeded/)
    expect(calls(/split_slice/).length).toBeLessThanOrEqual(3)
  })

  it('S6 opens a plain sibling for a type that does not split, rather than failing', async () => {
    // 🔴 `volunteer` is a role, not a place, so civic_spaces.is_splittable_slice_type says
    // no and split_slice would refuse it. The pre-split overflow path is still the right
    // answer there and must stay reachable — it is dormant, not dead.
    let joins = 0
    route([
      [
        /INSERT INTO slice_members/,
        () => {
          joins += 1
          if (joins === 1) throw sliceFull
          return rows([])
        },
      ],
      [
        /SELECT slice_type, geoid FROM slices/,
        () => rows([{ slice_type: 'volunteer', geoid: 'VOLUNTEER' }]),
      ],
      [/SELECT id, sibling_index, current_member_count FROM slices/, () => rows([slice(1, 6000)])],
      [/is_splittable_slice_type/, () => rows([{ splittable: false }])],
      [/SELECT sibling_index FROM slices/, () => rows([{ sibling_index: 1 }])],
      [/INSERT INTO slices/, () => rows([{ id: 'slice-v2' }])],
    ])

    await upsertSliceMember('user-1', 'slice-1')

    expect(calls(/split_slice/), 'volunteer was sent to split_slice').toHaveLength(0)
    expect(calls(/INSERT INTO slices/)[0][1]).toEqual(['volunteer', 'VOLUNTEER', 2])
    expect(calls(/INSERT INTO slice_members/).at(-1)![1]).toEqual(['user-1', 'slice-v2'])
  })
})

describe('the lifecycle: where members land as a jurisdiction divides (E2, E4)', () => {
  // 🔴 These two belong to the end-to-end rehearsal in civic-spaces
  // (scripts/rehearsal/19-01-split-e2e.sql), and they are here instead of there on purpose.
  // That file drives one synthetic jurisdiction through two consecutive splits and asserts
  // E1/E3/E5/E6/E7 — the split itself, the frontier rule, the seed's provenance, the count
  // invariant. E2 and E4 are the two claims in that story about WHERE THE NEXT MEMBER GOES,
  // and placement is this file's rule, not SQL's. Asserting them there would mean writing a
  // second implementation of the placement rule in SQL to check the first one against —
  // which is the duplication Task 4 exists to remove. See Ruling 1 in the 19-01 ledger.
  //
  // So the lifecycle is proven in two files. This is the half that knows about people
  // arriving; the SQL half is the one that knows about the town dividing.

  beforeEach(() => {
    queryMock.mockReset()
  })

  const slice = (i: number, n: number) => ({
    id: `slice-${i}`,
    sibling_index: i,
    current_member_count: n,
  })

  /** Answer the placement query with this picture of the jurisdiction. */
  const jurisdiction = (...rows: ReturnType<typeof slice>[]) =>
    queryMock.mockResolvedValueOnce({ rows })

  it('E2 after the first split, new members land in slice 1 — the second-newest', async () => {
    // Slice 1 reached 6000 and divided: it kept the longest-standing half and slice 2 opened
    // with the most recently joined half plus a forked window of the conversation. Both now
    // hold 3000 and both are open.
    //
    // 🔴 The newcomer goes to slice 1, the slice that just split, NOT to the new one. The
    // point of a split is to open the next room before it is needed, so the second-newest
    // fills while the newest holds its space. Sending arrivals to the new slice would fill
    // it in half the time and force the next split immediately.
    jurisdiction(slice(1, 3000), slice(2, 3000))

    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-1')
  })

  it('E4 once slice 1 refills and closes, members land in slice 2', async () => {
    // Slice 1 is back at the cap. It does NOT split again — slice 2 is newer, so slice 1
    // simply closes (that is E3, asserted in the SQL rehearsal, and it is the assertion this
    // whole phase turns on). From this side the only visible consequence is that arrivals
    // move to slice 2.
    //
    // 🔴 THIS ASSERTION PROVES NOTHING ON ITS OWN, and that is measured, not suspected: it
    // stays green with the two-newest window deleted and green again with the sort reversed.
    // Slice 2 is the only slice with room, so every candidate rule returns it. It is here to
    // keep the lifecycle readable as a story. E4b below is the step that carries the claim.
    jurisdiction(slice(1, 6000), slice(2, 3000))

    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-2')
  })

  it('E4b a closed slice that loses members does NOT reopen to new arrivals', async () => {
    // 🔴 The case the lifecycle makes real and P5 only sketches. Members leave; counts are
    // trigger-maintained and go down. Slice 1 is closed and now has room again — a query
    // that asked only "which slice has space" would start seating newcomers back in a room
    // the conversation left two splits ago, one at a time, with nobody arriving beside them.
    // Closed means closed. Room is not candidacy.
    jurisdiction(slice(1, 500), slice(2, 3000), slice(3, 3000))

    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-2')
  })

  it('E7b the open pair moves with the jurisdiction, split after split', async () => {
    // Three splits in: 1 and 2 are closed, 3 and 4 are open, and the answer walks forward
    // with them rather than staying anchored to where it started.
    jurisdiction(slice(1, 6000), slice(2, 6000), slice(3, 3000), slice(4, 3000))
    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-3')

    jurisdiction(slice(1, 6000), slice(2, 6000), slice(3, 6000), slice(4, 3000), slice(5, 3000))
    await expect(findActiveSliceForGeoid('city', '4858016')).resolves.toBe('slice-4')
  })
})
