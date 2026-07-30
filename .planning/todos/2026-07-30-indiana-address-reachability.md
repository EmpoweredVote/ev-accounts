# Indiana address-reachability: 37 findings, four separate problems, no quick win

**Status:** investigated, NOTHING APPLIED. Every group is blocked on external data or roster research.
**Found:** 2026-07-30 via `npm run check:reachability --verbose` (the gate added in commit 1ff71f84)
**Headline:** do NOT budget this like Utah. UT was mechanical — duplicate rows to merge. In Indiana
**nobody has a reachable twin**, so 17 of the 18 stranded officeholders need geography that does not
exist anywhere in the DB.

## The decisive query

For all 18 `UNREACHABLE` districts, "is this same person also seated on a district that HAS a
geofence?" returned **NULL for every one**. In UT that column was the whole fix (merge the twin).
Here there is no twin: these are the only records, and they have no polygon.

## Group 1 — 15 county council seats, no polygon (15 people invisible)

Synthesized `geo_id` of the form `18` + 3-digit county + 5-digit district, e.g. `1805500001`. No
`geofence_boundaries` row exists for any of them.

| county | FIPS | districts | stranded officeholders |
|---|---|---|---|
| Greene | 055 | 1–4 | Randall L Brown, Kelly J Zimmerly, Ron Lehman, Brent A Murray |
| Jackson | 071 | 1 | Michael Davidson |
| Lawrence | 093 | 1–4 | Amy Redman, Phil Inman, Janie C Chenault, Jeffrey Lytton |
| Marion (Indianapolis) | 097 | 8, 12, 13, 14, 18 | Ron Gibson, Vop Osili, Jesse Brown, Andy Nielsen, Kristin Jones |
| Morgan | 109 | 4 | Troy A Sprinkle |

Marion is the highest-value target (~977k residents) but note only **5 of Indianapolis's 25
City-County Council districts are seeded at all** — the other 20 are absent, not broken. The 10 Marion
rows on `geo_id 18097` are countywide offices (Mayor, Assessor, Sheriff, …) and all resolve fine.

**Fix:** per-county district polygons. Precedent exists — `scripts/fetch-mcc-district-polygons.ts` +
`import-mcc-district-polygons.ts` did exactly this for Monroe County off
`gis.co.monroe.in.us/.../MoCo_Council_Districts`. So the shape is known; each county needs its own
FeatureServer found.

⚠️ **Documented warning, carried over from phase 121 — do not ignore it:** *"Do NOT fall back to the
Indiana statewide FeatureServer (gisdata.in.gov) without human approval — the statewide service only
returned 3/4 districts in initial testing."*

⚠️ `scripts/load-arcgis-from-config.ts` is **UT-locked** (`const STATE_FIPS = '49'`) and its config is
`arcgis_sources.json`. Reusing the config-driven loader for IN needs that parameterized first.

## Group 2 — 2 appellate judges invisible, and 4 more OVER-broad (blocked on statute)

- `1800001` Judge **L. M Bailey** (District 1) and `1800002` Judge **Cale J Bradford** (District 2):
  synthesized geo_ids, no polygon → invisible.
- Their 9 colleagues sit on `geo_id 18`, which has the statewide `G4000` polygon, so they resolve.

🔴 **The obvious fix — re-key the 2 to `18` — would be WRONG.** Indiana Court of Appeals retention is
not uniformly statewide: **Districts 1, 2, 3 are retained only by the voters of that district**; only
Districts 4 and 5 span the whole state (they are composed of one judge from each geographic district).
The two stranded judges are D1 and D2, i.e. precisely the district-based kind. Putting them on `18`
would show them to voters who cannot retain them.

The same fact means **4 judges already on `18` are over-broad**: Foley (D1), Altice (D2), Kirsch (D2),
Crone (D3). An Indianapolis resident currently sees a judge covering the southern third of the state.
🔴 **Note the reachability gate cannot detect this class** — it only flags officials who are
*invisible*, never ones who are *too visible*. Worth a companion check.

**Blocked on:** the statutory county→district mapping. `in.gov/courts/appeals/districts/` describes the
districts only as "southern third / middle third / northern third" and gives **no county list**; the
FAQ has none either. Needs Indiana Code (look at IC 33-25) or an administrative rule. **Do not guess
the county lists** — that would fabricate the constituency that decides a judge's retention.

**Once sourced this is cheap and needs no external GIS:** all **92 Indiana county polygons already
exist and are valid** (`state='18'`, `mtfcc='G4020'`, 18001–18183), so Districts 1/2/3 can be built by
`ST_Union`. D4/D5 correctly stay on `18`.

🔴 **Doing this forces the deferred `geoIdGuard.ts` fix.** Its `X%` catch-all allows only
`('LOCAL','COUNTY')` while the inline copy at `essentialsService.ts:746` also allows `'JUDICIAL'`. Create
`X%` judicial polygons and address search will match them while **browse and elections will not**. The
guard drift stops being cosmetic the moment these polygons exist.

## Group 3 — 1 school board seat, a district_type/geography mismatch (1 person)

`Eminence School Board - Ashland Township` (Mary Stockwell), `district_type='SCHOOL'`,
`geo_id='1810902440'`. A polygon DOES exist for that geo_id — but it is `mtfcc G4040` named "Ashland",
i.e. the **township**, and the guard maps G4040 → LOCAL/LOCAL_EXEC, never SCHOOL. Hence unreachable.

A correct school polygon also exists: `G5420 "Eminence Community School Corporation"`.

**Needs a judgment call, because the seat is genuinely township-elected within the school corporation:**
- (a) retype to `LOCAL` — G4040 then matches, but a school board typed LOCAL is semantically wrong;
- (b) re-key to the G5420 school-corp polygon — reachable, but over-broad (every Eminence resident sees
  a seat only Ashland Township votes on);
- (c) extend the guard to allow `G4040 + SCHOOL` — risky, would let any township polygon match any
  school district sharing that geo_id.
3 other IN SCHOOL districts also lack a geofence (21 of 25 have one) but have no active holder, so they
do not show as UNREACHABLE.

## Group 4 — 19 `DEAD_GEOGRAPHY` rows, and NOT a safe bulk cleanup

I expected these to be deletable scaffolding. They are three different things:

- **Monroe County Council districts 1–4** (`18105-mcc-d1..d4`): polygons + offices, **zero holders**.
  These are a REAL body we simply never seeded — the mirror image of Group 1 (Monroe has the polygons
  and no roster; the other five counties have the roster and no polygons). **Do not delete** — seed the
  roster and 4 seats become reachable immediately, since the geography is already correct.
- **11 Monroe townships + Ellettsville**: here the empty rows *do* have occupied twins on the same
  geo_id — e.g. `1810503808` carries both an empty "Bean Blossom Township" and an occupied "Monroe
  County: Bean Blossom Township Board" with 3 active members. The empty ones look like scaffolding and
  are invisible per ADR-0002. **But Ellettsville wards 4 and 5 are real unseeded seats, not
  duplicates** (wards 1–3 are seated) — so this group cannot be swept in one predicate.
- **Appeals Court (Retain Kirsch?) / (Retain Riley?)** on `geo_id 18`: retention-question offices whose
  holder is inactive — almost certainly spent 2024-cycle questions. Needs a retirement decision, not a
  geofence.

## Recommendation

Ranked by stranded-people-per-unit-effort:

1. **Seed Monroe County Council (4 seats).** Only group where geography is already right and correct;
   pure roster research. Clears 4 DEAD_GEOGRAPHY at the same time.
2. **Marion County / Indianapolis council polygons (5 seats, ~977k residents).** Highest population
   impact. Also decide whether to seed the missing 20 districts while there.
3. **Appellate districts** — do the statute lookup first; the polygon build is then cheap
   (`ST_Union` of existing counties) and fixes 6 judges (2 invisible + 4 over-broad). Bundle the
   `geoIdGuard.ts` JUDICIAL fix with it.
4. **Greene / Lawrence / Jackson / Morgan polygons** (10 seats) — same pattern as Marion, smaller
   populations, four more GIS sources to locate.
5. **Eminence** (1 seat) — needs the (a)/(b)/(c) decision above; lowest value.

Do **not** touch the baseline in `backend/data/address-reachability-baseline.json` until a group is
actually fixed; the `in|*` buckets are the tracking mechanism for this list.
