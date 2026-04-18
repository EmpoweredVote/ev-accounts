# Phase 123: Photo Coverage Expansion - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Source and upload headshots for all linked candidates (`politician_id IS NOT NULL`) who
currently lack a `type='default'` row in `essentials.politician_images`. The roadmap
estimates ~62 candidates; the actual list is determined by running the audit script at
phase start — the DB is the ground truth.

This phase also absorbs the 17 photo-only Priority C township candidates deferred from
Phase 120 (contested-race, photo-only). They will be surfaced by the audit anyway.

**In scope:** Photo sourcing, CDN upload, and DB writes for all photo-gap candidates
found by the audit. No bio authoring — that is Phase 124.

**Out of scope:** Bios, new import infrastructure changes, geofence work, any new
election data imports.

</domain>

<decisions>
## Implementation Decisions

### Population Scope
- **D-01:** Run `audit-112-headshots.ts` (or an adapted variant) at the start of the
  phase to produce the authoritative photo-gap list. The "62" in the roadmap is an
  estimate — do not assume it is exact.
- **D-02:** Attempt photos for ALL candidates surfaced by the audit, regardless of
  whether the count exceeds 62. Phase 123's job is to close the gap, not stay under
  a number.
- **D-03:** Phase 120 Priority C (17 contested-race township candidates with no
  `politician_images` row) are folded into this phase. The audit will surface them;
  treat them identically to the non-contested-race population.

### Sourcing Strategy
- **D-04:** Sourcing depth: check Ballotpedia + one web/social search per candidate.
  If nothing surfaces after those two checks, accept the ev-ui initials fallback and
  mark the row as `NO_PHOTO` in the review table. Do not spend more time on low-profile
  township candidates — breadth over perfection.
- **D-05:** Photo source priority order (carried from Phase 120 D-08):
  1. Official government photo
  2. Campaign website
  3. Social media (LinkedIn, X)
  4. News article photo
- **D-06:** Always download and re-host on Supabase CDN — never hotlink. Consistent
  with Phase 120 D-09 and BIO-METHODOLOGY.md.

### Authoring Workflow
- **D-07:** Claude researches all candidates and prepares a REVIEW-DATA table;
  user approves before the import script runs. Same pattern as Phase 120.
- **D-08:** Single REVIEW-DATA table (`123-REVIEW-DATA.md`) covering all audit-surfaced
  candidates. One approval pass, one import run after user sign-off.

### Import Script
- **D-09:** Write a new `import-123-photo-expansion.ts` script (sibling to
  `import-120-contested-bios-photos.ts`). Photo-only — no bio writes. Preserves the
  established dual-write pattern and `--commit` flag convention.

### Claude's Discretion
- Exact query used in the audit (can extend `audit-112-headshots.ts` or write a fresh
  query covering all elections/states, not just May 5 2026 IN)
- REVIEW-DATA table column layout (follow Phase 120 convention as a starting point)
- Import script structure (follow `import-120-contested-bios-photos.ts` as analog)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-defining docs
- `.planning/ROADMAP.md` §Phase 123 — Goal, requirements (PHOTO-01), success criteria
- `.planning/REQUIREMENTS.md` §Tier 2 Photo Coverage Expansion — PHOTO-01 definition

### Phase 120 methodology (carry-forward)
- `.planning/phases/120-contested-race-bio-photo-authoring/120-BIO-METHODOLOGY.md` —
  Photo source priority, download/re-host rule, dual-write checklist, `contentType`
  pitfall (Pitfall 7), fallback policy
- `.planning/phases/120-contested-race-bio-photo-authoring/120-PATTERNS.md` —
  Transaction-per-candidate pattern, dual photo write (Pitfall 2)
- `.planning/phases/120-contested-race-bio-photo-authoring/120-CONTEXT.md` —
  D-08 through D-10 (photo sourcing decisions that carry forward)

### Prior art in codebase
- `ev-accounts/backend/scripts/audit-112-headshots.ts` — Existing audit script;
  classifies photo source as cdn/local/none. Extend or use as query reference.
- `ev-accounts/backend/scripts/import-120-contested-bios-photos.ts` — Analog for the
  new import-123 script: dotenv/pg.Pool init, `--commit` flag, Supabase upload,
  dual-write pattern.

### Phase 120 Priority C (absorbed into scope)
- `.planning/phases/120-contested-race-bio-photo-authoring/120-CANDIDATE-SCOPE.md` —
  Priority C section lists the 17 deferred contested-race township candidates

### Data model
- `essentials.politician_images` — `politician_id`, `url`, `type` (use `'default'`),
  `photo_license`, `focal_point`
- `essentials.politicians.photo_custom_url` — Secondary fallback field; must be
  dual-written alongside `politician_images`
- Supabase Storage bucket: `politician_photos`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `audit-112-headshots.ts` — DB-only audit script; adapt to cover all linked candidates
  (not just May 5 2026 IN election) or run as-is to get the photo-gap list
- `import-120-contested-bios-photos.ts` — Full upload + dual-write script to use as
  the structural template for `import-123-photo-expansion.ts`
- `auditHeadshots.ts` — Broader CDN health audit (HTTP checks, dimensions); not needed
  here but useful reference for the upload verification step

### Established Patterns
- `--commit` flag convention: dry-run by default, `--commit` to write
- Transaction-per-candidate: wrap each candidate's DB writes in a transaction so a
  failed upload doesn't leave partial data
- `contentType` on Supabase upload: always set `'image/jpeg'` or `'image/png'` —
  omitting it causes browsers to refuse to render the `<img>` (Pitfall 7)
- Dual-write: both `politician_images` INSERT and `politicians.photo_custom_url` UPDATE
  required per candidate (Pitfall 2)

### Integration Points
- PoliticianProfile component (ev-ui) reads `politician_images` as primary, falls back
  to `photo_custom_url` — no frontend changes needed
- Initials fallback renders automatically when both fields are null — acceptable outcome
  for unfindable candidates

</code_context>

<specifics>
## Specific Ideas

- Phase 120 Priority C (17 contested-race township photo-only candidates) are explicitly
  absorbed into this phase's scope — the audit will surface them alongside non-contested
  candidates
- Sourcing cutoff: Ballotpedia + one web/social search. If nothing in those two sources,
  mark `NO_PHOTO` and move on. Don't spend extra time on uncontested township trustee
  races where candidates have essentially no web presence.
- The "62" in the roadmap is an estimate from a point-in-time audit; the actual number
  will be confirmed when the phase starts.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 123-photo-coverage-expansion*
*Context gathered: 2026-04-17*
