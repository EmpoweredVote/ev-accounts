# Stance Research — Reconciliation with the Compass Stance Program

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Each task below is
> an integration task: it states files, required behaviour, tests and verification rather than full code.

**Goal:** The `claude/stance-research-hardening` branch includes everything in Chris Cantrell's Compass Stance
Program (`docs/superpowers/specs/2026-09-23-stance-program-design.md`, on master) that applies, merges cleanly
with master, and keeps the branch's own gates.

**Inputs:** the comparison report `.superpowers/sdd/2026-09-22-stance-research-evidence-gate/colleague-comparison-report.md`
(C-numbers = his program's items; B-numbers = the branch's; D-numbers = decisions). Read the relevant rows before each task.

## Global Constraints

- **Operator rulings (Chris Andrews), binding:**
  - 2026-09-22: every stance goes to the review queue; `--auto-push` exists, off by default, never used without a written ruling; citations are written on approval, never at queue time; an unresolved politician goes to review only when that is its only high finding; an existing open-season value (incl. 0) is never changed without a person.
  - 2026-09-23: **research and quote judgment run inline in the session, one politician per run — no research sub-agent, no judgment sub-agent** (his #662 / #691); `statement` evidence stays as built (any of the person's own words, always review); **school boards are in scope with an education lens only** (a `school` level; topics chosen per rung, approved by the operator).
- The canonical program text is his spec. Where a rule is only "stated" there, **reference the spec section instead of restating it**, except for the hard rules listed in Task 7.
- `audit-chair-evidence --check` runs on **record** rows only (statement rows cannot name an instrument; `NAMES_INSTRUMENT` is never widened).
- Migrations: number from the allocator (`npm run steward --prefix backend -- slot CA --purpose "..."`), idempotent, `DO $$` post-verify gate, dry-run as `BEGIN … ROLLBACK` on prod, **apply only with the operator's explicit OK**.
- No `--apply` of the verifier in any verification. Read-only prod queries are fine. Never print `.env`.
- Explicit-pathspec commits; new commits only; no push, no PR (operator decides).

---

### Task 1: Merge master and resolve the skill

**Files:** `.claude/skills/research-stances/SKILL.md` (conflict), `.claude/agents/politician-stance-researcher.md`, any file git reports.
- `git merge origin/master` on the branch (the worktree is the branch's own). Resolve the 8 SKILL.md hunks per report §5.1 and fix the 7 contradicting lines per §5.2.
- Apply D1 (inline) throughout: STEP 1 research and STEP 4a(ii) judgment are done by the session itself, one politician per run; master's #662 / #691 text is the base; remove every "dispatch", "re-dispatch" and "if an agent fails" instruction; "re-research that pair yourself".
- Agent file: keep the branch version (no hard-coded ladders, no party coaching — master's copy still has both, report B12); add a header that it is a **reference** (URL patterns, evidence contract, output format), not a dispatch target; **delete its rewrite-mode section** (take #667's deletion in the skill too).
- "~158" → "149"; the jurisdiction query stays the branch's (master's queries the dropped `offices.politician_id`, B10).
- Verification: `npm run test:unit`, `npm run typecheck`, `npm run lint`, admin build, `npm run check:ladder-text --prefix backend` (or the equivalent script name on master), `check:occupancy`, skill tests with `OTR_ROOT`. The merge commit uses an explicit pathspec only if git allows; otherwise a normal merge commit with every resolved path listed in the message.

### Task 2: Quote verification against raw bytes (his H2) + exit-code pattern

**Files:** SKILL.md STEP 4a, `backend/src/lib/researchVerifier.ts` (`normalizeText` / `htmlToText`), `backend/scripts/verify-stance-research.ts`.
- STEP 4a step (0): `cd backend && npm run verify:quotes -- data/stance-research/<batch>/research.csv --sources data/stance-research/otr-transcripts/<race_id>` (check `backend/scripts/verify-quotes.mjs` for the real flags; if it only takes a directory + pattern, use `--pattern '^research\.csv$'`). Exit 1 = stop.
- Port his numeric-entity decoding (verify-quotes.mjs, before punctuation strip) into `normalizeText`/`htmlToText`, with a test (`&#8217;` / `&#x2019;` → `'`).
- `verify-stance-research.ts`: replace `process.exit(0)` after network work with `process.exitCode` + an unref'd backstop, as in #666.

### Task 3a: School-board scope proposal (judgment — for operator approval, no code)

- For each of the 8 open-season `education-*` topics (and `school-vouchers`), read every rung of the pinned ladder (`season_questions → compass_stance_revisions`) and ask, per CLAUDE.md "Scope is a per-rung question": does a school board hold a lever on this rung? Write `.superpowers/sdd/2026-09-23-stance-program-reconciliation/school-scope-proposal.md`: per topic, per rung, yes/no with one line why, and a verdict (include / exclude / include-with-note). Also list how many Monroe school-board candidates this affects.
- Stop; the controller brings the proposal to the operator.

### Task 3b: The `school` level (after approval)

**Files:** new migration `CA_NNNN_school_board_role_scope.sql`; `backend/src/lib/topicApplicability.ts` (+test); `backend/src/lib/compassService.ts` callers; `backend/scripts/build-stance-topic-bundle.ts`.
- Migration: extend `chk_role_scope_tier` to include `'school'`; insert `compass_topic_roles (topic_id, 'school')` for the approved topics only; post-verify gate on the exact set; rationale in SQL comments naming the ruling.
- `Level` gains `'school'`; `levelForDistrict`: `SCHOOL` → `'school'`; `appliesFromRoles` reads `applies_school`; with no role rows a topic does NOT apply at school (unlike local). Voter compass and bundle both use it.
- Dry-run on prod, then stop for the operator's OK before apply.

### Task 4: A queued row remembers its ladder

**Files:** new migration (`stance_research_review.topic_revision_id` + `season_id`, nullable for legacy rows); `researchEvidenceService.ts` (`buildReviewRowForInsert`, `upsertReviewRow`, `resolveResearchReview`, reads); `verify-stance-research.ts` (pass the bundle revision); admin route + page.
- Queue time stores the bundle's `topic_revision_id` and the open `season_id`.
- Approval refuses (409 `CONFLICT`, "the ladder changed since this row was researched — re-research it") when the row's revision is known and differs from the open pin. A legacy row (null revision) is allowed, and the page shows "ladder revision unknown (queued before 2026-09-23)".
- Tests for all three cases. Dry-run the migration; apply only with the operator's OK.

### Task 5: Review against the ladder text (his §11.9, §3.4 cohort pass)

**Files:** `researchEvidenceService.ts` reads, admin route, `admin/src/pages/admin/ResearchReviewPage.tsx` (+ the list page).
- Detail view shows the question and all five rung texts **for the row's own revision** (open pin for legacy rows), the proposed chair highlighted, the current open-season value, and the verified snippets.
- List view groups pending rows by topic, then by body/chamber, so one person reviews a cohort against one ladder.
- Approving with `valueOverride` different from the proposal requires a changed `reasoningOverride` (the public summary moves with the value, C73) — server (422) and UI.

### Task 6: More deterministic gate checks

**Files:** `backend/scripts/lib/stanceGate.ts` (+test), `stancePublishPolicy.ts` if a new reason is needed, `verify-stance-research.ts` (report bucket).
- `reasoning-empty` (high) for a scored row.
- `ballotpedia-only` (high): every source URL is on ballotpedia.org (C57). `source-no-path` (medium): a source URL with no path (C58's `PRIMARY_SITE_NO_PATH`). Reuse the predicates in `backend/scripts/check-stance-sources.mjs` if they are exported; else mirror them with a comment pointing there.
- `instrument-not-cited` (high, record rows): every identifier-bearing instrument the reasoning names (bill / ordinance / resolution numbers matched by `NAMES_INSTRUMENT`'s identifier forms — not bare "Act" or "voted yes") must appear in at least one of the row's snippets (C68, citation control in both directions).
- `quote-not-in-snippet` (high): text inside quotation marks in the reasoning must appear verbatim (normalized) in one of the row's snippets (C69).
- `topic-out-of-scope` rows are reported in their own bucket (`out-of-scope`, recorded, not "re-research") so a scope finding is kept, not re-queued (C43, D3).
- Every new check gets a planted-defect test and a refusal test.

### Task 7: Ledger, audits, stamps

**Files:** `verify-stance-research.ts`; new `backend/scripts/export-written-ledger.ts`; SKILL.md STEP 4.
- On `--apply`: write `<dir>/written-<batch>.json` in `audit-chair-evidence`'s shape (`rows[{politician_id, topic_id, chair_after, season_id}]`, read `backend/scripts/audit-chair-evidence.mjs` for the exact shape) for rows written.
- `export-written-ledger.ts --batch <id> --dir <dir>`: after human approvals, write the same file from resolved review rows of that batch (record rows only, per the Global Constraints), so `node scripts/audit-chair-evidence.mjs --check <file>` can run; SKILL STEP 4 runs it, then `check:stance-sources`.
- Stamp `politicians.last_stances_researched_at` for every politician in the batch on `--apply`, including rows queued for review and politicians with no stance (C118: a research timestamp with zero answers is legitimate).
- SKILL: batch directories are committed as the ledger (they are deliberately not git-ignored).

### Task 8: Contract text — the hard rules, the rest by reference

**Files:** SKILL.md, agent reference file.
- Add, briefly, as hard rules: a cited vote needs ≥10% against (C46); a vote before the member took the seat is not evidence (C44); an excused absence is not a position, check tenure, verify a parse against the journal's own totals (C28); sponsorship evidences the bill as filed (C37); a short title is not evidence (C38); the operative section governs (C51); inference from silence and a study directive are refusals (C47, C48); a failed basis is not a failed chair (C64); positive control on every search (C60); OTR transcripts first in source order (C50); the Supabase MCP is production (C14).
- Everything else: a pointer to the spec section (§3 finding a chair, §4 refusal rules, §5 sourcing, §6 verification, §10 calibration set, §11 first-wave protocol and its exit criterion). Do not copy the spec.

### Task 9: Verify, control, prepare

- Full suite on the merged branch; re-run the Matt Pierce dry-run control (never `--apply`) including the new checks; update the PR draft; write the coordination list for Cantrell (verify-quotes default pattern, one fetch policy, statement rows vs `audit-chair-evidence`, the false "research CSVs are gitignored" line in spec §7.4, school-board decision reversing spec L644-648) and the rulings his spec requests of Chris Andrews (§12.3: P1, P3, P4, P7, §8.3 local roles, §5.6 baselines).
