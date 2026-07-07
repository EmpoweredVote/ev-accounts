# Phase 160 Field Table — Human View

**Artifact:** `160-field-table.csv` (178 rows, 19 columns) — the single canonical field-resolution
artifact that seeding phases 161–165 each filter by `seeding_phase`. Resolution date: 2026-07-03.

This document is prose + tables only (no fenced code) documenting the special cases baked into
the CSV, so seeding-phase planners and Phase 167 (post-primary reconciliation) can consume it
without re-deriving anything from the raw data.

---

## 1. The 88-Decided / 90-Late-Primary Split

As of the 2026-07-03 resolution date, 88 of the 178 districts already have a confirmed general-
ballot nominee field (their state primary has already occurred); the other 90 districts' fields
are still primary-pending and must be seeded as the **full provisional field** (all qualified
candidates, tagged for the Phase-167 post-primary cull), never deferred to a separate seeding
wave — per the v2.22 "seed now, cull later" principle generalized from Phase 159 (v2.21).

| Field status | Districts | Share |
|---|---|---|
| `decided` | 88 | 49.4% |
| `late-primary` | 90 | 50.6% |
| **Total** | **178** | 100% |

This split is close to 50/50 because roughly half of the 38 Wave-3 states hold their 2026
congressional primary before the 2026-07-03 resolution date and half hold it after.

---

## 2. Per-State District Counts (all 38 states)

| State | Decided | Late-Primary | Total Districts | Seeding Phase |
|---|---:|---:|---:|:---:|
| AK | 0 | 1 | 1 | 165 |
| AL | 3 | 4 | 7 | 163 |
| AR | 4 | 0 | 4 | 164 |
| AZ | 0 | 9 | 9 | 161 |
| CO | 8 | 0 | 8 | 163 |
| CT | 0 | 5 | 5 | 164 |
| DE | 0 | 1 | 1 | 165 |
| HI | 0 | 2 | 2 | 165 |
| IA | 4 | 0 | 4 | 164 |
| ID | 2 | 0 | 2 | 165 |
| IN | 9 | 0 | 9 | 162 |
| KS | 0 | 4 | 4 | 164 |
| KY | 6 | 0 | 6 | 164 |
| LA | 0 | 6 | 6 | 163 |
| MA | 0 | 9 | 9 | 161 |
| MD | 8 | 0 | 8 | 162 |
| ME | 2 | 0 | 2 | 165 |
| MN | 0 | 8 | 8 | 162 |
| MO | 0 | 8 | 8 | 162 |
| MS | 4 | 0 | 4 | 164 |
| MT | 2 | 0 | 2 | 165 |
| ND | 1 | 0 | 1 | 165 |
| NE | 3 | 0 | 3 | 165 |
| NH | 0 | 2 | 2 | 165 |
| NM | 3 | 0 | 3 | 165 |
| NV | 4 | 0 | 4 | 165 |
| OK | 5 | 0 | 5 | 164 |
| OR | 6 | 0 | 6 | 164 |
| RI | 0 | 2 | 2 | 165 |
| SC | 7 | 0 | 7 | 163 |
| SD | 1 | 0 | 1 | 165 |
| TN | 0 | 9 | 9 | 161 |
| UT | 4 | 0 | 4 | 165 |
| VT | 0 | 1 | 1 | 165 |
| WA | 0 | 10 | 10 | 161 |
| WI | 0 | 8 | 8 | 163 |
| WV | 2 | 0 | 2 | 165 |
| WY | 0 | 1 | 1 | 165 |
| **Total (38 states)** | **88** | **90** | **178** | — |

Per-seeding-phase district loads: **161** = 37 (WA+AZ+TN+MA, 100% late-primary — the anchor
seeding phase is entirely provisional-field work), **162** = 33 (IN+MD+MN+MO, 17 decided / 16
late-primary), **163** = 36 (WI+CO+AL+SC+LA, 18/18), **164** = 38 (KY+OR+CT+OK+AR+IA+KS+MS,
29/9), **165** = 34 (17 small-delegation states, 24/10).

---

## 3. Alabama Is District-Split, Not State-Split

Alabama's congressional map was redrawn mid-cycle (VRA redistricting litigation adding a second
Black-majority district; SCOTUS reverted to the 2023 map). This produces two different primary
timelines within the same state's delegation — the field table carries AL at the **district**
level, not the state level:

| Districts | Primary Timeline | `field_status` |
|---|---|---|
| AL-3, AL-4, AL-5 | Primary May 19, 2026; runoff June 16, 2026 (no candidate won >50%) | `decided` |
| AL-1, AL-2, AL-6, AL-7 | Governor's proclamation moved these 4 districts to a special primary Aug 11, 2026, **no runoff possible** | `late-primary` |

All 7 AL rows live in seeding Phase 163 (with WI+CO+SC+LA); the 3 decided rows and 4 late-primary
rows are seeded together but treated per their individual `field_status`.

---

## 4. Louisiana's Jungle Primary (System Change for 2026)

Louisiana was set to hold its first closed party primary for Congress in 2026, but a U.S. Supreme
Court ruling on Louisiana's congressional district lines forced that plan to be cancelled for
U.S. House races specifically. Congressional races revert to Louisiana's traditional **fall open
("jungle") primary**: all candidates regardless of party appear on the **November 3, 2026**
ballot; a candidate winning outright with >50% is elected; otherwise the top two advance to a
December runoff.

- **Qualifying period: August 5–7, 2026.** LA's House field cannot be authoritatively resolved
  before qualifying closes — this is why all 6 LA rows carry `field_status=late-primary` even
  though there is no traditional "primary date" to wait for.
- `ballot_system=open-primary-nov3` on all 6 LA rows, with `filing_open_deadline=2026-08-07`
  (the close of the qualifying window).
- LA's U.S. Senate race and local races still use the May 16, 2026 closed-primary date — only
  the U.S. House races are affected by the reversion.
- CD-6 (Cleo Fields, Black-majority district) was the specific subject of the SCOTUS case;
  verify at Phase-163 execution time whether district boundaries are still final for the Nov-3
  ballot.

---

## 5. AK/ME RCV Over-Indulgence (D-04a)

Per the operator's standing principle — "Empowered Vote MOST helps communities that Rank their
politician... if there is an area to over-indulge in our search, it's making sure we are very
thorough to support RCV races" — Alaska and Maine get exhaustive field research, not the routine
2-3-candidate minimum:

| State | `ballot_system` | `rcv` | Notes |
|---|---|---|---|
| AK (at-large) | `top-four-rcv` | `true` | Top-four primary Aug 18, 2026; RCV general Nov 3. The field table carries all **14 candidates** from the official Aug-18 primary field (`field_status=late-primary`) rather than pre-guessing the top-4 advancers. |
| ME-1 | `rcv-general` | `true` | RCV-tabulated primary (Jun 9, decided); Pingree renominated. |
| ME-2 | `rcv-general` | `true` | RCV-tabulated primary (Jun 9, decided); Dunlap beat the open-seat Democratic field; LePage secured the R nomination. |

`rcv=true` on exactly 3 of the 178 rows (AK's single at-large row + both ME districts) — no
other Wave-3 state uses ranked-choice voting for its U.S. House race.

---

## 6. Per-State New-Record Counts

Sum of `new_records_needed` entries per state (excludes embedded `NOTE-*` annotation markers,
which are advisory text, not candidate records):

| State | New Records | State | New Records | State | New Records |
|---|---:|---|---:|---|---:|
| AK | 14 | IN | 13 | OK | 10 |
| AL | 21 | KS | 22 | OR | 7 |
| AR | 6 | KY | 15 | RI | 4 |
| AZ | 32 | LA | 27 | SC | 16 |
| CO | 9 | MA | 18 | SD | 5 |
| CT | 17 | MD | 13 | TN | 73 |
| DE | 1 | ME | 3 | UT | 25 |
| HI | 15 | MN | 35 | VT | 3 |
| IA | 9 | MO | 58 | WA | 60 |
| ID | 8 | MS | 8 | WI | 28 |
| — | — | MT | 9 | WV | 5 |
| — | — | ND | 2 | WY | 14 |
| — | — | NE | 14 | — | — |
| — | — | NH | 22 | — | — |
| — | — | NM | 3 | — | — |
| — | — | NV | 11 | — | — |

**Total new records across all 178 districts: 655.** This is a ceiling estimate — some of these
(e.g., NV's already-wired challengers, UT's already-existing-pid incumbent re-links per §8) need
stance-only or re-linking work rather than brand-new `politicians` rows; each seeding phase
resolves the exact new-vs-reuse split per its own diagnostic pass.

---

## 7. The 13 Zero-Tier Incumbents (Downstream Scope)

13 of the 178 mapped incumbents currently have **zero** federal-24 compass stances on file
(`incumbent_top_up_tier=zero`) — despite being correctly-mapped, real, sitting incumbents who
went through v2.16/v2.17 House-rep seeding but were never run through the stance pipeline:

| Bucket | Count | Members |
|---|---:|---|
| Maryland (entire delegation) | 8 | Harris (MD-1), Olszewski (MD-2), Elfreth (MD-3), Ivey (MD-4), Hoyer (MD-5), McClain Delaney (MD-6), Mfume (MD-7), Raskin (MD-8) |
| Indiana (partial) | 3 | Baird (IN-4), Carson (IN-7), Messmer (IN-8) |
| Maine (entire delegation) | 2 | Pingree (ME-1), Golden — now Dunlap's opponent context (ME-2) |
| **Total** | **13** | — |

This zero-tier top-up work is in scope for the owning seeding phase (162 for IN+MD, 165 for ME) —
each incumbent needs a full federal-24 stance pass alongside the new-challenger stance work,
not just the challengers.

---

## 8. Pre-Existing Race Reuse (29 of 178 Rows)

Contrary to the ROADMAP's original "none of the 38 states have pre-seeded 2026 House races"
assumption, live diagnostic queries found 5 states with pre-existing `essentials.races` rows for
the 2026-11-03 election that must be **reused** (`existing_race_id` populated), not re-created:

| State | Pre-existing races | Pre-existing candidates | `existing_race_id` populated |
|---|---:|---:|---|
| MA | 9 (all districts) | 2 (Clark MA-5, Pressley MA-7 — both incumbents) | all 9 rows |
| MD | 8 (all districts) | 0 | all 8 rows |
| OR | 6 (all districts) | 0 | all 6 rows |
| NV | 4 (all districts) | 9 (all 4 incumbents + 5 challengers) | all 4 rows |
| ME | 2 (all districts) | 2 general (Pingree, LePage) + 8 stale primary rows | both rows |
| **Total** | **29 races** | — | **29 of 178 rows** |

### Anomaly callouts (must fix, not propagate, in the owning seeding phase)

- **NV-2 NULL-`politician_id`:** the pre-existing Lynn Chapman `race_candidates` row for NV-2 has
  `politician_id IS NULL` — a data-quality gap that violates the "non-null politician_id"
  invariant. Phase 165 must **fix this row in place**, not create a duplicate Chapman record.
- **IN-9 incumbent-flag bug:** stale May-5, 2026 Indiana primary `race_candidates` rows (race
  `7d3f0042-eb15-462b-bf14-df15244c5d16` and related) incorrectly flag Erin Houchin's primary
  losers (Graham, Roark, Peck) as `is_incumbent=true` and flag Houchin herself as
  `is_incumbent=false` — even though Houchin is the true sitting IN-9 incumbent (confirmed via
  the incumbent map, 25 stances on file). Phase 162 must **correct these flags**, not treat the
  stale primary losers as incumbents.

---

## 9. Phase-167 Primary-Date Cluster Table

Every late-primary state's exact 2026 congressional primary date, grouped by calendar week, so
Phase 167 (date-gated post-primary reconciliation) can author one plan per cluster rather than
one plan per state. Dates span **July 21 (AZ)** through **September 15 (DE)**; Louisiana has no
traditional primary date and is listed as its own case (its Aug 5–7 qualifying-window close is
the analogous trigger event).

| Cluster (calendar week) | States (primary date) | Districts | Trigger action |
|---|---|---:|---|
| Week of Jul 20–26, 2026 | AZ (Jul 21) | 9 | Prune primary losers, confirm nominees |
| Week of Aug 3–9, 2026 | WA (Aug 4), MO (Aug 4), KS (Aug 4), TN (Aug 6), HI (Aug 8) | 10+8+4+9+2 = 33 | Prune primary losers, confirm nominees |
| Week of Aug 3–9, 2026 (own case) | LA — qualifying window closes Aug 7 (no primary; jungle-primary field finalizes) | 6 | Resolve full Nov-3 jungle-primary field from qualifying results |
| Week of Aug 10–16, 2026 | MN (Aug 11), WI (Aug 11), CT (Aug 11), VT (Aug 11), AL-1/2/6/7 special primary (Aug 11) | 8+8+5+1+4 = 26 | Prune primary losers, confirm nominees |
| Week of Aug 17–23, 2026 | AK top-four primary (Aug 18), WY (Aug 18) | 1+1 = 2 | Resolve top-4 RCV advancers (AK); prune losers (WY) |
| Week of Aug 31–Sep 6, 2026 | MA (Sep 1) | 9 | Prune primary losers, confirm nominees |
| Week of Sep 7–13, 2026 | NH (Sep 8), RI (Sep 9) | 2+2 = 4 | Prune primary losers, confirm nominees |
| Week of Sep 14–20, 2026 | DE (Sep 15) | 1 | Prune primary losers, confirm nominees |
| **Total late-primary districts** | — | **90** | — |

Cluster count: 7 calendar-week clusters + LA's own qualifying-window case = 8 total Phase-167
trigger groups, consistent with the "5–7 clusters, practicality" recommendation in
`160-RESEARCH.md`. The Sep 7–13 and Sep 14–20 clusters (NH, RI, DE) may carry forward past the
v2.22 milestone's nominal close, mirroring the FL-153 / 159-05 date-gated-tail precedent from
prior milestones.

For reference, the 88 already-**decided** districts' primary dates (all in the past as of the
2026-07-03 resolution date) are: IN (May 5), AR (Mar 3), MS (Mar 10), NE/WV (May 12), AL-3/4/5 +
KY + OR + ID (May 19), MT/SD/IA/NM (Jun 2), SC/NV/ME/ND (Jun 9), OK (Jun 16), MD/UT (Jun 23),
CO (Jun 30). These do not need a Phase-167 cluster — their general-ballot fields are already
resolved and seeded directly in phases 162–165.
