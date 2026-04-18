# Phase 120: Contested-Race Bio + Photo Authoring — Research

**Researched:** 2026-04-16
**Domain:** Data authoring + import (ev-accounts backend scripts, Supabase Storage CDN, ev-ui PoliticianProfile component)
**Confidence:** HIGH (all claims verified against live codebase — no external library research needed)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Candidate Scope**
- D-01: Start from `117-FEASIBILITY.md` as the primary candidate list for contested Monroe County races.
- D-02: Supplement with a DB audit (`audit-112-candidates.ts` or similar query) to catch candidates added since Phase 117. Cross-reference for complete contested-race coverage.
- D-03: No special priority ordering — all contested-race candidates equal priority. Work in whatever order makes sense for sourcing efficiency.

**Authoring Workflow**
- D-04: Use a one-shot import script (TypeScript) that reads a prepared data file with candidate bios + photo URLs and inserts/updates the DB directly. Small batch (~5-10) doesn't need the staging review workflow.
- D-05: Claude researches each candidate online, writes the bio, finds a photo URL, and prepares the import data. User reviews before import runs.
- D-06: Review format is a markdown table in a review doc (`.planning/phases/120-*/120-REVIEW-DATA.md` or similar). Columns: name, bio text, photo URL, source citation. User reads and approves/edits before the import script runs.
- D-07: Produce a bio authoring methodology doc during this phase. Captures sourcing approach, tone, length, and antipartisan constraints — reusable for Phase 124's 45-candidate batch.

**Photo Sourcing**
- D-08: Photo source priority: Official government photos > Campaign website > Social media profiles > News article photos.
- D-09: Claude downloads photos and uploads to Supabase Storage CDN: download from source → upload to politician headshots bucket → store CDN URL in `essentials.politician_images`. No hotlinking.
- D-10: For candidates with no findable photo, use the existing ev-ui missing-photo fallback. Don't block on photos.

**Bio Tone + Voice**
- D-11: Neutral factual tone. Dry, objective facts: role, background, reason for running.
- D-12: Length: ~120-180 characters, one sentence (carries from Phase 117 D-14).
- D-13: Party affiliation omitted from bios unless it is the candidate's actual professional/service role (e.g., "president of Monroe County Democrats"). Minimize party mentions — antipartisan principle.
- D-14: Bios extracted + lightly compressed from a single named source — never LLM-synthesized across multiple sources. Source URL stored alongside bio text (carries from Phase 117 D-07).
- D-15: Fallback for candidates with insufficient info: office-title-only bio ("Candidate for [office title].").

### Claude's Discretion
- Exact structure of the import data file (JSON vs CSV)
- Import script location and naming
- Whether to batch all candidates in one run or process individually
- Methodology doc format and location within `.planning/`
- Exact column for source citation storage (`bio_source_url` or equivalent)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONT-01 | Bios authored for ~5–10 candidates in contested Monroe County May 5 races (D-61 IN House, IN-9 US House, contested county offices) | `bio_text` column on `essentials.politicians` is TEXT (nullable), already in SELECT across all essentialsService query paths and included in API response. Phase 117 patterns define the single-source rule and 120-180 char bar. |
| CONT-02 | Headshots sourced and uploaded for contested-race candidates lacking photos (includes Todd Young) | `essentials.politician_images` table exists; `PoliticianProfile.jsx` reads `pol.images[]` as primary photo source (falls back to `pol.photo_origin_url`). Upload pipeline established in EV-Backend Python scripts. Phase 117 plan 06 defined the complete write path: upload to Storage → INSERT politician_images row (type='default') AND update photo_custom_url. |

</phase_requirements>

---

## Summary

Phase 120 is a **content-authoring phase** — no schema migrations needed, no new backend routes, no frontend feature flags. The data model was designed to accept bios and CDN-hosted photos from the beginning. The task is: (1) audit who needs content, (2) research and draft bio + source a photo for each, (3) get user review, (4) run an import script.

Two critical discoveries shape planning:

1. **`bio_text` is in the API response but is not rendered by `PoliticianProfile.jsx` today.** The column exists, is SELECTed, and flows through the API to the frontend — but `ev-ui/src/PoliticianProfile.jsx` has no JSX block that renders `pol.bio_text`. Phase 120's "bios live on profile pages" success criterion (CONT-01) requires adding a bio rendering block to `PoliticianProfile.jsx` and bumping ev-ui — otherwise bios written to the DB will never surface to users.

2. **Phase 117 was planned but not executed.** There are no Phase 117 SUMMARY files and the VALIDATION doc shows `status: draft`, `nyquist_compliant: false`. The `117-FEASIBILITY.md` referenced in Phase 120's D-01 does not exist on disk. Phase 120 must resolve its own candidate scope from scratch using `audit-112-candidates.ts` + a fresh DB query.

**Primary recommendation:** Plan three tracks: (A) candidate scoping audit, (B) content research + review doc, (C) import script + bio rendering patch. Tracks A and B are human-gate sequential (B waits for A result). Track C (import script author) can be done before user review. The bio rendering patch to `PoliticianProfile.jsx` must ship via the ev-ui auto-bump pipeline before verification can pass.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate scoping (who needs content) | Database (audit script) | Human review | `audit-112-candidates.ts` queries `race_candidates` for contested races |
| Bio authoring (research + draft) | Claude (research agent) | Human review gate | D-05: Claude drafts, user approves before import |
| Photo sourcing + download | Claude (Bash fetches) | Human fallback | D-08/D-09: Claude fetches, uploads to Supabase Storage |
| Supabase Storage upload | External CDN (Supabase, bucket `politician_photos`) | Import script | Existing Python pattern in EV-Backend/scripts/utils.py; can be ported to TS |
| DB write (bio_text, politician_images) | Database (import script) | — | INSERT/UPDATE `essentials.politicians` and `essentials.politician_images` |
| Bio rendering on profile pages | Browser / ev-ui (PoliticianProfile.jsx) | — | `pol.bio_text` must be rendered — currently NOT rendered (gap found in research) |
| ev-ui patch delivery | CDN / Static (npm + Render auto-deploy) | — | Standard ev-ui auto-bump pipeline (version bump → npm publish → consumer PRs) |

## Standard Stack

This is a codebase-internal content phase. No new libraries required.

| Library / Tool | Version | Purpose | Verified |
|---|---|---|---|
| `pg` (node-postgres) | existing | Direct SQL writes to essentials schema | [VERIFIED: all scripts/audit-112-*.ts use `pg.Pool` with `DATABASE_URL`] |
| `tsx` | existing | TS execution for import scripts | [VERIFIED: all ev-accounts scripts invoke via `npx tsx scripts/…`] |
| `supabase-js` (Python) | existing | Storage upload via `upload_photo_to_storage()` in `EV-Backend/scripts/utils.py` | [VERIFIED: `EV-Backend/scripts/upload_monroe_council_photos.py` L60-65] |
| `dotenv` | existing | `.env` loading | [VERIFIED: audit-112-candidates.ts L18-26] |
| ev-ui | `^0.4.x` | PoliticianProfile component — needs bio_text render patch | [VERIFIED: `essentials/src/pages/Profile.jsx` imports from `@empoweredvote/ev-ui`] |

**Installation:** None. Phase 120 reuses everything already installed.

## Architecture Patterns

### System Architecture Diagram

```
Candidate scope query                 Bio/photo authoring
(audit-112-candidates.ts)            (Claude research + REVIEW-DATA.md)
        │                                        │
        ▼                                        ▼
 race_candidates WHERE                  User approval gate
 politician_id IS NOT NULL              (human reads, edits, approves)
 AND contested races only                        │
        │                                        │
        └─────────────────┬───────────────────────┘
                          ▼
              Import script (TS one-shot)
              ┌──────────────────────────┐
              │  For each candidate:     │
              │  1. Download photo       │
              │  2. Upload → Supabase    │
              │     Storage (bucket:     │
              │     politician_photos)   │
              │  3. INSERT politician_   │
              │     images (type=default)│
              │  4. UPDATE politicians   │
              │     SET bio_text, …      │
              └──────────────────────────┘
                          │
                          ▼
              essentials.politician_images ←── Supabase CDN URL
              essentials.politicians.bio_text
                          │
                          ▼
              essentialsService.getPoliticianById()
              (bio_text in SELECT ✓, images[] in LATERAL subquery ✓)
                          │
                          ▼
              PoliticianProfile.jsx
              ┌──────────────────────────┐
              │  profileImageUrl:        │
              │    pol.images[type=      │
              │    'default'].url        │  ← works today
              │  bio_text: NOT RENDERED  │  ← gap — needs patch
              └──────────────────────────┘
                          │
                 ev-ui patch + auto-bump
                          │
                          ▼
              essentials.empowered.vote/politician/{slug}
              (bio visible on profile page)
```

### Recommended Project Structure

```
ev-accounts/backend/scripts/
├── import-120-contested-bios-photos.ts   # one-shot import (new)
└── verify-120-imports.sql                # SELECT-only verification (new)

.planning/phases/120-contested-race-bio-photo-authoring/
├── 120-REVIEW-DATA.md                    # bio + photo table for user review (new)
├── 120-BIO-METHODOLOGY.md                # reusable methodology doc (new, for Phase 124)
├── 120-RESEARCH.md                       # this file

ev-ui/src/
└── PoliticianProfile.jsx                 # add bio_text render block (modify)
```

### Pattern 1: Candidate Scoping Query (extends audit-112-candidates.ts)

**What:** Identify all linked (non-stub) contestants in contested Monroe County races, then filter to those missing `bio_text` or missing a `politician_images` row.

**When to use:** Wave 0 setup step — determines the exact candidate list for content work.

```typescript
// Source: [VERIFIED: ev-accounts/backend/scripts/audit-112-candidates.ts pattern]
// Query: linked candidates in contested races, missing bio or photo
SELECT
  p.id,
  p.full_name,
  p.slug,
  p.bio_text,
  pi.url AS cdn_photo_url,
  r.position_name,
  r.primary_party
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = p.id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND rc.politician_id IS NOT NULL      -- linked candidates only
  AND rc.candidate_status = 'active'
  -- Filter: contested races (more than 1 active candidate)
  AND r.id IN (
    SELECT race_id FROM essentials.race_candidates
    WHERE candidate_status = 'active'
    GROUP BY race_id
    HAVING COUNT(*) > 1
  )
  AND (p.bio_text IS NULL OR pi.url IS NULL)  -- missing content
ORDER BY r.position_name, p.last_name;
```

### Pattern 2: Photo Upload + politician_images INSERT

**What:** Download image from source URL, upload to Supabase Storage, INSERT into `essentials.politician_images` with `type='default'`, AND update `essentials.politicians.photo_custom_url`.

**When to use:** For every candidate who has a sourced photo.

**Critical:** PoliticianProfile.jsx reads `pol.images[type='default'].url` FIRST. A `photo_custom_url`-only update will NOT render on the profile page. Both the `politician_images` row AND `photo_custom_url` must be written.

```typescript
// Source: [VERIFIED: EV-Backend/scripts/utils.py upload_photo_to_storage() + 
//          ev-accounts Phase 117 Plan 06 must_have truths]
// Step 1: Upload to Storage
const storageClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const filePath = `monroe_2026/${slug}.jpg`;
await storageClient.storage.from('politician_photos').upload(filePath, imageBytes, {
  contentType: 'image/jpeg',
  upsert: true,
});
const { data: { publicUrl } } = storageClient.storage
  .from('politician_photos')
  .getPublicUrl(filePath);

// Step 2: INSERT politician_images row (primary render path)
await pool.query(
  `INSERT INTO essentials.politician_images
     (politician_id, url, type, photo_license)
   VALUES ($1, $2, 'default', 'sourced')
   ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url`,
  [politicianId, publicUrl]
);

// Step 3: UPDATE photo_custom_url (fallback path)
await pool.query(
  `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
  [publicUrl, politicianId]
);
```

### Pattern 3: bio_text UPDATE

**What:** Update `bio_text` (and optionally a source citation field) on an existing politician row.

**When to use:** For every candidate in scope.

```typescript
// Source: [VERIFIED: essentialsService.ts confirms bio_text is TEXT nullable on essentials.politicians]
await pool.query(
  `UPDATE essentials.politicians
   SET bio_text = $1, updated_at = now()
   WHERE id = $2`,
  [bioText, politicianId]
);
```

**Note on `bio_source_url`:** No `bio_source_url` column currently exists on `essentials.politicians` — neither in migrations nor in service code. [VERIFIED: `grep -rn "bio_source_url" ev-accounts/backend/` → zero results]. The planner must either: (a) add a migration to create this column, or (b) store source citations in a sidecar file only (e.g., the REVIEW-DATA.md). Option (b) is simpler for a ~5-10 candidate batch and avoids a migration. Phase 120 CONTEXT D-14 defers this as "planner's discretion."

### Pattern 4: bio_text Render in PoliticianProfile.jsx (GAP — needs new code)

**What:** Add a conditional render of `pol.bio_text` in the hero section of PoliticianProfile.jsx.

**When to use:** Required to satisfy CONT-01 ("bios live in the DB" is necessary but not sufficient — they must render on profile pages).

```jsx
// Source: [ASSUMED — modeled on the existing pol.office_description render pattern at L662]
// Location: PoliticianProfile.jsx, after the roleLine paragraph (~L661)
{pol.bio_text && (
  <p style={styles.bioText}>{pol.bio_text}</p>
)}
```

A corresponding style entry must be added to the component's `styles` object.

**Delivery:** ev-ui patch requires `npm version patch` + `git push origin main --follow-tags` to trigger the auto-bump pipeline. Essentials app will auto-deploy once the consumer PR is auto-merged.

### Anti-Patterns to Avoid

- **Hotlinking photos:** Never reference a photo URL from a campaign site or social media directly in `politician_images.url`. Source breaks before May 5 are likely. Always upload to Supabase Storage first.
- **photo_custom_url-only updates:** `COALESCE(p.photo_custom_url, p.photo_origin_url)` feeds `pol.photo_origin_url` in the API response — but `PoliticianProfile.jsx` only checks `pol.photo_origin_url` as a fallback AFTER `pol.images[]`. Without a `politician_images` row, the photo will not render.
- **LLM-synthesized bios:** Never write a bio by combining facts from multiple sources. One source, one sentence, extracted and lightly compressed. Source URL must be recorded.
- **Party framing in bios:** "Republican candidate" or "Democrat running for" violates the antipartisan principle. Party may only appear if it's the candidate's literal job title (e.g., "served as Monroe County GOP chair").
- **Skipping the user review gate:** D-05/D-06 require the REVIEW-DATA.md to be created and user-approved BEFORE the import script runs. Do not merge research + import into one plan.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Photo upload to Supabase | Custom HTTP multipart uploader | `supabase-js` `.storage.from().upload()` | Supabase SDK handles auth, upsert, MIME type, CDN URL resolution |
| Candidate list scoping | New discovery query from scratch | `audit-112-candidates.ts` pattern + contested-race filter | Existing query already handles election/race/candidate joins correctly |
| Image fetching from web | Complex fetch pipeline | Standard `fetch()` → `arrayBuffer()` → `Buffer` pattern | Used throughout codebase in `auditHeadshots.ts` |

**Key insight:** The entire import infrastructure was designed and documented in Phase 117 — photo upload pattern, idempotent insert pattern, bio text bar, source citation rule. Phase 120 reuses all of it without modification.

## Common Pitfalls

### Pitfall 1: bio_text Written but Not Visible on Profile Pages
**What goes wrong:** Bio text is imported to the DB and the import script reports success, but the profile page shows no bio.
**Why it happens:** `PoliticianProfile.jsx` does not currently render `pol.bio_text`. The column is in the API response but has no corresponding JSX.
**How to avoid:** Plan explicitly includes a `PoliticianProfile.jsx` patch and ev-ui version bump as a prerequisite to the "profiles show bios" acceptance criterion.
**Warning signs:** After import, visiting the profile page shows no bio text under the politician's name.

### Pitfall 2: Photo in photo_custom_url Only — Not Rendering on Profile
**What goes wrong:** Upload script sets `photo_custom_url` but doesn't insert a `politician_images` row. Profile shows initials placeholder.
**Why it happens:** `PoliticianProfile.jsx` L282-288 — `pol.images[]` is checked FIRST. If no `politician_images` row exists, the component falls back to `pol.photo_origin_url` (which is the COALESCE of `photo_custom_url` + `photo_origin_url`). A candidate with no pre-existing `photo_origin_url` will show the placeholder even if `photo_custom_url` is set.
**How to avoid:** Always write BOTH (a) INSERT `essentials.politician_images (type='default')` AND (b) UPDATE `essentials.politicians.photo_custom_url`. Verified pattern in Phase 117 Plan 06 must-have truths.
**Warning signs:** Import completes but candidate profile shows initials placeholder instead of headshot.

### Pitfall 3: 117-FEASIBILITY.md Does Not Exist
**What goes wrong:** Phase 120 CONTEXT D-01 says "start from 117-FEASIBILITY.md" but Phase 117 was never executed — the feasibility doc was never created.
**Why it happens:** Phase 117 was planned (7 plan files authored, all planning docs committed) but not executed. No SUMMARY files, VALIDATION is `status: draft`.
**How to avoid:** Wave 0 of Phase 120 must run a fresh DB audit to determine contested-race candidate scope. Use `audit-112-candidates.ts` + a contested-race filter query (candidates in races with ≥2 active contestants). Do not assume the feasibility doc exists.
**Warning signs:** `ls .planning/phases/117-*/117-FEASIBILITY*.md` returns nothing (confirmed missing).

### Pitfall 4: Hotlinked Photo URL Breaks Before May 5
**What goes wrong:** Candidate's photo is linked directly from their campaign site. Site goes down, image moves, or bandwidth limit hit in the week before the primary.
**Why it happens:** D-09 explicitly prohibits hotlinking — always re-host to Supabase Storage.
**How to avoid:** Every photo must be downloaded and re-uploaded. Script should verify the Supabase CDN URL is accessible after upload.
**Warning signs:** CDN URL starts with anything other than `https://kxsdzaojfaibhuzmclfq.supabase.co`.

### Pitfall 5: Bio Source Citation Field Doesn't Exist
**What goes wrong:** Plan assumes `bio_source_url` column exists on `essentials.politicians` and writes to it. Migration is needed.
**Why it happens:** Phase 117 CONTEXT D-14 deferred source citation column placement to the planner, but the column was never added.
**How to avoid:** Planner must decide: add a migration for `bio_source_url` column (adds migration 068), OR store source citations only in REVIEW-DATA.md (no migration needed). For a ~5-10 candidate batch, REVIEW-DATA.md-only is simpler. If planner adds migration, ensure it's idempotent (`ADD COLUMN IF NOT EXISTS`).
**Warning signs:** Import script fails with `column "bio_source_url" does not exist`.

### Pitfall 6: Cache TTL Masks Verification
**What goes wrong:** Immediately after import, the live API returns stale data — old bio/photo state.
**Why it happens:** `essentialsService.ts` has in-process cache (TTL ~900s on address and profile lookups). After DB update, the cache serves the pre-import response for up to 15 minutes.
**How to avoid:** After import, either bounce the Render deployment (kills in-process cache) or wait 15 minutes before running verification. Document this in the verification plan.

### Pitfall 7: Photo Content-Type Default is text/plain
**What goes wrong:** Image uploads to Supabase Storage but the CDN serves it with `Content-Type: text/plain`. Browser refuses to render it as `<img>`.
**Why it happens:** Supabase SDK's upload default is `text/plain` when no `content-type` option is provided.
**How to avoid:** Always pass explicit `{ contentType: 'image/jpeg' }` (or `image/png` for PNGs) to the upload call. This is documented in EV-Backend/scripts/utils.py L147-149.
**Warning signs:** Photo URL loads fine in the browser directly but shows as broken in `<img>` tag.

## Code Examples

### Scoping Query — Contested Races with Missing Content

```sql
-- Source: [VERIFIED: adapted from audit-112-candidates.ts L91-105 and audit-112-headshots.ts L63-83]
SELECT
  p.id AS politician_id,
  p.full_name,
  p.slug,
  p.bio_text IS NULL AS missing_bio,
  pi.url IS NULL AS missing_photo,
  r.position_name AS race,
  r.primary_party
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = p.id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND rc.politician_id IS NOT NULL
  AND rc.candidate_status = 'active'
  AND r.id IN (
    SELECT race_id FROM essentials.race_candidates
    WHERE candidate_status = 'active'
    GROUP BY race_id HAVING COUNT(*) > 1
  )
ORDER BY r.position_name, p.last_name;
```

### Import Script Core Loop (TypeScript)

```typescript
// Source: [VERIFIED: ev-accounts/backend/scripts/import-monroe-stub-candidates — Phase 117 PATTERNS.md L145-182]
// Pattern: transaction-per-candidate with pre-flight check

for (const candidate of importData) {
  // Pre-flight: skip if already has both bio and photo
  const { rows: [existing] } = await pool.query<{ bio_text: string | null; has_photo: boolean }>(
    `SELECT p.bio_text,
            (EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id AND pi.type = 'default')) AS has_photo
     FROM essentials.politicians p WHERE p.id = $1`,
    [candidate.politician_id]
  );
  if (existing?.bio_text && existing?.has_photo) {
    console.log(`[skip] ${candidate.full_name} already has bio and photo`);
    continue;
  }

  await pool.query('BEGIN');
  try {
    // Update bio
    if (!existing?.bio_text && candidate.bio_text) {
      await pool.query(
        `UPDATE essentials.politicians SET bio_text = $1, updated_at = now() WHERE id = $2`,
        [candidate.bio_text, candidate.politician_id]
      );
    }

    // Upload + link photo
    if (!existing?.has_photo && candidate.photo_source_url) {
      const imageBytes = await fetchImageBytes(candidate.photo_source_url);
      const filePath = `monroe_2026/${candidate.slug}.jpg`;
      await supabaseAdmin.storage.from('politician_photos').upload(filePath, imageBytes, {
        contentType: detectContentType(candidate.photo_source_url),
        upsert: true,
      });
      const { data: { publicUrl } } = supabaseAdmin.storage
        .from('politician_photos').getPublicUrl(filePath);

      await pool.query(
        `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')
         ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url`,
        [candidate.politician_id, publicUrl]
      );
      await pool.query(
        `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
        [publicUrl, candidate.politician_id]
      );
    }

    await pool.query('COMMIT');
    console.log(`[ok] ${candidate.full_name}`);
  } catch (err) {
    await pool.query('ROLLBACK');
    console.error(`[error] ${candidate.full_name}:`, err);
  }
}
```

### PoliticianProfile.jsx — bio_text Render Block (ev-ui patch)

```jsx
// Source: [ASSUMED — modeled on pol.office_description pattern at PoliticianProfile.jsx L662]
// Placement: after the roleLine <p> tag, before the Term/Years in Office section

{pol.bio_text && (
  <p style={styles.bioText}>{pol.bio_text}</p>
)}

// Corresponding style entry:
bioText: {
  fontSize: '0.875rem',
  color: colors.text.secondary,
  margin: '4px 0 0 0',
  lineHeight: 1.5,
},
```

### Bio Authoring Format (REVIEW-DATA.md table row)

```markdown
| Candidate Name | Bio Text (≤180 chars) | Photo URL (source) | Source Citation |
|---|---|---|---|
| Jane Smith | Monroe County teacher and community organizer running for Monroe County Council District 3. | https://campaign-site.com/photo.jpg | https://monroecounty.gov/council-filing-2026 |
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| EV-Backend Python scripts for all imports | ev-accounts TypeScript scripts for new imports | 2025 (Go→Express migration) | Phase 120 import script is TypeScript, not Python — Python path still valid for photo upload helper |
| Photo stored only in `photo_origin_url` | `photo_custom_url` + `politician_images` table (dual write) | Phase 117 design (April 2026) | Both fields must be written; `politician_images` is the primary render path |
| Single `inform.politicians` schema | `essentials.politicians` is canonical source of truth | Phase 35 deduplication | All Phase 120 writes target `essentials.*` tables only |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `bio_text` column exists on `essentials.politicians` without a migration | Standard Stack, Code Examples | Low — verified across multiple SELECT queries in essentialsService.ts, confirmed in migration 033 (was included in CREATE TABLE or early ALTER) |
| A2 | `politician_images` table has a unique constraint on `(politician_id, type)` allowing the ON CONFLICT clause | Code Examples | Medium — if no unique constraint, ON CONFLICT will fail; planner should verify or use DELETE+INSERT pattern |
| A3 | `photo_custom_url` column exists on `essentials.politicians` | Code Examples | Low — confirmed by COALESCE usage across essentialsService.ts at 6+ locations |
| A4 | bio_text is not currently rendered in PoliticianProfile.jsx | Common Pitfalls, Architectural Map | High risk if wrong (would change scope significantly) — verified by grep across ev-ui/src/ returning zero results |
| A5 | Supabase Storage bucket is named `politician_photos` (not `politician-headshots`) | Code Examples | Low — confirmed in EV-Backend/scripts/utils.py L139 and upload_monroe_council_photos.py L23 |

## Open Questions

1. **Does `politician_images` have a unique constraint on `(politician_id, type)`?**
   - What we know: The ON CONFLICT clause in Phase 117 PATTERNS.md assumes it does; Phase 117 Plan 06 uses this pattern.
   - What's unclear: No explicit constraint definition was found in reviewed migrations.
   - Recommendation: Planner should add a verification step — if no constraint, use `DELETE FROM … WHERE politician_id=$1 AND type='default'` before INSERT.

2. **Should bio_source_url be persisted in DB or REVIEW-DATA.md only?**
   - What we know: No `bio_source_url` column exists; Phase 120 CONTEXT D-14 leaves this to planner discretion.
   - What's unclear: Phase 124 (45-candidate batch) may want DB-stored source citations for traceability.
   - Recommendation: For Phase 120's ~5-10 candidates, REVIEW-DATA.md-only is sufficient. Add a `bio_source_url` column migration as Wave 0 if the planner wants it in the DB for Phase 124 reuse.

3. **What is the exact contested Monroe County race list?**
   - What we know: The CONTEXT names D-61 IN House, IN-9 US House, and contested county offices. Todd Young is explicitly named for photo sourcing (CONT-02).
   - What's unclear: Exact number (estimated 5-10) — depends on DB state. Phase 117 was never executed, so exact candidate count is unknown.
   - Recommendation: Wave 0 plan runs the contested-race scoping query to establish the exact list before any content work begins.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| DATABASE_URL | DB writes | Exists in `.env` | — | — |
| SUPABASE_URL | Storage upload | Exists in `.env` | — | — |
| SUPABASE_SERVICE_ROLE_KEY | Storage upload (requires service role) | Exists in `.env` | — | — |
| `supabase-js` (Python SDK) | Photo upload via Python helper | Installed in EV-Backend | — | Port to TypeScript supabase-js |
| `supabase-js` (TypeScript) | If TS upload is used | `@supabase/supabase-js` in ev-accounts | — | Use Python helper |
| `tsx` | Running TS import scripts | Available (all scripts use it) | — | — |
| `psql` | Running verify SQL | [ASSUMED installed] | — | Use pg pool from Node |

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Vitest (ev-accounts/backend) + SQL verification scripts |
| Config file | `ev-accounts/backend/vitest.config.ts` |
| Quick run command | `cd ev-accounts/backend && npm run typecheck` |
| Full suite command | `cd ev-accounts/backend && npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CONT-01 | bio_text exists in DB for all contested-race candidates | SQL verification | `psql $DATABASE_URL -f ev-accounts/backend/scripts/verify-120-imports.sql` | ❌ Wave 0 |
| CONT-01 | bio_text renders on profile page | Manual smoke | Visit each slug in browser | — |
| CONT-02 | politician_images row exists for each candidate | SQL verification | included in verify-120-imports.sql | ❌ Wave 0 |
| CONT-02 | Photo renders on profile page (not placeholder) | Manual smoke | Visit each slug in browser | — |

### Sampling Rate

- **Per task commit:** `cd ev-accounts/backend && npm run typecheck`
- **Per wave merge:** `cd ev-accounts/backend && npm test`
- **Phase gate:** Full suite green + manual smoke of all imported slugs before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `ev-accounts/backend/scripts/verify-120-imports.sql` — covers CONT-01, CONT-02 (SELECT-only; checks bio_text not null, politician_images row present, CDN URL format)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | N/A — this is a CLI import script, not an API endpoint |
| V3 Session Management | No | N/A |
| V4 Access Control | No | Import script runs with service role key directly |
| V5 Input Validation | Yes (partial) | Bio text is ≤180 chars (content rule, not schema constraint) — import script should validate length before write |
| V6 Cryptography | No | N/A |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Bio text containing HTML/JS injected into profile page | Tampering | Render bio_text as text node (`{pol.bio_text}`), not `dangerouslySetInnerHTML` — React default escaping applies |
| Photo fetched from attacker-controlled URL | Spoofing/Tampering | Photo sourcing is human-reviewed before import (D-05/D-06 gate) — only approved URLs reach the import script |
| Service role key exposed in import script output | Information Disclosure | Key comes from `.env`; script never prints env vars; standard practice |

## Sources

### Primary (HIGH confidence)
- `ev-accounts/backend/src/lib/essentialsService.ts` — bio_text, photo_custom_url, politician_images SELECT patterns
- `ev-ui/src/PoliticianProfile.jsx` — profileImageUrl resolution logic (L282-288), bio_text not rendered (confirmed)
- `ev-accounts/backend/scripts/audit-112-candidates.ts` — candidate scoping pattern
- `ev-accounts/backend/scripts/audit-112-headshots.ts` — photo coverage audit pattern
- `EV-Backend/scripts/upload_monroe_council_photos.py` — Storage upload pattern
- `EV-Backend/scripts/utils.py` L139-171 — `upload_photo_to_storage()` canonical implementation
- `.planning/phases/117-candidate-stub-resolution-data-import/117-PATTERNS.md` — import script patterns, transaction-per-candidate, dual photo write
- `.planning/phases/117-candidate-stub-resolution-data-import/117-06-PLAN.md` — must-have truths for photo write path

### Secondary (MEDIUM confidence)
- `.planning/phases/117-candidate-stub-resolution-data-import/117-VALIDATION.md` — confirmed `status: draft`, `nyquist_compliant: false` → Phase 117 not executed
- Git log — confirmed no Phase 117 execution commits

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools verified against codebase
- Architecture: HIGH — render path verified in PoliticianProfile.jsx
- Pitfalls: HIGH — most derived from Phase 117 PATTERNS.md (executed against same codebase)
- Bio_text not rendered gap: HIGH — confirmed by grep across ev-ui/src/

**Research date:** 2026-04-16
**Valid until:** 2026-05-05 (primary day — stable DB schema, no anticipated changes)
