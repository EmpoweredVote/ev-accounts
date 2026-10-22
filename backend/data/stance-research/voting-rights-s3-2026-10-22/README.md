# voting-rights — Season 3 draft, Opus-alone coder run (2026-10-22)

Operator: Chris Andrews (`CA_`). Revision 4 = 08e7026f (CA_0318), pinned in draft Season 3 (7b3a066c) only.
Season 3 annex: `docs/codebook/annex/season3/voting-rights.md`. Every chair goes to review; nothing is auto-pushed.
Voters cannot see draft rows.

**Who:** the 65 people in the Stage 3 test set (`.planning/research/s3-prep-voting-rights/stage1/test-set-final.tsv`)
who hold an affirmative record (a Yea or a sponsorship), plus Terry Wilson from the Stage 4 carry list
(`stage4/reaudit/carry.json`, ruled 2026-10-21). Nay-only people are left out: a Nay cannot seat a chair (annex).
A person's Nay records in the set are given to the coder too. O'Quinn also gets VA HB 46 (2022) from the carry list.

**Steps** (from `backend/`): `make_spec.py` → `scripts/gold-desk/build_batch.py <spec> --season draft
[--coders-only --slots 1]` → per batch `code-stance-batch.ts --season draft --models "opus"` and
`queue-coded-batch.ts --season draft --include-needs-source` (dry run) → `gate.py` (labels → research.csv,
`combined-research.csv`, `results.json`) → `node scripts/audit-chair-evidence.mjs --csv combined-research.csv`.

**Specs:** `spec-all.json` (66), `spec-dry.json` (Wilson, Reid), `spec-wave1.json` (56), `spec-va.json` (8 Virginia
people re-coded after the profile below), `spec-mi.json`, `spec-r2.json` (10 people coded with saved copies).

## What changed during the run

- **Bill history pages added** to every vote record (`HISTORY` in `make_spec.py`): the dry-run coder for Reid asked
  which motion the 2020-03-05 vote was on.
- **Virginia bill text lost its deletions.** LIS prints deleted Code text in `<s>` tags; the plain fetch ran deleted
  and kept words together, and 6 Virginia people came out blank (`direction-only`) on SB 1256 (2013) / HB 1444 /
  HB 46. New profile `docs/sources/states/VA/lis-bill-text.md` (`amendment_text: marked`) makes the snapshot fence
  them as `[deleted: …]`. Re-coded: all five SB 1256 voters seat at 4, matching Stage 3. The first-round batches are
  kept in `_r1-…` directories (git-ignored).
- **Saved copies (Chris Andrews' OK, 2026-10-22, this run only)** in `human-saved/`: the 2017 Texas House journal
  (day 84) and Senate journal (2017-05-27), SB 5 sections only, because both journals are over the snapshot size cap;
  the 2021-10-06 Michigan Senate journal, which the fetcher failed on every tier while curl received it. Each file's
  first line records its source and method.

## Result (coder, before review)

`results.json` per person. 57 of 66 seated (86%): 20 at 3, 17 at 4, 10 at 5, 10 at 2. 64 of 66 match the Stage 3
expected chair. The two that differ are blank: Charlie Geren (TX SB 1: the coder thought SB 1 might be
multi-subject) and David Meade (KY SB 2: read the eight impediments as named exemptions); every other voter on
those two bills was seated as Stage 3 expected. Of the 9 blanks, 7 were expected (VA HB 1444 under ruling D1,
MI SB 303 under DC1). The 6 carried seats (Wilson, Gates, VanDeaver, Toth, Hunter, O'Quinn) all came out at 4.

Pre-write gate: `audit-chair-evidence.mjs --csv` first failed 1 of 66 — Paul K. Frost, whose reasoning names
"H.4359 House Amendment #7", which the lexical pattern did not recognise. The pattern now admits the Massachusetts
form (eighth widening, `chair-evidence-patterns.mjs`) and the gate passes 66 of 66.

Every queued row carries `confirm-failed` (no source profile for most of these sites); 31 seated rows also carry
`needs-source` (mostly term dates). Coder cost about $178 (API-price equivalent), including superseded runs.

## Written (Chris Andrews' yes, 2026-10-22)

- 57 rows queued (`store-snapshots` / `code-stance-batch --models "opus"` / `queue-coded-batch --include-needs-source`,
  all `--apply --season draft`) and approved under Chris Andrews' admin account on his instruction
  (`resolveResearchReview`). The draft Season 3 now holds 57 voting-rights answers (2=10, 3=20, 4=17, 5=10), 57
  context rows and 110 evidence snippets. Blanks are not written (the coder pipeline queues chairs only).
- needs-source, checked before approval: every bill here is single-subject for Season 3 under codebook 0.6
  (Stage 1 verdicts in the source store), and every seated Yea is a member confirmed on the vote date by the Stage 0
  identity check, except the two carry-list records Chris ruled on 2026-10-21. The other requests ask for as-filed
  text to code co-sponsorships on top of a vote that already decides the chair.
- Seat rate: `topic:seat-rate --season draft` reads written answers only, so it prints 57/57. With the blanks
  (`rows.tsv`, `--research-only`): **57 of 66 = 86.4%**; 7 blanks `wording` (VA HB 1444, MI SB 303), 2 unclassified
  (Geren, Meade).
