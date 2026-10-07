# Season 2 blanks through the review queue — design (draft, 2026-10-07)

**Status:** draft for the operator (Chris Andrews). Option A of three (below), recommended 2026-10-07.
**Why now:** the Opus-alone Monroe pilot (PR #911) coded 145 rows and blanked 140. 52 of those blanks sit
over a Season 1 chair that voters see today, and none of them can reach the review queue — so the old chair
stays visible even though the current codebook cannot support it.

## 1. The problem

A blank is a value-0 Season 2 row plus a context row that names the examined sources (season2-prestage
correction 2026-09-23; precedent migrations 1888, CA_0190). The database already allows it
(`politician_answers_value_whole_0_to_5`; 393 open-season value-0 rows exist, all written by migrations),
and the read path filters 0 **after** the newest-season collapse, so a value-0 Season 2 row hides the
Season 1 chair and shows a blank spoke.

What does not exist is a path from research to that row:

| Step | Today | File |
|---|---|---|
| research.csv | a blank is an empty value | `scripts/gold-desk/labels_to_research.py` |
| gate | `value === null` returns early; 0 is `value-out-of-range` (high) | `scripts/lib/stanceGate.ts:185,188` |
| verifier | null rows are "skipped; not pushed, not queued" | `scripts/verify-stance-research.ts:187-189,521` |
| policy | `decidePublish` has no blank case | `scripts/lib/stancePublishPolicy.ts:55` |
| approval | `valueOverride` must be 1–5; writes answer + context + evidence | `src/lib/researchEvidenceService.ts:610-650` |
| review page | shows `value {proposedValue}` | `admin/src/pages/admin/ReviewQueuePage.tsx:305` |

## 2. Options

- **A (recommended). A blank goes through the review queue.** A blank that would change what voters see is
  queued; a person approves it; approval writes the value-0 row. Same human gate as a chair, and approvals
  become labeled data for blanks.
- B. One migration per batch writes the value-0 rows (the 1888 pattern). Faster; no per-row review in the
  UI; re-creates the per-person migration the pipeline replaced.
- C. Write nothing. The unsupported Season 1 chairs stay visible. Rejected.

## 3. Design (option A)

### 3.1 Research files
- `research.csv` carries a blank as `value = 0` with a new column `blank_reason` (one of codebook V6's
  six). An empty value keeps today's meaning ("not researched / insufficient evidence") so old batches are
  unaffected.
- `evidence_type = blank`. Its sources are the **examined** sources (every snapshot the coder read for the
  row), not `rests_on` (empty for a blank). Snippets as today (verbatim, 25+ words).

### 3.2 Gate (`stanceGate.ts`)
- `value = 0` is valid only with a `blank_reason`; `value-out-of-range` still fires for 0 without one.
- A blank row skips the chair checks (instrument-not-cited, quote-not-in-snippet, party-inference still
  runs on the reasoning). New high check `blank-unexamined-fallback` (see 3.3).

### 3.3 Policy (`decidePublish`) — one new branch, before the chair branches
| Voters see now | Open season holds | Action |
|---|---|---|
| nothing | nothing | `unchanged` — write nothing; the run's research stamp (C118) records it |
| a Season 1 chair (fallback) | nothing | `review`, reason `blank-replaces-published-chair` |
| — | a chair (1–5) | `review`, reasons `value-change` + `blank-replaces-published-chair` |
| — | 0 | `unchanged` |

**Rule (new): a blank may remove a visible chair only after the coder examined that chair's own cited
sources.** The collector adds every source cited by the Season 1 context (`build-s1-leads.ts` already lists
them) to the row's batch as an ordinary source — never `s1-leads.json` itself, which stays collector-only.
The gate fires `blank-unexamined-fallback` (high → re-research) when a blank's examined URLs do not include
the fallback chair's cited URLs that are still fetchable. The pilot did not do this; its 52 blanks must be
re-coded with those sources before they are queued.

`--auto-push` never writes a blank (a blank always replaces something a voter sees, or is a no-op).

### 3.4 Queue row
`proposed_value = 0`; new nullable column `proposed_blank_reason` (CHECK the six V6 values);
`evidence_type = 'blank'` (extend `stance_research_review_evidence_type_check`). Migration via the allocator
(`steward slot CA`), idempotent, post-verify gate.

### 3.5 Review page
Show **"Blank — <reason>"** in place of `value 0`, beside "Voters see now: chair N (Season 1)" and the S1
reasoning, and list the examined sources. Approve = write the blank. The reviewer may instead approve a chair
(valueOverride 1–5, with reasoning, as today) or reject.

### 3.6 Approval (`resolveResearchReview`)
Accept `proposed_value = 0` (and `valueOverride = 0` when a reviewer blanks a proposed chair, with a
required reason). Write, in one transaction: the Season 2 answer `value = 0`; the context
`"Blank in Season 2 — researched on <date>. <coder reasoning>"`; one `politician_context_evidence` row per
examined source. 🔴 Never DELETE an existing Season 2 row — UPDATE to 0 (season2-prestage correction).

### 3.7 Readers
No read-path change: every `@zero-scope` site (11 today) already decides what 0 means. Add a test that a
queued-then-approved blank hides the Season 1 chair in `getPoliticianAnswers` and is counted by the coverage
rollup (`counts-blanks`).

## 4. Tests (minimum)
- policy: the four rows of 3.3; `--auto-push` never writes a blank.
- gate: 0 without reason → high; blank without fallback sources → `blank-unexamined-fallback`.
- approval: blank over S1 → S2 row 0, S1 untouched (closed-season trigger), context + evidence written;
  an existing S2 chair is UPDATEd to 0, never deleted.
- end-to-end on a fixture batch: research.csv → gate → verify --apply → resolve → read path shows a blank.

## 5. Open questions for the operator
1. A blank where voters see nothing: write nothing (3.3), or write the value-0 row without review so the
   Season 2 record exists?
2. Does a voter see the blank's reasoning ("Why is this blank?"), or only an empty spoke? (Citations.jsx and
   CompassV2 behaviour for value 0 should be checked.)
3. Should a `no-evidence` blank (no source found at all) be allowed to remove a visible chair, or only blanks
   whose examined sources include the fallback chair's sources (3.3 rule)? The draft says the latter.
