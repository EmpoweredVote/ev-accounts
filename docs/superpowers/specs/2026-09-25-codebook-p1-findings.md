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
- **D2 — no term start date for either seat.** (Data)
  - `office_terms.term_start` is NULL for both Yoder and Durazo, with precision `unknown`, so every row gets `dates-imprecise`.
  - This blocks certification for most sitting legislators. Backfill real term starts for seated state legislators before P2.
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

## Sources and access

- Indiana `iga.in.gov` pages are JavaScript-only. They were saved from the browser (`fetched_by = human`, public record).
- One roll-call PDF was downloaded by the operator and its text extracted.
- California `leginfo` bill text pages were fetched by code. Its vote pages are robots-disallowed, so they were saved from the browser (public record).
- News was used as excerpts only (Indiana Capital Chronicle, WFYI, WVPE).

## Next steps

1. Fix D1, then run CONFIRM again on these two batches. No new coding is needed, because the labels are stored.
2. needs_source round 1: fetch the requested roll calls, bill texts and statements, re-snapshot, and have all three coders code again.
3. Code 3 or more politicians toward the P1 exit (M1 ≥ 0.80 over ≥ 30 rows, ≥ 5 politicians).
   - Include one topic with a clearly chair-shaped authored bill, so that a non-BLANK category exists. M1 is undefined when every value is BLANK.
4. `--apply` of both batches to `inform.stance_coder_labels` needs the operator's OK.
