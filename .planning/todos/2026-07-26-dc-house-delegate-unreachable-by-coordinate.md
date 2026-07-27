# DC's House delegate is unreachable by coordinate

**Found:** 2026-07-26, while diagnosing the `essentials.office_current_holder` port (a `1198`
zero-office district turned up in the ported holder-invariant sweep).
**Status:** diagnosed, NOT fixed — the fix is a judgment call, see Options.
**Severity:** user-facing gap for every DC resident. Read-only diagnosis; no writes made.

## What's wrong

DC has **two parallel `NATIONAL_LOWER` district rows**, and the polygon is on one while the
offices are on the other:

| district `geo_id` | mtfcc | polygon | offices |
|---|---|---|---|
| `1198` | `G5200` | ✅ full District, 177 km² | **0** |
| `dc-national-lower` | — | **none** | 3 — all with current holders |

The three offices on `dc-national-lower` are `Delegate, District of Columbia`
(Eleanor Holmes Norton), `U.S. Shadow Senator (Senior)` (Paul Strauss) and
`U.S. Shadow Senator (Junior)` (Ankit Jain).

A DC coordinate `ST_Covers`-resolves to `1198`, which has no office. Norton is seated and
correct in the database — she is simply not reachable from a point.

## All three lookup paths miss

Verified against `backend/src/lib/essentialsService.ts` and `essentialsBrowseService.ts`:

1. **Primary district-join** — coordinate → geofence → district `1198` → 0 offices.
2. **Single-House-rep fallback** (`findCoveringCdGeoId`, `essentialsService.ts:1106`) — resolves
   `G5200` covering geo_id, which is `1198`, then `getPoliticiansByArea('1198','G5200')` → 0 offices.
3. **Statewide floor** (`getStatewideOfficials`, `essentialsBrowseService.ts:984`) — its WHERE
   clause is `d.district_type IN ('NATIONAL_UPPER','STATE_EXEC','NATIONAL_EXEC','NATIONAL_JUDICIAL')`.
   **`NATIONAL_LOWER` is excluded**, so the Delegate cannot come through here either.

So `getRepresentativesByCoordinate` returns no House representative for a DC address.

## What the v2.8 docs say (checked 2026-07-26)

This was **not** a deliberate split. Each row was created by a different era and they were never
reconciled:

- **`1198` predates v2.8.** `105-01-SUMMARY.md:21` records it as a deviation — *"`SELECT COUNT(*) …
  WHERE state='DC'` returns 20, not 19. The extra row (`geo_id='1198'`,
  `district_type='NATIONAL_LOWER'`) is a **pre-existing Cicero-era import**, not created by
  migration 284."* The phase noticed it purely as a **row-count discrepancy** and moved on.
- **`dc-national-lower` was authored by v2.8.** Migration 287 (`105-02-SUMMARY.md:19`) seeded
  Norton, Strauss and Jain onto it, and the roadmap success criterion (`v2.8-ROADMAP.md:1072`)
  asked for *"1 NATIONAL_LOWER row for the EHN at-large delegate seat — all FK'd to the DC
  government."*
- **The coordinate path was never in scope.** v2.8's geofencing goal (`:1058`) is *"DC users can be
  geofenced to their **ward**"*, and its only resolution test was
  `resolve_user_districts(38.9072,-77.0369) → dc_ward/11002/Ward 2`. NATIONAL_LOWER was never
  exercised from a point, which is why this survived.
- **USHR-05 (v2.15) did cover DC — but not by coordinate.** It required *"Path 0 returns the correct
  rep for spot-check addresses across ≥5 states (including an at-large state and DC)"* and is marked
  ✅ via `verify-phase-125-126.sql`. That gate resolves Norton through
  `d.tiger_geoid = 'dc-national-lower'` (line 135) — a **geo_id/tiger_geoid** lookup. So DC is
  reachable when you already know the slug, and unreachable from a coordinate. Both facts are true;
  they are different paths.
- **No wiring contract covers DC.** `164.1-ut-wiring-contract.md`'s NOTOUCH md5 is scoped to
  FIPS-49. Re-keying DC offices is not contract-blocked.

## Each row holds exactly half of what a working district needs

| | `1198` (Cicero-era) | `dc-national-lower` (v2.8) |
|---|---|---|
| geo_id convention | 4-char — matches **all 436** other House districts | 17-char slug — the **only** non-4-char `NATIONAL_LOWER` row in the DB |
| `mtfcc` | `G5200` (the House MTFCC every coordinate path keys on) | empty |
| geofence polygon | ✅ full District, 177 km² | ❌ none |
| FK to DC government | ❌ none | ✅ yes |
| offices | 0 | 3 (Norton + both shadow senators) |
| label | "Delegate District (at Large)" | "District of Columbia At-Large" |

The slug is also structurally invisible to every House gate in the repo: they scope with
`length(geo_id)=4` and `substr(geo_id,1,2)`, so `dc-national-lower` matches none of them.

## Options

- **A. MERGE onto `1198` (recommended).** Move the 3 offices to `1198`, set its `government_id` to
  the DC government (the one thing it lacks), retire `dc-national-lower`. Produces a single row
  holding both halves, and still satisfies v2.8's actual criterion — *one* NATIONAL_LOWER row for
  the delegate seat, FK'd to the DC government. Also brings DC onto the same 4-char/`G5200`
  convention as the other 436 districts, so it stops being invisible to House-scoped queries.
  Cost: `verify-phase-125-126.sql:135` asserts the `dc-national-lower` tiger_geoid and must be
  updated — note that gate is *already* broken (it reads the dropped occupancy column and appears in
  the `check:occupancy:all` GATE-SHAPED list), so it needs a visit regardless.
- **B. Attach a polygon to `dc-national-lower`.** Leaves offices alone, but gives DC two overlapping
  `NATIONAL_LOWER` polygons over the same ground — precisely the double-match condition 164.1-04
  documented as producing spurious two-race results in dual-map states. Also leaves the slug
  invisible to House-scoped gates.
- **C. Add a shadow-seat branch to the statewide floor.** Narrowest blast radius, but bends
  `getStatewideOfficials` past its stated contract and fixes only the reps feed, not `/elections`
  or anything else keyed on the district join.

**Recommendation: A.** The v2.8 record shows the split was an accident of two import eras, not a
design decision, and `1198` is the row that already behaves like a House district everywhere the
code looks. Merging is the only option that leaves DC with one row instead of two.

## Verify after any fix

```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a
# A DC point must resolve to a district that has >= 1 holder:
psql "$DATABASE_URL" -X -c "
WITH pt AS (SELECT public.ST_X(public.ST_PointOnSurface(geometry)) lng,
                   public.ST_Y(public.ST_PointOnSurface(geometry)) lat
            FROM essentials.geofence_boundaries WHERE geo_id='1198' AND geometry IS NOT NULL LIMIT 1)
SELECT d.geo_id,
       (SELECT COUNT(och.politician_id) FROM essentials.offices o
          LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
         WHERE o.district_id=d.id) AS holders
FROM pt, essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id=gb.geo_id AND d.district_type='NATIONAL_LOWER'
WHERE public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(pt.lng, pt.lat), 4326));"
# expect: holders >= 1
```

## Context

- Unrelated to ADR 0002 — `getStatewideOfficials` already joins `office_current_holder` correctly.
  This surfaced during that port but is a separate, older defect.
- Sources checked: `.planning/milestones/v2.8-phases/105-dc-infrastructure-official-records/`
  (`105-01-SUMMARY.md`, `105-02-SUMMARY.md`), `.planning/milestones/v2.8-ROADMAP.md`,
  `.planning/milestones/v2.15-REQUIREMENTS.md` (USHR-05).
- An earlier draft of this todo guessed the split was "probably deliberate from the v2.8 era" and
  leaned on that guess. The docs say the opposite: `1198` is a Cicero-era leftover v2.8 logged as a
  count discrepancy and never reconciled. Corrected above.
