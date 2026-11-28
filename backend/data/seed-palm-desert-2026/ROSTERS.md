# Palm Desert, CA — deep seed

Compiled **2026-11-28**. `CC_0531` (council, polygons, holders) and `CC_0532` (headshots) applied to production on
2026-11-28. **`CC_0533` is written but NOT applied** — it finishes the district transition and refuses to run before
2026-12-10.

## What was already there

Nothing for the city: only the TIGER outline `0655184`. Schools: Desert Sands Unified (`CC_0524`; City Hall is in
Trustee Area 1).

## The council, now and after the transition

Palm Desert is a charter city with five councilmembers on four-year terms. **There is no elected Mayor**: the council
picks a Mayor and Mayor Pro Tem each year (kept in office descriptions, not titles). The city is finishing a switch from
at-large to five single-member districts: Districts 1–3 elected by district in 2024; Districts 4–5 in 2026.

| Seat | Today (CC_0531) | From the December installation (CC_0533) |
|---|---|---|
| District 1 | Karina Moreno | Karina Moreno |
| District 2 | Joe Pradetto (Mayor Pro Tem 2026) | Joe Pradetto |
| District 3 | Gina Nestande | Gina Nestande |
| At-large (citywide) | Evan Trubee (Mayor 2026) | — seat ends; Trubee moves to District 4 |
| At-large (citywide) | Jan Harnik | — seat ends; Harnik did not run |
| District 4 | (not created yet) | **Evan Trubee** — 2,240 v Jonathon Polly 1,670 |
| District 5 | (not created yet) | **John Greenwood** — 2,799 v Ralph E. Perry 1,885 |

Results: Riverside ROV update #27 (2026-11-25).

## Why District 4 and 5 are not created yet (operator decision 2026-11-28: "Exact changeover")

Until installation, Trubee and Harnik represent the whole city, so every address sees them on two at-large seats.
Creating District 4/5 offices now, with terms starting in December, would leave those districts with no current
holder — `check-address-reachability.mjs` (master-only) calls that DEAD_GEOGRAPHY and would go red for every merge
until December. So `CC_0533` does the whole changeover in one transaction: create D4/D5, seat Trubee and Greenwood,
close the at-large terms, detach the two at-large offices (history kept) and delete the empty at-large district.
Cost, accepted: Greenwood is not shown as "incoming" before then.

## Polygons

The city's own layer, linked from its elections page: "Adopted Map 109 Renumbered B" (Palm Desert Voting Districts
2024 FeatureServer, edited 2026-07-21) — `palm-desert-council-districts.geojson`. Its NAME field labels Districts
1–3 with Moreno, Pradetto and Nestande, which ties each number to a sitting member. All 5 loaded as X0001
`palm-desert-council-district-N`; union covers 99.87% of the city, no overlaps.

## Open items (dated)

1. **On or after 2026-12-10** — read the 2026-12-10 council agenda/minutes, set the install date in `CC_0533` (one
   place) and its precision to `day`, then apply it. Also update the Mayor / Mayor Pro Tem descriptions (the council
   picks new ones at that meeting).
2. **Photo** for John Greenwood (none yet).
3. Terms are undated (the city gives "since" years and term spans, not start days).
4. No stance research.
