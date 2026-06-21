# Phase 141: Roster Lock + Seed (Records + Headshots) - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the authoritative ~208-office elected-Big-5 roster (which of Governor / Lt. Governor / Attorney General / Secretary of State / Treasurer each state *popularly elects*), then idempotently seed every **missing** politician + office record across all 50 states — with `role_canonical` set and a headshot on every newly-seeded exec. Covers **SEXR-01..04**.

**In scope:** roster lock (SEXR-01); idempotent gap-seed of missing elected Big-5 records (SEXR-02); `role_canonical` backfill incl. existing Big-5 (SEXR-03); headshots for new execs (SEXR-04).

**Out of scope (other phases / milestones):** stance research (SEXS-01/02 → Phases 142–143); feed-surfacing smoke-test + phase gate (SEXR-05/SEXS-03 → Phase 144); non-Big-5 statewide officers; appointed/legislature-selected offices; AZ Lt. Governor (not seated until Jan 2027).
</domain>

<decisions>
## Implementation Decisions

### Treasurer-equivalent mapping
- **D-01:** **Functional mapping.** Where a state abolished its elected Treasurer and an elected Comptroller/CFO now performs the function — **NY Comptroller, TX Comptroller, FL CFO** — map that office to `role_canonical='treasurer'` and count it as the state's Big-5 Treasurer. Keep the office's real display title (e.g. "Comptroller", "Chief Financial Officer").
- **D-02:** Where a *separate* elected Comptroller coexists with an appointed/legislature-selected Treasurer (e.g. **MD**: elected Comptroller + legislature-chosen Treasurer), the elected Comptroller is **NOT** the Big-5 Treasurer — it is a non-Big-5 office, out of scope, and the state is recorded as having no in-scope elected Treasurer. (MD's existing Comptroller record stays untouched.)

### external_id scheme
- **D-03:** Newly-seeded execs use **`-(state_fips * 100000 + seq)`**, `seq` 1–9. This is the only scheme universally below the federal US-House band (**-1001 … -56000**) for all 50 state FIPS — confirmed by prod query 2026-06-20. (`-(fips*100+seq)` and `-(fips*1000+seq)` both fall *inside* the federal band, e.g. VA fips 51 → -5101 / -51001 → collision; rejected.) Matches OR's existing convention.
- **D-04:** **Mandatory preflight before any seed migration:** for every computed id assert (a) `id < -56000` and (b) `id` not already present in `essentials.politicians`. Never assume the formula — verify the range is clear against prod.
- **D-05:** Do **not** retrofit the existing inconsistent ids (MD/ME/VA use fips×10000; CA/MA/TX are ad-hoc; IN uses positive ids). We only seed *missing* records, so old ids are left as-is — except UT (see D-08).

### Existing-record handling (the 68 STATE_EXEC records, 9 states)
- **D-06:** Backfill `role_canonical` (`governor`/`lt_governor`/`attorney_general`/`secretary_of_state`/`treasurer`) on the existing **Big-5** records. `role_canonical` is the dormant column on `essentials.offices`; it becomes the cross-state dedup/query key.
- **D-07:** **Leave display titles as-is** — do NOT normalize "Indiana Governor"→"Governor" etc. Cosmetic churn with no user value and breakage risk. Title inconsistency is tolerated; `role_canonical` carries the canonical identity.
- **D-08:** **Fix UT's 5 NULL external_ids** — assign via the D-03 scheme (`-(49*100000+seq)`, UT fips 49). NULL ids break idempotent `ON CONFLICT` keys, so this is required for clean re-runs.
- **D-09:** **Hard no-reseed guarantee.** Dedup on `(district_type='STATE_EXEC', uppercase state, role_canonical)` — never title string. Dry-run gap query MUST return **0 new INSERTs** for already-present Big-5 offices before any write. Non-Big-5 officers (Comptroller-as-distinct, Auditor, Commissioners, etc.) are untouched entirely. (Migrations `192_ca_exec_dedup.sql` + `223a_or_executive_district_fix.sql` are the real prior traps this prevents.)
- **D-10:** Every seeded district row asserts **uppercase `state`** and **non-empty `geo_id`** inline (the `223a` lowercase-`or` defect made OR execs silently invisible to the feed's `WHERE d.state = $1` uppercase match).

### Roster source of truth (SEXR-01)
- **D-11:** **Wikipedia "List of current [office]" tables** are the structured primary source (parseable via WebFetch, current to Jan-2026 inaugurations, include party + selection method). **Cross-check each officeholder against the state's official `.gov`** page when Wikipedia is ambiguous. Ballotpedia *individual* politician pages are tertiary; Ballotpedia *list/category* pages are JS-rendered and return empty — do not rely on them for the roster.
- **D-12:** **As-of cutoff: 2026-06** ("current officeholder as of seed date"). Capture a **source URL per office** in the roster (feeds SEXR-01 + the SEXS-02 context rows later). Individually verify known-contested cases: **WA Treasurer** elected-vs-appointed status; any **2025-election turnover** (e.g. VA Spanberger/Hashmi/Jones already reflected in DB).

### Claude's Discretion
- Seed migration batching (one migration vs regional waves) — planner's call; the 41 empty states are a bounded set. Reuse the `seed-national-house-reps.ts` "generate a reviewable SQL migration" pattern.
- Headshot fallback when no portrait is found: default to **honest-skip** (no headshot, mirroring the McDowell precedent) rather than a placeholder — but planner may use `find-headshots` fallbacks first.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & requirements
- `.planning/REQUIREMENTS.md` — SEXR-01..05, SEXS-01..03; out-of-scope + deferred (AZ Lt Gov) definitions
- `.planning/ROADMAP.md` §"v2.18 State Leaders" / Phase 141 — goal + success criteria
- `.planning/PROJECT.md` §"Current Milestone: v2.18 State Leaders" — gap baseline + Key Decisions

### Research (this milestone — read before authoring)
- `.planning/research/SUMMARY.md` — synthesized findings; 208 denominator, build order, external_id conflict resolution
- `.planning/research/FEATURES.md` — the 50-state elected-Big-5 matrix + per-office exception sources (the roster skeleton for SEXR-01)
- `.planning/research/ARCHITECTURE.md` — feed-surfacing trace, seed model, external_id scheme rationale
- `.planning/research/PITFALLS.md` — dedup/state-code/external_id traps + office-type evidence framework (matters in 142–143)

### Reusable code assets
- `backend/scripts/seed-national-house-reps.ts` — the idempotent "generate a reviewable migration" seeding pattern to mirror (gap-iteration, ON CONFLICT, dry-run report)
- `backend/migrations/270_md_state_executives.sql` + `271_md_executive_headshots.sql` — cleanest recent STATE_EXEC seed + headshot precedent (fips×10000 era)
- `backend/migrations/192_ca_exec_dedup.sql`, `backend/migrations/223a_or_executive_district_fix.sql` — the dedup + lowercase-state defects to NOT repeat
- `backend/src/lib/essentialsService.ts` — feed query enumerates `STATE_EXEC` at both sites (~L706 `getRepresentativesByAddress`, ~L1589 `getRepresentativesByJurisdiction`); `WHERE d.state = $1` uppercase match (no code change this phase)
- find-headshots skill — headshot sourcing/storage-mirror pattern (SEXR-04)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `seed-national-house-reps.ts`: idempotent gap-seed → reviewable SQL migration with dry-run coverage report; adapt for STATE_EXEC.
- MD migrations 270/271: per-office STATE_EXEC district + politician + office + headshot seed in one reviewable migration.
- `find-headshots`: official `.gov`/Ballotpedia/Wikimedia portrait sourcing + storage mirror.

### Established Patterns
- One `essentials.districts` row **per office** (not per state), `district_type='STATE_EXEC'`, `state='XX'` UPPERCASE, `geo_id`=FIPS string non-empty.
- `role_canonical` column exists on `essentials.offices` (added migration 154) but is **dormant** — never read by service code yet; populate for Big-5.
- Feed surfacing already wired — seeding data alone makes execs appear; **no backend/route changes in this phase**.

### Integration Points
- New records surface automatically via the existing state-code path in `essentialsService.ts` (verified in Phase 144's smoke-test, not here).
- Dedup/idempotency key: `(STATE_EXEC, uppercase state, role_canonical)`.

</code_context>

<specifics>
## Specific Ideas

- The 9 existing states' elected Big-5 **records** are essentially complete (prod inventory 2026-06-20) — the seed gap is overwhelmingly the **41 empty states**, plus the UT NULL-id fix and `role_canonical` backfill. (Their *stance* gaps — IN AG/SoS/Treasurer, all of ME, all of TX — are Phase 142–143, not here.)
- Denominator is ~**208 elected offices**, NOT 250 — the roster (SEXR-01) is the authoritative count and gates everything downstream.

</specifics>

<deferred>
## Deferred Ideas

- **Non-Big-5 statewide officers** (Auditor, Comptroller-as-distinct, Superintendent, Insurance/Labor/Ag/PUC Commissioners, Land/Boards) — future coverage milestone.
- **AZ Lieutenant Governor** — office not seated until Jan 2027; documented exclusion, future milestone.
- **State-exec FEC/state campaign finance** — FINA stream.
- **Display-title normalization** across existing records — cosmetic cleanup, not pursued (D-07).

None of these are in Phase 141 scope.

</deferred>

---

*Phase: 141-roster-lock-seed-records-headshots*
*Context gathered: 2026-06-20*
