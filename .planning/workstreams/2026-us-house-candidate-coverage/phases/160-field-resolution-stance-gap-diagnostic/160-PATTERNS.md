# Phase 160: Field Resolution + Stance-Gap Diagnostic - Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** 8 (5 scripts + 3 CSV artifacts; `160-FIELD-TABLE.md` is prose, not pattern-mapped)
**Analogs found:** 8 / 8 (3 exact, 3 role-match/structural, 2 exact-shape-with-new-columns)

This is a **pure read-only diagnostic phase** — no backend app code, no migrations, no
frontend. Every script below runs from `backend/` using the existing `dotenv/config` +
`pool` (`backend/src/lib/db.ts`, NOT `db.js` — the required-reading prompt's `db.js`
reference is stale; the real file is `backend/src/lib/db.ts`) bootstrapping already
proven in Phase 154/148. Nothing here should invent new connection/config patterns.

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|-----------------|----------------|
| `backend/scripts/diag-160-incumbent-stance-gap.ts` | script (diagnostic/utility) | batch (DB SELECT → console + CSV emit) | `backend/scripts/diag-154-incumbent-stance-gap.ts` | exact |
| `backend/scripts/diag-160-external-id-collision.ts` | script (diagnostic/utility) | batch (DB SELECT → in-memory audit → CSV emit) | `backend/scripts/diag-154-incumbent-stance-gap.ts` (scaffolding) + RESEARCH.md "Pattern 2" (query logic, no prior script exists) | role-match (new query class, inherited scaffolding) |
| `backend/scripts/diag-160-race-preexistence-audit.ts` | script (diagnostic/utility) | batch (DB SELECT, any election_date → console + CSV/field-table feed) | `backend/scripts/diag-154-incumbent-stance-gap.ts` (scaffolding) + RESEARCH.md "Pattern 3" (query logic, no prior script exists) | role-match (new query class, inherited scaffolding) |
| `backend/scripts/diag-160-validate-field-table.py` | test/validator (CSV shape gate) | batch (file read → assertions) | `backend/scripts/diag-154-validate-field-table.py` | exact |
| `backend/scripts/160-verify.sql` | migration-adjacent (write-free SQL gate) | batch (SELECT-only assertions) | `backend/scripts/154-verify.sql` | exact |
| `.planning/phases/160-.../160-incumbent-map.csv` | data artifact | file-I/O (CSV emit) | `.planning/phases/154-.../154-incumbent-map.csv` | exact (same schema) |
| `.planning/phases/160-.../160-field-table.csv` | data artifact | file-I/O (CSV emit) | `.planning/phases/154-.../154-field-table.csv` | exact-shape-with-new-columns (add `seeding_phase`, `ballot_system`, `rcv`, `filing_open_deadline`) |
| `.planning/phases/160-.../160-negative-id-audit.csv` | data artifact | file-I/O (CSV emit) | none (NEW — no Phase-154 equivalent; Wave-2 had 0 collisions) | no analog — invent shape (see below) |

---

## Pattern Assignments

### `backend/scripts/diag-160-incumbent-stance-gap.ts` (script, batch)

**Analog:** `backend/scripts/diag-154-incumbent-stance-gap.ts` (full file read, 409 lines — small enough for one pass, no re-read needed)

This is a **direct clone-and-rescale**. Every structural piece carries over unchanged; only the constants and the vacancy-handling narrative change (Wave-3's Query C returned 0 rows this session — no known special seats to hardcode, unlike Wave-2's GA-13/NJ-11/VA-11).

**Header/bootstrap pattern** (lines 1-27 of the analog):
```typescript
/**
 * Phase 154 — Field Resolution + Stance-Gap Diagnostic (READ-ONLY)
 * ...
 * SELECT-ONLY. Never INSERT/UPDATE/DELETE. Never pass --commit. Re-runnable / idempotent.
 *
 * Run with:
 *   cd /c/EV-Accounts/backend && set -a && source .env && set +a \
 *     && node --import tsx scripts/diag-154-incumbent-stance-gap.ts
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pool } from '../src/lib/db.js';
```
Note: the analog imports `'../src/lib/db.js'` — TS path with `.js` extension resolving
to `db.ts` under the project's `tsx`/NodeNext module resolution. Copy this import
verbatim (do not "fix" it to `.ts`).

**Constants to rescale** (lines 29-59): replace `WAVE2_FIPS` (8 states) with the 38-state
`WAVE3_FIPS` array already proven live this session (RESEARCH.md "Pattern 1", lines
357-360), replace `EXPECTED_PER_STATE` with the 38-state per-state district counts,
`EXPECTED_TOTAL = 178` (not 113), keep `FEDERAL_TOPIC_BAR = 24` unchanged. Wave-3 has
**no known expected vacancy set** (`EXPECTED_VACANCY_GEO_IDS = new Set([])` — Query C
returned 0 rows this session, RESEARCH.md Critical Finding under "Architecture Diagram"
Query C) — do NOT hardcode a GA-14-style special case; keep the code path generic so it
still self-heals if a retirement surfaces as a 0-holder row between research and seeding.

**Core Query A/B/C pattern** (lines 107-229, copy verbatim except FIPS/state maps):
```typescript
const queryA = await pool.query<IncumbentRow>(`
  SELECT substr(d.geo_id, 1, 2) AS state_fips, d.geo_id AS geo_id,
         p.id AS politician_id, p.external_id AS external_id,
         p.full_name AS full_name, p.is_active AS is_active,
         (SELECT COUNT(*) FROM inform.politician_answers pa
           WHERE pa.politician_id = p.id)::int AS stance_count
  FROM essentials.districts   d
  JOIN essentials.offices     o ON o.district_id = d.id
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id, 1, 2) = ANY($1::text[])
  ORDER BY state_fips, d.geo_id
`, [WAVE3_FIPS]);
```
`topUpTier()` helper (lines 81-86) is unchanged — zero/partial(<24)/done(>=24)/vacant.

**CSV emit + hard-guard pattern** (lines 232-397): the `csvField()` RFC-4180 quoting
helper (lines 88-96), the "exactly N data rows or refuse to write" guard (lines
340-354 — change `113` to `178`), and the WARNING blocks for unexpected/missing
vacancies (lines 373-394) all carry over unchanged in shape. Change
`CSV_PATH` (lines 61-68) to point at `160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv`.

**Error handling pattern** (lines 400-408):
```typescript
main().catch(async (err) => {
  console.error('Diagnostic failed:', err);
  try { await pool.end(); } catch { /* noop */ }
  process.exit(1);
});
```

---

### `backend/scripts/diag-160-external-id-collision.ts` (script, batch — NEW query class)

**Analog:** scaffolding from `diag-154-incumbent-stance-gap.ts` (dotenv/pool bootstrap,
`csvField()` helper, hard-guard-before-write, `main().catch()` error wrapper — copy
these verbatim, same as above). **No Phase-154 script solved this problem** (Wave-2's
8 states had 0 collisions under the naive formula); the query logic itself comes from
RESEARCH.md's "Pattern 2" (already proven live this session, 16/178 real collisions
found):

```typescript
// RESEARCH.md lines 378-398 — proven this session, reuse verbatim as the core loop.
const FIPS: Record<string, number> = { WA:53, AZ:4, TN:47, /* ...all 38... */ };
const DELEG: Record<string, number> = { WA:10, AZ:9, TN:9, /* ...district counts... */ };
const { rows } = await pool.query('SELECT external_id FROM essentials.politicians WHERE external_id < 0');
const negIds = new Set(rows.map(r => Number(r.external_id)));
for (const [st, fips] of Object.entries(FIPS)) {
  for (let cd = 1; cd <= DELEG[st]; cd++) {
    const collisions: number[] = [];
    for (let seq = 1; seq <= 99; seq++) {
      const candidate = -(fips * 10000 + cd * 100 + seq);
      if (negIds.has(candidate)) collisions.push(seq);
    }
    if (collisions.length) {
      console.log(`${st}-CD${cd}: ${collisions.length} collisions, max seq ${Math.max(...collisions)}`);
    }
  }
}
```

**Extend for CSV emit** (per Wave-0 Gap requirement — "writes `160-negative-id-audit.csv`"):
follow the exact `csvField()` + `writeFileSync(CSV_PATH, ...)` idiom from
`diag-154-incumbent-stance-gap.ts` lines 88-96 / 356-358. Suggested row shape (no
prior art — Claude's/planner's discretion per RESEARCH.md line 311-312):
`state,cd,geo_id,fips,collision_count,colliding_seqs,max_seq,free_slots_remaining,safe_start_seq`.
Flag KY-CD1 (98/99 occupied) and OK-CD1 (43/99 occupied) explicitly per RESEARCH.md
Critical Finding 6's recommendation — these two need a documented alternate sub-band
(e.g., `seq` starting at 200) rather than the standard 1-99 range.

**Read-only guard:** this script only ever does `SELECT ... WHERE external_id < 0` —
never mutate; same SELECT-ONLY discipline as the incumbent-map script (see analog's
top-of-file comment banner, lines 1-15 — copy that banner style with `160`/`external_id
collision` substituted).

---

### `backend/scripts/diag-160-race-preexistence-audit.ts` (script, batch — NEW query class)

**Analog:** same scaffolding reuse as above (dotenv/pool/csvField/hard-guard/error
wrapper from `diag-154-incumbent-stance-gap.ts`). Query logic from RESEARCH.md
"Pattern 3" (proven live this session — discovered ME/MD/MA/NV/OR pre-seeded races +
IN/UT/ME stale primary-era candidate rows):

```typescript
// RESEARCH.md lines 406-421 — the critical deviation from a naive port: sweep
// ANY election_date, NOT just '2026-11-03' (a Nov-3-only filter misses IN's and
// UT's already-resolved primary infrastructure that informs the general-nominee).
const q = await pool.query(`
  SELECT substr(d.geo_id,1,2) AS fips, el.election_date, el.name,
         COUNT(DISTINCT r.id) AS race_ct, COUNT(rc.id) AS cand_ct
  FROM essentials.races r
  JOIN essentials.elections el ON el.id = r.election_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) = ANY($1::text[])
  GROUP BY fips, el.election_date, el.name ORDER BY fips, el.election_date
`, [WAVE3_FIPS]);
```

For the per-district (not just per-state-summary) detail needed to populate
`existing_race_id` in the field table, add a second query joining down to
`r.id, d.geo_id, rc.politician_id, rc.is_incumbent` (grain = one row per race +
candidate) — this is the query that will surface the NV-2 NULL-`politician_id`
anomaly and the IN-9 incumbent-flag bug (RESEARCH.md Critical Finding 4) for
explicit console.warn flagging, mirroring the WARNING-block style in
`diag-154-incumbent-stance-gap.ts` lines 373-394 (`console.warn` with a clear
"MUST fix, not propagate" message per anomaly).

**Artifact decision (Claude's discretion, per RESEARCH.md line 312):** either emit a
standalone `160-race-preexistence-audit.csv` (grain: one row per pre-existing
race/candidate found) OR fold the `existing_race_id` values directly into
`160-field-table.csv`'s `existing_race_id` column during the merge wave — RESEARCH.md
explicitly leaves this open ("NEW or folded into field-table"). Recommend: emit the
standalone CSV as the audit trail (so the anomaly list is inspectable independent of
the field table), AND populate `existing_race_id` in the field table from it — same
"emit both a full audit CSV and a curated final CSV" pattern already implicit in how
`154-incumbent-map.csv` (full audit) differs from `154-field-table.csv` (curated,
enriched with source URLs).

---

### `backend/scripts/diag-160-validate-field-table.py` (validator, batch)

**Analog:** `backend/scripts/diag-154-validate-field-table.py` (full file read, 132
lines — one pass, no re-read needed).

**Bootstrap + path pattern** (lines 1-33):
```python
HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.normpath(os.path.join(
    HERE, "..", "..",
    ".planning", "phases", "154-field-resolution-stance-gap-diagnostic",
    "154-field-table.csv",
))
EXPECTED = {"PA": 17, "IL": 17, "OH": 15, "GA": 14, "NC": 14, "MI": 13, "NJ": 12, "VA": 11}
EXPECTED_TOTAL = 113
EXPECTED_DECIDED = 89
EXPECTED_PENDING = 24
PID_EXEMPT = {"open-seat-vacancy", "special-seated", "vacancy"}
REQUIRED_COLS = [
    "state", "cd", "geo_id", "target_election", "existing_race_id",
    "incumbent_name", "incumbent_pid", "incumbent_external_id",
    "incumbent_stance_count", "incumbent_top_up_tier", "nominee_status",
    "general_candidates", "new_records_needed", "field_status", "source_url",
]
```
For 160, rewrite the path to `160-field-resolution-stance-gap-diagnostic/160-field-table.csv`,
rebuild `EXPECTED` for 38 states / 178 total, and rebuild the decided/late partition to
**88 decided / 90 late-primary** (RESEARCH.md Critical Finding 1's verified split —
NOT 89/24 like Wave-2). Extend `REQUIRED_COLS` with the D-05 additions:
`seeding_phase`, `ballot_system`, `rcv`, `filing_open_deadline`.

**Per-row validation loop** (lines 70-115) — copy the structure verbatim
(non-empty `source_url`/`nominee_status`, PID-exempt set check, `existing_race_id`
UUID-shape check). **Critical adaptation:** the analog's `existing_race_id` check is
state-blanket (`if st == "VA": require UUID else: require blank` — lines 87-95). For
160 this must become a **row-level set membership check**, not a state check, because
existing-race states are ME/MD/MA/NV/OR at the **district** level, all 29 confirmed
rows: e.g. `EXISTING_RACE_STATES = {"ME", "MD", "MA", "NV", "OR"}` then `if st in
EXISTING_RACE_STATES: require UUID else: require blank`. Also add the AL split-state
handling per RESEARCH.md Critical Finding 2 — AL-3/4/5 rows must have
`field_status=decided`, AL-1/2/6/7 rows must have `field_status=late-primary`
(district-level assertion, not a per-state EXPECTED-partition shortcut).

**Fail/pass pattern** (lines 46-48, 117-127) — copy verbatim:
```python
def fail(msg):
    print("FAIL: " + msg)
    sys.exit(1)
...
if problems:
    print("FAIL: %d problem(s):" % len(problems))
    for p in problems:
        print("  - " + p)
    sys.exit(1)
print("PASS: ...")
```

---

### `backend/scripts/160-verify.sql` (write-free SQL gate, batch)

**Analog:** `backend/scripts/154-verify.sql` (full file read, 154 lines — one pass).

**Header/safety banner pattern** (lines 1-37) — copy the write-free framing verbatim,
substituting the discovered baseline narrative:
```sql
-- 160-verify.sql — Phase 160 read-only PRE-SEEDING baseline gate (USHC3-01).
-- SELECT-only. ...
-- WRITE-FREE: no INSERT/UPDATE/DELETE into essentials|inform. The only writes are
--   `CREATE TEMP TABLE ... ON COMMIT DROP` for diffing (149/148/154-verify.sql precedent).
\set ON_ERROR_STOP on
DO $$
DECLARE
  v_total int;
  v_mismatch text;
  ...
BEGIN
  ...
  RAISE NOTICE 'ALL ASSERTIONS PASSED (160 baseline)';
END $$;
```

**A1 — per-state district-count assertion** (lines 40-77): copy the
`_expected_counts` temp table + `string_agg` mismatch-diffing pattern verbatim, scaled
to the 38-state list, asserting `v_total = 178` (not 113).

**A2 — pre-seeding candidate/race invariant, REWRITTEN not copied verbatim:** this is
the single most important deviation the RESEARCH.md explicitly calls out (line 252):
Phase 154's A2 asserted "0 pre-seeded races except VA's 11 scaffold-only rows." Phase
160 **must assert the DISCOVERED 29-race baseline** (ME 2 / MD 8 / MA 9 / NV 4 / OR 6),
**not** a blanket zero-races claim, and must separately assert the **candidate**
invariant per state since NV already has 9 real `race_candidates` (unlike VA's 0):
```sql
-- Adapt A2b's shape (154-verify.sql lines 99-117) to a multi-state VALUES list:
CREATE TEMP TABLE _expected_races (fips text, st text, n int) ON COMMIT DROP;
INSERT INTO _expected_races (fips, st, n) VALUES
  ('23','ME',2), ('24','MD',8), ('25','MA',9), ('32','NV',4), ('41','OR',6);
-- then assert: (a) races.count for these 5 states' NATIONAL_LOWER districts on
-- 2026-11-03 = SUM(n) = 29; (b) 0 pre-seeded races for the OTHER 33 states;
-- (c) race_candidates count for NV = 9 (not 0), for ME/MD/MA/OR = whatever this
-- session's live sweep found (MA=2, ME=2 general + note the 8 stale primary rows
-- separately, MD=0, OR=0) — do NOT assert 0 candidates blanket like 154 did.
```

**A3 — holder invariant** (lines 119-150): copy the symmetric-difference pattern
verbatim, but the expected-vacant set is **empty** for Wave-3
(`_expected_vacant` gets **no INSERT rows** — RESEARCH.md confirms Query C returned 0
rows this session, unlike Wave-2's GA-13). Assert `_actual_nonone` is empty (all 178
districts have exactly 1 holder) rather than asserting a specific vacant geo_id set.

**Optional A4 (new, discretionary):** an assertion documenting (not blocking on) the
16-collision finding from Critical Finding 6 is reporting-only info, not a fail-worthy
invariant (collisions are handled by seeding-time live-checks, not by this gate) — do
NOT add a hard `RAISE EXCEPTION` for the collision count; if included at all, use
`RAISE NOTICE` only, consistent with the "informational, not a gate failure" nature of
that finding.

---

### `.planning/phases/160-.../160-incumbent-map.csv` (data artifact)

**Analog:** `.planning/phases/154-.../154-incumbent-map.csv` — identical schema, no
new columns needed here (the incumbent-map is a pure DB-derived audit, D-05's new
columns belong on the field table, which is the research-enriched artifact):
```
state,cd,geo_id,incumbent_name,incumbent_pid,incumbent_external_id,incumbent_is_active,incumbent_stance_count,incumbent_top_up_tier
GA,1,1301,"Earl L. ""Buddy"" Carter",4bf58192-5208-4c5f-93f1-ac0a7e6b162d,-13001,true,15,partial
```
Reuse verbatim column order/quoting (RFC-4180 double-quote escaping on names with
embedded quotes/commas, e.g. `"Earl L. ""Buddy"" Carter"`).

### `.planning/phases/160-.../160-field-table.csv` (data artifact)

**Analog:** `.planning/phases/154-.../154-field-table.csv` — same 15-column base
shape, **append 4 columns per D-05**: `seeding_phase` (161-165), `ballot_system`
(`standard`/`top-two`/`top-four-rcv`/`rcv-general`/`open-primary-nov3`), `rcv`
(boolean/flag), `filing_open_deadline` (blank unless `field_status` contains
`filing-open`). Base row shape to extend:
```
state,cd,geo_id,target_election,existing_race_id,incumbent_name,incumbent_pid,incumbent_external_id,incumbent_stance_count,incumbent_top_up_tier,nominee_status,general_candidates,new_records_needed,field_status,source_url
GA,1,1301,GA 2026 Statewide General,,"Earl L. ""Buddy"" Carter",4bf58192-5208-4c5f-93f1-ac0a7e6b162d,-13001,15,partial,open-seat-vacancy,Jim Kingston (Republican); Amanda Hollowell (Democratic),Jim Kingston; Amanda Hollowell,decided,https://en.wikipedia.org/wiki/...
```
`field_status` values change from Wave-2's binary `decided` / `pending-primary` to
Wave-3's `decided` / `late-primary` (per D-04/CONTEXT.md) — update the validator's
literal string match accordingly (see `diag-160-validate-field-table.py` above).

### `.planning/phases/160-.../160-negative-id-audit.csv` (data artifact — NEW)

**No analog** (Wave-2 had 0 collisions, never needed this artifact). Shape is
Claude's/planner's discretion; suggested per RESEARCH.md's Pattern 2 output and the
"safe starting seq" recommendation (Critical Finding 6):
```
state,cd,geo_id,fips,collision_count,colliding_seqs,max_seq,free_slots_remaining,safe_start_seq
KY,1,2101,21,98,"1-98",98,1,99
```
Follow the same `csvField()` RFC-4180 quoting convention as the other two artifacts
for the `colliding_seqs` list field (will contain commas — must be quoted).

---

## Shared Patterns

### DB Connection + Env Bootstrap
**Source:** `backend/src/lib/db.ts` (imported as `'../src/lib/db.js'` per NodeNext/tsx
resolution — copy the import path exactly as written in the 154 analog, do not "fix"
the extension) + `import 'dotenv/config';` at the top of every `.ts` script.
**Apply to:** all three new `.ts` scripts.
```typescript
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
```

### Read-Only / Write-Free Discipline
**Source:** top-of-file banner comments in `diag-154-incumbent-stance-gap.ts` (lines
1-15) and `154-verify.sql` (lines 1-28).
**Apply to:** all 5 new scripts — every file must open with a comment banner stating
SELECT-ONLY / no INSERT-UPDATE-DELETE / re-runnable, and the SQL gate must use
`CREATE TEMP TABLE ... ON COMMIT DROP` for any diffing scratch space (never a
persistent table).

### CSV Emit (RFC-4180 quoting + hard row-count guard)
**Source:** `diag-154-incumbent-stance-gap.ts` `csvField()` (lines 88-96) + the
pre-write row-count guard (lines 340-354).
**Apply to:** `diag-160-incumbent-stance-gap.ts`, `diag-160-external-id-collision.ts`,
`diag-160-race-preexistence-audit.ts` (any script that writes a CSV artifact).
```typescript
function csvField(value: unknown): string {
  if (value === null || value === undefined) return '';
  const s = String(value);
  if (/[",\r\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}
// ... then, before writeFileSync:
if (dataRowCount !== EXPECTED_TOTAL) {
  console.error(`FATAL: CSV would have ${dataRowCount} data rows, expected exactly ${EXPECTED_TOTAL}...`);
  await pool.end();
  process.exit(1);
}
```

### Error Handling Wrapper (TS scripts)
**Source:** `diag-154-incumbent-stance-gap.ts` lines 400-408.
**Apply to:** all three `.ts` scripts.
```typescript
main().catch(async (err) => {
  console.error('Diagnostic failed:', err);
  try { await pool.end(); } catch { /* noop */ }
  process.exit(1);
});
```

### SQL Assertion Style (`DO $$ ... RAISE EXCEPTION`)
**Source:** `154-verify.sql` full file (esp. lines 40-153).
**Apply to:** `160-verify.sql`.
```sql
DO $$
DECLARE
  v_mismatch text;
BEGIN
  SELECT string_agg(...) INTO v_mismatch FROM ... WHERE ...;
  IF v_mismatch IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL A1: ...: %', v_mismatch;
  END IF;
  RAISE NOTICE 'PASS A1: ...';
END $$;
```

### Python Validator Fail/Pass Style
**Source:** `diag-154-validate-field-table.py` lines 46-48, 117-127.
**Apply to:** `diag-160-validate-field-table.py`.

### Incumbent Identity Join (never computed external_id)
**Source:** every Query A across both Phase-154 and Phase-160 research —
`essentials.districts d JOIN essentials.offices o ON o.district_id = d.id JOIN
essentials.politicians p ON p.id = o.politician_id WHERE d.district_type =
'NATIONAL_LOWER'`.
**Apply to:** `diag-160-incumbent-stance-gap.ts`, `diag-160-race-preexistence-audit.ts`,
and `160-verify.sql`'s A1/A3 assertions. Never join or filter on a computed
`external_id` for incumbent lookup.

### Command Invocation (cwd reset discipline)
**Source:** `diag-154-incumbent-stance-gap.ts` header comment (lines 17-19) and
`154-verify.sql` header comment (lines 30-32).
**Apply to:** every plan task that runs these scripts.
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a \
  && node --import tsx scripts/diag-160-incumbent-stance-gap.ts
# and
cd /c/EV-Accounts/backend && set -a && source .env && set +a \
  && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `backend/scripts/diag-160-external-id-collision.ts` (query logic only — scaffolding has an analog) | script | batch | No Phase-154 script exists because Wave-2's 8 states had 0 collisions; query logic instead sourced from this session's live RESEARCH.md findings (Pattern 2), which stands in for a codebase analog here |
| `backend/scripts/diag-160-race-preexistence-audit.ts` (query logic only — scaffolding has an analog) | script | batch | Same reasoning — Wave-2 only had VA as a single pre-existing-race case, handled inline in the 154 field-table validator rather than a dedicated script; Wave-3's 5-state/29-race scale warrants its own script, logic sourced from RESEARCH.md Pattern 3 |
| `160-negative-id-audit.csv` | data artifact | file-I/O | Genuinely new artifact class — no Phase-148 or Phase-154 equivalent (both waves' collision checks came back clean) |

## Metadata

**Analog search scope:** `backend/scripts/` (all `diag-*`, `*-verify.sql` files),
`.planning/phases/154-field-resolution-stance-gap-diagnostic/`,
`.planning/phases/148-*` (referenced in RESEARCH.md but `148-verify.sql` does not
exist on disk — confirmed via Glob; the origin pattern lives entirely in
`diag-148-incumbent-stance-gap.ts` / `diag-148-validate-field-table.py`, which Phase
154 already absorbed and is the more current/complete template to clone), `backend/src/lib/db.ts`.
**Files scanned:** `diag-154-incumbent-stance-gap.ts` (409 lines, full read),
`154-verify.sql` (154 lines, full read), `diag-154-validate-field-table.py` (132
lines, full read), `154-field-table.csv` + `154-incumbent-map.csv` (header + first 4
rows each), `backend/src/lib/db.ts` (21 lines, full read), plus Glob sweeps for
`148-verify.sql` (not found) and all `backend/scripts/*verify*.sql` / `*.py` files.
**Pattern extraction date:** 2026-07-03
