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

## Options (each has a real downside — needs an operator call)

- **A. Re-key the 3 offices onto district `1198`.** Smallest change, puts offices where the polygon
  already is. But `essentials.offices` re-keying is exactly what the `164.1-ut-wiring-contract.md`
  NOTOUCH md5 exists to prevent for UT; check no equivalent contract covers DC before touching it.
  Would also orphan `dc-national-lower` — decide whether to retire or keep it.
- **B. Attach a geofence polygon to `dc-national-lower`.** Leaves offices alone, but then DC has two
  overlapping `NATIONAL_LOWER` polygons for the same ground, which is precisely the double-match
  condition 164.1-04 documented as producing spurious two-race results in dual-map states.
- **C. Add a shadow-seat branch to the statewide floor.** Narrowest blast radius, but bends
  `getStatewideOfficials` past its stated contract and only fixes the reps feed, not
  `/elections` or anything else keyed on the district join.

**My lean: A**, contingent on confirming no wiring contract covers DC. It makes the data match the
model the rest of the codebase already assumes (offices hang off the district that owns the polygon)
rather than adding a special case.

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

- v2.8 was a DC milestone, so the `dc-national-lower` row is likely deliberate from that era and
  predates the TIGER `1198` import. Check the v2.8 phase docs before assuming it is a mistake.
- Unrelated to ADR 0002 — `getStatewideOfficials` already joins `office_current_holder` correctly.
  This surfaced during that port but is a separate, older defect.
