# Proposal: how a human-saved own-site copy should count for verification

Status: **RULED 2026-10-07 (Chris Andrews) — not yet implemented.** Option B; rules 2 and 3 below accepted as recommended.

## Problem

`verify-stance-research.ts` fetches each cited URL and matches the snippet in the page text. A
JS-only own-site page (e.g. `stevehiltonforgovernor.com/policies/*`, a TanStack SPA) returns an HTML
shell with no body text, so every snippet fails `snippet_not_found` and the chair goes
`below-threshold`. The coding pipeline already accepts a person-saved copy
(`human_saved_path`, spec 2026-09-25 §5.4; `sources.json`, `snapshot-sources.ts`), but the verifier
ignores it. (On the Record transcripts had the same symptom and are fixed in this PR by reading the
OTR API; they are machine-verifiable. An own-site SPA is not.)

## What "hand-verified" means today

- Review row → admin page (`ResearchReviewPage.tsx`): each source has a "verified" toggle. Sources
  with a machine-verified snippet are pre-checked; a person may toggle any other source on after
  opening it.
- `resolveResearchReview(id, resolvedBy, humanVerifiedUrls, …)` accepts those URLs. For each it
  writes a `politician_context_evidence` row with the placeholder snippet
  `[Human verified during review]` (batch `human-review-<id>`), so the **URL** appears as a citation
  but **no quote is published**.
- A row needs at least one machine-verified span or one human-verified URL to be approvable.
- Review-all (default) already sends every row to a person; `--auto-push` is the only path where
  nothing human happens.

So hand-verified = "a person opened the URL and vouched for it". It publishes a link, never a span.

## Options

**A. Count it as machine-verified (verifier reads `human_saved_path`).** Rejected. The verified span
would be published as if the pipeline had fetched it, but the saved text came from a person's
browser and could be edited. It would also let a row clear `--auto-push` with no human review of
the copy. This breaks the line the codebook draws (§5.4: `fetched_by = 'human'`).

**B. Hand-verified path, link only (recommended).** The verifier does not use the copy to verify.
It records, per own-site source that failed only because the page is JS-only and that has a
`human_saved_path`, a *human-saved* marker on the review row's evidence entry (verdict stays
`url_broken`/`snippet_not_found`; add `human_saved: true` plus the file's `sha256`). The review page
shows "human-saved copy available" and, **as a convenience only**, a snippet-found / not-found check
against the saved copy so the reviewer need not eyeball a long page. Approval is the existing
hand-verified path: the reviewer toggles the URL, and it is published as a link with the
`[Human verified during review]` placeholder. No span is published.

**C. B plus a published span.** As B, but when the snippet matches the saved copy, publish the span
(tagged human-saved). Gives voters a quote. Costs: a schema/placeholder change and a trust decision
(a person-supplied file becomes quoted text). Only worth it if voters must see own-site quotes.

## Recommendation

**B.** It keeps one meaning for "machine-verified" (the pipeline fetched it itself), keeps
review-all unchanged, and uses the existing hand-verified mechanism and its audit trail
(`resolved_by`, batch `human-review-<id>`). The `sha256` makes a later edit of the saved file
detectable.

## Rulings (2026-10-07, Chris Andrews)

1. **Option B.** Link only; no span is published from a human-saved copy.
2. **Auto-push:** a row whose only support is a human-saved copy always goes to review, even under
   `--auto-push`. Stated as an explicit rule so a later change to the threshold logic cannot let it through.
3. **Scope:** only sources the manifest marks `own-site`. Widen later if a government site proves JS-only.

Implementation is a separate change.

## Not changed by this PR

Verifier behaviour for own-site pages, `resolveResearchReview`, the admin page, and review-all.
