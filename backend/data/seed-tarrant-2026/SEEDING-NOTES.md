# Tarrant seed — execution notes (2026-08-08)

⛔ **THE MIGRATION WAS NOT WRITTEN AND NOTHING WAS SEEDED.** Two blockers, both recorded below.
This file exists so the next session does not re-derive the pattern or repeat the arithmetic error.

---

## 🔴 Blocker 1 — no database connection

The `mcp__supabase-local__*` tools **disconnected mid-session**, and `backend/.env` is not readable
(permission denied, correctly). Per [[migration_apply_roles]] migrations are applied **as `postgres`
via MCP** — `ev_migrator` sees zero rows under RLS and UPDATEs silently no-op — so there is no safe
alternative apply path even though `psql` is installed.

Consequence: a migration could be *written* but not applied, not verified on row counts, and — more
importantly — **not validated against the five open schema questions below**.

## 🔴 Blocker 2 — my seat arithmetic was wrong, and the operator approved the wrong numbers

I reported "**56 of 61** seats sourced… leave the five vacant". Recounted from `ROSTERS.md`:

| government | seats | cleared | vacant |
|---|---|---|---|
| Tarrant County Commissioners Court | 5 | 5 | 0 |
| Collin County Commissioners Court | 5 | 5 | 0 |
| City of Fort Worth | 11 | 11 | 0 |
| City of Arlington | 9 | 7 | **2** (D3, D8) |
| City of Mansfield | 7 | 7 | 0 |
| City of North Richland Hills | 8 | 8 | 0 |
| City of Grapevine | 7 | 7 | 0 |
| City of Euless | 7 | 3 | **4** (Mayor, P2, P4, P5) |
| **total** | **59** | **53** | **6** |

**It is 53 seeded and 6 left vacant, out of 59 — not 56 and 5 out of 61.** Euless Place 5 (Eads)
counts as vacant under the operator's own rule, since its only source is an *Unofficial Results*
report on a 16-vote margin. The instruction "seed the 56, leave the five vacant" is unambiguous in
intent — seed everything verified, leave everything unverified vacant — so the intent carries over
cleanly to 53/6; only my counts were wrong.

---

## ✅ The seed pattern, reverse-engineered from `783_lynn_city_government.sql`

Worth keeping — it is intricate and undocumented elsewhere. Order matters.

1. **Pre-flight A**: `RAISE EXCEPTION` if the government row already exists (abort on double-apply).
2. **Pre-flight B**: `RAISE EXCEPTION` if the **TIGER geofence is absent** —
   `essentials.geofence_boundaries WHERE geo_id=… AND mtfcc='G4110'`. Seeds do **not** create
   geofences; they assert a prior TIGER load.
3. `essentials.governments (id, name, type, state, city, geo_id)` — `gen_random_uuid()`,
   **`WHERE NOT EXISTS`** because there is **no unique constraint on geo_id**.
   `type='LOCAL'` for cities; `state` **UPPERCASE**.
4. `essentials.chambers (id, name, name_formal, government_id)` — ⚠ **`slug` is GENERATED ALWAYS,
   never include it in the column list.**
5. `essentials.districts (id, district_type, state, geo_id, label, mtfcc)` — one **`LOCAL_EXEC`** row
   for the mayor and one **`LOCAL`** row for councillors. ⚠ `state` **lowercase**; `mtfcc` **NULL**
   (not `'G4110'`).
6. `essentials.politicians (…, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)`
   with `ON CONFLICT (external_id) DO NOTHING`. ⚠ **`party` is always NULL** (antipartisan design).
   **`external_id` is a negative integer built from the place FIPS**: Lynn `2537490` →
   `-2537490001`, `-2537490002`, … i.e. `-(geo_id * 1000 + n)`.
7. `essentials.offices (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)` — written as a CTE
   `WITH ins AS (INSERT INTO politicians … RETURNING id) INSERT INTO offices SELECT … FROM districts d, ins p`.
   ⚠ `representing_state` **UPPERCASE**.
8. **Back-fill `office_id` onto each politician row.**

⚠ Title conventions: the ward/district goes **in the title string** (`'City Councilor (Ward 3)'`),
there are no per-ward geofences at this tier, and **internal officer roles are not titles** — a
council president is still `'City Councilor (Ward N)'`. Applies directly here: Mansfield/NRH/Grapevine
"Mayor Pro Tem" and Arlington "Deputy Mayor Pro Tempore" are **not** office titles.

---

## ▶ Five questions that MUST be answered against the DB before writing the migration

None of these can be guessed, and each would corrupt the seed if wrong:

1. **Do the TIGER geofences exist?** Pre-flight B aborts without them. Need
   `G4110` for `4827000, 4804000, 4846452, 4852356, 4824768, 4830644` and a county boundary for
   `48439` (and `48085` for Collin). The 29 existing TX locals are all Collin-area, so **Tarrant place
   geofences may never have been loaded** — this is the single most likely blocker.
2. **What `district_type` does a county commissioners court use?** `LOCAL`/`LOCAL_EXEC` is the city
   pattern. A County Judge is countywide and commissioners are per-precinct, so precinct districts may
   need their own rows — and possibly their own geofences, which likely do not exist.
3. **What is the `external_id` convention for a county?** The `-(geo_id*1000 + n)` scheme assumes a
   7-digit place FIPS; county FIPS are 5-digit (`48439`), so `-48439001` may collide with a place.
   **Check for collisions before choosing.**
4. **What `role_canonical` values are valid** for County Judge / County Commissioner / Mayor /
   Councilmember? Lynn passed `NULL`; some seeds set it (`950_in_sos_treasurer_seed_rolecanonical`).
5. **What does Collin County already have?** It exists with 0 chambers — but does it already have
   districts, or a geofence, or politician rows pointing nowhere?

Suggested probe (single query, read-only):
```sql
select 'geofence' k, geo_id, mtfcc from essentials.geofence_boundaries
 where geo_id in ('4827000','4804000','4846452','4852356','4824768','4830644','48439','48085')
union all
select 'district', geo_id, district_type from essentials.districts
 where geo_id in ('48085','48439') or state='tx'
union all
select 'extid', min(external_id)::text, max(external_id)::text from essentials.politicians;
```

---

## Recommended order when unblocked

1. Run the probe above; answer Q1–Q5.
2. If Tarrant geofences are missing, **load TIGER first** — that is its own task and the seed cannot
   proceed without it.
3. Write **one migration per government** (8 files) rather than one giant one — each is independently
   verifiable and independently revertible, and Collin is an UPDATE-shaped change (chambers onto an
   existing row) while the other seven are INSERT-shaped.
4. Verify on **row counts**, never absence of error.
5. `coverage.js` chips come **last, after the data is live** — a chip pointing at a government that
   does not exist yet is a broken browse link. `hasContext` **omitted** (no stances this pass).
