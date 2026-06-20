# Pitfalls Research

**Domain:** Civic data platform — adding elected Big 5 state executives to an existing multi-tier politician database
**Researched:** 2026-06-20
**Confidence:** HIGH (all pitfalls grounded in actual production migrations and confirmed defects in this codebase)

---

## Critical Pitfalls

### Pitfall 1: Seeding Phantom Offices — Appointed Officers Treated as Elected

**What goes wrong:**
The roster phase produces a naive 50×5 grid and seeds all five roles for every state. This creates politician and office records for appointed positions that should never appear in the elected-rep feed — Maine AG/SoS/Treasurer (legislature-elected), TX SoS (governor-appointed), UT SoS (does not exist), VA SoS (governor-appointed), MD SoS (governor-appointed). Users in those states see the wrong person listed as an "elected" official they can hold accountable.

**Why it happens:**
"Big 5" is shorthand that implies a flat grid. The temptation is to treat all five roles as structurally identical and source names from a single aggregator (e.g., NGA/Ballotpedia) without reading the "how selected" column carefully. Maine is especially deceptive: it has an AG, SoS, and Treasurer, but all three are elected by the state legislature in Joint Convention — not by voters.

**How to avoid:**
The roster phase must produce a per-state table with explicit columns: `office`, `selection_method` (voter-elected / legislature-elected / governor-appointed / does not exist), and source URL. Each row must be individually verified against the state .gov or Ballotpedia "How selected" section — never defaulted. A Big 5 office is only in scope when `selection_method = voter-elected`.

**Warning signs:**
- Any state with all five offices checked without a source URL per office
- ME, TX, UT, VA, MD not listed as partial/exception states on the roster
- `is_appointed_position=false` on a Maine AG, SoS, or Treasurer record

**Phase to address:**
Roster phase (Phase 1 of the milestone). The roster is the gate — seed and stance phases must be derived from it, never independently deciding scope.

---

### Pitfall 2: Duplicating Existing Records via Title-String Dedup

**What goes wrong:**
The seed migration matches existing records by `office_title` or `label` string, fails to find an existing "Indiana Governor" because the new migration checks for "Governor", and creates a second politician + office + district for the same person. The dedup migration (CA's `192_ca_exec_dedup.sql`) required hardcoded UUIDs and a three-step delete/update/repair cycle to undo — expensive and risky to replay on 68 existing records across 9 states.

**Why it happens:**
Existing STATE_EXEC titles are inconsistent across states. Migration `103` used "Texas Governor" (state-prefixed). Migration `154` used "Governor" (short form, MA-namespaced via chamber). Migration `190` used "California Governor" (state-prefixed label). A title-string check like `WHERE title = 'Governor'` misses "Indiana Governor"; a check for "Indiana Governor" misses "Governor". The CA dedup (`192`) is proof this trap already fired once in production.

**How to avoid:**
The seed migration must dedup on `(district_type='STATE_EXEC', state='XX')` for the existence check, not on title strings. The gap query should be:
```sql
SELECT state FROM <roster>
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id = d.id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.district_type = 'STATE_EXEC'
    AND d.state = roster.state_code
    AND <office_kind_match>  -- role_canonical or chamber name pattern
    AND p.is_active = true
)
```
This is the "iterate the gap, not the roster" principle (established v2.15, KEY DECISION in PROJECT.md).

**Warning signs:**
- Seed migration uses `WHERE title = 'Governor'` or `WHERE label LIKE '%Governor%'` without also scoping by `state` and checking the existing chamber structure
- A state that already has STATE_EXEC records (CA, IN, MA, MD, ME, OR, TX, UT, VA) produces new rows instead of zero rows when the migration is dry-run against production

**Phase to address:**
Seed phase (Phase 2). The gap query must be written and executed as a diagnostic read before authoring any INSERT statements. Verify output from prod ref `kxsdzaojfaibhuzmclfq` shows exactly 0 new rows for the 9 already-seeded states.

---

### Pitfall 3: Lowercase `state` Code on STATE_EXEC Districts Silently Breaking Feed Routing

**What goes wrong:**
A STATE_EXEC district inserted with `state='or'` (lowercase) never appears in any user's representative feed — the query at `essentialsService.ts:707` filters `WHERE d.state = $1` where `$1` is the uppercase two-letter postal abbreviation. The politician record exists in the database but is completely invisible. This defect already shipped to production in migration `223` and required a repair migration (`223a`).

**Why it happens:**
State codes are passed as `$1` from user district cache (which stores uppercase postal abbreviations, e.g. `'OR'`). There is no CHECK constraint on `essentials.districts.state` enforcing uppercase. A migration author writing the state code by hand will occasionally use lowercase, mixed-case, or a FIPS code (`'41'`) instead of the postal abbreviation.

**How to avoid:**
Every new STATE_EXEC district INSERT must use the uppercase two-letter postal abbreviation (e.g., `'OR'`, `'TX'`, `'WY'`). Include a post-insert assertion in the migration:
```sql
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM essentials.districts
    WHERE district_type = 'STATE_EXEC' AND state != upper(state)
  ) THEN RAISE EXCEPTION 'state column contains non-uppercase values'; END IF;
END $$;
```
The gate SQL must also assert `state = upper(state)` across all STATE_EXEC rows.

**Warning signs:**
- Any state code with lowercase letters in the migration source
- A newly seeded exec who does not appear in the feed for users in that state immediately after migration apply

**Phase to address:**
Seed phase (Phase 2). The assertion should be part of the migration itself, not a post-hoc check.

---

### Pitfall 4: Gov+LtGov Ticket Turnover — Wrong Officeholders from Stale Sources

**What goes wrong:**
Many governors and lieutenant governors took office January 2026 after 2024 elections (37 gubernatorial races in 2024). Virginia's 2025 elections replaced all three Big 5 slots (Spanberger/Hashmi/Jones, confirmed per migration 317). Sources cached before January 2026 — Wikipedia article snapshots, training data, cached NGA pages — may list the outgoing governor. The record is seeded with the wrong person's name, stances are researched for someone who is no longer in office, and the error persists until manually corrected.

**Why it happens:**
The roster phase uses aggregator sources (NGA.org, Ballotpedia) that are generally current but can lag 1-4 weeks post-inauguration. Research agents working from training knowledge rather than fetching current state .gov pages will produce stale rosters. VA is the highest-risk case because its January 2026 transition was recent.

**How to avoid:**
Every officeholder name in the roster must be verified from a live fetch of the current state .gov governor/executive page, not from training data or a cached aggregator. For states with January 2026 inaugurations, the fetch must post-date January 2026. The roster phase output should include the URL fetched and the date fetched for each row.

For any state in the 9 already-seeded set, also verify the existing record is current — do not assume it is. Migration 317 is a proof point that VA was updated, but an IN, ME, or TX exec who changed in 2024 may not have been updated yet.

**Warning signs:**
- Any officeholder name that matches the 2022-inaugurated governor rather than the 2026-inaugurated one for states with 2024 elections (e.g., NC, WI, MO, NH, WV, ND, UT, WA, VT, OR)
- Roster sourced from a single URL with no date verification

**Phase to address:**
Roster phase (Phase 1). Every row must include a verified source URL and the research agent must explicitly fetch the state .gov page, not rely on training memory.

---

### Pitfall 5: Stance Evidence Mismatch by Office Type — Over-reading or Under-sourcing Exec Actions

**What goes wrong:**
Research agents apply the legislator evidence framework to executive officials and produce either (a) underpopulated stances ("no floor votes found") or (b) over-read proxy rows ("AG's office issued a press release mentioning climate"). State executives act via different mechanisms than legislators, and each role type has specific legitimate evidence forms.

**Why it happens:**
The v2.16/v2.17 pipeline was built for legislators. The TOPIC_SCALE instructions reference floor votes, co-sponsorships, and caucus memberships — all irrelevant for executives. Governors sign or veto bills; AGs file lawsuits, join multistate coalitions, and submit amicus briefs; Treasurers make investment/divestment decisions; SoS officials administer election policy. An agent trained on the legislative framework will either skip legitimate exec evidence or accept office-action descriptions that don't actually document a position.

**How to avoid:**
The stance research skill prompt must be updated with office-type-specific evidence guidance before any research agents are dispatched. Per office type:

- **Governor:** Bill signings/vetoes (documented at legislature.state.gov or governor press room), executive orders (official EO archive), public statements in official press releases. Inaugural address is acceptable for broad position statements. Campaign platform is documentary (above the caucus bar) for recent inaugurees.
- **Lt. Governor:** Same sources as Governor for any stated positions; also committee assignments if Lt Gov presides over a specific domain. Thin records are common — honest-partial is correct; never infer from governor's positions.
- **Attorney General:** Multistate coalition membership is acceptable ONLY when the coalition has a published policy position directly on that topic (analogous to the caucus rule). Filed lawsuits or amicus briefs are the strongest evidence — document the case name and docket. Declined to join a coalition = evidence of opposite position (document the news source). Department-issued guidance or opinion letters are legitimate. AG's political party alone is never sufficient.
- **Secretary of State:** Election administration actions (certifying results, refusing to certify, suing over election rules, issuing voting guidance) map to the `voting` and `elections` topics. Public statements on specific election legislation are valid. "Administers elections" as a role description alone is not a documented stance.
- **Treasurer:** Investment/divestment decisions (documented fund actions or board votes) are the strongest evidence for topics like climate (fossil fuel divestment), tariffs (trade bond positions), and healthcare (state pension coverage decisions). ESG policy statements from the state investment board are legitimate. Budget proposal priorities are acceptable for fiscal topics.

The proxy-row drop rules from v2.17 still apply: "overall record alignment" rows, coalition membership without a published topical platform, and committee role ≠ any topic are all dropped. An honest-partial with 4-8 stances is correct for a Treasurer or Lt. Gov who lacks documented positions on most compass topics.

**Warning signs:**
- Any AG stance sourced only from "AG's office works on [topic]" or "AG is a Democrat/Republican"
- Any Treasurer stance sourced only from a budget overview page without a specific fund action
- Any SoS stance sourced from "SoS administers elections" without a specific policy action
- Lt Gov stances that exactly mirror the same-state Governor's stances without independent sourcing

**Phase to address:**
Stance research phase (Phase 3). The updated skill prompt is the prevention; the proxy-row review gate (now standard since Phase 138) catches any that slip through.

---

### Pitfall 6: Re-researching Already-Stanced Executives (Scope Creep into Existing Records)

**What goes wrong:**
The stance phase dispatches agents for all STATE_EXEC officials in the in-scope states, including CA officials who already have complete compass coverage and IN Governor who already has stances. The push script overwrites existing well-sourced stances with new research, potentially downgrading quality or introducing errors.

**Why it happens:**
The v2.16/v2.17 pipeline filtered by `WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers WHERE politician_id = p.id)` scoped to the external_id range. For state execs, the external_id scheme is heterogeneous (positive legacy IDs for some CA execs, -06000xxx for others after migration 192, -200xxx for MA, -510xxx for VA). A naive filter on external_id range will miss some already-stanced records.

**How to avoid:**
The stance gap query must use the same pattern as v2.17: filter by `NOT EXISTS` on `inform.politician_answers`, keyed on the politician UUID — not on external_id range. For the 9 already-seeded states, run the diagnostic before authoring any research plans:
```sql
SELECT p.full_name, p.external_id, COUNT(pa.id) as stance_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
WHERE d.district_type = 'STATE_EXEC'
GROUP BY p.id, p.full_name, p.external_id
ORDER BY stance_count, p.full_name;
```
Only dispatch research agents for rows where `stance_count = 0`.

**Warning signs:**
- Stance research plan includes CA Governor Newsom, CA AG Bonta, or any CA exec (all are fully stanced)
- Plan includes any IN Governor (already stanced per PROJECT.md context)

**Phase to address:**
Stance research phase (Phase 3) setup — gap diagnostic must be the first step before any research agents are dispatched.

---

### Pitfall 7: Dedup Key Collision in the `external_id` Scheme

**What goes wrong:**
The state exec external_id scheme is not uniform across the 9 existing states. CA used `-06000101` through `-06000108`. MA used `-200001` through `-200007` (with a gap at `-200002` due to a pre-existing collision with CA politician Curren D. Price Jr.). TX used `-100202` through `-100207`. A new 41-state batch that adopts one pattern will collide with an existing range if it accidentally uses `-{FIPS}00X` for a FIPS code that was already used differently.

**Why it happens:**
The negative external_id space was allocated ad hoc per migration. There is no global registry or reserved-range table. CA used `-(fips*1000000 + sequential)`. TX used a flat negative sequence. MA used a flat negative sequence starting at -200001. A new migration for AL (FIPS 01) using `-01000101` would be fine; one using `-200008` would collide with MA's next available slot.

**How to avoid:**
Before authoring the seed migration for any new state, query production for the full range of existing negative external_ids among STATE_EXEC politicians and define a non-overlapping range. The safest convention for v2.18 is `-(state_fips * 10000 + office_seq)` which gives each state 9,999 exec slots. Verify 0 collisions with a pre-flight SELECT before the batch INSERT. Document the chosen scheme explicitly in the migration header comment.

**Warning signs:**
- `ON CONFLICT (external_id) DO NOTHING` silently skips a politician because the external_id was already taken by a different politician
- Post-migration row count is less than expected

**Phase to address:**
Seed phase (Phase 2). The external_id scheme must be defined in the roster phase and verified for collisions before the seed migration is written.

---

### Pitfall 8: Missing `geo_id` on STATE_EXEC Districts Breaks Feed Geo-Matching

**What goes wrong:**
STATE_EXEC districts with `geo_id=''` (empty string) existed in the original migrations (TX `103`, OR `223`) and were patched in `223a` and implicitly by later migrations. A new state migration that uses empty string or NULL for `geo_id` will seed records that appear in the database but may be unreachable depending on future geo-matching logic additions.

**Why it happens:**
STATE_EXEC districts do not use TIGER polygon matching (there's no geofence for "the whole state"). The current feed query (`essentialsService.ts:707`) filters only by `d.state = $1` for STATE_EXEC rows, so `geo_id` is not currently load-bearing in the query path. This makes the defect invisible in testing — the records surface correctly despite the bad value — but creates a latent data quality problem.

**How to avoid:**
Every STATE_EXEC district must have `geo_id = '{state_fips}'` (the two-digit state FIPS code as a string, e.g., `'48'` for TX, `'23'` for ME). This is already the established pattern in migration `154` (MA) and `317` (VA). Include a gate assertion: `WHERE district_type='STATE_EXEC' AND (geo_id IS NULL OR geo_id = '')` should return 0 rows.

**Warning signs:**
- Any `geo_id = ''` or `NULL` on a STATE_EXEC district in a new migration
- FIPS code inserted as an integer (`48`) rather than a string (`'48'`)

**Phase to address:**
Seed phase (Phase 2). The gate SQL should assert non-empty `geo_id` on all STATE_EXEC rows.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use NGA or Ballotpedia as sole elected/appointed source | Fast roster construction | May lag post-inauguration by weeks; NGA lists appointed AGs as if elected in some states | Never for a milestone that spans all 50 states; always verify against state .gov |
| One migration per state (41 states = 41 migrations) | Easy to review individually | Migration directory bloat; numbering pressure | Group by natural batches (e.g., 10 states per migration) to stay within reasonable migration count |
| Skip `role_canonical` on new exec offices | Simpler migration | `role_canonical` is the only mechanism to normalize cross-state title aliases at query time for future features | Set it now for all Treasurer and SoS offices; NA for Governor/LtGov/AG which have standard titles |
| Research stances for all 50 governors at once | Parallelism | Rate limit hits; no per-batch validation; proxy rows go unreviewed | Use the 3-concurrency cap, validate first wave before proceeding (MEMORY.md standing rule) |
| Infer LtGov stances from same-ticket Governor | Fast fill for sparse record | Violates the evidence-over-party guardrail; Lt Gov and Gov may diverge on compass topics | Never — honest-partial is always correct |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Feed surfacing (`GET /representatives/me`) | Assuming STATE_EXEC is already wired for new states because CA works | The query filters `d.state = $1` — the state code on the district must match the user's stored state exactly. Test with a user in a newly seeded state to confirm. CA works because it was seeded; new states work only after their districts are seeded with correct uppercase state codes. |
| Ballotpedia "How selected" | Reading the "partisan election" badge and assuming voter-elected | Some offices labeled as "partisan election" are elected by the legislature in partisan votes (ME). Always read the "Ballotpedia describes this office as..." section or the state constitution source. |
| NGA Governor directory | Using NGA as the sole source for the full Big 5 roster | NGA covers only Governors and Lt. Governors. AG/SoS/Treasurer selection methods must be sourced from state constitutions or Ballotpedia. |
| Existing IN/ME/TX gap-fill stances | Treating these as new research | These politicians already have records — only stances are missing. The push must use their existing politician UUIDs, not create new records. Query the UUID before dispatching research. |
| `role_canonical` query | Assuming the column exists on all offices tables | `role_canonical` was added in migration `154`. It exists. But it is currently NULL on most exec offices (only MA Treasurer and SoS have it set). Do not build feed logic that depends on `role_canonical` being non-null for Big 5 filtering — use `district_type = 'STATE_EXEC'` instead. |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Dispatching 41-state stance research in a single wave | Agent queue exhaustion, rate limit hits, empty output on some agents | Cap at 3 concurrent research agents (MEMORY.md); validate first 3-rep wave before proceeding | At >3 concurrent on premium tier |
| Full-table scan of `inform.politician_answers` to find stance gaps | Slow gap diagnostic | Scope by politician UUID list derived from `WHERE d.district_type='STATE_EXEC'`; do not scan the full 10k+ answer table | Not a problem at current scale, but scope it correctly from the start |
| Chamber subquery without `government_id` scope | Returns multiple chambers with same name from different states | Always include `AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of X' AND state = 'XX')` in chamber lookups | Any migration where two states share a chamber name (e.g., "Governor" is used in CA and VA) |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Setting `is_appointed=false` on an appointed official | User sees a governor-appointed SoS labeled as an elected official they voted for, undermining trust | The roster phase must explicitly set `is_appointed_position=true` for every legislature-elected or governor-appointed office; never default to false |
| Seeding stances for an official who is no longer in office | Stances attributed to a departed official damage data credibility | Verify incumbency before researching stances; set `is_incumbent=false` and `is_active=false` for outgoing officials rather than researching their stances |

---

## "Looks Done But Isn't" Checklist

- [ ] **Roster completeness:** Every state has a source URL per office, not just per state — ME's three appointed execs need individual source confirmation.
- [ ] **Elected filter applied:** Confirm the count of in-scope (voter-elected) execs matches the roster. ME=1, TX=3, OR=4, UT=4, VA=3, MD=3. Any deviation needs explanation.
- [ ] **Existing record gap verification:** Run the stance count diagnostic against production before dispatching any research agents. CA should show all 8 with stances; IN should show Governor stanced, AG/SoS/Treasurer at 0.
- [ ] **State code case check:** `SELECT DISTINCT state FROM essentials.districts WHERE district_type='STATE_EXEC'` should return only uppercase two-letter codes.
- [ ] **Feed test per new state:** Manually verify at least 3 newly-seeded states return the correct exec in `GET /representatives/me` for a user with a stored state code in that state.
- [ ] **Proxy-row review gate:** Before any push, review agent output for AG/Treasurer/SoS stances that cite only "office works on X topic" or "coalition membership" without a specific action. Drop them.
- [ ] **external_id collision check:** `SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id` — verify no new exec external_id overlaps any existing negative ID.
- [ ] **`geo_id` non-empty:** `SELECT COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' AND (geo_id IS NULL OR geo_id = '')` must return 0 after seed migrations.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Phantom appointed office seeded | MEDIUM | Set `is_active=false` on the politician and `is_vacant=true` on the office; do not delete (preserve FK integrity); add a correction migration with the fix documented |
| Duplicate politician created (title-dedup failure) | HIGH | Requires a dedup migration in the style of `192_ca_exec_dedup.sql`: null out `office_id`, delete duplicate office, delete duplicate politician, delete duplicate district, update original politician's external_id, fix any corrupted title — all in one transaction |
| Lowercase `state` code on district | LOW | One-line UPDATE with a WHERE clause scoped to the bad FIPS, as in migration `223a` |
| Wrong officeholder name (stale roster) | MEDIUM | Update `full_name`, `first_name`, `last_name` on the politician row; if stances were already researched for the old person, delete them and re-research for the current officeholder |
| Over-populated proxy stances pushed | MEDIUM | DELETE from `inform.politician_answers` and `inform.politician_context` WHERE `politician_id IN (...)` AND topic_id IN (...) for the affected rows; re-research with the corrected evidence standard |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Phantom appointed offices | Phase 1: Roster | Per-state table with `selection_method` column; count of voter-elected offices matches known exceptions (ME=1, TX=3, etc.) |
| Title-string dedup failure | Phase 2: Seed | Dry-run gap query against prod returns 0 rows for 9 already-seeded states |
| Lowercase state code | Phase 2: Seed | Post-migration assertion in migration SQL + gate SQL `upper(state)` check |
| Stale officeholders | Phase 1: Roster | Source URL + fetch date per row; explicit check for 2024-election states |
| Wrong evidence type for exec office | Phase 3: Stances | Updated TOPIC_SCALE / skill prompt with AG/Treasurer/SoS guidance before first agent dispatch |
| Re-researching stanced execs | Phase 3: Stances | Stance gap diagnostic run before any research plans authored |
| external_id collision | Phase 2: Seed | Pre-flight SELECT for collision; documented scheme in migration header |
| Empty `geo_id` | Phase 2: Seed | Gate SQL asserts 0 rows with `geo_id IS NULL OR geo_id = ''` for `district_type='STATE_EXEC'` |
| Feed not surfacing new states | Phase 4: Feed surfacing | Smoke test: user with stored state code in 3 newly-seeded states hits `GET /representatives/me` and sees the correct exec |

---

## Sources

- Migration `103_texas_state_federal_officials.sql` — TX exec pattern (title-prefixed chambers, flat negative external_ids)
- Migration `154_ma_state_executives.sql` — MA exec pattern (role_canonical established, -200xxx scheme, external_id -200002 gap from CA collision)
- Migration `169_me_state_executives.sql` — ME exec pattern (legislature-elected AG/SoS/Treasurer documented with is_appointed_position=true)
- Migration `190_ca_state_executives.sql` — CA exec first attempt (seeded duplicates because pre-existing records existed)
- Migration `192_ca_exec_dedup.sql` — CA dedup repair (hardcoded UUIDs, three-step cycle — the cost of title-string dedup failure)
- Migration `223_or_executive_officials.sql` + `223a_or_executive_district_fix.sql` — OR lowercase state code defect and repair
- Migration `317_va_state_executives.sql` — VA exec pattern (2025 election turnover; pre-flight government row assertion)
- `backend/src/lib/essentialsService.ts:707` — STATE_EXEC feed query (`WHERE d.state = $1`) confirming state-code matching is the sole filter for exec surfacing
- PROJECT.md v2.18 section — milestone scope, gap baseline (68 records / 9 states), known exceptions (ME/OR no LtGov, TX no elected Treasurer/appointed SoS, UT no SoS, VA/MD appointed SoS)
- PROJECT.md Key Decisions — "iterate the gap, not the roster" (v2.15); v2.17 proxy-row drop rules (agent efficiency, caucus membership standards); 3-concurrency cap (MEMORY.md)

---
*Pitfalls research for: v2.18 State Leaders — elected Big 5 statewide executives across 50 states*
*Researched: 2026-06-20*
