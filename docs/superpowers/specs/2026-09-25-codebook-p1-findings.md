# Codebook P1 — first shadow run findings (2026-09-25)

Plan Task 14, steps 3–4. Spec: `2026-09-25-stance-quote-codebook-reliability-design.md`.
Nothing was published and nothing was written to `stance_coder_labels` (no `--apply`).

## Runs

| Batch | Politician | Seat | Topics coded | Sources (snapshots) |
|---|---|---|---|---|
| `backend/data/stance-research/2026-09-25-shadow-yoder` | Shelli Yoder | IN Senate District 40 (Monroe County) | 7 | 11 (5 public-record, 2 own-site, 4 news) |
| `backend/data/stance-research/2026-09-25-shadow-durazo` | Maria Elena Durazo | CA Senate District 26 (LA County) | 7 | 13 (all public-record) |

- **Coders:** slot 1 = Opus, slots 2–3 = Sonnet. Codebook 0.2.
- **Topics:** a subset chosen for the likely presence of a record. Only state-applicable topics.
  - Yoder: abortion, data-centers, fossil-fuels, medicare/aid, school-vouchers, trans-athletes, voting-rights.
  - Durazo: abortion, childcare, data-centers, deportation, school-vouchers, trans-athletes, voting-rights.
  - `immigration` is not in the open season. `local-immigration` has no state role.
- **Round:** needs_source round 0 only. The requested sources were not fetched yet (see Next steps).

## Results

| | Yoder | Durazo |
|---|---|---|
| Valid coder files | 3/3 | 3/3 |
| Invalid rows | 0 | 1 (slot 2, a `provision_quote` not verbatim in the snapshot; the validator caught it) |
| Rows with a `needs_source` request | 7/7 | 5/7 |
| Unanimous chair | 0 | 1 (voting-rights, rung 1), and it was **refused by CONFIRM** |
| Rows the shadow policy would publish if certified | 0 | 0 |
| M1 (chair, α nominal) | undefined (every coder BLANK on every row) | 1.000 over 7 rows |

### Chair per coder (slot 1 | 2 | 3)

**Yoder.** Every row was BLANK, and every coder asked for more sources on every row:
- `direction-only`: abortion, data-centers, medicare/aid, trans-athletes.
- `no-evidence`: fossil-fuels, voting-rights.
- school-vouchers: `no-evidence`, `no-evidence`, `direction-only`.

**Durazo:**
- `no-evidence`: abortion, childcare, data-centers (slot 2 invalid), school-vouchers, trans-athletes.
- deportation: slot 1 `direction-only`, slots 2–3 `no-evidence`. Slot 1 also questioned whether a state seat holds any lever on this ladder.
- voting-rights: 1 | 1 | 1.

### Disagreement digest (improvement loop 1)

Diagnostic only. Shown as α per variable (split units / coded units).

| Variable | Yoder | Durazo |
|---|---|---|
| v4_shape | α 0.64 (4/12) | α 0.80 (2/10) |
| v3_class | α 0.70 (3/12) | no split |
| v2_relevance | α 0.72 (2/12) | α 0.67 (3/10) |
| v1_attribution | α 0.89 (1/12) | no split |
| v5_time | no split | no split |

The coders agree on the chair and split on *why*. V4 (shape) and V2 (relevance) are the least reliable variables. That matches the design's expectation that shape is the core judgment.

## What the run shows

1. **The codebook refuses the Season 1 chairs.**
   - Yoder has 21 seated Season 1 chairs. On the 7 topics coded, all 7 blanked unanimously.
   - Durazo has 27 chairs across Seasons 1–2. 6 of the 7 coded blanked. The seventh, voting-rights, gave rung 1 against Season 1's rung 2.
   - The Season 1 reasoning uses bare votes and caucus membership ("a consistent California Democratic caucus vote", "AFL-CIO background places her"). The vote ladder and the party-inference rule exclude both.
2. **Season 1 contains a false factual claim.**
   - Durazo / school-vouchers (S1 rung 1) says SB 494 (2023) "imposes a moratorium on new charter school approvals".
   - The official record title of SB 494 is *School district governing boards: meetings: school district superintendents and assistant superintendents: termination*.
   - Report it to the operator. It is a live Season 1 chair.
3. **The unanimous chair shows why gold is required.**
   - All three coders put Durazo / voting-rights at rung 1 ("Require no identification to vote") on the strength of SB 1174 (2024).
   - SB 1174 only **stops local governments** from adding a voter-ID requirement "unless required by state or federal law". It does not say what state law should require.
   - That is V2 `adjacent`, and V4.2 "broader than the instrument": a unanimous reading that is probably wrong. This is the convergent-error case (spec §5.4). **Coder agreement alone would have published it.**
   - CONFIRM refused it, but for other reasons (below). Add it to the codebook as hard example H12, and add a sentence to V2: "a preemption of local rules is not a position on the state rule".
4. **The `needs_source` loop works.** The requests are specific and on target. Examples:
   - "Full text of Indiana SB 208 (2024), the section … showing the gestational limit it would set".
   - "Indiana Senate roll call on SB 2 (2025), final passage, showing Yoder's vote".
   - Most requests ask for the person's own words answering the question. The record alone rarely carries magnitude.
5. **The validator did its job.** One paraphrased `provision_quote` was caught, and that coder became `coder-missing` for the row.

## Defects found (fix before P2)

- **D1 — CONFIRM checks each passage alone, but a vote needs two passages.** (Important)
  - A record is usually two passages: the **vote page** names the person but carries no provision text, and the **bill text** carries the provision but never names the voters.
  - `confirmRow` requires a name on *every* rests_on passage, and a provision on *every* record passage. So a correct record basis can never pass: here it gave `person-not-in-snapshot` and `provision-missing`.
  - Fix: evaluate the basis as a set. At least one passage names the person as the actor. The named instrument's provision is verbatim in one of the passages. All passages are about the same instrument.
- **D2 — no term start date for either seat.** (Data) — **FIXED for IN + CA by `CA_0293` (applied 2026-09-25, PR #806).**
  - `office_terms.term_start` was NULL for both Yoder and Durazo (precision `unknown`), so every row got `dates-imprecise`.
  - `CA_0293` dated 267 of 269 IN + CA legislators (219 day, 48 year). Yoder is 2020-11-04 and Durazo 2022-12-05.
  - Both reports were re-run with those dates (only `coding-context.json` seat dates changed; the coder inputs are unchanged). Durazo / voting-rights now fails only on D1 (`provision-missing`, `person-not-in-snapshot`).
  - Other states still need the roster pass.
- **D3 — `build-coder-inputs` codes every topic in the bundle.** (Minor)
  - It does not drop topics that do not apply to the seat's level (spec §5.3).
  - This run worked around it by trimming `topics.json` by hand (the full list is in `topics.all.json`).
- **D4 — coder prompt size and dispatch.** (Process)
  - Each prompt is 66,000–99,000 characters, mostly the codebook.
  - Starting sub-agents with the file's text in the Agent call needs a manual copy, which is not byte-exact.
  - The run used the headless CLI instead, which is exact and runs on plan quota, with Write only and started from an empty directory:

    ```bash
    CLAUDE_CONFIG_DIR=~/.claude-ev claude -p --model <m> --tools Write --allowedTools Write --permission-mode acceptEdits --add-dir <batch>/labels < coder-N.md
    ```

  - Update the SKILL shadow section to this command, or add a script that runs it.
  - A slim "coder edition" of the codebook would cut cost; the examples are most of the size.
- **D5 — the local `.env` lacks `ADMIN_INGEST_TOKEN`.** (Minor)
  - The env schema requires it even for scripts. This run passed a placeholder for each process only.
  - Consider making it optional outside `EV_ROLE=api`.

## Codebook 0.2 → 0.3 re-run (2026-09-26)

Same snapshots, rebuilt inputs, the same three models (Opus, Sonnet, Sonnet) through the headless
`claude-ev -p --tools Write` dispatch. The 0.2 outputs are kept as `labels-0.2/`,
`coding-report-0.2.json`, `disagreement-digest-0.2.json`, `coder-inputs-0.2/` and `coder-logs-0.2/`.
Nothing was applied to the database.

### Chair per coder (slot 1 | 2 | 3) — identical under 0.2 and 0.3

| Politician | Topic | 0.2 and 0.3 |
|---|---|---|
| Yoder | abortion, data-centers, medicare/aid, trans-athletes | direction-only ×3 |
| Yoder | fossil-fuels, voting-rights | no-evidence ×3 |
| Yoder | school-vouchers | no-evidence · no-evidence · direction-only |
| Durazo | abortion, childcare, data-centers, school-vouchers, trans-athletes | no-evidence ×3 |
| Durazo | deportation | direction-only · no-evidence · no-evidence |
| Durazo | voting-rights | **1 · 1 · 1** |

No coder changed a single value. Codebook 0.3 changed the *form* of the labels, not the readings.

### Validator errors under 0.3

- **No error comes from the new fields.** Every `record` passage carries `record_kind` and a
  verbatim `actor_quote`; every vote carries a verbatim `tally_quote`.
- Five rows are invalid, for older reasons:
  - Yoder slot 3, one quote: `text not verbatim in snapshot`.
  - Durazo slot 1 (voting-rights) and slot 3 (voting-rights, childcare, data-centers):
    `provision_quote not verbatim in snapshot`. See **D6**.
- So Durazo / voting-rights is no longer unanimous among *valid* rows: slots 1 and 3 are
  `coder-missing`, and the row goes to review for that reason. CONFIRM does not run.

### D1 on the real pages

The SB 1174 pair was checked directly with `checkRecordGroup`, using slot 1's own `actor_quote`
("Cortese, Dodd, Durazo, Eggman, Glazer") and `tally_quote` ("Ayes Count 30 Noes Count 8 NVR Count 2"),
with the provision moved to the bill-text passage where it is verbatim:

| Group | Findings |
|---|---|
| vote page + bill text | none |
| bill text only | `person-not-in-snapshot`, `vote-not-evidenced` |
| vote page only, as coded | `provision-missing` |

D1 was fixed in `checkRecordGroup` only: a correct record basis passes, and each half alone still
fails. The vote is divided (8 of 38 = 21 % No), so `near-unanimous-vote` does not apply.

⚠ **Correction (final review, 2026-09-26).** This check called `checkRecordGroup` **directly**. End to
end, the validator ran first and then **rejected the bill-text half**: it required `actor_quote` on
every record passage and `tally_quote` on every vote passage, and the bill text names no voter and has
no tally. So D1 was not reachable through `code-stance-batch`. Fixed in `510b7ec6`: the record fields
are now required **per instrument group** (operator ruling "Per group"), and an end-to-end test runs
the pair through `validateCoderLabelFile` + `buildCodingReport` with no errors and no findings. The
same commit adds a namesake guard (the actor page must name the seat's chamber; a common surname
needs a first name or initial) and fails a 0–0 tally closed. Re-running both reports after the fix
changed no row: no row reached CONFIRM, and no validator result moved.

### Seed flags

Yoder 3 fresh / 4 stale; Durazo 2 fresh / 5 stale. The first build showed 14 of 14 stale, because
the design spec compared the Season 1 pin with the open season's *served* revision. The seasons
design compares **pin with pin**; abortion's S1 and S2 pins are the same revision, and only a
clarifying revision re-words the served text. Fixed in `8527e762`.

### What this shows

- **Durazo / voting-rights still does not fail on its real ground.** All three coders still read
  SB 1174 as rung 1 ("Require no identification to vote …"). SB 1174 only bars *local* ID rules;
  state law is untouched. That is V2 `adjacent` (preemption), and no coder said so. Had the coders
  cited the vote page and the bill text correctly, CONFIRM would have **passed** this chair: every
  mechanical check holds. Only a coding judgment can stop it. See **D7**.
- The verbatim fields do what they were built for: nothing the coders copied was invented.

## Defects found in the 0.3 re-run

- **D6 — coders put the bill's provision on the vote-page passage.** (Important)
  - Two of three coders wrote the SB 1174 provision as the `provision_quote` of the *vote-page*
    passage, and cited only that page in `rests_on`. The validator correctly refuses it (the words are
    on the bill-text page, not the vote page). Slot 1's own log says it expected this.
  - Cause: codebook 0.3 lists the record fields but has **no worked example** of a two-passage vote
    record, although the design spec (§1) asked for one example for each `record_kind`.
  - Fix (codebook 0.3.1, PATCH): add the worked examples — a vote as two passages (vote page with
    `actor_quote` + `tally_quote`; bill text with `provision_quote`; both in `rests_on`), and one each
    for `sponsor`, `author` and `other-act`. State in V3 that `provision_quote` comes from the page
    that prints the provision.
  - **Status 2026-09-26:** the two-passage vote example and the "`provision_quote` from the page that
    prints the provision" rule are now in codebook V3 (kept at 0.3: a clarification, not a new
    variable). The `sponsor` / `author` / `other-act` examples are still owed. The coders have **not**
    been re-coded against it, so it is not yet shown to work.
- **D7 — preemption is read as a position.** (Important, codebook)
  - A bill that forbids *another level of government* from acting (SB 1174: local governments may not
    require ID) does not say what the voter-ID rule itself should be. It is V2 `adjacent` for the
    ladder, unless a rung is about which level decides.
  - Fix: a **Hard [real]** example in V2 (Durazo / voting-rights / SB 1174), register row H12, and a
    `voting-rights` annex — **done 2026-09-26**.
  - Because the example is now in every coder prompt, H12 is `excluded_from_cert` (Part D, leakage). A
    re-code of Durazo can no longer test D7 — the coders read the answer. The certification gold needs
    a **different** preemption case the coders have not seen (another state's local-ID or local-rule
    preemption bill). CONFIRM cannot catch this class, so gold is the only guard.

## Durazo re-code after D6 + D7 (2026-09-26)

Same snapshots; inputs rebuilt with the two-passage worked example (D6), hard example H12 and the new
`voting-rights` annex (D7). Run 1 of 0.3 is kept as `labels-0.3-run1/`, `coding-report-0.3-run1.json`,
`coder-inputs-0.3-run1/`, `coder-logs-0.3-run1/`.

- **D6 is fixed.** 0 invalid rows (run 1: 4). All three coders cite SB 1174 as **two passages**: the
  vote page with `actor_quote` and the bill text with `provision_quote`.
- **D7:** all three now code SB 1174 V2 `adjacent` → BLANK `no-evidence` (run 1: rung 1 ×3). This is
  expected and proves nothing about coder skill: H12 is in the prompt (leakage). The certification gold
  needs an unseen preemption case.
- Every row now asks for more sources (`needs-source` ×7), so CONFIRM does not run on any row.

## Sources and access

- Indiana `iga.in.gov` pages are JavaScript-only. They were saved from the browser (`fetched_by = human`, public record).
- One roll-call PDF was downloaded by the operator and its text extracted.
- California `leginfo` bill text pages were fetched by code. Its vote pages are robots-disallowed, so they were saved from the browser (public record).
- News was used as excerpts only (Indiana Capital Chronicle, WFYI, WVPE).

## Next steps

1. ~~Fix D1~~ — done (0.3 re-run above). Next: fix D6 and D7 in the codebook (0.3.1), then re-code Durazo.
2. needs_source round 1: fetch the requested roll calls, bill texts and statements, re-snapshot, and have all three coders code again.
3. Code 3 or more politicians toward the P1 exit (M1 ≥ 0.80 over ≥ 30 rows, ≥ 5 politicians).
   - Include one topic with a clearly chair-shaped authored bill, so that a non-BLANK category exists. M1 is undefined when every value is BLANK.
4. `--apply` of both batches to `inform.stance_coder_labels` needs the operator's OK.
