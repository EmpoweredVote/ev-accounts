# Data Coverage Tracker

Per-jurisdiction view of how complete EV's data is, **plus** the jurisdiction-specific
research rules the `research-stances` skill must obey. One YAML file per state
(`ut.yaml`, `in.yaml`, …). This file is the **version-controlled source of truth**.

> **Looking for how the `/admin/coverage/map` % is calculated** (what counts toward the
> score — stances, donors, treasury, etc.)? See [`COVERAGE-MAP.md`](./COVERAGE-MAP.md).

## Who reads it

| Consumer | Reads | Purpose |
|----------|-------|---------|
| Admin page `/admin/coverage` | whole file | visual, at-a-glance completeness dashboard |
| `research-stances` skill (STEP 0.5) | `rules.skip_topics` | auto-exclude inapplicable topics + warn |
| `scripts/coverage-sync.ts` | `locations[]` | refresh the **auto** columns from the live DB |
| `src/lib/coverageService.ts` | whole file | serve `GET /api/admin/coverage` (recomputes auto cols live) |

## Schema

```yaml
state: UT                       # 2-letter code (matches essentials.districts.state, case-insensitive)
state_name: Utah
synced_at: 2026-05-30           # stamped by coverage-sync.ts on its last run

rules:
  skip_topics:                  # MACHINE-READ by research-stances
    - topic_key: rent-regulation
      reason: "…why this topic is inapplicable here…"
      source:  "https://…"      # statute / authority (optional but encouraged)
      applies_to: [state, county, local, school]   # office levels the rule covers
  notes:                        # free-text, human-only
    - "…"

locations:
  - ocd_id: ocd-division/country:us/state:ut/place:salt_lake_city
    name: Salt Lake City
    level: local                # state | county | local | school
    status: active              # active | in_progress | deferred
    expected_seats: 7           # full-roster target; null = unknown (see "complete" below)
    # ── manual columns (hand-edited) ──
    geofenced: true
    donors: none                # none | partial | full
    candidates: none            # none | partial | full
    treasury: none              # none | partial | full
    # ── auto columns (written by coverage-sync, recomputed live by the API) ──
    populated: true             # has ≥1 active politician
    headshots: none             # none | partial | full  (photos / total)
    stances: { researched: 0, total: 7 }   # researched = last_stances_researched_at IS NOT NULL
    last_researched: null       # YYYY-MM-DD | null  (max last_stances_researched_at)
```

### Field ownership

- **manual** — `geofenced`, `donors`, `candidates`, `status`, plus all of `rules`.
  Edit by hand; the sync script never touches these.
- **auto** — `populated`, `headshots`, `stances`, `last_researched`, `treasury`, `synced_at`.
  Overwritten by `coverage-sync.ts` from the live database.

### Treasury (auto)

`treasury` is matched to `treasury.municipalities` by an **exact TIGER `geo_id` join** —
`treasury.municipalities.geo_id` (migration 194) ↔ the coverage location's district `geo_id`
(`resolveLocationGeoIds()` resolves it via `essentials.districts`). Rows whose treasury `geo_id` is
still NULL fall back to the legacy **name + state** slug. `full` = budgets loaded, `partial` =
municipality exists but no budgets, `none` = no match. Read-only against the treasury schema — it
never writes treasury data.

> `treasury.municipalities.geo_id` must be populated on import (handled by `resolveTreasuryGeoId()` in
> the budget importers; backfill existing rows with `scripts/backfill-treasury-geo-id.ts`). See the
> root `CLAUDE.md` → "Treasury ↔ TIGER geofence link".

The API also returns `treasury_orphans`: budget-bearing municipalities with **no matching coverage
row** (money data but no officials tracked — e.g. TX has 14 cities with budgets but no local rosters
yet).

### Granularity

One row per **tracked** jurisdiction (one we've started). Add a row when work begins. Do **not**
hand-enumerate every municipality — the full universe (and what's left) is computed automatically
(see below). The `state`-level row is the roll-up (it matches the entire `state:ut` OCD subtree).

### Universe — progress toward the whole state

```yaml
universe:
  state_fips: "49"          # FIPS code (matches geofence_boundaries.state); enables the geofence diff
  tribes:                   # static list — no tribal geofences/rosters loaded yet
    - Navajo Nation
    - ...
```

The admin API computes, per category, **how many of the entire state's jurisdictions have
politicians yet** and which remain — so you can see "10 / 255 cities populated". Totals come from
TIGER geofences in `essentials.geofence_boundaries` (counties `G4020`, cities/towns `G4110`, school
districts `G5420`); "populated" is derived by diffing those against `districts.ocd_id`. Tribes have no
geofences yet, so they're a static list here (all counted as not-yet-started). This block is **not**
touched by `coverage-sync.ts` — the universe is always computed live.

### "Complete" definition (full roster)

A jurisdiction is **complete** when its active politician count ≥ `expected_seats`. The statewide
progress bars count *complete* jurisdictions (green) vs *in progress* (started but under-rostered,
amber) vs *not started* (no politicians). `expected_seats` is manual:
- **Counties** — authoritative, from `ut_county_rosters.json` (commissioners/council seats +
  at-large officers). This is why Washington & Weber show 9/10 (a missing officer).
- **Cities & school districts** — seeded at the currently-loaded roster size as a baseline; verify
  against official council/board sizes and adjust. `null` means "unknown" → never counted complete.

### "Calibrated" definition

A politician is *calibrated* when `essentials.politicians.last_stances_researched_at IS NOT NULL`.
A location's `stances` is `researched / total` over its active politicians. The 180-day freshness
window only drives a "stale" badge on the admin page and a re-research hint in the skill — it does
**not** change the fraction.

## How a location maps to politicians

`essentials.politicians → offices.district_id → districts.ocd_id`, matched as a subtree:

```sql
WHERE d.ocd_id = $ocd OR d.ocd_id LIKE $ocd || '/%'
```

So a `place:salt_lake_city` row also counts its `…/ward:N` districts, and the `state:ut` row counts
everything. OCD `place:` and `county:` are siblings under `state:`, so a county row counts county
officials only — its cities are their own rows (no double-counting except at the state roll-up).

## Refreshing

After any data load (`load-ut-*.ts`, stance research, etc.):

```bash
cd ev-accounts/backend
npx tsx scripts/coverage-sync.ts --state ut --dry-run   # preview the diff
npx tsx scripts/coverage-sync.ts --state ut             # write auto cols back into ut.yaml
git add data/coverage/ut.yaml && git commit -m "chore(coverage): refresh UT auto columns"
```

The admin page recomputes auto columns live on each request, so it is always fresh; the committed
snapshot exists for git history and for the skill's offline read.

## Row types (`match`)

A location row matches politicians one of three ways:

| `match` | meaning | used for |
|---------|---------|----------|
| `subtree` (default) | `ocd_id` = X or under `X/` | a specific county / city / school district |
| `exact` | `ocd_id` = X exactly | statewide offices at the bare state OCD (Gov / U.S. Senate) |
| `kind` | all districts of `ocd_kind` under the state | **chamber aggregates** (U.S. House `cd`, State Senate `sldu`, State House `sldl`) |

Chamber rows carry `ocd_kind` and `match: kind`, share the state-prefix `ocd_id`, and use
`level: federal` (U.S. House) or `level: state` (legislature). Their `expected_seats` is the real
TIGER seat count, so e.g. "State House 150/150" is meaningful.

## Adding a new state — use the generator

```bash
cd ev-accounts/backend
npx tsx scripts/coverage-init.ts --state ca            # dry run — prints the YAML
npx tsx scripts/coverage-init.ts --state ca --write    # writes data/coverage/ca.yaml
```

`coverage-init.ts` derives everything from the live DB: chamber-aggregate rows (real seat counts
from TIGER geofences), a statewide-offices row where present, and one local row per county / city /
school district that has politicians. It leaves `rules.skip_topics` and `universe.tribes` empty and
seeds local `expected_seats` at the **loaded-roster baseline** (verify against official sizes).
Then edit by hand as needed and refresh auto columns with `coverage-sync.ts --state ca`. The admin
page picks the new state up via the `?state=` selector — no code changes required.

Universe categories with no TIGER geofences for the state are omitted; if more jurisdictions are
populated than the geofence universe contains (incomplete geofences, e.g. IN counties), that card is
flagged "universe size unknown" instead of showing a wrong fraction.

---

## State of the tracker — 2026-07-28

**12 states, 393 locations, all synced 2026-07-28.** Previously 7 states / 290, last synced
2026-05-30. New files this pass: `wi`, `az`, `nv`, `md`, `va`. (394 → 393 when `in.yaml` was
re-initialised later the same day — see the IN SCHOOL note below; it is a fold, not a loss.)

### Four things in this toolchain were broken and are now fixed

Nothing here was a deferred decision — the tools simply did not run, so the gap they exist to close
never closed. Worth knowing, because the same classes will recur:

| script | bug | effect |
|---|---|---|
| `coverage-init.ts` | joined the dropped `offices.politician_id` (ADR-0002 phase 5 / mig 1463) | every run died; no coverage file addable |
| `coverage-init.ts` | `geofence_boundaries.name` is nullable and null in practice (MA 5, IN 159, VA 1) | `r.name.replace()` threw and killed the whole run — `--state ma` produced **no output at all** while other states succeeded |
| `coverage-init.ts` | `STATE_NAME` held only the 7 states that already had a file | `--state wi` would have written `state_name: undefined`, silently |
| `backfill-district-ocd.ts` | same dropped-column join | the tool that fixes ~353 unmapped locals had been dead since the port |
| `backfill-district-ocd.ts` | revert-log path `../../.planning/coverage/` — one level too many, resolved outside the repo, dir absent | `--write` threw ENOENT **before** any UPDATE. Failed safe, but never worked |
| `backfill-district-ocd.ts` | revert-log date hardcoded `2026-05-30` in filename and payload | any later run produced a revert log lying about its own capture date |
| `coverage-sync.ts` | `/^synced_at:\s*.*$/` vs CRLF checkouts — JS `.` does not match `\r`, so `.*$` never reaches end-of-string | `synced_at` **never** updated on Windows while the script printed that it had; auto-field lines also dropped `\r`, leaving mixed line endings |

### ocd_id backfill: what it is safe to assume

`ocd_id` is read **only** by `coverageService` / `coverageMapService`. Address search joins
`geofence_boundaries.geo_id = districts.geo_id` and never reads `ocd_id`. **So a missing or wrong
`ocd_id` costs dashboard visibility, not public correctness** — Madison's alders were reachable by
address the whole time they were absent from this tracker.

**Review slugs BEFORE writing.** The write is
`WHERE ocd_id IS NULL OR ocd_id NOT LIKE 'ocd-division/%'`, so a wrong-but-well-formed slug is
**sticky** — a re-run will not correct it and you need a migration (see 1484). Three real defects
were caught this way, and one false alarm avoided:

- **`village` was missing** from the TIGER descriptor strip (`city|town` only). Invisible in states
  whose place names omit the descriptor, wrong in WI where names read "Elmwood Park village".
- **State-suffixed ward slugs.** Geo_id slugs sometimes disambiguate with a state code
  (`boston-ma-council-district-5`), producing `place:boston_ma` — which would have **split Boston
  into two coverage rows**, since its mayor row resolved to `place:boston`. Same for Lowell,
  Worcester, and CA/AZ equivalents. Now stripped generally, guarded on an exact match with that
  district's own state.
- **County boards mapped as places** (caught only by reading generated output — AZ showed a `local`
  row named "Pima"). The ward regex matches `council|supervisor`, and "supervisor" is county-board
  terminology. Fixed for 10 rows by mig 1484; the script now routes county-labelled LOCAL districts
  to `county:<slug>/council_district:N`.
- **False alarm worth not "fixing":** `boulder_city` (NV) and `wood_village` (OR) look
  type-suffixed but **are the real place names**. Only the *trailing* descriptor is stripped, so both
  were already correct. San Francisco likewise keeps `place:san_francisco` for its
  `sf-supervisor-district-N` rows — its Board of Supervisors *is* the city council of a consolidated
  city-county. The county rule is keyed on the **label** naming a county, which is what excludes SF.

### What is left

- **166 LOCAL/LOCAL_EXEC districts unmapped.** All are `--type LOCAL` skips: no G4110 place geofence
  and an unparseable ward layer. Needs geofence work, not this script. Includes 4 WI towns
  (Burlington, Dover, Norway, Waterford) which are MCDs with 10-digit geo_ids.
- **SCHOOL tier: COMPLETE.** See below.

#### SCHOOL tier finished — 2026-07-28 (36 districts / 244 officials, 0 skipped)

`backfill-district-ocd.ts --type SCHOOL --write` across all states. Revert log:
`.planning/coverage/backfill-log-school-2026-07-29.json` (the log stamps **UTC**, so an
afternoon-Pacific run dates tomorrow — the two logs from this one working day read 07-28 and 07-29).
Then `coverage-init --write` + `coverage-sync` for `ca ma me nv or tx va`. Verified through
`getCoverage()` per state: school tier is **120 rows / 657 officials, every row complete** —
CA 85/423, OR 12/74, MA 6/45, ME 5/36, TX 5/35, IN 5/24, NV 1/11, VA 1/9.

Slug review found **two defects, both the `village` class** — a descriptor that only fails to strip
in one state's naming style, invisible everywhere else. Both were caught by reading generated output
against the 125 slugs already in prod, in which **not one contains `school_district_` or a district
number**:

- **Oregon's district numbers carry a joint-district letter** ("Hillsboro School District 1J",
  "Beaverton ... 48J"). `\s+\d+$` could not match `1J`, which left the name ending in the number so
  the ` school district` strip could not match either — 6 of 12 OR slugs would have been
  `hillsboro_school_district_1j`, while OR's own numberless siblings (`reynolds`, `parkrose`,
  `david_douglas`) resolved clean. Now `\s+\d+[A-Za-z]?$`.
- **The 7 "unresolvable" skips were the nullable-name defect, not missing geography.** MA and VA city
  school departments are keyed to the **city place GEOID**, and their G5420 row exists with a **NULL
  `name`** (MA 5, VA 1 — Cambridge has no G5420 at all). TIGER offers no district name, so the script
  now falls back to `districts.label`, guarded by `BARE_SEAT_LABEL` so a per-seat label ("District 4",
  "At-Large" — what IN's consolidated sub-districts carry) can never become
  `school_district:district_4`.

Slugs deliberately kept as generated: `plano_independent` etc. are exactly analogous to the existing
`burbank_unified` (the qualifier stays, the words "School District" go); `san_diego_city_unified` and
`sacramento_city_unified` use TIGER's legal name over the label; `clark_county` is the real LEA name
and cannot collide with `county:clark` (different OCD kind). Pre-write checks, all clean: 0 exact
collisions, 0 internal duplicates (two districts → one slug would silently merge rows), 0 slugs
containing a district number, and CA/IN/UT are the only states with pre-existing school slugs — so
MA/ME/NV/OR/TX/VA had **no split risk at all**.

`ca.yaml` also picked up an unrelated stale-file correction: `place:riverside` → `county:riverside`
(+5 supervisors). Not a loss — `place:riverside` has 0 districts / 0 officials; migration 1484
re-keyed that county board and the file predated it.

#### 🔴 Two live bugs found in `coverageService.ts` while verifying this (both now fixed)

Neither was caused by the backfill; verifying the result is what exposed them.

- **`getCoverage()` 500'd for MA and VA.** `computeUniverse` → `toSlug(r.name)` had no null guard, so
  **a single NULL geofence name took down the whole coverage endpoint for that state** — the same
  nullable-name defect fixed in `coverage-init.ts` and missed here. The admin coverage page was dead
  for both states. `toSlug` is now null-safe and nameless geofences are excluded from name matching;
  they still count toward `total`, but the card is flagged `reliable: false` rather than listing them
  as "remaining", which for MA's school districts would falsely claim Boston/Lynn/Medford/Newton/
  Somerville are unstarted.
- **`UNIVERSE_LAYERS` strips had drifted from the backfill's**, so the universe card contradicted
  itself: OR read **"12 of 12 started" while listing 11 as remaining**, because the backfill strips a
  trailing district number and this did not. The `local` strip was also missing
  `village|borough|CDP`, the WI-village divergence. Measured A/B over all 12 states: named geofences
  matching a populated slug went **328 → 350**, with **no layer losing a match** (or school 1→12,
  wi local 3→14). **These strips and the backfill's must change together** — there is now a comment
  on both saying so.

**Still self-contradicting, pre-existing and NOT fixed by the strips** (populated slugs that no
TIGER name can match, mostly LA County rows slugged from labels like "ABC Unified Board" rather than
the TIGER name): `ca` school 34 unmatched, `in` local 12, `ca` local 1, `va` county 1. Each needs
individual judgement, not a regex.

#### IN SCHOOL + `in.yaml` re-init — DONE 2026-07-28

`backfill-district-ocd.ts --type SCHOOL --state in --write` resolved 2 districts / 14 politicians
(0 skipped), then `coverage-init --state in --write` + `coverage-sync --state in`. IN is **38 rows**,
and its school tier reads **24 officials across 5 rows, all complete** (IPS 7/7, MCCSC 7/7) —
verified through `getCoverage('in')`, not just SQL. Revert log:
`.planning/coverage/backfill-log-school-in-2026-07-28.json`.

The school changes:

- `school_district:mccsc` (6 seats) → `school_district:monroe_county_community_school_corporation`
  (7 seats); IPS `expected_seats` 6 → 7. **Both seat bumps are corrections**, not drift — the old
  6s were baselines seeded from the 6 stale sub-districts, while the rosters show MCCSC districts
  1–7 and IPS districts 1–5 + 2 at-large, no gaps.

**🔴 The re-init silently destroyed hand-authored `match: title` config, and the check below did not
catch it.** The earlier claim that "`U.S. Senate` folds into the combined statewide row" was wrong.
IN deliberately split them: a `match: title` + `office_title_like: "U.S. Senate%"` row, paired with
`exclude_title_like: "U.S. Senate%"` on the `match: exact` statewide row so the two do not
double-count. **`coverage-init` does not generate any of those three keys**, so re-init dropped the
Senate row and the exclude, merging Senate into statewide (5/28 + 2/2 → one 7/30 row) — which looks
like a clean fold in a row-count diff and is actually a loss of a deliberate distinction. Restored
by hand, and both rows now carry a `HAND-AUTHORED` comment saying re-init will drop them.

**`me.yaml` and `ut.yaml` have the same pattern (2 occurrences each) — do not re-init either without
restoring it afterward.** Grep before regenerating anything:

```bash
grep -l "match: title\|office_title_like\|exclude_title_like" data/coverage/*.yaml
```

**Why the MCCSC slug change was safe, and the check to repeat.** A new slug that differs from an
existing one is exactly the "split Boston into two rows" defect. It was safe here only because the
6 old `school_district:mccsc` sub-districts were **drained to 0 active politicians** by the
consolidation, so `coverage-init` no longer emits a competing row. **Verify that subtree is empty
before accepting a slug rename** — it is one query, and it is the difference between a correction
and a duplicate row. The descriptive slug is also the right house style (cf.
`eminence_community_school_corporation`, `SCHOOL_ALIAS`'s `los_angeles_unified`); `mccsc` rendered
on the dashboard as "Mccsc School District".

Two loose ends, both harmless:

- The 6 drained MCCSC sub-districts still carry `school_district:mccsc`, now orphaned outside the
  parent's subtree. OCD-correct would be `…monroe_county_community_school_corporation/board_district:N`.
  They hold 0 officials and `ocd_id` never affects address search, so this buys nothing today and
  would need a migration.
- 1 IN SCHOOL district (`geo_id 180063000007`, "District 7") still has `ocd_id = ''`. It has **0
  politicians**, so the script's politician join excludes it by design.

### Before regenerating any file

`coverage-init` **rewrites manual columns and `rules`, and drops any row shape it cannot generate.**
The check below used to cover only `rules` + `candidates`, which is how IN's `match: title` Senate
row was destroyed without anyone noticing (see above). It now also counts the title-match keys and
the other manual columns:

```bash
node -e "const y=require('js-yaml'),f=require('fs');for(const n of f.readdirSync('data/coverage').filter(x=>x.endsWith('.yaml'))){const d=y.load(f.readFileSync('data/coverage/'+n,'utf8')),L=d.locations||[];const t=L.filter(l=>l.match==='title'||l.office_title_like||l.exclude_title_like).length,m=L.filter(l=>['candidates','donors'].some(k=>l[k]&&l[k]!=='none')||l.geofenced===false||(l.status&&l.status!=='active')).length;if(t||m||(d.rules.notes||[]).length||(d.rules.skip_topics||[]).length)console.log(n.padEnd(9),'title-match rows',t,'| non-default manual',m,'| notes',(d.rules.notes||[]).length,'| skip_topics',(d.rules.skip_topics||[]).length)}"
```

Any nonzero **`title-match rows`** means re-init will silently drop a deliberate row split —
re-add it afterward. The count is **2 per split** (the `match: title` row plus the `match: exact`
row carrying its paired `exclude_title_like`); both halves must come back or the two rows
double-count. As of 2026-07-28: **`in` 2** (destroyed by this pass's re-init, restored), **`me` 2**,
**`ut` 2** — plus `ut`'s 3 hand-set `candidates` / 1 note / 1 skip_topic and `wi`'s 5 notes.
`coverage-sync` is always safe — it does surgical line edits.
