# 159-03 SUMMARY — VA 2026 U.S. House provisional field seed (onto existing races)

**Status:** ✅ COMPLETE (both tasks; automated verify PASS; idempotency proven)
**Executed:** 2026-07-01 (inline — web reconciliation + prod writes)

## What was built

- **Migration 1148** `1148_seed_va_2026_house_candidates.sql` — PROVISIONAL marker on the 11 existing VA races + 46 new politicians + 58 active `race_candidates`. **No election/race/office created** (VA already scaffolded).
- **Reconciliation CSV** `backend/data/seed-va-2026-house/159-03-va-reconciliation.csv` — 58 rows.
- **Generator** `backend/scripts/159-va-generate.mts` (includes the dedup pass).

## Key facts for downstream plans (159-04 headshots/stances, 159-06 gate)

- VA election: `2026 Virginia General Election` (`a820319c-…`), 11 existing races (race_ids in CSV/generator).
- **New-candidate external_id band:** `-510101 .. -511104` (46 records; band verified empty pre-insert). Scheme `-(51*10000 + cd*100 + seq)`.
- **REUSE (non-incumbent):** **Stella Pekarsky** (VA-11 D) = existing "Stella G. Pekarsky" VA state senator record `-5110036`, `is_incumbent=false` — NOT duplicated.
- **Per-district active counts:** VA-1:8, VA-2:7, VA-3:3, VA-4:3, VA-5:7, VA-6:2, VA-7:5, VA-8:6, VA-9:7, VA-10:4, VA-11:6 = **58 active** (11 incumbents + 46 new + 1 reuse).
- **In-scope for 159-04 stances/headshots:** the 46 new records (`-510101..-511104`) + 3 thin incumbent top-ups (Vindman -5102007, Subramanyam -5102010, McGuire -5102009). Other 8 incumbents partial-and-left.

## Verification (PASS)

- 11 races, 58 active rc, 0 NULL politician_id, 0 duplicate full_name, exactly 1 Walkinshaw record, 11 PROVISIONAL markers.
- VA-5/6/9 incumbents correctly wired in elections feed: geo 5105→McGuire, 5106→Cline, 5109→Griffith.
- Idempotency: re-running 1148 inserted/updated 0 rows.

## ⚠ Pre-existing data issue surfaced (CARRY-FORWARD — NOT fixed here)

**VA-5/6/9 incumbent OFFICE→district links are rotated in `essentials.offices`:** the office for CD-5 (geo 5105) links to **Ben Cline**, CD-6 → **Morgan Griffith**, CD-9 → **John McGuire** — but the true 2026 delegation (GovTrack/Wikipedia + districts-table OCD labels) is **VA-5 McGuire, VA-6 Cline, VA-9 Griffith**. This is a pre-existing incumbent-office assignment bug (predates this phase; likely from before McGuire's 2024 VA-5 win reshuffled the map).

- **This phase wired the ELECTIONS feed CORRECTLY** (true incumbent per district by reusing the right person's record), so `/elections` is right.
- **The REPS feed (`offices`) is still rotated** for VA-5/6/9 → a residing user in VA-5 would see Cline as their rep. **Recommend a dedicated 3-office `politician_id` swap** (out of this phase's "seed 2026 field" scope). Flagged for operator decision.

## Reconciliation notes (vs 159-RESEARCH VA table — reconciled to current Wikipedia-raw + Ballotpedia)

- **VA-2:** Elaine Luria confirmed active D; indeps = Gaines + Staten (RESEARCH's Albritton + write-in dropped — not on current lists).
- **VA-5:** R primary = McGuire (inc) + Melanie Lucero + **Bob Good** (former incumbent, running again — new record); D = Perriello/Krzyzanowski/Tracinski; indep Chris Register.
- **VA-9:** D primary adds **Brandi Hall** (4 total); R primary adds **Brandon Cook**; indep Michael Jackson.
- **VA-10:** **Sam Wong WITHDREW** → 3 R (Beckwith/Perry/Suttles), not 4.
- **VA-7:** all D challengers withdrawn (Vindman uncontested); R = Harding/Ollivant/Ricky Smithers; indep Randall Terry.
- **VA-11:** R primary = Headrick + Van Meter (Purves not seeded — absent from current sources); Pekarsky REUSE.
- **Withdrawn candidates excluded** throughout; declared indep/3rd-party seeded PROVISIONAL (VA filing deadline 2026-08-04) → 159-05 reconciles.
- **Map:** 2021 Special Masters map in effect (SCoVA May-8 ruling); DB geo 5101..5111 unchanged. (A later redistricting-referendum article surfaced in search — flag for 159-05 to confirm which map governs the Nov general.)
- **Dedup:** all other 46 challengers (incl. former US Reps Luria/Good/Perriello) had zero existing records → NEW.

## Antipartisan invariant

Party never stored on `race_candidates`; `races.primary_party` untouched; `politicians.party` NULL. Only the `description` column of the 11 existing races was written (PROVISIONAL marker).
