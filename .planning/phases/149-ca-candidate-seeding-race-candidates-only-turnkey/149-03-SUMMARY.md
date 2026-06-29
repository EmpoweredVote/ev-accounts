---
phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
plan: 03
subsystem: data
tags: [headshots, politician_images, ca-house, wikipedia-pageimages, wrong-person-guard, partial]

# Dependency graph
requires:
  - phase: 149-ca-candidate-seeding-race-candidates-only-turnkey
    plan: 01
    provides: 36 new active CA-House candidate records in the -601xxxx external_id band (mig 1091/1092)
provides:
  - 4 of 36 new CA-House candidates given a 600x750 free-license headshot (politician_images row + politician_photos/{uuid}-headshot.jpg)
  - backend/scripts/seed-ca-house-headshots.py — band-targeted headshot pipeline (clone of seed-state-exec-headshots.py) with a HARDENED wrong-person guard
  - 32-candidate "needs manual second-source" handoff list for the orchestrator
affects: [149-11-verification, ca-headshots]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Headshot pipeline self-targets the new-candidate set by external_id band (-6019999..-6010000, is_active=true, no politician_images) instead of the STATE_EXEC offices-join — challengers have no offices row"
    - "Hardened wrong-person guard for obscure challengers: resolved Wikipedia PAGE TITLE must contain BOTH the candidate first name AND surname, must not match an election/place/event article pattern, and must not carry a non-political parenthetical disambiguator (racing driver / actor / musician / TV series ...)"

key-files:
  created:
    - backend/scripts/seed-ca-house-headshots.py
    - backend/data/seed-ca-2026-house/149-03-headshots.manual.txt
  modified: []

key-decisions:
  - "Target by the -601xxxx band query (per corrected scope), NOT the plan's buggy -600[0-9]{4} SUMMARY-regex; is_active=true naturally excludes the 2 mig-1092-retired dups (-6013801 Hilda Solis, -6014101 Linda Sánchez)"
  - "Hardened the inherited wrong-person guard (Rule 2 / threat T-149-09): the base POLITICAL_KW+state-name description guard is too weak for obscure House challengers — it false-passed 21 of 25 auto-matches onto election-map/place/seal images and same-name different individuals (e.g. John McBride -> 'Danny McBride' the actor; Shane Lewis -> 'Shane Lewis (racing driver)')"
  - "USHC-04 left PARTIAL (4/36) on purpose — Wikipedia has no usable free portrait for the other 32; manual second-source sourcing is the orchestrator's job (it has web tools). Executor did NOT invent URLs."

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-06-29
---

# Phase 149 Plan 03: CA House Candidate Headshots — Wikipedia Auto-Pass Summary

**Cloned the verified headshot pipeline to target the 36 new CA-House candidates by external_id band, hardened its wrong-person guard against false matches, and imaged the 4 candidates that have genuine free-license Wikipedia portraits — leaving an exact 32-candidate list for the orchestrator's manual second-source pass.** USHC-04 is PARTIAL.

## Performance
- **Duration:** ~15 min
- **Started:** 2026-06-29T05:04:01Z
- **Completed:** 2026-06-29
- **Tasks:** 1
- **Files created:** 2

## Accomplishments
- Created `backend/scripts/seed-ca-house-headshots.py` — a clone of the Phase-141 `seed-state-exec-headshots.py` with the **only** functional change being the target-selection query (band `-6019999..-6010000 AND is_active=true AND NOT EXISTS politician_images`). All Phase-141 pipeline guards intact: free-license-only, 4:5 center/top crop → 600×750 LANCZOS q90, x-upsert to `politician_photos/{uuid}-headshot.jpg`, idempotent `INSERT … WHERE NOT EXISTS`.
- Confirmed the live target set is exactly **36** (38 band rows − 2 mig-1092-retired dups).
- Ran the automatic Wikipedia `pageimages` pass; **4 candidates imaged**, all verified as the correct individual on a genuine own-name biographical page with a real portrait:

  | external_id | candidate | district | Wikipedia page | license |
  |---|---|---|---|---|
  | -6014801 | Jim Desmond | CA-48 | "Jim Desmond" (SD County Supervisor) | public_domain |
  | -6014501 | Chuong Vo | CA-45 | "Chuong Vo" (Mayor Pro Tem, Cerritos) | public_domain |
  | -6011301 | Kevin Lincoln | CA-13 | "Kevin Lincoln (politician)" (fmr Stockton Mayor) | public_domain |
  | -6010601 | Richard Pan | CA-6 | "Richard Pan" (fmr CA State Senator) | cc_by-sa_2.0 |

- All 4 verified post-write: 600×750 JPEG, `type=default`, live on the CDN (HTTP 200), free-licensed.
- **Idempotent confirmed:** a second run found 32 targets (the 4 dropped out) and inserted 0 rows.

## Task Commits
1. **Task 1: Clone band-targeted headshot pipeline + harden wrong-person guard + run Wikipedia auto-pass** — see final commit hash in the completion block.

## Files Created/Modified
- `backend/scripts/seed-ca-house-headshots.py` — band-targeted headshot pipeline; hardened wrong-person guard (`_title_is_candidate_person` + `_NON_PERSON_TITLE` + `_BAD_DISAMBIG`); results written to gitignored `_ca-house-headshot-results.json`.
- `backend/data/seed-ca-2026-house/149-03-headshots.manual.txt` — header + the 32-candidate manual-sourcing list (`external_id|image_url|license` format) for the orchestrator.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality / T-149-09 wrong-person] Hardened the inherited wrong-person guard**
- **Found during:** Task 1 (dry-run inspection before any write)
- **Issue:** The inherited guard only requires the resolved page's wikidata description to contain a `POLITICAL_KW` term OR the state name. For obscure House challengers this is far too weak: a bare-title / search match routinely lands on an **election/place/event article** (lead image = a district map or state seal, not a portrait) or on a **same-name different individual**. The first dry-run "passed" 25 candidates, of which ~21 were wrong: 18 resolved to articles like "2026 United States House of Representatives elections in California" / "Palm Springs, California" / "2026 California's 14th congressional district special election"; John McBride → "Danny McBride" (actor); Shane Lewis → "Shane Lewis (racing driver)"; Pedro Antonio Casas → "José Antonio Aguirre"; Jenny Le Roux → "2022 California gubernatorial election". Writing these would have violated T-149-09 (wrong-person) and T-149-11 (wrong image attached).
- **Fix:** Added `_title_is_candidate_person()` (plus `_NON_PERSON_TITLE` and `_BAD_DISAMBIG` regexes) and wired it into `resolve_portrait()` after the political-description check. The resolved PAGE TITLE must now (a) not match an election/place/event article pattern, (b) not carry a non-political parenthetical disambiguator (racing driver / actor / musician / TV series / …), and (c) contain BOTH the candidate's first name AND surname. This reduced the pass set from 25 → 4, all verified-correct portraits.
- **Files modified:** backend/scripts/seed-ca-house-headshots.py
- **Verification:** Re-ran dry-run + a title-dump diagnostic; the 4 survivors all resolve to genuine own-name person pages; the 32 rejections each carry a documented skip reason.
- **Committed in:** Task 1 commit.

**Total deviations:** 1 auto-fixed (Rule 2, security/correctness — wrong-person guard).
**Impact on plan:** No scope change. Prevented ~21 wrong-person/wrong-image writes; the cost is that more candidates fall to the manual pass — which is correct behavior, not a regression.

## NEEDS MANUAL SECOND-SOURCE (orchestrator handoff)
The Wikipedia auto-pass found no usable free portrait for these **32** candidates. They are listed in `backend/data/seed-ca-2026-house/149-03-headshots.manual.txt` for the orchestrator to source (.gov / campaign / Ballotpedia free-license / Wikimedia Commons) and feed back via `--manual`. Name | external_id | district | geo_id:

| external_id | candidate | district | geo_id | auto skip reason |
|---|---|---|---|---|
| -6015201 | Jeff Belle | CA-52 | 0652 | desc-not-political ("boeing b-17f bomber") |
| -6015101 | Richardo Cabrera | CA-51 | 0651 | election-article |
| -6014901 | Armen Kurdian | CA-49 | 0649 | election-article |
| -6014701 | Jenny Le Roux | CA-47 | 0647 | 2022 CA gubernatorial election |
| -6014601 | David Pan | CA-46 | 0646 | no-lead-image |
| -6014401 | Genevieve Angel | CA-44 | 0644 | desc-not-political ("category 4 pacific hurricane") |
| -6014301 | Cristian Morales | CA-43 | 0643 | desc-not-political ("mexican boxer") |
| -6014201 | Brian Burley | CA-42 | 0642 | election-article |
| -6014102 | Mitch Clemmons | CA-41 | 0641 | "Baskets (TV series)" |
| -6013901 | Steve Manos | CA-39 | 0639 | "Palm Springs, California" |
| -6013802 | Pedro Antonio Casas | CA-38 | 0638 | "José Antonio Aguirre" (wrong person) |
| -6012901 | Angélica María Dueñas | CA-29 | 0629 | 2022 election article |
| -6012601 | Sam Gallucci | CA-26 | 0626 | desc-not-political (120th-congress elections) |
| -6012401 | Bob Smith | CA-24 | 0624 | desc-not-political ("canadian musician and criminal") |
| -6012301 | Tessa Lynn Hodge | CA-23 | 0623 | election-article |
| -6012201 | Randy Villegas | CA-22 | 0622 | election-article |
| -6012101 | Kyle Kirkland | CA-21 | 0621 | no-wikipedia-page |
| -6012001 | Sandra Van Scotter | CA-20 | 0620 | election-article |
| -6011901 | Peter Verbica | CA-19 | 0619 | election-article |
| -6011801 | Shane Lewis | CA-18 | 0618 | "Shane Lewis (racing driver)" (wrong person) |
| -6011701 | Ritesh Tandon | CA-17 | 0617 | desc-not-political ("2021 US supreme court case") |
| -6011601 | Peter Sundin Soulé | CA-16 | 0616 | election-article |
| -6011501 | Charles Hoelter | CA-15 | 0615 | election-article |
| -6011401 | Melissa Hernandez | CA-14 | 0614 | CA-14 special election article |
| -6011201 | Jamie Joyce | CA-12 | 0612 | no-lead-image |
| -6011001 | Jeff Frese | CA-10 | 0610 | election-article |
| -6010901 | John McBride | CA-9 | 0609 | "Danny McBride" (actor, wrong person) |
| -6010801 | Rudy Recile | CA-8 | 0608 | election-article |
| -6010501 | Michael Masuda | CA-5 | 0605 | election-article |
| -6010401 | Eric Jones | CA-4 | 0604 | election-article |
| -6010301 | Robb Tucker | CA-3 | 0603 | desc-not-political ("1974 single by eagles") |
| -6010201 | Robin Littau | CA-2 | 0602 | election-article |

## Known Stubs
None. The 4 written rows are genuine portraits. The 32 missing headshots are not stubs — no placeholder/wrong-person image was written; they are a documented, intentional handoff for the orchestrator's manual second-source pass (per the corrected scope). USHC-04 is therefore PARTIAL pending that pass — do NOT mark it complete.

## Threat Flags
None new. The plan's threat register (T-149-09/10/11) is fully honored: the free-license guard, the x-upsert deterministic path, and a STRENGTHENED wrong-person guard are all enforced.

## Self-Check: PASSED
- FOUND: backend/scripts/seed-ca-house-headshots.py
- FOUND: backend/data/seed-ca-2026-house/149-03-headshots.manual.txt
- DB: 4 politician_images rows in the -601xxxx band, all 600×750 JPEG, CDN HTTP 200
- IDEMPOTENT: second run inserted 0 rows (32 targets remaining = the manual-sourcing set)

---
*Phase: 149-ca-candidate-seeding-race-candidates-only-turnkey*
*Completed: 2026-06-29*
