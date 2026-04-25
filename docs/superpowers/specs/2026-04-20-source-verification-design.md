# Source URL Verification — Design

**Date:** 2026-04-20
**Status:** Approved design, pending implementation plan

## Problem

Compass stances and read-rank quotes are backed by source URLs. Some of these URLs are wrong — broken links, fabricated URLs, or pages that don't actually support the blurb/quote they're attached to. There is no current way to tell which sources have been vetted and which haven't.

We need a repeatable workflow that (1) tracks per-URL verification status, (2) automatically checks URL validity and content alignment where the LLM can be confident, and (3) routes ambiguous cases to a human review queue.

## Non-Goals

- Fully automated replacement of URLs without human sign-off.
- Real-time verification at ingest time. Verification is a background process.
- Analytics, history logs, or bulk actions in the admin UI for v1.

## Architecture Overview

Three pieces:

1. **`source_verifications` table in Supabase** — single source of truth for every URL's status, shared across compass and read-rank.
2. **`verify-sources` Claude Code skill** — runs on demand in Claude Code, uses `WebFetch` and `WebSearch` to classify unverified URLs, writes results back to Supabase. No API calls, no cron job, no backend worker.
3. **Admin SPA review page** at `accounts.empowered.vote/admin/source-review` — human-in-the-loop queue for rows the skill flagged as `needs_review`.

The skill is the engine. The admin page is the human-in-the-loop surface. Running the skill is ad-hoc (user invokes `/verify-sources` whenever); scheduling is not part of v1 but can be layered on later with `/schedule` or `/loop`.

## Data Model

### New table: `public.source_verifications`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `entity_type` | text | `'compass_stance'` or `'readrank_quote'` |
| `entity_id` | uuid | Pointer to the stance or quote row |
| `url` | text | The URL being verified |
| `url_index` | int | Position in the `sources` array (compass); 0 for read-rank |
| `status` | text | `'unverified'` \| `'verified'` \| `'needs_review'` |
| `verified_at` | timestamptz | null until checked |
| `verified_by` | text | `'auto'` or a user id |
| `notes` | text | LLM reasoning or human note |
| `replacement_url` | text | LLM-suggested new URL (only when old one is broken) |
| `original_url` | text | Preserved when `url` gets replaced |
| `http_status` | int | Last observed HTTP code |
| `created_at` / `updated_at` | timestamptz | |

Unique constraint: `(entity_type, entity_id, url_index)`.

### Compass stance sources

The existing `sources: string[]` column on the compass context row stays. The skill reads from it to populate `source_verifications` rows. When a human approves a replacement in the admin page, the array gets updated in place and the verification row flips to `verified`. The array remains the displayed truth; the verification table is the audit trail.

### Read-rank quotes

One URL per quote (to be confirmed against the read-rank schema during plan-writing). `url_index` is always 0.

### Backfill

One-time script run on deploy: walk every existing compass stance and read-rank quote, insert one `source_verifications` row per URL with `status = 'unverified'`. After that, service-layer writes keep the verification table in sync as new stances/quotes are created.

## Skill: `verify-sources`

**Location:** `.claude/skills/verify-sources.md` (project-scoped, lives with the repo)

**Invocation:** `/verify-sources` with optional args:
- `--limit N` — number of URLs to process (default 20)
- `--type compass|readrank|all` — default `all`
- `--dry-run` — don't write back to Supabase

**Per-run flow:**

1. Query `source_verifications` where `status = 'unverified'`, ordered by `created_at` asc, limit N. Join to pull the blurb/quote text and entity metadata (politician name, topic name, etc.).
2. Process sequentially. For each row, run the classification loop below.
3. Write back to Supabase immediately after each row (not batched) — crash mid-run shouldn't lose progress.
4. At end, print summary: `verified: N | needs_review: N | errors: N`, plus a short list of `needs_review` rows with one-line reasons.

**Per-URL classification:**

```
fetch URL with WebFetch
├── HTTP error / timeout / 4xx / 5xx
│   └── WebSearch for replacement using blurb + politician name
│       ├── found high-confidence candidate (reputable domain + verbatim support)
│       │   └── status=needs_review, replacement_url=<found>,
│       │       notes="broken; replacement candidate"
│       │       (NEVER auto-replace — human approves all replacements)
│       └── nothing good found
│           └── status=needs_review, notes="broken; no replacement found"
│
└── HTTP 200
    ├── page content clearly supports blurb (verbatim quote for readrank;
    │   clear policy statement for compass)
    │   AND domain is reputable (news org, .gov, official campaign, verified social)
    │   AND domain has been seen before in verified rows
    │   └── status=verified, notes=<short reason>
    │
    └── any ambiguity — paraphrase, unfamiliar domain, partial match,
        blog/Reddit/aggregator
        └── status=needs_review, notes=<what was ambiguous>
```

**Trusted-domain guardrail:** first time a domain appears, the URL goes to `needs_review` even if everything else passes. Once a human approves one URL from that domain, future URLs from the same domain are eligible for auto-verify. This prevents the LLM from confidently stamping sketchy sites as verified.

**Auto-verify threshold (all must hold):**
1. HTTP 200 and reputable domain
2. Page content contains verbatim quote (read-rank) or clearly supporting policy text (compass)
3. Replacement candidates never auto-apply — always `needs_review`
4. First-time-seen domain always → `needs_review`

**Idempotency:** re-running never reprocesses `verified` or `needs_review` rows. To re-check, manually set status back to `unverified`.

**Error handling:** any exception on a single row → log, set status to `needs_review` with `notes="skill error: <msg>"`, continue. Never crash the whole run.

## Admin Review Page

**Route:** `/admin/source-review` in the existing admin SPA at `accounts.empowered.vote`, gated by existing admin role check.

**Layout:** single-row focused queue view. Top of page shows `N remaining`.

Each row displays:

- **Context header:** entity badge (Compass / Read-Rank), politician name, topic name (compass) or quote excerpt (read-rank), link to underlying stance/quote
- **Blurb/quote** being verified, rendered prominently
- **Current URL** — clickable link, domain highlighted, plus last HTTP status code
- **LLM notes** — why this was flagged
- **Replacement candidate** (if present) — URL + domain, clickable preview
- **Actions:**
  - `Approve current URL` → status=verified, no URL change
  - `Approve replacement` → swap URL in source array, status=verified, preserve old in `original_url`
  - `Edit URL…` → inline input for custom URL, then approve
  - `Mark unfixable` → status stays `needs_review` with a flag; hidden from default queue
  - `Skip` → no change, next row
- **Keyboard shortcuts:** `1` approve current, `2` approve replacement, `e` edit, `s` skip

**Queue ordering:** oldest first by default. Filters: by entity type, by "has replacement candidate" (prioritize — skill did useful legwork here).

### Backend endpoints (ev-accounts)

All require admin role middleware.

- `GET /api/admin/source-verifications?status=needs_review&limit=50&type=...` — paginated queue
- `POST /api/admin/source-verifications/:id/approve` — body: `{ url?: string }` (omit to approve current URL; include to approve replacement or custom edit). On approval: update the underlying stance/quote source array if URL changed, set `status=verified`, `verified_by=<user id>`, preserve `original_url` if replaced.
- `POST /api/admin/source-verifications/:id/unfixable` — flag as unfixable (status stays `needs_review` with a sub-flag)

### Out of scope for v1

- Bulk actions
- Diff view or source array history
- Analytics / coverage dashboards

## Testing & Rollout

**Testing**

- Vitest integration tests on the three admin endpoints covering status transitions and source-array mutation.
- Skill is validated manually — LLM judgment isn't unit-testable. Validate by running `--dry-run --limit 5` on real data and spot-checking decisions.
- Backfill script has a dry-run mode that prints counts without writing.

**Rollout order**

1. Migration: create `source_verifications` table.
2. Backfill script (dry-run, then real).
3. Admin endpoints + admin SPA page.
4. Skill file.
5. First real runs: `--limit 5 --dry-run` → review → `--limit 5` real → review admin queue → scale up.

## Open Items for Plan-Writing

- Exact read-rank quote table and source column name (not confirmed during brainstorm).
- Whether the admin SPA has existing routing/auth conventions to match vs. scaffolding fresh.
- Whether the backfill should skip null/empty source URLs or flag them as `needs_review` with a special note.
