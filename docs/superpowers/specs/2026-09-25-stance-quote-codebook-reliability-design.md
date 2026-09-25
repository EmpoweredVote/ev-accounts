# Stance & quote codebook + inter-coder reliability — design

**Status:** design approved section by section in session, and rulings Q1–Q9 made (Chris Andrews,
2026-09-25; §9.1). Not built.
Nothing in this document changes the pipeline, the database or the review page yet.
**Author of record:** Chris Andrews (operator). Migration slots, when they come, are `CA_`.
**Companion:** first-draft codebook at [`docs/codebook/stance-and-quote-codebook.md`](../../codebook/stance-and-quote-codebook.md).

**Goal.** Let `/research-stances` (and the quote side of the on-the-record evidence program)
eventually publish a chair or a quote **without a human reviewer** — but only in the strata where we
have *measured* that the machine agrees with a blind human, and only for rows where independent coders
agree with each other. Everything else keeps going to a person, and every disagreement a person settles
becomes a new hard example in the codebook.

---

## 0. What exists today (measured 2026-09-25)

### 0.1 ev-accounts stance pipeline

`build-stance-topic-bundle.ts` → inline research (one politician per run) → `stance-gate.ts`
(21 deterministic checks, `backend/scripts/lib/stanceGate.ts`) → `verify-stance-research.ts`
(re-fetches every URL; snippet must be on the page — `backend/src/lib/researchVerifier.ts`) →
`--apply` queues **every** row (review-all, ruling 2026-09-22) → human approves in
`admin/src/pages/admin/ResearchReviewPage.tsx` → `resolveResearchReview`
(`backend/src/lib/researchEvidenceService.ts:590`) writes answer + context + verified spans.
Policy: `backend/scripts/lib/stancePublishPolicy.ts` (`decidePublish`).

### 0.2 What the review queue actually holds

Measured on prod (read-only):

| status | rows | with `resolved_by` |
|---|---|---|
| resolved | 23 | 7 |
| rejected | 28 | 0 (the CA_0284 legacy sweep) |

- **The newest row was created 2026-06-05.** The post-#793/#794 pipeline has not queued a row yet.
- All 23 resolved rows are Season 1, which is now closed. 16 were bulk-pushed "after 2nd recovery pass
  (rq2)" with no reviewer.
- **None of them was reviewed blind.** Several of them fail the codebook in §2. Examples: a voucher
  chair from an omnibus vote; a party-line vote as the only basis; an LCV scorecard used as evidence.
- Season 2 research will re-code them, and these rows are **not** gold (see §4).

### 0.3 Why the queue cannot produce gold today

- **The final chair is not on the review row.** It lands in `politician_answers`, and later writes
  change it. Blake Moore / `social-security` was proposed as 4, and it is live as 5 today.
- **Per-source judgments are not recorded.** A human-verified URL is stored with the placeholder
  snippet `[Human verified during review]`.
- **A reject carries free text only.** There are no reason codes.
- **"Approved unchanged" and "didn't look closely" are the same row.**

### 0.4 On-the-record evidence program (quotes)

- **Roles:** extractor (haiku) → cross-checker (gemini-flash) → judge (deepseek). All are paid API calls.
- **Tiers:** `lever` / `direction` / `none` (stance-tiers spec, unmerged branch).
- **Gold:** `tier_gold_v1.json`, 64 items, one labeler (Chris Andrews).
- **Agreement:** measured as raw percent only (`scripts/judge_ab.py`): 0.47–0.77 judge-to-judge.
- **Tier eval:** failed on every judge (Read & Rank precision 0.27–0.43).
- **Not present:** no chance-corrected agreement, no second labeler, no auto-accept. The review-surface
  spec lists auto-accept as an explicit non-goal. The stance-decomposition spec is a draft only.

**This spec supersedes** the evidence program's judging and eval design where the two overlap (§8). It
keeps the evidence program's tier vocabulary and its gold items.

### 0.5 Rulings this design changes

- 2026-08-24 and 2026-09-23: "no research sub-agent, no judgment sub-agent".
- **New ruling, 2026-09-25 (Chris Andrews): *tool-less coder sub-agents are allowed*.**
  - *Research (collection)* stays inline, one politician per run, with DB and MCP access, as ruled.
  - *Judgment* moves to three coder sub-agents, which the inline session dispatches.
  - The two failure causes behind the old ruling are closed by construction:
    - Each coder receives the saved source text in its prompt and has no tools except writing its
      label file. It needs neither DB nor MCP access.
    - A coder only emits labels; it never claims a verification. Every verification is code, so no
      "reported a check it never ran" failure is possible.
  - **Sub-agents, not API calls:** API calls are billed per token. Sub-agents run on plan quota
    (the operator's decision, 2026-09-25).
  - **Why tool-less (Q1, ruled 2026-09-25):**
    - Every coder must code the *same* units. If coders could search, α would mix "found different
      sources" with "read the same source differently".
    - A coder can make no claim that code cannot check.
    - WebFetch returns a model summary, not the page (stance-program §4.11).
    - Replay needs identical inputs.

    A coder that needs more evidence emits a **source request** instead of fetching it (§1.3).

---

## 1. Roles and data flow

```
1 COLLECT    inline session → sources.json
             (URL, instrument IDs, pointer passage, candidate quotes). No chair. No "supports X".
2 SNAPSHOT   code: fetch; keep excerpt windows + sha256 of the full page → inform.source_snapshots
             (reuses researchVerifier: snippet on page, name near span)
3 CODE ×3    three tool-less coder sub-agents; independent; shuffled source order
             input: codebook + annex + served ladder text + snapshot passages ONLY
             output: labels/coder-N.json (schema: codebook Part E)
4 GATE       stanceGate (unchanged) + label checks: every cited snapshot ID exists;
             every quoted string is verbatim in its snapshot; schema-valid
5 AGREE      code: row unanimous? consensus chair + shared source; stratum α vs gold
5b CONFIRM   code: identity (office/jurisdiction in snapshot matches the seat), dates vs
             office_terms (pre-seating), provision text present (vote ladder), served revision
             [phase 2: a "skeptic" sub-agent tries to refute the consensus; refutation → review]
6 DECIDE     stancePublishPolicy: auto-push iff gate clean ∧ verified ∧ unanimous ∧
             CONFIRM clean ∧ stratum certified ∧ no always-review reason; else queue
7 REVIEW     admin page; blind-first on a 1-in-3 sample → inform.stance_gold_labels
```

### 1.1 Collector (inline session)

It is the existing `/research-stances` session. It keeps web search and DB/MCP access.

**New output contract:** `sources.json`. It holds per source: the URL, a `source_kind` (see §5.4),
the named instruments, and pointer passages and candidate quotes (text the collector saw).

**It contains no `value` and no reasoning.** The collector's opinion never reaches a coder, so the
coders cannot anchor on it. `research.csv` / `evidence.csv` stay for the transition (phase P1, below)
and are generated from the consensus labels once coding is live.

### 1.2 Snapshot (code)

Script `backend/scripts/snapshot-sources.ts`. It reuses `researchVerifier`'s fetch, normalisation and
`matchSnippet`.

**Stored:**
- **Public records** (government sites, the politician's own site): the full normalised text.
- **Third-party copyrighted text** (news): excerpt windows only — matched span ± context, a few
  hundred words maximum — plus `raw_sha256` of the full page. Enough to verify and replay; not a
  copy of the article.
- Raw bytes go to the batch directory (git-ignored).

**Blocked fetch:** follows the source policy in §5.4. A human-saved page is ingested with
`fetched_by = 'human'`.

### 1.3 Coders (three sub-agents)

**Agent definition:** `.claude/agents/stance-coder.md`, with `tools: Write`. No Read, no Bash, no
WebFetch, no MCP. The prompt carries everything, and the coder writes exactly one file,
`labels/coder-N.json`. Code validates it (§1.4) and records its sha256, so a later edit by the session
is detectable.

**Independence:**
- Each coder gets the sources in a different random order.
- The model set is configurable. The default is one Opus and two Sonnet.
- The model set is part of the certification key (§3). Three Claude coders are more alike than three
  vendors ("convergent error is not corroboration", stance-program §5.4). **That is why agreement
  alone never publishes.** Only agreement *in a stratum measured against blind human gold* does.

**Source requests.** A coder may add `needs_source` entries to its label (for example, `"Clerk
roll call, H.R. 28 (2025)"`), meaning the evidence it needs is named but not in the snapshots.
- A row with any `needs_source` does not publish.
- The collector (inline, with tools) fetches the requested source, and code snapshots it.
- **All three** coders then code the row again, so every coder always sees the same material.
- After two request rounds with no new snapshot, the row goes to review with reason
  `source-unavailable`.

**Unit of coding:**
- One (politician, office, topic, season) row.
- Per source passage: V1–V5.
- Per row: V6.
- Per candidate quote: V7–V8.

The codebook defines each variable (Parts A–B).

### 1.4 Gate additions (code)

| New check | Severity |
|---|---|
| `label-schema-invalid` | high (→ the coder counts as missing) |
| `label-cites-unknown-snapshot` | high |
| `label-quote-not-in-snapshot` | high |
| `label-provision-missing` (the vote ladder requires a named provision and it is absent) | high |

### 1.5 Agreement (code)

**A row is unanimous iff:**
- all three labels are valid; **and**
- the three `value`s are equal (or all BLANK with the same reason); **and**
- at least one snapshot ID is in all three `rests_on` sets.

Same chair on disjoint sources is **not** unanimous (§5.5).

**The consensus reasoning** shown to voters comes from the coder whose `rests_on` set is smallest
among the agreeing coders (the tightest basis). A person may edit it in review.

### 1.6 CONFIRM (code, phase 1)

- **Identity:** the office or jurisdiction named in the snapshot matches the seat's `office_id`.
- **Dates:** the act or statement date is compared with `office_terms`. If `start_precision <> 'day'`
  or `term_start` is NULL → review.
- **Vote ladder:** the provision text the coders named is in the snapshot.
- **Revision:** the served revision equals the bundle's.

**Phase 2** adds a skeptic sub-agent. It is given the consensus and asked only to find the reason it
is wrong. A refutation that carries a code-verifiable citation → review.

### 1.7 Decide (code)

New `queue_reasons` values: `coder-split`, `coder-missing`, `confirm-failed`, `stratum-uncertified`,
`blind-sample`, `audit-sample`, `source-unavailable`, `statement-other`, `statement-out-of-cycle`.

**The existing always-review reasons stay always-review, even in a certified stratum:**
- `replaces-published-chair`
- `value-change`
- `statement-evidence` is narrowed (Q2): it becomes `statement-other`, which is always review.
  `statement-answer` rows follow the normal certification rule.

---

## 2. Codebook

The draft is in [`docs/codebook/stance-and-quote-codebook.md`](../../codebook/stance-and-quote-codebook.md).

Structure, in the standard content-analysis form (definition, values, coding rules,
inclusion/exclusion, good / hard / bad examples):

- **Part 0 — Frame:**
  - units;
  - fixed decision order V1 → V6, where an earlier "no" stops the chain;
  - principles: a blank is correct; the least-extreme rung is a tiebreaker, not evidence; never assume
    polarity;
  - versioning.
- **Part A — Stance variables:**
  - V1 attribution
  - V2 relevance
  - V3 evidence class
  - V4 shape, including the **vote ladder** (§2.1)
  - V5 time
  - V6 chair + blank reasons
- **Part B — Quote variables:**
  - V7 tier (`lever` / `direction` / `none`)
  - V8 quotable + reason codes, which are the `audit-quotes` check IDs.
- **Part C — Per-topic annexes:**
  - the served ladder;
  - orientation;
  - per rung: what evidence establishes it, the levels that hold a lever, the known instruments;
  - hard cases.
- **Part D — Worked examples:** at least 1 good, 2 hard and 1 bad example per variable. Sources:
  - the stance-program §10 calibration set;
  - `CASEBOOK.md`;
  - the `tier_gold_v1` label notes;
  - the real reviewed rows (§0.2).
- **Part E — Coder output JSON schema.**

**Versioning:** `MAJOR.MINOR`.
- **A material change** bumps MAJOR and triggers replay re-certification (§3.4). A material change is
  a new variable or value, a changed decision rule, or a changed annex rung reading.
- **A wording-only change** bumps MINOR. No replay. This mirrors the ladder-rewording ruling of
  2026-08-28.

### 2.1 The vote ladder (operator, 2026-09-25)

A vote does not mean support for every clause of a bill.

| Vote | Can prove |
|---|---|
| Amendment / motion to strike / divided question on **the specific provision** | a chair |
| Final passage of a **single-subject** bill whose operative section matches the rung | a chair |
| Final passage of a **multi-subject** bill (omnibus, budget, appropriations, reconciliation) | direction only — a chair **only** with the person's own statement tying the vote to that provision |
| **No** on a multi-subject bill | nothing |
| Procedural (cloture, rule, table, recommit, previous question) | nothing about the policy |

New V4 values: `multi-subject`, `procedural`. Coders must name the provision they rely on
(`provision_quote`). CONFIRM checks it is in the snapshot.

---

## 3. Reliability metric and certification

### 3.1 Measures (per stratum)

| # | Measure | Between | Role |
|---|---|---|---|
| M1 | Krippendorff's α, **nominal** | 3 coders, every row | reliability of the process |
| M2 | α, nominal | coder consensus vs blind gold | validity |
| M3 | precision of **unanimous** rows (Wilson 95% lower bound) | unanimous chair vs blind gold | **decides** |
| M4 | severe errors (count) | unanimous vs gold | veto |

- **Nominal, not ordinal.** The chairs are five distinct stances, not a scale (CLAUDE.md, "Compass
  chairs are five distinct stances"). BLANK is a sixth category. Ordinal α is reported as a
  diagnostic only.
- **Severe error:** a chair on the other side of the ladder, or a seated chair where gold is BLANK.
- **Diagnostics:** α on V1–V5 shows where the coders split. Diagnostics never gate.
- **Quotes:** the same measures on V7 and V8 give a separate certification for quote strata.

### 3.2 Strata

A stratum is the topic's role-scope **level** (federal / state / local / school) × the **evidence
class** of the basis the consensus rests on. The class is one of:
- `record`
- `statement-answer`: a questionnaire, a moderated debate answer, a first-person issue page, or a
  signed pledge;
- `statement-other`: news quotes, social posts, speeches, interviews.

That gives 12 chair strata.
- **`statement-other` strata never certify** (Q2, ruled 2026-09-25). Statements matched to a question
  after the fact had 0% pass-1 survival.
- **`statement-answer` strata certify under the normal rule.** This is what lets a candidate with no
  record ever auto-publish.
- **A row resting on several classes takes the weakest class present.**
- **Per-topic veto:** one severe error on a topic removes that topic from auto-publish in every
  stratum, until a person clears it.

### 3.3 Certification rule

A stratum is certified when **all** of the following hold:
1. There are at least **50 blind gold items** in the stratum with `excluded_from_cert = false`. An item
   used as a codebook example is excluded (leakage).
2. **M1 ≥ 0.80** and **M2 ≥ 0.80.** Krippendorff: α ≥ .800 is reliable; .667–.800 is only tentative.
3. **M3 Wilson lower bound ≥ 0.90.** For scale: 50/50 → 0.929 (pass); 49/50 → 0.895 (fail);
   98/100 → 0.930 (pass).
4. **M4 = 0.**

### 3.4 Staying certified

- **Audit sample (Q7, ruled 2026-09-25):**
  - 1 in 5 of a newly certified stratum's first 100 auto-published rows goes to a person, blind, as
    `audit-sample`; after that, 1 in 10.
  - This grows the gold set and detects drift. For scale: if the machine starts to get 1 row in 10
    wrong, a 1-in-10 audit catches it within 100 published rows about 65% of the time; 1 in 5, about
    88%.
  - The rates are configuration, not code.
- **Immediate decertification:**
  - any severe error on an audited row; or
  - M3 over the last 50 audited rows falls below the rule.
- **Replay re-certification:** inputs are frozen snapshots, so after any of the following, code re-runs
  the three coders over the saved gold inputs and recomputes M1–M4:
  - a coder model change;
  - a codebook MAJOR bump;
  - a ladder revision (which re-opens only that topic's gold).

  This needs no new human labels.
- **Decertification writes a new row.** Certification rows are never updated.

### 3.5 Tooling

- `backend/scripts/lib/reliability.ts`: nominal α with missing data, Wilson interval, confusion
  matrices.
- 🔴 **Positive control:** a unit test must reproduce Krippendorff's published worked example
  (*Computing Krippendorff's Alpha-Reliability*, 2011, the nominal example with missing values)
  exactly, before any stratum figure is trusted.
- `npm run reliability:report --prefix backend` writes the per-stratum report into the batch directory
  and a row into `inform.reliability_certifications`.

### 3.6 Expected pace

Blind mode is 1 in 2 of queued rows until the first stratum certifies, then 1 in 3 (§4.6). So one
stratum needs about 100 reviewed rows to reach 50 blind items early on, and about 150 later. Federal/record will certify first. Local and school will take months. That is intended: those
strata have the least structured evidence.

---

## 4. Gold capture schema

**Principle:** gold is **append-only**, in its own table. A correction is a new row with
`supersedes_id`. Nothing downstream (`politician_answers` rewrites, merges, season changes) can
change what a person decided.

Migration slots come from `npm run steward --prefix backend -- slot CA --purpose "..."`.

### 4.1 `inform.source_snapshots`

| Column | Notes |
|---|---|
| `id` | |
| `url` | |
| `source_kind` | see §5.4 |
| `fetched_at` | |
| `fetched_by` | `code` or `human` |
| `http_status` | |
| `raw_sha256` | |
| `normalized_text` | full text for public records; excerpt windows only for third-party text |
| `batch_id` | |

### 4.2 `inform.stance_coder_labels`

| Column | Notes |
|---|---|
| `review_id` | |
| `coder_slot` (1–3) | |
| `model` | |
| `codebook_version` | |
| `value` | smallint NULL = BLANK |
| `blank_reason` | |
| `rests_on` | uuid[] of snapshot IDs |
| `source_codes` | jsonb: V1–V5 per snapshot, plus `provision_quote` |
| `quote_codes` | jsonb: V7–V8 |
| `needs_source` | jsonb: source requests (§1.3); empty when none |
| `valid` | |
| `label_sha256` | |
| `raw_output` | |

### 4.3 `inform.stance_gold_labels`

| Column | Notes |
|---|---|
| `review_id`, `politician_id`, `office_id`, `topic_id`, `season_id`, `served_revision_id` | the ladder the person actually read |
| `mode` | `blind` · `standard` · `audit` |
| `blind_value`, `blind_blank_reason`, `blind_submitted_at` | locked before the reveal — **the gold** |
| `final_value`, `final_blank_reason` | after the reveal — the decision |
| `source_judgments` | jsonb: per snapshot, `used`, plus any V1–V5 codes the person changed |
| `reject_reason` | closed list, below |
| `codebook_version`, `reviewer_id`, `created_at` | |
| `excluded_from_cert` | true once the item becomes a codebook example |
| `supersedes_id` | |

- **Counts toward certification:** `mode IN ('blind','audit') AND blind_submitted_at IS NOT NULL AND
  NOT excluded_from_cert`.
- **`reject_reason`** is a closed list: `wrong-person` `off-question` `direction-only`
  `adjacent-chairs` `wrong-chair` `source-fails` `pre-seating` `study-directive` `near-unanimous`
  `multi-subject` `scope-unavailable` `other`. The value `other` requires a note.
- **BLANK vs `value = 0`:** gold stores BLANK as `blind_value NULL` + `blind_blank_reason`. The write
  path translates it into the season's `value = 0` blank rule. The two meanings stay in two places.

### 4.4 `inform.reliability_certifications`

| Column | Notes |
|---|---|
| `stratum` | level × evidence class, optionally topic |
| `codebook_version` | |
| `model_set` | |
| `n`, `m1_alpha`, `m2_alpha`, `m3_wilson_low`, `m4_severe` | |
| `certified`, `reason`, `computed_at` | |

`decidePublish` reads the newest row per key.

### 4.5 Additions to `inform.stance_research_review`

`review_mode`, `codebook_version`, `unanimous`, `consensus_value`, `office_id`. `queue_reasons` exists
since CA_0285; it gains the values in §1.7.

### 4.6 Review page — blind mode

1. **Hidden:** the proposed chair, the coders' chairs, the reasoning, the queue reasons, and what
   voters see now (that last one is also an anchor).
2. **Shown:** the ladder (served revision), the snapshot passages with links to the live pages, and the
   person's office and term dates.
3. **The reviewer** picks a chair, or BLANK with a reason, and optionally marks sources used or not
   used. **Submit blind** writes and locks the gold row.
4. **Reveal:** the coders' chairs and reasoning appear. The reviewer approves, changes or rejects
   (`final_*`). If the blind and final answers differ → the row is flagged `hard-example-candidate`.

**Sample rate (Q7):** 1 in 2 of queued rows (`blind-sample`) until the first stratum certifies, then
1 in 3. Every `audit-sample` is also blind. Other rows review as
today and write `mode = 'standard'` (reference, not gold).

**Legacy rows:** the 23 resolved rows (§0.2) may be imported as `standard`, for reference only.

---

## 5. Edge cases and failure handling

**Default: fail closed.** Anything not covered here goes to a person. The machine can only *lose* a
publish, never gain one.

### 5.1 Identity

- **Namesake:** CONFIRM requires the office or jurisdiction in the snapshot to match the seat. Any coder
  giving V1 = `namesake/unclear` → review.
- **Common surname with no title near the span:** the existing verifier rule, unchanged.
- **One person, two offices:** every coder, gold and review row carries `office_id`. Joins that start
  from the politician use `DISTINCT ON` (CLAUDE.md, "the second one can [fan out]"). A source about the
  other seat is V2 = `off`.
- **Duplicate-person merge:** the merge template re-points `politician_id` on
  `stance_coder_labels` and `stance_gold_labels` exactly as it does on review rows.
- **Candidate with no record:** statement strata only. Such a row can auto-publish only from a
  certified `statement-answer` stratum (Q2).

### 5.2 Time and seating

- **Pre-seating act:** CONFIRM compares the act date with `office_terms`. If the dates cannot settle it
  → review (stance-program §4.10).
- **Superseded statement:** V5 = `superseded-by-later`. The coders use the newest evidence. If they
  split on which is newest → review.
- **Old record, new ladder:** allowed if the record is chair-shaped against the *served* rung text.
  A record has no age limit.
- **Statement age follows the election cycle (Q4, ruled 2026-09-25).** A statement counts only if it
  is from one of:
  - the current term;
  - the current campaign;
  - the campaign that seated the person in *this* office.

  Anything older → review (`statement-out-of-cycle`). CONFIRM computes this from `office_terms` and the
  race dates. If the dates are not at `day` precision → review. Every published chair shows its
  `evidence_as_of` date (§6).

### 5.3 Ladder and season

- **Ladder revised while a row is pending:** `resolve` already refuses. The coder labels become stale
  and the row is re-coded. Blind gold on the old revision stays valid for that revision only.
- **Season closes with blind rows open:** the gold rows remain. The review row goes to `superseded`.
- **Inverted or off-axis topic:** the annex marks it. The coders see rung text only, never "pro/anti".
  The per-topic veto applies.
- **Scope-unavailable rung:** these rows are not coded; the bundle already drops them
  (`topic-out-of-scope`).

### 5.4 Sources — policy by owner (operator, 2026-09-25)

| `source_kind` | Blocked automated fetch (403 / robots / JS-only) | Storage |
|---|---|---|
| `public-record`: legislature, council, clerk, SOS, court, agency | a person fetches it in a real browser (operator or Claude in Chrome, human pace) → `fetched_by = 'human'` | full text |
| `own-site`: the politician's campaign or office site, own social account | as above | full text |
| `news`: publisher, wire | **never bypassed**, including by anti-bot scraping services. The collector finds the primary source. If the news article is the only source → review, and a person may human-verify it | excerpt windows only |
| `pointer`: Ballotpedia, VOTE411, aggregators, **scorecard pages** (LCV, NRA, ATR…) | not evidence; the coders see it tagged `pointer` and cannot rest a chair on it. The collector follows a scorecard page to the roll calls it lists, and each roll call is snapshotted and coded as a record on its own. A grade, a percentage or an endorsement is never evidence and never corroboration (Q9) | excerpt |
| `transcript`: OTR transcript | codable. A bare video URL is a lead, not evidence | full text |

- A row whose only sources cannot be snapshotted → review, never auto-publish.
- PDFs are snapshotted as extracted text; the hash is on the PDF bytes.
- A source that dies after publication does not unpublish the row. The snapshot keeps replay working;
  the re-check only sends a notice.
- **Separate track, not designed here:** content licensing or API agreements with publishers (Gray,
  Hearst, AP) and nonprofit newsrooms (CalMatters, INN members). This is for `/cto` (cost, vendor,
  legal) and `/marketer` (partnership).

### 5.5 Coders

- **Invalid JSON or schema failure:** one retry, then the coder is missing → `coder-missing` → review.
- **Cites an unknown snapshot, or quotes text not in the snapshot:** the label is invalid (gate). The
  failure is counted per model in the report.
- **Two agree, one missing:** not unanimous → review. α tolerates missing data; the publish rule does
  not.
- **All three BLANK with the same reason:** a unanimous BLANK. No write, because a null is never queued.
  It is recorded as closed research.
- **Same chair, disjoint sources:** not unanimous.
- **Refusal or prose output:** missing.

### 5.6 Evidence

- **Record vs statement conflict:** the record wins (existing contract). If the coders split on whether
  it is a conflict → review.
- **Compound chair with one clause evidenced:** BLANK `compound-partial` (stance-program §4.2).
- **Own bills on adjacent chairs:** BLANK `adjacent-chairs` (§4.3).
- **Near-unanimous vote:** V4 = `near-unanimous`; it cannot seat a chair alone (C46). CONFIRM checks
  the tally where the snapshot has it.
- **Multi-subject or procedural vote:** the vote ladder, §2.1.
- **A published chair would change:** `replaces-published-chair`, always review.

### 5.7 Process

- **Blind ≠ final answer:** both are kept. Such rows are the best hard examples.
- **The researcher reviews their own batch:** allowed (there are two operators). Recorded;
  blind mode covers most of the risk.
- **Coder model change:** the stratum is uncertified until replay passes.
- **Codebook edit:** MAJOR → replay; MINOR → none.

---

## 6. Cadence and history

The seasons are the history: a closed season keeps the chair that was true then.

- **Carry-forward at season open (Q3, ruled 2026-09-25):**
  - If the topic's question and all five rungs are **unchanged** between the closed season's pin and
    the new season's served revision, the old chair **carries forward** and is shown until the row is
    re-researched. This is the current behaviour: an absent new-season row shows the older season.
  - If the question or any rung **changed**, the old chair does **not** carry forward; the spoke shows
    as not yet researched this season.
  - "Unchanged" is decided by code, by comparing the revision texts, not by the change class alone.
- **Re-research in every season, including carried-forward rows.** Every seated politician is coded
  again against the new season's served ladders during that season. This is the main refresh. A
  carried-forward row keeps its old `evidence_as_of` date until then, and voters see that date.
- **Inside an open season:** a quarterly light pass. The collector searches only for evidence
  **newer than `evidence_as_of`**. If it finds any, the row is re-coded. A changed chair is always
  `value-change`, so it is always reviewed.
- **Newly added politicians:** coded when added, against the open season.
- **Two dates per row:**
  - `researched_at`: when we looked. This exists today as `last_stances_researched_at`.
  - **`evidence_as_of`** (new): the date of the newest evidence the chair rests on. The read path can
    show "position as of <date>".
- **A position change is not an error.** Both chairs are kept, each with its season.
- **Re-certification cadence:** replay at every season open (ladders change), in addition to the
  triggers in §3.4.

---

## 7. Phases

| Phase | Delivers | Publish behaviour |
|---|---|---|
| **P0** | codebook v1.0 + annexes for the first-wave topics; migrations §4; `reliability.ts` + positive control | unchanged (review-all) |
| **P1 shadow** | `sources.json`, snapshots, 3 coders, agreement, CONFIRM, report — **all computed, none acted on** | unchanged; the review page shows the coder split as information only |
| **P2 blind review** | blind mode on the review page; gold capture; hard-example loop into the codebook | unchanged |
| **P3 certify** | `reliability_certifications`; `decidePublish` reads it; audit sample | auto-publish **only** in certified strata |
| **P4 skeptic** | refutation sub-agent in CONFIRM | tighter |
| **P-quotes** | the same pipeline over V7–V8 for quotes; the evidence-program gold is imported as `standard` | quote auto-promote only in certified quote strata |

P1 exists because M1 can be measured before any gold exists. If three coders cannot reach α ≥ 0.80
with *each other*, the codebook is the problem, and gold would not help.

---

## 8. Relation to the on-the-record evidence program

- **Vocabulary kept:** `lever` / `direction` / `none`, and the `audit-quotes` check IDs, as V7 and V8.
- **Gold kept:** `tier_gold_v1` (64 items) is imported as `mode = 'standard'`, single labeler, **not
  blind** (its 32 re-cut items came with pre-filled suggestions). It is reference and codebook-example
  material, not certification gold.
- **Superseded:** raw percent agreement → α; the single-labeler accept criteria → §3.3; "no
  auto-accept" → auto-accept only in certified strata.
- **Paid models (Q6, ruled 2026-09-25):**
  - **The extractor stays**, as a collector tool that finds candidate quotes in long transcripts.
    Finding is collecting, not judging.
  - **One other-vendor judge stays as a diagnostic fourth coder.** Its label is recorded and reported
    per stratum as a **shared-error warning**. The warning fires when the three Claude coders agree
    unanimously and the fourth coder often disagrees. **It never counts** toward unanimity or
    certification.
  - The cross-checker and the second judge retire.
  - **Before building:** read the per-item cost from the judge A/B report. If the cost is too high, run
    the fourth coder on a sample (e.g., 1 in 5).
- **The lever definition (Q5, ruled 2026-09-25)** is the codebook's V7. It is binding on both programs.

---

## 9. Rulings

### 9.1 Made 2026-09-25 (Chris Andrews)

| # | Question | Ruling |
|---|---|---|
| Q1 | May the coders use tools? | **No.** They get Write only (for their label file). A coder that needs more evidence emits `needs_source`; the collector fetches it and all three re-code (§0.5, §1.3). |
| Q2 | Can statement evidence ever auto-publish? | **Split.** `statement-answer` (questionnaire, moderated debate answer, first-person issue page, signed pledge) can certify. `statement-other` (news quotes, social posts, speeches, interviews) never auto-publishes (§3.2). |
| Q3 | Does a Season 1 chair carry forward? | **Yes, if the question and rungs are unchanged**, until the row is re-researched in the new season. If they changed, no (§6). |
| Q4 | Statement age? | **By election cycle:** current term, current campaign, or the campaign that seated them; older → review. Every chair shows `evidence_as_of`. Records have no age limit (§5.2). |
| Q5 | What is a lever? | **Two tests:** T1, a same-goal opponent could choose a different means; **and** T2, a voter could later check whether it was done. Optional `lever-named` tag when a specific instrument is named (codebook V7). |
| Q6 | The evidence program's paid models? | **Keep the extractor** as a collector tool. **Keep one other-vendor judge** as a diagnostic fourth coder (a shared-error warning, never counted). Retire the rest. Read the per-item cost first (§8). |
| Q7 | Sample rates? | **Staged.** Blind 1 in 2 until the first stratum certifies, then 1 in 3. Audit 1 in 5 for a stratum's first 100 auto rows, then 1 in 10. These are configuration (§3.4, §4.6). |
| Q8 | Pledges and lawsuits? | **A pledge is `statement-answer`** (a signed answer to fixed text; it does not outrank the person's later words). **Lawsuits, amicus briefs and signed official letters are `record`**, but the legal claim itself must match the rung clause; procedural claims prove nothing (codebook V3). |
| Q9 | Scorecards? | **A grade, percentage or endorsement is not evidence and not corroboration.** The scorecard page is a `pointer` to the roll calls it lists, and each roll call is coded as its own record. A candidate's published answers to a group's questionnaire are `statement-answer` (§5.4). |

### 9.2 Still owed from the stance-program spec §12.3 (Cantrell, 2026-09-23)

These affect the annexes, so the annexes for those topics wait for them:

- **P1** — `surveillance-technology` has 17 seated rows against rung text that breaks the level-agnostic
  gate. Revise and re-audit, or accept as-is?
- **P3** — can a topic express per-jurisdiction legal availability, or is a documented exclusion list
  the answer?
- **P4** — store topic orientation, yes or no? (Part C annexes need it either way; the codebook records
  orientation in prose until then.)
- **P7** — does ballot access get its own ladder?
- Also listed there: §8.3 (seven local `ORPHAN_CONTEXT` rows) and §5.6 (were the
  `BALLOTPEDIA_ONLY` / `PRIMARY_SITE_NO_PATH` baseline raises earned?).
