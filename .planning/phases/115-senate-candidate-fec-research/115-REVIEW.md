---
phase: 115-senate-candidate-fec-research
reviewed: 2026-06-12T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - backend/scripts/senate-candidate-fec.ts
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 115: Code Review Report

**Reviewed:** 2026-06-12
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

`backend/scripts/senate-candidate-fec.ts` is a one-shot admin data ingestion script for resolving FEC candidate IDs and populating `finance_summary` for 2026 Senate challengers. The script has already run successfully (per the SUMMARY.md), but two blockers need correction before this script is used again or repurposed.

The most serious issue is that the DC Shadow Senator NOT_APPLICABLE check in the main loop (lines 313–331) is dead code — the comment even states Strauss/Jain are NATIONAL_LOWER and won't appear in the NATIONAL_UPPER query. Despite being dead today, this check creates a double-counting trap if the DB schema changes, and the fact that it passed the summary self-check undetected indicates neither path was traced completely during implementation. The second blocker is that the confirmed-match DB write block has no dry-run guard, making the guard logic inconsistent across the three outcome paths (not_applicable and no_match are guarded; confirmed is not).

Four warnings cover: API key exposure in log-visible URLs, a redundant double invocation of the scoring function, an unguarded `stats.not_applicable` increment in the shadow-senator loop that fires even in dry-run mode, and the `DISTINCT` query returning multiple rows per politician when district state values differ.

---

## Critical Issues

### CR-01: NOT_APPLICABLE check in main loop is dead code that double-counts if ever triggered

**File:** `backend/scripts/senate-candidate-fec.ts:313-331`

**Issue:** The `NOT_APPLICABLE.has(nameLower)` branch at line 314 is intended to handle DC Shadow Senators (Paul Strauss, Ankit Jain). But the opening DB query at line 288 filters `district_type = 'NATIONAL_UPPER'`. The code comment at line 441 explicitly states: "they are stored as NATIONAL_LOWER in the DB since DC has no Senate seats." This means `NOT_APPLICABLE.has()` will never evaluate true in the main loop — it is dead code.

The SUMMARY confirms this was discovered during Task 1 dry-run and fixed by adding the explicit fallback query at line 445. However, the dead branch was not removed. The danger: if either Strauss or Jain is ever assigned a `NATIONAL_UPPER` district record (e.g., a future schema migration or data correction), their `stats.not_applicable` counter would increment twice (once here, once in the shadow senator loop at line 467), and two `fec_senate` rows would be written — the second INSERT would follow a DELETE-INSERT cycle that wipes the first. The dry-run branch also silently increments `stats.not_applicable` without any DB guard, making dry-run stats misleading.

**Fix:** Remove the dead `NOT_APPLICABLE` branch from the main loop entirely. All DC Shadow Senator handling is already correct in the explicit fallback query at lines 445–468. If the intent is defensive belt-and-suspenders, add a guard comment but do not increment `stats` or write to DB from a code path that the query predicate already prevents.

```typescript
// REMOVE lines 313-331 entirely:
// if (NOT_APPLICABLE.has(nameLower)) { ... }
//
// The NATIONAL_UPPER query predicate prevents Strauss/Jain from appearing
// here. All not_applicable handling is in the explicit fallback block below.
```

---

### CR-02: Confirmed-match DB writes have no dry-run guard

**File:** `backend/scripts/senate-candidate-fec.ts:407-418`

**Issue:** The confirmed-match path (lines 407–418) runs the DELETE + INSERT into `transparent_motivations.politician_sources` with no `if (!DRY_RUN)` guard. The two other outcome paths (not_applicable at line 316 and no_match at line 386) are both wrapped in `if (!DRY_RUN)`.

Currently this is safe in practice because when `DRY_RUN` is true, `results` is always `[]` (the FEC call is skipped), so `bestCandidate` is always null and lines 407–418 are unreachable. But this safety is implicit and undocumented — it relies on a coupling between the dry-run FEC-skip at lines 346–354 and the match-path predicate at line 369. A future change that injects test results in dry-run mode (e.g., for unit testing), or that moves the FEC skip guard, would silently execute real DB writes while the user believes the script is in dry-run mode. This is a data integrity trap.

**Fix:** Wrap the confirmed-match DB writes in an explicit dry-run guard, consistent with the other two outcome paths:

```typescript
// --- match found ---
const fecId = bestCandidate.candidate_id;
console.log(`MATCH  ${pol.full_name} -> ${fecId} (score ${bestScore.toFixed(2)})`);
stats.confirmed++;

if (!DRY_RUN) {
  // Write politician_sources row
  await pool.query(
    `DELETE FROM transparent_motivations.politician_sources
     WHERE essentials_politician_id = $1 AND source_system = 'fec_senate'`,
    [pol.id],
  );
  await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, source_type, notes)
     VALUES ($1, 'fec_senate', $2, 'confirmed', 'candidate_committee', '')`,
    [pol.id, fecId],
  );

  // Fetch and write finance data
  try {
    const summary = await fetchFecData(fecId, apiKey);
    // ... rest of match block
  } catch (err) { ... }
}
```

---

## Warnings

### WR-01: FEC API key appears in log-visible error messages via URL construction

**File:** `backend/scripts/senate-candidate-fec.ts:199`

**Issue:** The `candidateSearch` function constructs the FEC request URL with the API key inline: `` `${FEC_BASE}/candidates/?api_key=${apiKey}&...` ``. In `fetchFecData`, the same pattern appears at lines 212, 225, 241, 251. If any of these `fetch()` calls throw an error whose message includes the URL (e.g., from a network library or a future debugging enhancement), the API key would appear in console output and any log aggregator attached to the process.

The FEC API key is a public-use key with a per-IP rate limit, not a secret credential, so the practical impact is low. However, this project's MEMORY.md explicitly notes the key is read from `process.env` and "never logged or written to DB." The current code does not log it, but it is one debug `console.log(url)` away from exposure.

**Fix:** Build the URL with the key separate from any logged portions, or use a `Headers` approach if supported by the FEC API:

```typescript
// Option A: mask key in any potential error logging
const urlWithKey = `${FEC_BASE}/candidates/?api_key=${apiKey}&q=${encodeURIComponent(lastName)}&office=S&state=${stateAbbr}&per_page=20`;
// If you ever log the URL for debugging, use a redacted form:
// const safeUrl = urlWithKey.replace(apiKey, '[REDACTED]');
```

---

### WR-02: scoreMatch called twice per candidate in the no-match reporting path

**File:** `backend/scripts/senate-candidate-fec.ts:370-376`

**Issue:** When no match meets the 0.8 threshold, the code recomputes `scoreMatch(pol.full_name, c.name)` for every candidate in the top-3 list (line 374), even though those scores were already computed in the earlier scoring loop (lines 360–366). The scoring loop discards all scores except the best; the no-match path then recomputes them from scratch. For a typical result set of ≤ 20 candidates this is negligible, but it creates a maintainability issue: if `scoreMatch` is ever made stateful or gains side effects, this double-call would be a latent bug.

**Fix:** Collect scores in the initial loop:

```typescript
const scored = results.map(c => ({
  candidate_id: c.candidate_id,
  name: c.name,
  score: scoreMatch(pol.full_name, c.name),
}));

let bestScore = 0;
let bestCandidate: FecCandidateResult | null = null;
for (const { score, ...c } of scored) {
  if (score > bestScore) { bestScore = score; bestCandidate = c as FecCandidateResult; }
}

// In the no-match block:
const top3 = scored.sort((a, b) => b.score - a.score).slice(0, 3);
```

---

### WR-03: Shadow senator loop increments stats.not_applicable unconditionally in dry-run

**File:** `backend/scripts/senate-candidate-fec.ts:452-468`

**Issue:** In the shadow senator fallback loop (lines 452–468), `stats.not_applicable++` at line 467 fires regardless of `DRY_RUN`. The DB writes inside the loop are correctly guarded by `if (!DRY_RUN)`. But the stats increment is always live. This means a dry-run will report `not_applicable: 2` in the summary even though no DB rows were written, and the summary would be misleading — it would appear identical to a live run's output.

For the `not_applicable` case in the main loop (line 329), the same issue exists: `stats.not_applicable++` is outside the `if (!DRY_RUN)` block. The dry-run log already says "No DB writes or FEC calls," so a user would expect the stats to reflect that nothing was written.

**Fix:** Move `stats.not_applicable++` inside the `if (!DRY_RUN)` blocks, or add a separate dry-run stats counter. Alternatively, document the convention that stats count "candidates processed" not "DB rows written" — but then document this explicitly, since `stats.written` is clearly "rows written."

---

### WR-04: DISTINCT query can produce multiple rows per politician when d.state differs across offices

**File:** `backend/scripts/senate-candidate-fec.ts:288-297`

**Issue:** The query selects `DISTINCT p.id, p.full_name, d.state AS fips_code`. If a politician has offices linked to two different districts with the same `district_type = 'NATIONAL_UPPER'` but different `state` values (a data quality edge case), they would appear twice in `rows` with different `fips_code` values. The script would then process them twice: two DELETE+INSERT cycles on `politician_sources` and two attempts to write `finance_summary`.

The second pass would silently overwrite the first (the finance_summary UPDATE is idempotent, and the DELETE+INSERT pattern handles duplicates). But the stats would double-count confirmed/written for that politician, and two FEC API call sequences would be made, burning rate-limit budget.

**Fix:** Add a deduplication guard using a `Set` of already-processed politician IDs, or restructure the query to return at most one row per politician:

```sql
SELECT DISTINCT ON (p.id) p.id, p.full_name, d.state AS fips_code
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
WHERE d.district_type = 'NATIONAL_UPPER'
  AND p.is_active = true
  AND p.finance_summary IS NULL
ORDER BY p.id, p.full_name
```

Or in TypeScript after the query:

```typescript
const seen = new Set<string>();
for (const pol of rows) {
  if (seen.has(pol.id)) continue;
  seen.add(pol.id);
  // ... rest of processing
}
```

---

## Info

### IN-01: scoreMatch never returns 1.0 — exact full-name match scores 0.9

**File:** `backend/scripts/senate-candidate-fec.ts:160`

**Issue:** When last names match exactly (`baseScore = 1.0`) and first names match exactly, line 160 returns `baseScore >= 1 ? 0.9 : 0.85`, which evaluates to `0.9`. A perfect full-name match scores lower than the `baseScore` variable suggests. This is harmless (0.9 > 0.8 threshold), but the logic is confusing — `baseScore = 1.0` does not actually produce a score of 1.0 for any code path. The `baseScore >= 1` guard was likely intended to differentiate compound-last from exact-last, but the effect is that the maximum achievable score is 0.9, not 1.0.

**Fix:** Rename `baseScore` to `lastMatchQuality` and document that the function's maximum output is 0.9 by design, or simplify the branch:

```typescript
if (db.first === fec.first) return lastMatch ? 0.95 : 0.85;
```

---

### IN-02: NOT_APPLICABLE Set and NOT_APPLICABLE_NOTE constant are now vestigial

**File:** `backend/scripts/senate-candidate-fec.ts:64-67`

**Issue:** As described in CR-01, the `NOT_APPLICABLE` Set and `NOT_APPLICABLE_NOTE` constant at lines 64–67 exist solely to support the dead branch in the main loop. The shadow senator fallback query at line 445 uses `LOWER(p.full_name) IN ('paul strauss', 'ankit jain')` directly and `NOT_APPLICABLE_NOTE` as a string literal. If CR-01 is applied (removing the dead branch), these two constants become dead code that should also be removed to reduce confusion.

**Fix:** After removing the dead main-loop branch (CR-01), also remove lines 64–67 and inline the note string directly into the fallback INSERT at line 462, or keep `NOT_APPLICABLE_NOTE` as a named constant used only by the fallback block.

---

_Reviewed: 2026-06-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
