# Elections API — State & Federal Races Now Live

**From:** Accounts team  
**To:** Essentials team  
**Date:** 2026-04-13  
**Re:** Request filed 2026-04-12 — state/federal races missing from elections endpoint

---

## What we found

We ran your diagnostic queries and confirmed both causes you suspected.

**Cause 1 — Race records missing.** The 2026 LA County Primary had races only for LOCAL-tier offices (Board of Supervisors districts, City Council seats). No race records existed for State Assembly, State Senate, US House, county-wide offices (Sheriff, Assessor), school board, or statewide offices (Governor, etc.).

**Cause 2 — Geofence data incomplete and corrupted.** CA State Assembly and Senate district geofences were partially loaded: 27 of 80 Assembly districts and 26 of 40 Senate districts had geofence polygons. The loaded entries also had their MTFCC codes swapped — Assembly polygons were tagged with the Senate MTFCC and vice versa. This caused a geo_id collision: LA County's FIPS code (`06037`) is the same numeric format as Assembly District 37's GEOID (`06037`), so the county's polygon was incorrectly matching against the wrong legislative districts.

---

## What we fixed

**1. Loaded all CA state legislative district geofences.**  
All 80 CA Assembly and 40 CA Senate district boundaries from TIGER/Line 2024 are now in `geofence_boundaries` with correct MTFCC codes (`G5210` for Assembly, `G5220` for Senate) and `state = 'CA'`. The corrupt old entries (identifiable by `state = '06'`) were removed and replaced.

**2. Fixed the geofence join in `electionService.ts`.**  
The `ST_Covers` query now includes MTFCC in the join condition so a county polygon can't match a legislative district record with the same numeric geo_id. The join is:
```sql
JOIN essentials.geofence_boundaries gb
  ON gb.geo_id = d.geo_id
  AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
```
This is a silent correctness bug that would have affected any address where a county FIPS suffix matched a legislative district number. For LA County (`06037`), it was incorrectly matching Assembly D37 and Senate D37 for addresses across the entire county.

**3. Seeded 16 new race records for the 2026 LA County Primary.**  
All missing tiers are now present. For a voter at 500 W Temple St, Los Angeles CA 90012, the endpoint now returns:

| Tier | Race | Source |
|------|------|--------|
| STATE_LOWER | CA State Assembly District 54 | geofence match |
| STATE_UPPER | CA State Senate District 26 | geofence match |
| NATIONAL_LOWER | U.S. Representative District 34 | geofence match |
| COUNTY | LA County Sheriff | geofence match (county-wide) |
| COUNTY | LA County Assessor | geofence match (county-wide) |
| SCHOOL | LAUSD Board of Education District 2 | geofence match |
| SCHOOL | LAUSD Board of Education District 4 | geofence match |
| SCHOOL | LAUSD Board of Education District 6 | geofence match |
| STATEWIDE | CA Governor | state match (open seat) |
| STATEWIDE | CA Lieutenant Governor | state match |
| STATEWIDE | CA Attorney General | state match |
| STATEWIDE | CA Secretary of State | state match |
| STATEWIDE | CA State Treasurer | state match |
| STATEWIDE | CA State Controller | state match |
| STATEWIDE | CA Insurance Commissioner | state match |
| STATEWIDE | CA Superintendent of Public Instruction | state match |

No changes to the frontend are needed. `ElectionsView` already renders all tiers — you were already right about that.

---

## One CA-specific note about primary_party

Indiana's primaries are closed — a race is party-scoped (e.g., "Republican Primary — State Senate District 40"). California uses a **top-2 jungle primary**: all candidates regardless of party run on a single ballot. `primary_party` is `NULL` for every CA race. The frontend should handle NULL gracefully — don't display a party header for CA primary races, or display "All Candidates" instead.

---

## Candidate data — current state

All known incumbents have been seeded. Here's the full picture:

| Race | Incumbent seeded | Notes |
|------|-----------------|-------|
| CA Assembly District 54 | Isaac G. Bryan ✓ | |
| CA State Senate District 26 | — | Ben Allen potentially term-limited (12 years 2014–2026); open seat pending CA SoS confirmation |
| U.S. Representative District 34 | Jimmy Gomez ✓ | |
| LA County Sheriff | Robert Luna ✓ | |
| LA County Assessor | — | Jeff Prang term verification pending |
| LAUSD Board District 2 | Scott Schmerelson ✓ | |
| LAUSD Board District 4 | Nick Melvoin ✓ | |
| LAUSD Board District 6 | Kelly Gonez ✓ | |
| CA Governor | — | Open seat — Newsom term-limited |
| CA Lieutenant Governor | Eleni Kounalakis ✓ | |
| CA Attorney General | Rob Bonta ✓ | |
| CA Secretary of State | Shirley N. Weber ✓ | |
| CA State Treasurer | Fiona Ma ✓ | |
| CA State Controller | Malia M. Cohen ✓ | |
| CA Insurance Commissioner | Ricardo Lara ✓ | |
| CA Superintendent of Public Instruction | Tony Thurmond ✓ | |

**What's still missing — challengers across all races.**  
Challenger candidates need to be sourced from the CA Secretary of State's 2026 primary filing list. We're building an ingestion script for this next.

**What we're building next:**

1. **CA SoS challenger ingestion** — The CA SoS publishes candidate filing data for the June 2026 primary. We're writing a script that reads those filings and creates challenger `race_candidates` entries linked to the correct races by position name and district. Once that runs, every race will have its complete candidate list.

2. **LAUSD board sub-district geofences** — Right now LAUSD board races (D2, D4, D6) appear for any address inside the LAUSD boundary. LAUSD has internal board district boundaries — a voter in District 4 should only see the District 4 race. We'll load those sub-district geofences in a follow-up pass once the challenger ingestion is done.

---

## Verification query

You can confirm what the endpoint returns for any address by running the geocode + coordinate lookup manually, or by using the API directly:

```
GET https://api.empowered.vote/api/essentials/elections-by-address?address=500+W+Temple+St%2C+Los+Angeles%2C+CA+90012
```

Expected response: one election object (`2026 LA County Primary`) with races spanning LOCAL, COUNTY, SCHOOL, STATE_LOWER, STATE_UPPER, NATIONAL_LOWER, and statewide (no district type — served via state match).

---

Let us know if anything looks wrong on your end once you've pulled fresh data.
