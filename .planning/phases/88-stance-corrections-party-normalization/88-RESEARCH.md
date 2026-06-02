# Phase 88: Stance Corrections + Party Normalization — Research

**Researched:** 2026-06-02
**Domain:** Data correction via direct SQL / pool.query(), research-stances skill, PostgreSQL UPDATE migration
**Confidence:** HIGH

---

## Summary

Phase 88 is a data-correction phase, not a feature phase. All work is either (a) re-researching individual politicians using the research-stances skill and applying corrections via migration files, or (b) running a single UPDATE statement to normalize party strings across `essentials.politicians`. No new API endpoints, no schema changes, no frontend work.

The 87-AUDIT-REPORT.md is the canonical work queue. Tier 1 (8 confirmed inversions) is the highest priority and most certain — these politicians have systematic stance assignments that contradict their documented public record. Tier 2 (21 borderline cases) requires individual judgment; the MA value=3 cluster requires separate investigation (batch research artifact vs. genuine centrism). Tier 3 (226 likely-correct) is not a correction target unless evidence surfaces otherwise.

The Ukraine-support verification (Wave 3) is investigative, not automatically correctional: 25 Republicans at value=2 may reflect accurate pre-2025 positions. Each must be individually assessed before any correction is made. Party normalization (Wave 4) is a simple UPDATE with no FK dependencies — it can run at any point in the phase.

**Primary recommendation:** Work through Tiers 1 and 2 politician-by-politician using the research-stances skill in correction mode (fetch real sources, then apply UPDATE/upsert via migration). Never correct a stance without at least one real fetched URL in `inform.politician_context`. Party normalization runs as a standalone migration last.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stance value corrections | Database / Storage | — | Direct SQL UPDATEs to `inform.politician_answers` + `inform.politician_context` via pool.query() in migration |
| Party string normalization | Database / Storage | — | Single UPDATE on `essentials.politicians.party` — no API or frontend impact |
| Re-research (stance lookup) | Agent / Research | — | research-stances skill dispatches politician-stance-researcher agents |
| Migration application | Database / Storage | — | psql via DATABASE_URL, same as all prior migrations |

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SACC-02 | All politicians confirmed as having accuracy issues are individually re-researched with real sources and corrected via migration(s); each correction requires at least one fetched source URL | 87-AUDIT-REPORT.md Tier 1 (8 politicians) + Tier 2 (21 politicians) provide the work queue. research-stances skill + pool.query() migration pattern is the established correction mechanism. |
| SACC-03 | Party string inconsistency resolved — all politicians have a normalized party value (no mixed "Democrat" / "Democratic" entries) | Verified: 496 "Democrat" rows + 280 "Democratic" rows in essentials.politicians. Single UPDATE normalizes both to one canonical value. |
</phase_requirements>

---

## Standard Stack

### Core

| Tool | Purpose | Why Standard |
|------|---------|--------------|
| `research-stances` SKILL.md | Re-research individual politicians | Established skill; five-chairs framing now baked in after Phase 87 |
| `pool.query()` / Node.js `--import tsx` | Apply corrections to `inform.*` tables | All `inform.*` writes must bypass PostgREST — mandatory per project pattern |
| Migration files (`supabase/migrations/`) | Persist corrections to DB | All schema/data changes tracked as numbered migration files |

### No New Packages

This phase uses only existing infrastructure. No npm installs needed.

---

## Package Legitimacy Audit

No new packages. All DB access uses the existing `pg` pool pattern.

---

## Architecture Patterns

### Recommended Phase Structure

```
Phase 88
├── Wave 1: Tier 1 confirmed inversions (8 politicians)
│   ├── One research-stances agent per politician
│   ├── Collect CSV output; review before DB push
│   └── Correction migration per politician (or grouped where safe)
├── Wave 2: Tier 2 borderline cases (21 politicians)
│   ├── MA value=3 cluster (11 politicians): batch investigate source — one CSV first
│   ├── Val Hoyle + Andrea Salinas (OR Dems, value=1 lock): sample 3-4 topics each
│   └── Remaining borderline Rs/Ds: individual assessment
├── Wave 3: Ukraine-support Rs (25 at value=2)
│   ├── Sample 5-10 for manual source verification
│   └── Batch UPDATE only if pattern holds; individual corrections otherwise
└── Wave 4: Party string normalization
    └── Single migration: UPDATE essentials.politicians SET party = 'Democratic' WHERE party = 'Democrat'
```

### Pattern 1: Correction Migration Structure

Every stance correction follows this SQL pattern inside a migration file:

```sql
-- Correct inform.politician_answers for [POLITICIAN_NAME]
-- Source: [URL that was fetched]
-- Researched: [date]

BEGIN;

-- Correct stance values
UPDATE inform.politician_answers
SET value = [NEW_VALUE]
WHERE politician_id = '[UUID]'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = '[TOPIC_KEY]');

-- Update context with real source
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '[POLITICIAN_UUID]',
  (SELECT id FROM inform.compass_topics WHERE topic_key = '[TOPIC_KEY]'),
  '[REASONING_TEXT]',
  ARRAY['[SOURCE_URL_1]', '[SOURCE_URL_2]']
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
```

**Critical constraint:** `inform.*` tables are NOT in PostgREST's exposed schema list. All corrections go through `pool.query()` or direct psql — never `supabaseAdmin.schema('inform')`.

### Pattern 2: Using research-stances Skill for Corrections

The skill is designed for net-new research but also works for corrections. Key difference in correction mode:

1. The planner already knows the current (wrong) values from the audit report
2. The researcher agent should fetch the same topic(s) fresh and produce a new value
3. The orchestrator compares old vs. new and flags discrepancies for human review before applying
4. Only apply if new value differs from current AND is backed by a fetched URL

**Agent dispatch rule:** ONE agent at a time. Never parallel. Rate limit constraint is real.

### Pattern 3: Investigating MA Value=3 Cluster

The 11 MA legislators with 80–94% stances at value=3 require a different approach than individual re-research. The hypothesis is these came from a shared research run that defaulted to value=3. Investigation steps:

1. Pull politician_context rows for these 11 politicians on 2-3 shared topics — check if reasoning text is generic/templated vs. specific
2. If reasoning is templated, this is a batch artifact → all 11 need re-research
3. If reasoning is specific and cites real sources → these may be legitimately centrist MA legislators

```sql
-- Pull context samples for MA value=3 cluster
SELECT p.full_name, t.topic_key, pa.value, pc.reasoning, pc.sources
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
JOIN inform.compass_topics t ON t.id = pa.topic_id
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.full_name IN (
  'Mark C. Montigny', 'David Robertson', 'John C. Velis', 'Cynthia F. Friedman',
  'John J. Cronin', 'Danielle W. Gregoire', 'Joan B. Lovely', 'Aaron L. Saunders',
  'Aaron Michlewitz', 'Ronald Mariano', 'Christopher J. Worrell', 'Dawne Shand'
)
AND pa.value = 3
AND t.topic_key IN ('abortion', 'healthcare', 'voting-rights')
ORDER BY p.full_name, t.topic_key;
```

### Pattern 4: Party String Normalization

Two distinct strings exist for Democratic party affiliation:

| String | Count | Action |
|--------|-------|--------|
| "Democrat" | 496 | Normalize to "Democratic" |
| "Democratic" | 280 | Keep as canonical |

**Decision required for planner:** Which direction to normalize? Options:
- **"Democratic" as canonical** (aligns with official party name: "Democratic Party")
- **"Democrat" as canonical** (shorter, matches Republican pattern)

The research-stances SKILL.md uses both strings interchangeably in its tier assignment logic. Neither direction breaks functionality — it is purely a display/filtering issue. However, "Democratic" is the official party name per the Democratic National Committee.

**Normalization SQL (whichever direction is chosen):**

```sql
-- Option A: Normalize to "Democratic" (recommended — official party name)
BEGIN;
UPDATE essentials.politicians
SET party = 'Democratic'
WHERE party = 'Democrat';
COMMIT;
-- Affected rows: 496

-- Option B: Normalize to "Democrat"
BEGIN;
UPDATE essentials.politicians
SET party = 'Democrat'
WHERE party = 'Democratic';
COMMIT;
-- Affected rows: 280
```

Note: There are also 7 "Independent" and 3 "Unenrolled" rows — these are correct and should not be touched. 1,289 "Nonpartisan" rows (mostly politicians without stance data) — also correct.

### Pattern 5: Ukraine-Support Verification Approach

25 Republicans currently have `ukraine-support = 2` ("continue providing current levels of military and economic aid"). This was a defensible position before 2025 Republican party realignment on Ukraine. Some may now be outdated.

Investigation strategy:
1. Pull the 25 politicians with their names and offices
2. Spot-check 5 — fetch each politician's current position from official sources or recent news
3. If majority of spot-check is still accurate at value=2: document as "verified at research date" and move on
4. If majority has shifted: research all 25 individually and apply corrections

```sql
-- Pull the 25 Ukraine Rs at value=2
SELECT p.full_name, p.party,
  (SELECT o.title FROM essentials.offices o WHERE o.politician_id = p.id LIMIT 1) AS office,
  pc.reasoning, pc.sources
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
JOIN inform.compass_topics t ON t.id = pa.topic_id
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE t.topic_key = 'ukraine-support'
  AND pa.value = 2
  AND p.party = 'Republican'
ORDER BY p.full_name;
```

### Anti-Patterns to Avoid

- **Correcting by party inference:** Never change a value to what "a Republican should have" or "a Democrat should have." Every correction must cite a fetched URL. The audit found inversions BECAUSE researchers made party-inference assignments.
- **Parallel research agents:** One at a time only. Two concurrent agents is the absolute maximum per MEMORY.md user preference note.
- **Using PostgREST for inform.* writes:** `supabaseAdmin.schema('inform').from('politician_answers').update()` will fail silently or throw. All correction writes go through `pool.query()`.
- **Generic reasoning text:** If researcher agent produces "As a Republican, [politician] likely supports..." in the reasoning field — that is party inference and must be rejected.
- **Losing context rows:** When correcting a stance value, always UPDATE the corresponding `politician_context` row with the new reasoning and source URL. Do not leave stale reasoning from the original (wrong) research.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Web research for politician positions | Custom fetch loop | research-stances skill agent (already has URL patterns, five-chairs framing, output format) |
| DB writes to inform.* | PostgREST / supabaseAdmin.schema() | pool.query() via backend/src/lib/db.js |
| Batch party UPDATE | Multi-step ORM calls | Single SQL UPDATE statement in migration file |
| Verifying source URLs | Manual URL typing | Agent fetches and reports actual URL it used |

---

## Confirmed Inversion Work Queue (Wave 1)

All 8 verified from DB query 2026-06-02. These are the current (wrong) values that need correction:

| Politician | UUID | Party | Current Stances (from DB) | Primary Error |
|-----------|------|-------|--------------------------|---------------|
| Jeff Gonzalez | `5ad32852-789e-4013-995b-6f0aa6a5a5d4` | Republican | abortion=1, civil-rights=1, healthcare=1, immigration=1, medicare/aid=1, same-sex-marriage=1, school-vouchers=1, social-security=1, taxes=1 (plus ai-reg=4, redistricting=4, trans-athletes=4) | All progressive-leaning topics at value=1 — should be 4 or 5 for an R |
| Roger Niello | `22152e41-31b9-4700-9226-4e274c616f37` | Republican | abortion=2, civil-rights=2, climate-change=2, healthcare=1, immigration=2, medicare/aid=2, taxes=2, voting-rights=2 | Conservative R reading as moderate/liberal Democrat |
| Angie Nixon | `0ac89151-2b8d-4430-b9bd-3a80bef3413b` | Democratic | All 9 topics at value=4 | Uniform value=4 lock — not credible; likely progressive D should have many at 1 or 2 |
| Alex Vindman | `a2fee754-f90c-47ff-a3b7-377d55992273` | Democratic | abortion=5, civil-rights=4, climate-change=4, healthcare=4, immigration=4, religious-freedom=5, same-sex-marriage=4, taxes=4, voting-rights=4 | Mix of 4s and 5s for progressive D is plausible but abortion=5 + religious-freedom=5 together is suspicious |
| Tim Grayson | `29389f8b-de23-4312-af73-264289dc7774` | Democrat | civil-rights=5, climate-change=5, house=5, same-sex-marriage=5 (multiple at 5) | Extreme progressive lock at 5 — per audit, should be 1 or 2 direction |
| Ashley Hinson | `bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1` | Republican | abortion=2, campaign-finance=2, civil-rights=2, climate-change=2, healthcare=2, immigration=2, taxes=2, voting-rights=2 | R uniformly at value=2 — should be 4 or 5 for most of these |
| Derek Dooley | `b841a475-41b4-4f19-9ad1-13769b1f4eef` | Republican | abortion=2, civil-rights=2, climate-change=2, healthcare=2, immigration=2, taxes=2, voting-rights=2 | Same pattern as Hinson |
| Adam Hinojosa | `0c6c482a-feba-45bc-821b-02769a810063` | Democrat (suspect) | abortion=4, civil-rights=4, immigration=4, religious-freedom=4, school-vouchers=5, taxes=4 | Values look Republican; party tag may be wrong — verify both |

**Note on Tim Grayson and Angie Nixon direction:** The five-chairs scale has no fixed direction. The researcher must fetch real sources and match to the chair text — do not assume "D should be at 1" without reading the stance texts for each topic.

**Note on Adam Hinojosa:** Phase 88 must verify his party affiliation via official sources (Texas politician, listed as "Democrat" but values suggest Republican). If party is wrong, correct `essentials.politicians.party` AND re-research stances.

---

## Common Pitfalls

### Pitfall 1: Correcting Without a Source URL

**What goes wrong:** Researcher agent produces corrected values but reasoning says "As a conservative Republican, this politician likely..." or draws from party affiliation alone.
**Why it happens:** Even with five-chairs framing, agents may fall back to party inference when direct sources are hard to find.
**How to avoid:** Reject any correction where reasoning doesn't cite a fetched URL. SACC-02 explicitly requires at least one real fetched source URL per correction.
**Warning signs:** Reasoning text contains "likely", "as a [party] politician", "generally speaking."

### Pitfall 2: Wrong Direction Assumption on Topics

**What goes wrong:** Planner assumes "Tim Grayson has climate-change=5 so it should be corrected to 1 or 2."
**Why it happens:** Forgetting that value direction varies by topic — value=1 is not always "conservative."
**How to avoid:** Always fetch the live topic stance texts before deciding what the correct value should be. The stance text for climate-change=1 may be "Transition to 100% renewables immediately" (progressive). Read the chair text.

### Pitfall 3: Losing inform.politician_context Rows

**What goes wrong:** UPDATE runs on `inform.politician_answers` but the corresponding `politician_context` row still contains the old (wrong) reasoning.
**Why it happens:** Migration only updates the answer value, forgets to update context.
**How to avoid:** Every migration that changes a value must also UPDATE or INSERT the context row. Use the upsert pattern (ON CONFLICT DO UPDATE).

### Pitfall 4: MA Cluster Investigation Skipped

**What goes wrong:** Phase 88 plans treat the MA value=3 cluster as 11 individual re-research tasks without first checking whether they share a common research artifact.
**Why it happens:** The audit report lists them as individual borderline cases.
**How to avoid:** Wave 2 must first run the Pattern 3 context investigation SQL to determine if these came from a shared batch. If they did, a single batch re-research is more efficient and more likely to find the root cause.

### Pitfall 5: Party Normalization Breaks No Downstream Logic

**What goes wrong:** Normalizing party strings causes subtle filter bugs elsewhere if any code does `WHERE party = 'Democrat'` (case-sensitive).
**Why it happens:** Party strings are used in filtering/display across the API.
**How to avoid:** Before applying normalization, grep the codebase for hardcoded party string comparisons. Any code doing exact-string match on 'Democrat' will need to handle the new canonical value.

```bash
# Run before normalization migration
grep -r "Democrat" C:/EV-Accounts/backend/src --include="*.ts" --include="*.js" -l
```

---

## Runtime State Inventory

This is a data-correction phase. No renamed strings, no rebrand. Skipping this section — no runtime state changes.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js + tsx | Migration scripts, research-stances skill | Yes | v24.13.0 | — |
| `pg` pool | All inform.* DB writes | Yes | Existing in backend/src/lib/db.js | — |
| Supabase remote DB | Stance corrections | Yes | Live, verified 2026-06-02 | — |
| WebFetch | research-stances agents | Yes | Claude built-in | — |
| psql / DATABASE_URL | Applying migration files | Yes (session pooler pattern) | — | — |

**Migration number:** Last applied migration filename prefix is `20260516000018` (migration 115 in sequential numbering). **Next sequential migration number is 257** (the last applied was 256 per STATE.md v2.5 infrastructure notes — migrations 207–256 were applied during Phases 77–87 work). Verify exact next number before writing: `ls supabase/migrations | sort | tail -1`.

---

## Validation Architecture

`workflow.nyquist_validation` is not set to `false` in `.planning/config.json` — treated as enabled.

Phase 88 is a data-correction phase with no runtime code changes and no new API endpoints. All "code" is SQL migration files and research-stances skill invocations.

### Phase Gate Validation (Manual/SQL)

| Requirement | Validation Command |
|------------|-------------------|
| SACC-02: All Tier 1 politicians corrected | `SELECT COUNT(DISTINCT pa.politician_id) FROM inform.politician_answers pa WHERE pa.politician_id IN ('[8 UUIDs]')` — verify new values match researched corrections |
| SACC-02: No correction without source URL | `SELECT COUNT(*) FROM inform.politician_context pc WHERE pc.politician_id IN ('[8 UUIDs]') AND (pc.sources IS NULL OR array_length(pc.sources, 1) = 0)` — must return 0 |
| SACC-03: Party normalization complete | `SELECT DISTINCT party FROM essentials.politicians WHERE party IN ('Democrat', 'Democratic')` — must return exactly 1 row |
| Ukraine verification documented | Check that each of 25 Rs at value=2 has a determination note in VERIFICATION.md |

### Wave 0 Gaps

None — no new test files needed. This phase is validated by SQL queries against live data, not unit tests.

---

## Security Domain

No security-relevant changes in this phase. All writes are admin/service-role SQL applied via migration — no user-facing endpoints modified. ASVS categories V2/V3/V4 do not apply. V5 (input validation) is N/A (no user input paths changed).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | "Democratic" is the preferred canonical party name (official party name) | Party Normalization pattern | If "Democrat" is preferred, normalization direction reverses — low impact either way |
| A2 | Next migration number is 257 | Migration numbering | Wrong number causes migration ordering conflict — verify with `ls supabase/migrations \| sort \| tail -1` before writing |
| A3 | Tim Grayson's stances are inverted toward progressive (should be moderate-conservative) | Tier 1 work queue | If Grayson is genuinely progressive (e.g., was a Democrat who became more progressive after audit), no correction needed — research will determine |
| A4 | The 25 Ukraine Rs at value=2 may include some that are still accurate | Ukraine pattern | If most have shifted, a larger batch correction is warranted; if most are still accurate, no change needed |

---

## Open Questions

1. **Party normalization direction: "Democrat" or "Democratic"?**
   - What we know: 496 "Democrat" + 280 "Democratic" exist. Both are used in audit tier logic.
   - My read: Normalize to "Democratic" — it is the official name of the party (Democratic Party, not Democrat Party). Aligns with how senators like Alex Padilla and Sherrod Brown are already stored ("Democratic").
   - Planner can lock this as a decision.

2. **Wave 4 timing: before or after stance corrections?**
   - What we know: Party normalization is independent of stance corrections.
   - Recommendation: Run Wave 4 (party normalization) last, after Waves 1–3 are complete, so all re-research agents work with consistent party strings during research.

3. **Adam Hinojosa — what if he's actually a Republican?**
   - What we know: DB has party = "Democrat"; his 6 stances all look Republican.
   - Recommendation: Verify via official sources (Texas legislature, official bio). If Republican, correct `essentials.politicians.party` in the same migration that corrects his stances. Document both changes with sources.

---

## Sources

### Primary (HIGH confidence)

- Direct DB queries against `inform.politician_answers`, `essentials.politicians` run 2026-06-02 — exact counts and UUIDs verified
- `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` — Tier 1/2/3 work queues, confirmed correct cases
- `.claude/skills/research-stances/SKILL.md` — correction workflow pattern (Steps 1–4)
- `.planning/STATE.md` §v2.6 Stance Accuracy Retro + §v2.5 Infrastructure Patterns — migration patterns, pool.query() requirement

### Secondary (MEDIUM confidence)

- MEMORY.md — rate limit rule (one agent at a time, max 2 concurrent), pool.query() for inform.* pattern

---

## Metadata

**Confidence breakdown:**
- Tier 1 work queue (8 politician UUIDs + current values): HIGH — queried directly from live DB
- Party string counts (496 Democrat / 280 Democratic): HIGH — verified from live DB
- Ukraine Rs count (25 at value=2): HIGH — verified from live DB
- Correction migration SQL pattern: HIGH — same pattern used in Phases 74, 76, 78
- MA cluster investigation approach: MEDIUM — hypothesis (batch artifact) not yet confirmed
- Party normalization direction recommendation: ASSUMED — "Democratic" as canonical is my judgment

**Research date:** 2026-06-02
**Valid until:** 30 days — DB values will change as corrections are applied; re-query before each wave
