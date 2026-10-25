# Open items backlog — surfaced 2026-09-29

**Created** 2026-09-29 · **Source** the St. Louis MO slice (waves 1–5a) and the reachability work
that came out of it. Every item below was **measured**, not guessed, and every number carries the
query or the file that produced it so the next session does not have to re-derive it.

🔴 **These exist because they were found in passing, not because anyone planned them.** Several are
invisible to CI and to every existing gate. Re-measure before acting — the counts move.

**Status 2026-10-25 — items 1, 3, 6 and 7 ✅ CLOSED, item 2 ◐ half closed. Five remain, and ▶ NEXT is
item 4 (St. Louis banner).** ⚠ That re-measure instruction earned its keep this pass: item 1's population had fallen
210 → 153 on its own, item 3 had been quietly resolved by someone else, and item 6's baseline turned
out never to have moved. **Three of the four were already partly or wholly fixed before anyone
looked.** Measure before you plan the work, not after.

---

## 1. ✅ CLOSED 2026-10-25 — governments with a NULL `geo_id` are unreachable from the landing page

**Closed by `CC_0288` and `CC_0289`.** What is left in the NULL-geoid set is correct and is not
owed a geoid.

**Re-measured 2026-10-25: 210 → 153 before the fix, 137 after.** The drop from 210 happened on its
own, as other waves seated people and loaded boundaries. 🔴 **The estimate in the line this replaces
— "the city-and-town subset is roughly 80" — did not survive measurement. The subset is ZERO.**

```sql
-- the population this item was about
SELECT count(*) FROM essentials.governments g
 WHERE g.geo_id IS NULL AND EXISTS (
   SELECT 1 FROM essentials.chambers c
     JOIN essentials.offices o ON o.chamber_id = c.id
     JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE c.government_id = g.id AND och.politician_id IS NOT NULL);
```

Reading what the 153 actually were is what settled the scope:

| | What | Verdict |
| --- | --- | --- |
| 131 | `LOCAL` — school districts, community college districts, water and irrigation districts, library / health / park districts | **Not chips by design.** Reached through the area browse. No geoid owed. |
| 16 | `Township` (IN) — general-purpose local government: trustees, township boards, small-claims constables | **Fixed — `CC_0289`.** |
| 5 | `School District` (IN) | Same as the 131. |
| 2 | the federal government, duplicated into a `federal` row and a `NATIONAL` row | **Fixed — `CC_0288`.** |

🔴 **NOT ONE CITY OR TOWN IS UNREACHABLE, AND A POSITIVE CONTROL IS THE ONLY REASON THAT ZERO CAN
BE BELIEVED.** The detector is a title predicate — mayor / council member / alderman / city clerk /
city attorney / selectman — over the offices of the NULL-geoid set. It returned 0. The same
predicate over the geoid-bearing set returned **280**, which is what proves the 0 is an absence and
not a broken query. Every row of type `City` (80), `Town` (9), `Village` (11), `County` (84) and
`STATE` (50) carries a geoid.

**What `CC_0289` did, and the rule it follows.** The 16 townships were the only general-purpose
local governments left without a chip. Each one's offices already hang off districts carrying a
TIGER county-subdivision geoid (MTFCC **G4040**), all 16 resolve to exactly one distinct geoid, and
all 16 have a matching polygon — so 🔴 **every geoid was verified against a district that EXISTS and
CARRIES A POLYGON** (`CC_0183`'s rule), never composed from a name. ⚠ Indiana reuses township names
across counties, so the migration keys on the government UUID and re-derives each geoid from that
government's own districts in its gate.

**Proved end-to-end, not by count.** `POST /api/essentials/browse/by-government-list` against
production returns 7 officials for Center Township (`1809711512`), 4 for Bloomington
(`1810505878`), 4 for Ashland (`1810902440`).

**What `CC_0288` did.** The United States Federal Government was two rows: a `federal` row holding
only the Supreme Court and its nine justices, and a `NATIONAL` row holding the President, Cabinet,
House and Senate. Merged into the `NATIONAL` row. 🔴 **`essentials.chambers.government_id` HAS NO
FOREIGN KEY**, so deleting first would have silently orphaned the chamber and dropped all nine
justices out of every government-joined read with no error anywhere — repoint, then delete. The
surviving row keeps its NULL `geo_id`, correctly: federal officials are served by the supplemental
query in `essentialsBrowseService.ts` keyed on `d.district_type IN (… 'NATIONAL_JUDICIAL')`, never
by a chip, and a national government has no TIGER geoid to carry.

⚠ **The remaining 137 are the correct resting state, not a backlog.** Do not re-open this by
counting NULLs again — count the ones that should be chips.

Full mechanism: `reference_government_geoid_reachability` memory, and `CC_0183`'s header.
Full mechanism: `reference_government_geoid_reachability` memory, and `CC_0183`'s header.

---

## 2. ◐ HALF CLOSED — 86 active politicians render a PAGE URL as their photo

**Measured 2026-09-29: 86.** `photo_custom_url` is empty and `photo_origin_url` points at an HTML
page, so the read path serves a page URL into an `<img>`.

```sql
SELECT count(*) FROM essentials.politicians
 WHERE is_active AND coalesce(photo_custom_url,'') = ''
   AND photo_origin_url ILIKE 'http%'
   AND photo_origin_url !~* '\.(jpg|jpeg|png|webp|gif)(\?|$)';
```

🔴 **The cause is the `find-headshots` skill's own import step.** It sets `photo_origin_url` to the
SOURCE PAGE and writes a `politician_images` row — but `districtQueries` reads
`COALESCE(p.photo_custom_url, p.photo_origin_url, '')` and **never consults `politician_images`**
(only `compassService` does). So a skill-run import that omits `photo_custom_url` both fails to
render and poisons the fallback.

▶ **Two jobs:** clear or repair the 86, and fix the skill so the next run writes `photo_custom_url`.
The St. Louis wave wrote all three columns; that is the pattern to copy.

### ◐ HALF CLOSED 2026-10-25 — the 86 are repaired; the CAUSE is unverified

**The query above now returns 0.** 🔴 **That zero is only meaningful because of a positive
control** — a count of 0 from this predicate is exactly what a broken predicate also returns.

| probe | 2026-10-25 |
| --- | --- |
| active politicians whose `photo_origin_url` is NOT an image extension | **6,174** |
| …of those, rescued by a `photo_custom_url` | **6,174** |
| …still broken (`photo_custom_url` empty) — **the item** | **0** |

⚠ **My first attempt at this control was worthless and looked fine.** I ran the inverted regex
*inside* the `photo_custom_url = ''` filter, so the control was nested in the very set I was
testing; it returned 0 because its parent returned 0, and that reads just like a pass. The control
has to sit OUTSIDE the filter under test. → `feedback_control_must_fail_first`

🔴 **THE POISONED FALLBACK IS STILL THERE — 6,174 ROWS RENDER ONLY BECAUSE THE CUSTOM COLUMN IS
FILLED.** Clear `photo_custom_url` on any one of them, for any reason, and it serves a page URL
into an `<img>` again. The symptom is fixed; the shape that caused it is not.

▶ **STILL OWED: the second job, and it was NOT checked.** The `find-headshots` skill is not on disk
in this repo or under `~/.claude/skills`, so whether its import step now writes `photo_custom_url`
could not be verified here. **Do not read this item as closed until someone reads that skill.**
Until then, treat 0 as a count that can come back.

---

## 3. ✅ CLOSED — Indianapolis has no `geo_id` that is both correct and free

**Resolved before 2026-10-25 and confirmed on that date.** The modelling question this item asked
has been answered: the city and the county are **one government row**, not two.
`Consolidated City of Indianapolis and Marion County, Indiana, US` is type `City` and carries
`geo_id 18097` / `mtfcc G4020`, with 64 seated officials. There is no longer a separate
`Marion County, Indiana, US` row to collide with it, so `18097` is both correct and unique —
`CC_0289`'s gate re-asserts that `geo_id` is unique table-wide and passed.

▶ **The ruling worth keeping: a consolidated city-county is ONE row on ONE polygon.** The place
code `1836003` is still absent from `essentials.districts` and should stay unused.

---

## 4. ▶ NEXT TASK — ⏳ St. Louis city and county have no banner, and that blocks their chip

`buildingImages.js` holds no `st louis` / `saint louis` key (checked 2026-09-29). `CC_0183` gave both
governments a `geo_id`, so the DATA is ready; the chip is a one-line `coverage.js` addition **once a
banner is certified**.

Full spec, including the 1700×540 asset spec, the D-09 no-AI rule and the Bend-crop trap:
`2026-09-28-st-louis-mo-deep-seed.md`, "What wave 5b still owes".

---

## 5. ⚠ The Kansas and Kentucky chips are UNCOMMITTED in the essentials working tree

Wichita and Lexington chips were added to `src/lib/coverage.js` in
`C:\Transparent Motivations\essentials` on 2026-09-29 and **deliberately not committed**: that repo
had a large uncommitted pass on `main` (8 new state blocks, a 112-line `Landing.jsx` rewrite, a
`LocationCombobox.jsx` change) belonging to another session.

▶ **Check with whoever owns that session before committing.** Until it lands, Wichita and Lexington
have their data fixed but still no chip.

---

## 6. ✅ CLOSED 2026-10-25 — CLAUDE.md's `offices_missing_terms` baseline is stale

The original complaint (CLAUDE.md said **238**, the measurement was **239**) was fixed before this
pass; CLAUDE.md has read 239 for some time. **Re-measured 2026-10-25: `400 / 161 / 239`.**

✅ **THE BASELINE IS CORRECT AND HAS NOT MOVED.** 239 unflagged, exactly as recorded. What was stale
was the *dated observation* beside it — `433 / 194` from 2026-10-20 — because Augusta and Westbrook
were seated in between (`CC_0282`/`CC_0283`). Both numbers are now current in CLAUDE.md.

🔴 **The distinction that keeps this from recurring, now written into CLAUDE.md: only `unflagged` is
a baseline. `total` and `flagged` are dated observations and a seating wave is SUPPOSED to move
them.** Reading all three as a baseline is what produced the "+194 of drift" false alarm.

⚠ **One thing the closure surfaced and did NOT fix:** the 13 flagged seats that carry a
`vacant_since` date — the audited, real vacancies — have not moved at all, while the undated pile
fell 181 → 148. The flagged total is falling because Maine is being seeded, not because any audited
vacancy was resolved. Read the two sub-buckets apart.

---

## 7. ✅ CLOSED 2026-10-25 — 349 offices carry a NULL `chamber_id`, and nothing distinguishes orphaned from legitimate

**The gate now exists: `npm run check:chamberless-orphans` (CI job "chamber-less orphans",
schedule-only).** Production is clean — **0 seated offices are hidden from their own government.**

🔴 **THE COUNT 349 IS NOT THE PROBLEM AND NEVER WAS. Only 201 of them are SEATED, and an empty
office drops nobody.** The other 148 — 80 CA/IN county seats, 24 Indiana judicial, 23 Indiana local,
21 with no district at all — hold no one.

**All 201 seated ones render.** Verified end-to-end against prod, not inferred:

| Probe | `POST /api/essentials/coordinate-lookup` |
| --- | --- |
| Culebra, PR | 30 officials, **all chamber-less** — the mayor, 14 senators, 14 representatives, the Resident Commissioner |
| Washington, DC | 47 officials, 13 chamber-less — Council Members, SBOE, both shadow senators, the Delegate |

They work because the address and coordinate paths run `districts → offices →
office_current_holder` and **`LEFT JOIN`** the chamber. Only the landing-page browse query needs
one, and its `governments → chambers → offices` join is INNER.

### The predicate, and why it needs no carve-out for DC

An office is an **orphan** when all three hold: `chamber_id IS NULL` · somebody is **seated** in it ·
its district's **`(mtfcc, geo_id)`** matches a `governments` row, so a chip for that government
*should* list this person.

🟢 **Condition 3 is what makes the old false positive disappear.** No `governments` row matches
Puerto Rico's municipal districts or DC's council districts, so neither was ever reachable through a
chamber and neither is flagged — without naming them. Wichita satisfied all three.
🔴 The key is the **pair** `(mtfcc, geo_id)`, never `geo_id` alone.

### ◐ 121 LATENT, and this is the number to watch

An **unseated** chamber-less office whose government exists becomes an orphan the moment anyone
seats it. There are **121**, in 13 governments — **96 in Monroe County IN**, 4 in LA County, the
rest one or two per Indiana township. The check prints them and does **not** fail on them.
▶ **Seating Monroe County without attaching those offices to a chamber would create 96 orphans in
one migration.**

### 🔴 The control had to be MANUFACTURED

A healthy database contains zero orphans, so unlike `check-rls-coverage` — which always has
`spatial_ref_sys` sitting there — there was nothing standing to prove the detector works. The script
opens a transaction, strips the chamber from a real seated office, confirms the detector reports it,
and **always rolls back**; it cannot write. If the planted orphan is not seen, the check **errors**
instead of passing, because an empty result would then mean nothing. Both paths were exercised:
green with the control passing, and red (exit 1) against a planted orphan. Rollback verified — 349
and 201 unchanged after the run.

**Measured 2026-09-29: 349** (was 356 before `CC_0183` attached Wichita's 7).

Most are **legitimate** — the whole DC Council, the LA Superior Court bench, territory delegates,
Monroe County IN townships. They render fine. But Wichita's 7 were **orphaned**: its government row
existed and reported 0 chambers and 0 offices, so the browse join dropped every one.

🔴 **No gate tells the two apart.** The tell is a government row that exists and holds zero offices
while its districts hold seated ones. A check worth writing:

```sql
SELECT g.name FROM essentials.governments g
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id);
```

Measured 2026-09-29 that returns exactly **1** row — and it is **`District of Columbia`**, which is
a FALSE POSITIVE: DC legitimately holds its whole Council on NULL-chamber offices and renders fine.
⚠ **So that query alone is not the check.** Wichita was distinguishable because its government had
a name matching a city whose districts held seated officials it did not own. Any real gate has to
compare a government's own office count against the seats sitting on districts it should own.

---

## 8. ⚠ MO congressional map may be the superseded one

Prod holds MO congressional as plain `census_tiger_2024`, `2901`–`2908`, with no vintage tag, but
Missouri redistricted mid-decade in 2025 and the Census geocoder's `120th Congressional Districts`
layer puts **414 E 12th St, Kansas City in CD-4**. Found during wave 1 and deliberately out of that
slice's scope.

▶ Belongs with `2026-08-19-congressional-map-vintage-collision.md`.

---

## 9. ⚠ A production credential appeared in this session's transcript

On 2026-09-29 a `dotenvx` banner line contaminated a `DATABASE_URL` capture, and the resulting error
message printed the full pooler connection string, including the `ev_api` password. It went no
further than the transcript.

▶ **Rotating it is the operator's call.** The extraction bug is avoidable: pipe the value through
`| tail -1`, because `dotenvx` writes a banner to stdout.

---

## 10. Cosmetic — `npm run banners:check` reports stale on a clean `main`

The generated `public/banners.json` is byte-identical to what `gen-banners-json.mjs` produces; the
check trips on **CRLF** line endings in the working copy. Pre-existing, not caused by any recent
change. Worth a `.gitattributes` entry so the CI check stops crying wolf.
