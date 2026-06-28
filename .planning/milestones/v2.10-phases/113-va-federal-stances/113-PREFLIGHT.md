# Phase 113 Pre-flight: VA Federal House Reps Stances + Finance

## Status
- Pre-flight captured: 2026-06-10
- Execution: inline research (no sub-agents — avoids API invocations)
- Context start: fresh session after /clear

## Migration Numbers
- max_migration in schema_migrations: 358 (NOTE: psql-applied migrations don't insert here — always use highest disk file)
- Highest file on disk: `20260610000010_340_va_delegates_wave10_stances.sql`
- **Next free migration: 341**

## The 11 VA Federal House Reps (external_id BETWEEN -5102011 AND -5102001)

| CD | full_name | UUID | external_id | Party |
|----|-----------|------|-------------|-------|
| VA-01 | Rob Wittman        | 8f4379fc-ae32-4f6a-8773-ac1d723106a5 | -5102001 | R |
| VA-02 | Jen Kiggans        | 512f27a4-e24f-4f62-a288-18b1e37db463 | -5102002 | R |
| VA-03 | Bobby Scott        | cc499c9a-d165-4cd7-831d-51611339ac29 | -5102003 | D |
| VA-04 | Jennifer McClellan | 3e7c0e88-5e35-4d71-8022-98731af6461b | -5102004 | D |
| VA-05 | Ben Cline          | e4deeac3-b172-473d-9696-a07d874f4795 | -5102005 | R |
| VA-06 | Morgan Griffith    | 12eef223-444e-4bed-8081-f1fd26c43e42 | -5102006 | R |
| VA-07 | Eugene Vindman     | 9a9d6b64-60b3-40c9-b213-4088d9a51e68 | -5102007 | D |
| VA-08 | Don Beyer          | 0c1eef2f-19be-440f-b3d9-bd99d44ec056 | -5102008 | D |
| VA-09 | John McGuire       | e603fa67-7992-409e-a1e2-1385c32dc217 | -5102009 | R |
| VA-10 | Suhas Subramanyam  | 98b05c70-2a30-48ea-81f3-b3216ffb0ca0 | -5102010 | D |
| VA-11 | James Walkinshaw   | 32ea954f-8bfa-4d28-9f9e-12d1929cb853 | -5102011 | D |

**Existing stances: 0** (clean slate confirmed 2026-06-10)

## Execution Plan (inline — no sub-agents)

### Approach
Research all 11 reps directly using WebFetch in the main conversation. Sources:
- congress.gov/member/[slug] — voting record, sponsored bills
- votesmart.org — VIF questionnaire responses (most reliable for exact stances)
- ballotpedia.org — biography + issue positions
- Each member's official House website
- govtrack.us — bill sponsorship patterns
- OpenSecrets.org — FEC finance data (also covers VAFI-01)

Do 3-4 reps per context block (WebFetch HTML is verbose). Batch: R members together, D members together, or by similarity to keep stance calibration tight.

### Suggested Research Order
**Batch 1** (R members, national security/military focus):
1. Rob Wittman (VA-01) — Armed Services Chair, long record
2. Jen Kiggans (VA-02) — freshman, Navy vet, fewer votes
3. Morgan Griffith (VA-09... wait, he's VA-09 by district but ext_id -5102006)
   Actually: Ben Cline (VA-05), Morgan Griffith (VA-06)

**Batch 2** (D members, progressive record):
1. Bobby Scott (VA-03) — longest-serving, Education & Labor ranking
2. Don Beyer (VA-08) — wealthy, progressive NoVA
3. Jennifer McClellan (VA-04) — former state senator, won special election 2023

**Batch 3** (newer D members):
1. Eugene Vindman (VA-07) — won 2024, progressive
2. Suhas Subramanyam (VA-10) — won 2024, tech/AI background
3. James Walkinshaw (VA-11) — won 2024

**Batch 4** (remaining R):
1. John McGuire (VA-09) — won 2024 runoff vs. Bob Good

### Migration Plan
- All 11 reps = 1 migration: **341**
- File: `supabase/migrations/20260610000011_341_va_federal_reps_stances.sql`
- CSV: `backend/data/stance-research/2026-06-10-113-va-federal-reps.csv`
- DO $$ range: `BETWEEN -5102011 AND -5102001`

### Finance (VAFI-01/02) — Lower Priority, Same Session
After stances, run existing FEC ingestion script for all 11 reps.
Script: `backend/scripts/fix-fec-name-mismatches.ts` or equivalent FEC fetch.
VA state officials (Governor, Lt. Gov, AG, state senators) — assess VPAP only; no ingestion unless machine-readable structured data found.

## VAST-04 / VAST-05 Success Criteria
- All 11 reps: ≥1 sourced stance OR documented honest-skip
- Every answer row paired with politician_context row containing ≥1 real source URL
- DO $$ ASSERT unsourced_count = 0 scoped to BETWEEN -5102011 AND -5102001

## Key Sources Per Rep (pre-research notes)
- **Wittman**: long Armed Services record; votes on defense, agriculture (rural VA-01)
- **Kiggans**: Navy veteran; healthcare, veterans issues; moderate R
- **Bobby Scott**: Education & Labor; civil rights, criminal justice, voting rights — rich record since 1993
- **McClellan**: first Black woman from VA in Congress; reproductive rights, civil rights
- **Cline**: conservative; Judiciary Committee; immigration, fiscal issues
- **Griffith**: Energy & Commerce; fossil fuels, healthcare drug pricing
- **Vindman**: national security, Ukraine, civil rights — progressive freshman
- **Beyer**: Ways & Means; tax policy, environment, gun control — very well documented
- **McGuire**: defeated Bob Good in R primary; more mainstream R than Good
- **Subramanyam**: tech/AI background; may have AI regulation stances
- **Walkinshaw**: county supervisor background; housing, local gov't issues
