# 159-01 SUMMARY — MI 2026 U.S. House provisional field seed

**Status:** ✅ COMPLETE (both tasks; both automated verifies PASS; idempotency proven)
**Executed:** 2026-07-01 (inline — web-reconciliation + prod writes; gsd-executor lacks web tools)

## What was built

- **Migration 1146** `1146_seed_mi_2026_house_elections_races.sql` — 1 election + 13 provisional races.
- **Migration 1147** `1147_seed_mi_2026_house_candidates.sql` — 56 new politicians + 67 active `race_candidates`.
- **Reconciliation CSV** `backend/data/seed-mi-2026-house/159-01-mi-reconciliation.csv` — 69 rows (67 active + 2 REUSE-NO-ROW).
- **Generator** `backend/scripts/159-mi-generate.mts` — reproducible source of both migrations + CSV.

## Key facts for downstream plans (159-02 headshots/stances, 159-06 gate)

- **MI election UUID:** `03079314-238b-417b-a9e5-5e6d203e1594` (name `MI 2026 Statewide General`, date 2026-11-03, general/state/MI).
- **New-candidate external_id band:** `-260101 .. -261307` (56 records; band verified empty pre-insert; 0 collisions). Scheme `-(26*10000 + cd*100 + seq)`, seq per district in D→R→I/G order.
- **Per-district active counts:** MI-1:8, MI-2:4, MI-3:3, MI-4:4, MI-5:3, MI-6:3, MI-7:6, MI-8:4, MI-9:4, MI-10:7, MI-11:8, MI-12:5, MI-13:8 = **67 active** (11 incumbents reused + 56 new).
- **In-scope for 159-02 stances/headshots:** the 56 new records (`-260101..-261307`). The 11 reused incumbents are already partially stanced (v2.17) and are OUT of 159-02 scope.

## Verification (both PASS)

- Task 1: 1 election, 13 provisional races, 0 NULL office_id, all 13 `PROVISIONAL:%`.
- Task 2: 13 races, 67 active rc, 0 NULL politician_id, 0 duplicate full_name, James(-26010)+Stevens(-26011) **absent** from active field.
- Idempotency: re-running 1147 inserted 0 rows.

## Reconciliation notes / decisions

- **MI-12 Allen Downer** (RESEARCH-flagged as news-only) **live-confirmed** as a qualified Dem primary candidate (Ballotpedia has a candidate page; Tlaib/Downer/Jackson/Nolen D primary + Hooper R). Seeded active.
- **MI field** taken from the 159-RESEARCH MI BOE PRI-2026 table (HIGH confidence, official BOE report); no flips vs the table.
- **Open seats — MI-10 James (-26010) → Governor, MI-11 Stevens (-26011) → US Senate:** both kept as records, **no active row** in their old seat (open-seat convention, mirrors NJ-12 Watson Coleman). All MI-10/MI-11 primary candidates (both parties) are new active records.
- **Declared indep/Green seeded provisional** (MI filing deadline 2026-07-16): MI-1 Featherly/Latza, MI-5 Bronke (Green), MI-6 Shabazz (Green), MI-7 Prieditis, MI-9 Cartwright/Valdez, MI-13 Morton. Reconciled in 159-05 cull.
- **Dedup:** live name-match against `essentials.politicians` (first+last, real records only) — all 56 challengers had zero existing-record matches → all NEW (even former US Rep Elaine Luria, former state figures Greimel/Moss/Bouchard/Jackson have no records in this DB; coverage = current members + specifically-seeded sets).

## Antipartisan invariant

Party never stored on `race_candidates`; `races.primary_party` NULL; `politicians.party` NULL (matches NJ-157 convention). Party parsed for seq-ordering context only.
