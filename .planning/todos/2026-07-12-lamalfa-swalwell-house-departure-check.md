# LaMalfa CA-01 + Swalwell CA-14 — possible mid-2026 House departures (2026-07-12)

Surfaced by the bioguide photo audit (2026-07-12): both carry their own CORRECT bioguide IDs
(L000578, S001193) but have **dropped out of legislators-current.json**, which tracks sitting
members only. Photos are correct — this is a FIELD/OFFICE data question, not photo work.

## What to verify

For each: did he resign / leave the House in 2026 (e.g., Swalwell CA governor run?), and is
the seat now vacant or filled by special election?

1. Check unitedstates.github.io/congress-legislators/legislators-historical.json for an
   end-date on their final term (fastest oracle).
2. Corroborate via clerk.house.gov vacancy list or news.

## If departed, fix on prod

- `essentials.offices` for the seat: `is_vacant = true` + `vacant_since` (or point at the
  special-election winner if one exists).
- `essentials.politicians.is_active/is_incumbent` for the departed member (remember: the
  politicians.is_incumbent mass-true pollution — authoritative flag lives on race_candidates).
- Check `essentials.races`/`race_candidates` for CA-01 / CA-14 2026: a departed incumbent
  should not be seeded as incumbent-running; check for special-election races to seed.
- Reps feed shows `is_incumbent=true` only — a stale record here leaks a non-member into
  the feed.

## Cross-refs

- Audit method + wrong-bioguide incident (Kelly/Moreno/Schmitt/Budd): memory
  `project_headshot_sweep_program.md`.
- CA seeding history: Phase 149 (v2.20 Wave-1).
