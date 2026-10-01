# Open items backlog — surfaced 2026-09-29

**Created** 2026-09-29 · **Source** the St. Louis MO slice (waves 1–5a) and the reachability work
that came out of it. Every item below was **measured**, not guessed, and every number carries the
query or the file that produced it so the next session does not have to re-derive it.

🔴 **These exist because they were found in passing, not because anyone planned them.** Several are
invisible to CI and to every existing gate. Re-measure before acting — the counts move.

---

## 1. ▶ NEXT TASK — governments with a NULL `geo_id` are unreachable from the landing page

**Measured 2026-09-29: 210 governments carry `geo_id IS NULL` and still have at least one current
occupant. 184 of them are California.**

```sql
SELECT count(*) FROM essentials.governments g
 WHERE g.geo_id IS NULL AND EXISTS (
   SELECT 1 FROM essentials.chambers c
     JOIN essentials.offices o ON o.chamber_id = c.id
     JOIN essentials.office_current_holder och ON och.office_id = o.id
    WHERE c.government_id = g.id AND och.politician_id IS NOT NULL);
```

⚠ **The operator asked for "the 80 LA County cities", and 80 was my own narrower figure** — the
count after excluding school districts, water districts and community colleges. The honest total is
**210 with occupants / 184 in CA**; the city-and-town subset is roughly 80. Agree the scope before
starting, because "all 210" and "the ~80 cities" are different jobs.

**Why it matters:** a landing-page chip is keyed on `governments.geo_id`
(`WHERE g.geo_id = ANY($1)` in `essentialsBrowseService.getPoliticiansByGovernmentList`). A NULL
cannot be named by any browse URL. **Address search still works**, because it goes
`districts → offices → office_current_holder` and never touches `essentials.governments` — which is
exactly why this was invisible until a human noticed two cities missing from the main page.

**The rules `CC_0183` established, which apply unchanged:**
- 🔴 **Verify every `geo_id` against a district that EXISTS and CARRIES A POLYGON.** Do not compose
  one from a name. `CC_0183`'s gate refused its own first run over this.
- 🔴 **A geo_id is not always available.** Indianapolis has none — see item 3.
- 🔴 `geo_id` must stay unique table-wide. It currently is; the gate re-asserts it.
- ⚠ Most of the 184 CA rows are **school, water and community-college districts that were never
  meant to be chips** — they are reached through the area browse, not their own card. Fixing their
  `geo_id` may be correct data hygiene but it is not the reachability win. **Decide which tier is in
  scope first.**

Full mechanism: `reference_government_geoid_reachability` memory, and `CC_0183`'s header.

---

## 2. 86 active politicians render a PAGE URL as their photo

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

---

## 3. 🔴 Indianapolis has no `geo_id` that is both correct and free

Indianapolis and Marion County are consolidated (Unigov). Its Mayor sits on the **county** polygon
`18097` — but `Marion County, Indiana, US` **already carries `18097`**, with 38 chambers. The place
code `1836003` appears **nowhere** in `essentials.districts`.

So `18097` duplicates and `1836003` points at ground the database does not hold. `CC_0183`'s gate
refused the write, and its 6 seats stay browse-unreachable (they still answer an address).

▶ **This is a modelling decision, not a data fix.** How should a consolidated city-county be
represented when the city and the county are two government rows over one polygon? Answer that
before touching it.

---

## 4. ⏳ St. Louis city and county have no banner — and that blocks their chip

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

## 6. CLAUDE.md's `offices_missing_terms` baseline is stale

CLAUDE.md says **238** unflagged. **Measured 2026-09-29: 239.** Wave 3 created the St. Louis Sheriff
seat unseated by ruling, which moved it, and that is recorded in the MO spec but never propagated to
CLAUDE.md.

▶ One-line edit: read the baseline as **239**. A stale high baseline hides drift; a stale low one
cries wolf.

---

## 7. ⚠ 349 offices carry a NULL `chamber_id`, and nothing distinguishes orphaned from legitimate

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
