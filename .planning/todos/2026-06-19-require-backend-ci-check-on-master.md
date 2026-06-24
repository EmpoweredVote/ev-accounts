---
created: 2026-06-19T00:00
title: Make the backend CI check a required, merge-blocking gate on master
area: ci
files:
  - .github/workflows/ci.yml
---

## Problem

CI now runs on every PR/push to `master` (`.github/workflows/ci.yml`: lint →
typecheck → unit tests, added in #53), but `master` has **no branch
protection** — so a PR with failing CI can still be merged. The check is
advisory, not a gate. (read-rank's `main`, by contrast, already requires its
`build` check before merge.)

## Solution

Add a branch-protection rule on `ev-accounts` `master` requiring the
`backend lint · typecheck · test` status check to pass before merge. Decisions
to make when picking this up:

- Whether to also require PRs (block direct pushes to `master`) or leave direct
  pushes allowed.
- Whether to require the check for admins too (`enforce_admins`).
- Likely keep `required_approving_review_count` at 0 to match current solo flow.

Can be done via `gh api -X PUT repos/EmpoweredVote/ev-accounts/branches/master/protection`
or the GitHub UI. Note: editing branch protection needs admin; pushing further
workflow files needs a `gh` token with `workflow` scope (current token lacks it
— used SSH for #53).
