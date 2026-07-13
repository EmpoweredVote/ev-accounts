# LaMalfa CA-01 + Swalwell CA-14 — possible mid-2026 House departures (2026-07-12)

## RESOLVED 2026-07-12 (same day) — both departures confirmed and fixed on prod

- **LaMalfa left the House 2026-01-05** (legislators-historical). **James Gallagher (R) won
  the special election, sworn 2026-06-10** (bioguide G000607). Fixed: CA-01 office
  `095d8394` reassigned LaMalfa→Gallagher (both directions), LaMalfa is_incumbent=false +
  office unlinked, Gallagher is_incumbent=true on politicians AND his Nov CA-01
  race_candidates row (`7d86f45c`). Gallagher already had a headshot from the CA wave.
- **Swalwell left the House 2026-04-14** (ran for CA Governor — that candidacy is now
  **withdrawn** per his rc row). **CA-14 seat still VACANT** (no member in
  legislators-current). Fixed: office `4cb713ee` is_vacant=true, vacant_since=2026-04-14,
  holder NULL; Swalwell officeholder record (`c98fd0a3`) is_incumbent=false + unlinked.

## Remaining follow-ups (still open)

1. **CA-14 special election**: seat vacant since April — a special election is likely
   called/scheduled (possibly consolidated with Nov). Watch for it and seed the race when
   the field is known. Re-check ~Aug 1.
2. **Swalwell dual-pid**: `c98fd0a3` (ex-officeholder) + `b0cddcaa` (withdrawn gov
   candidate, no office) — add to the dual-pid merge queue
   (`.planning/todos/2026-07-10-senate-dual-pid-merge.md` pattern).
3. ~~Optional: replace Gallagher's campaign headshot with his official G000607 congressional
   portrait now that he's sworn in.~~ DONE 2026-07-12: unitedstates.io CDN doesn't have
   G000607 yet (new member lag) — **bioguide.congress.gov/photo/{id}.jpg and
   clerk.house.gov/content/assets/img/members/{id}.jpg both serve freshly sworn members**;
   used the bioguide one (600×750, exact 4:5), overwritten in place, public_domain.

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
