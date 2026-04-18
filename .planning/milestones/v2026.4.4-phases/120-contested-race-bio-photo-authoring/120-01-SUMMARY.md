---
phase: 120-contested-race-bio-photo-authoring
plan: 01
subsystem: essentials / ev-ui / content-authoring
tags:
  - contested-race
  - bio-authoring
  - candidate-scope
  - ev-ui-patch
  - antipartisan
dependency_graph:
  requires:
    - essentials.race_candidates, races, elections, politicians, politician_images tables
    - ev-ui auto-bump pipeline (publish.yml)
    - Production DB DATABASE_URL
  provides:
    - 120-CANDIDATE-SCOPE.md (authoritative scope for Plan 02)
    - bio_text render on PoliticianProfile hero (ev-ui >= 0.4.3)
    - 120-BIO-METHODOLOGY.md (reusable for Phase 124)
  affects:
    - ev-ui v0.4.3 consumer repos (CompassV2, essentials, read-rank, civic-spaces) — auto-bump PRs
tech_stack:
  added: []
  patterns:
    - React text-node render for untrusted DB text (XSS mitigation via default escaping)
    - ev-ui auto-bump via npm version patch + tag push
    - PostgreSQL contested-race scoping (HAVING COUNT(*) > 1 subquery)
key_files:
  created:
    - .planning/phases/120-contested-race-bio-photo-authoring/120-CANDIDATE-SCOPE.md
    - .planning/phases/120-contested-race-bio-photo-authoring/120-BIO-METHODOLOGY.md
  modified:
    - ev-ui/src/PoliticianProfile.jsx (external repo, not in worktree)
decisions:
  - Phase 117 was never executed — 117-FEASIBILITY.md does not exist; scoped from scratch via DB audit
  - Audit surfaced 37 contested candidates (28 needing content) vs. CONTEXT.md's ~5-10 estimate — Plan 02 to decide narrow vs. broad
  - Todd Young (CONT-02 named) already has bio + photo; CONTEXT assumption is stale
  - Source citations stored in REVIEW-DATA.md only — no bio_source_url DB column added (not needed at this batch size)
metrics:
  duration: ~15 minutes
  completed_date: 2026-04-16
  tasks_completed: 3
  files_created: 2
  files_modified: 1
  commits_in_worktree: 2 (+1 ev-ui commit in external repo + version-bump commit + tag)
---

# Phase 120 Plan 01: Contested-Race Bio/Photo Authoring Foundation — Summary

## One-liner

Established the authoritative candidate scope (37 contested Monroe County May 5 candidates, 28 needing content) via production DB audit, closed the bio_text render gap in ev-ui PoliticianProfile.jsx (shipped v0.4.3 via auto-bump pipeline), and wrote the reusable bio authoring methodology doc required by Phase 124.

## What Was Built

### Task 1 — Contested-race candidate scoping audit
- Ran the Pattern-1 scoping query from RESEARCH.md against production (`kxsdzaojfaibhuzmclfq`) via `psql` + `DATABASE_URL` (Supabase MCP not available as a tool in this agent; CLI fallback via psql used).
- Filter: 2026-05-05 IN election, linked+active candidates, races with 2+ active contestants.
- Result: **37 contested-race candidates** — 11 missing bios, 18 missing photos, 1 missing both, 9 already complete.
- Produced `120-CANDIDATE-SCOPE.md` with full roster table, priority buckets (A=both, B=bio-only, C=photo-only), skip list, and scope note flagging that the audit is broader than CONTEXT.md's ~5-10 framing.
- Noted Todd Young (CONT-02 named) already has bio+photo — the CONTEXT assumption was stale.
- **Commit:** `3a24ca9` (worktree)

### Task 2 — ev-ui PoliticianProfile.jsx bio_text render patch
- Added `bioText` style entry in the `styles` object (after `officeDesc`, lines 513-521 in ev-ui@0.4.3).
- Added conditional render block `{pol.bio_text && (<p style={styles.bioText}>{pol.bio_text}</p>)}` immediately after the `pol.office_description` block, before the Term/Years in Office meta row (lines 675-677).
- Render is a React text node — no `dangerouslySetInnerHTML`. React default escaping mitigates T-120-01 (tampering / XSS via DB-sourced bio text).
- `npm run build` succeeded (tsup 0 errors, ESM + CJS bundles built).
- Bumped version: 0.4.2 → 0.4.3. Pushed `main --follow-tags` to origin; tag `v0.4.3` triggered the publish.yml workflow (OIDC npm publish + repository_dispatch fan-out).
- **Commits (external ev-ui repo):** `3842999` (feat patch) + `1beb88e` (version bump 0.4.3) + tag `v0.4.3`. Not in this worktree — ev-ui is an independent repo.

### Task 3 — Bio authoring methodology doc
- Created `120-BIO-METHODOLOGY.md` with all required sections: Bio Sourcing Rules, Tone and Voice, Length, Antipartisan Constraint, Fallback, Photo Source Priority, Photo Upload Checklist, Review Process.
- Documented 180-char hard max, single named source rule, party omission (with narrow professional-role exception), office-title-only fallback, dual photo write requirement (`politician_images` + `photo_custom_url`).
- Included antipattern list and Phase 124 reusability checklist.
- **Commit:** `2ed0bee` (worktree)

## Deviations from Plan

None — plan executed as written. Two documentation-only notes for downstream plans:

- **Scope surprise (not a deviation, but Plan 02 should decide):** the audit surfaced 37 contested candidates vs. CONTEXT.md's "~5-10 candidates" framing. Plan 02 can narrow scope to county + state + US-9 headliners (~10-12 candidates) or broaden to the full 28-content-needed list. CANDIDATE-SCOPE.md presents both options.
- **Stale CONTEXT assumption:** Todd Young (explicitly named in CONT-02) already has bio + photo in the DB. Verified during the audit. No action needed.

## Authentication Gates

None. DB access used production `DATABASE_URL` from `ev-accounts/backend/.env`; ev-ui push used standard git credentials; npm publish handled by GitHub Actions via OIDC (no local auth needed).

## Tooling Note

The spawn prompt's `<notes>` suggested using the Supabase MCP tool `execute_sql` with project_id `kxsdzaojfaibhuzmclfq`. This agent did not have Supabase MCP tools available in its toolset. Per documentation_lookup fallback guidance, used `psql` against the same production DATABASE_URL — same target project, equivalent output. No impact on Task 1 results.

## Requirements Marked

- **CONT-01** (bios authored for contested-race candidates): **Partially satisfied** by this plan. The render gap is closed (column now renders on profile pages). Actual bio content authoring happens in Plan 02 / Plan 03. Plan 01 provides the scope doc and methodology.
- **CONT-02** (headshots sourced for contested-race candidates): **Not yet satisfied.** Plan 01 scopes the work (17 photo-only + 1 bio+photo candidate). Actual photo sourcing + upload happens in Plan 02 / Plan 03.

Plan 01 unblocks both requirements without closing either. Leaving final mark-complete to the plan that actually writes bio_text and politician_images rows.

## Threat Flags

None. The ev-ui patch renders `pol.bio_text` as a React text node (T-120-01 mitigated). The DB audit output in CANDIDATE-SCOPE.md contains public politician names and UUIDs (T-120-02 accepted per threat model). No new security surface introduced.

## Known Stubs

None. No hardcoded empty arrays, placeholder text, or unwired components.

## Self-Check

### Files created

- `.planning/phases/120-contested-race-bio-photo-authoring/120-CANDIDATE-SCOPE.md` — FOUND
- `.planning/phases/120-contested-race-bio-photo-authoring/120-BIO-METHODOLOGY.md` — FOUND

### Files modified

- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianProfile.jsx` — FOUND (external repo; `bio_text` + `bioText` both present per grep)

### Commits

- `3a24ca9` (worktree, docs(120-01): contested-race candidate scope audit) — FOUND
- `2ed0bee` (worktree, docs(120-01): add reusable bio authoring methodology) — FOUND
- `3842999` (ev-ui, feat(120-01): render pol.bio_text) — FOUND in `/Users/chrisandrews/Documents/GitHub/ev-ui`
- `1beb88e` (ev-ui, version bump 0.4.3) — FOUND
- Tag `v0.4.3` — FOUND in ev-ui remote (push confirmed: `5581dbb..1beb88e  main -> main, * [new tag] v0.4.3 -> v0.4.3`)

## Self-Check: PASSED

All 3 tasks executed, all artifacts present, all commits verified, ev-ui auto-bump pipeline triggered.
