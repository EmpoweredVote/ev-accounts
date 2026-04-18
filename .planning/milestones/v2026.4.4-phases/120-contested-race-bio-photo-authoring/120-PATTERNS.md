# Phase 120: Contested-Race Bio + Photo Authoring — Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 5 new/modified files
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `ev-accounts/backend/scripts/import-120-contested-bios-photos.ts` | script (import) | batch / file-I/O | `ev-accounts/backend/scripts/importElectionData.ts` | role-match |
| `ev-accounts/backend/scripts/verify-120-imports.sql` | script (verification) | CRUD (read-only) | `ev-accounts/backend/scripts/audit-112-headshots.ts` | role-match |
| `ev-ui/src/PoliticianProfile.jsx` | component | request-response | `ev-ui/src/PoliticianProfile.jsx` (self — additive patch) | exact |
| `.planning/phases/120-contested-race-bio-photo-authoring/120-REVIEW-DATA.md` | planning doc | n/a | `.planning/phases/109-per-meeting-body-tagging/109-REVIEW.md` (pattern only) | partial |
| `.planning/phases/120-contested-race-bio-photo-authoring/120-BIO-METHODOLOGY.md` | planning doc | n/a | n/a — first methodology doc of this type | none |

---

## Pattern Assignments

### `ev-accounts/backend/scripts/import-120-contested-bios-photos.ts` (script, batch)

**Analog:** `ev-accounts/backend/scripts/importElectionData.ts`

**Imports pattern** (`importElectionData.ts` lines 35-50):
```typescript
import dotenv from 'dotenv';
import pg from 'pg';
import path from 'path';
import { fileURLToPath } from 'url';
import { createClient } from '@supabase/supabase-js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});
```

**Supabase admin client init** (add after pool; pattern from `EV-Backend/scripts/utils.py` L139):
```typescript
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);
const BUCKET = 'politician_photos';
```

**Dry-run / commit flag pattern** (`importElectionData.ts` lines 112-113):
```typescript
const isCommit = process.argv.includes('--commit');
const isDryRun = !isCommit;
```

**Transaction-per-candidate core loop** (RESEARCH.md Code Examples, "Import Script Core Loop"):
```typescript
for (const candidate of importData) {
  // Pre-flight: skip if already has both bio and photo
  const { rows: [existing] } = await pool.query<{ bio_text: string | null; has_photo: boolean }>(
    `SELECT p.bio_text,
            (EXISTS (SELECT 1 FROM essentials.politician_images pi
                     WHERE pi.politician_id = p.id AND pi.type = 'default')) AS has_photo
     FROM essentials.politicians p WHERE p.id = $1`,
    [candidate.politician_id]
  );
  if (existing?.bio_text && existing?.has_photo) {
    console.log(`[skip] ${candidate.full_name} already has bio and photo`);
    continue;
  }

  await pool.query('BEGIN');
  try {
    // 1. Update bio_text
    if (!existing?.bio_text && candidate.bio_text) {
      await pool.query(
        `UPDATE essentials.politicians SET bio_text = $1, updated_at = now() WHERE id = $2`,
        [candidate.bio_text, candidate.politician_id]
      );
    }

    // 2. Download photo → upload to Storage → INSERT politician_images + UPDATE photo_custom_url
    if (!existing?.has_photo && candidate.photo_source_url) {
      const imageBytes = await fetchImageBytes(candidate.photo_source_url);
      const ext = candidate.photo_source_url.match(/\.(png|gif|webp)$/i) ? RegExp.$1 : 'jpg';
      const filePath = `monroe_2026/${candidate.slug}.${ext}`;
      await supabaseAdmin.storage.from(BUCKET).upload(filePath, imageBytes, {
        contentType: ext === 'png' ? 'image/png' : 'image/jpeg',  // NEVER omit — see Pitfall 7
        upsert: true,
      });
      const { data: { publicUrl } } = supabaseAdmin.storage.from(BUCKET).getPublicUrl(filePath);

      // INSERT politician_images (primary render path — required for PoliticianProfile to show photo)
      await pool.query(
        `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')
         ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url`,
        [candidate.politician_id, publicUrl]
      );
      // Also update photo_custom_url (fallback render path)
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

**Image fetch helper** (pattern from `audit-112-headshots.ts`; fetch approach from RESEARCH.md):
```typescript
async function fetchImageBytes(url: string): Promise<Buffer> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status} fetching image: ${url}`);
  const arrayBuffer = await response.arrayBuffer();
  return Buffer.from(arrayBuffer);
}
```

**Main entry point pattern** (`importElectionData.ts` lines 939-970):
```typescript
async function main(): Promise<void> {
  console.log('import-120-contested-bios-photos.ts');
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no DB writes)' : 'COMMIT'}`);
  // ... load JSON data file, call import loop
  await pool.end();
}

main().catch(err => {
  console.error('Fatal error:', (err as Error).message);
  pool.end().catch(() => undefined);
  process.exit(1);
});
```

**Input data file shape** (JSON array per CONTEXT.md D-04 "planner's discretion"):
```typescript
interface CandidateImport {
  politician_id: string;   // UUID from essentials.politicians
  full_name: string;
  slug: string;
  bio_text: string;        // ≤180 chars, single sentence, sourced from one URL
  photo_source_url: string | null;  // null = no photo found (D-10)
}
```

**Bio length validation** (RESEARCH.md ASVS V5 note):
```typescript
if (candidate.bio_text.length > 180) {
  console.error(`[error] ${candidate.full_name} bio too long: ${candidate.bio_text.length} chars`);
  continue;
}
```

---

### `ev-accounts/backend/scripts/verify-120-imports.sql` (verification, read-only)

**Analog:** `ev-accounts/backend/scripts/audit-112-headshots.ts` (SQL query patterns)

**Bio coverage check** (adapted from `audit-112-headshots.ts` lines 63-83):
```sql
-- Verify bio_text and politician_images for all contested-race candidates
SELECT
  p.full_name,
  p.slug,
  p.bio_text IS NOT NULL                                AS has_bio,
  length(p.bio_text)                                    AS bio_length,
  pi.url IS NOT NULL                                    AS has_cdn_photo,
  pi.url                                                AS cdn_url,
  -- CDN URL format check (must be on Supabase project)
  pi.url LIKE 'https://kxsdzaojfaibhuzmclfq.supabase.co%' AS cdn_url_valid,
  r.position_name                                       AS race
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

---

### `ev-ui/src/PoliticianProfile.jsx` — bio_text render patch (component, additive)

**Analog:** Self — existing `pol.office_description` render pattern at line 662-664

**Insert point:** After the `pol.office_description` conditional block (line 664), before the Term/Years in Office section (line 666)

**Existing pattern to copy** (`PoliticianProfile.jsx` lines 662-664):
```jsx
{pol.office_description && (
  <p style={styles.officeDesc}>{pol.office_description}</p>
)}
```

**New bio_text block (copy the pattern):**
```jsx
{pol.bio_text && (
  <p style={styles.bioText}>{pol.bio_text}</p>
)}
```

**Existing `officeDesc` style to copy for new `bioText` style** (`PoliticianProfile.jsx` lines 505-512):
```jsx
officeDesc: {
  fontFamily: fonts.primary,
  fontSize: fontSizes.base,
  color: '#6A7282',
  margin: 0,
  marginBottom: spacing[3],
  lineHeight: 1.5,
},
```

**New `bioText` style** (add to `styles` object — slightly smaller to differentiate from officeDesc):
```jsx
bioText: {
  fontFamily: fonts.primary,
  fontSize: fontSizes.sm,
  color: '#6A7282',
  margin: 0,
  marginTop: spacing[1],
  marginBottom: spacing[3],
  lineHeight: 1.5,
},
```

**Delivery:** After patch, run `npm version patch && git push origin main --follow-tags` from `ev-ui/` to trigger auto-bump pipeline.

---

### `.planning/phases/120-contested-race-bio-photo-authoring/120-REVIEW-DATA.md` (planning doc)

**Analog:** No direct code analog — this is a human-readable review gate document.

**Required columns** (CONTEXT.md D-06):
```markdown
| Candidate Name | Politician ID | Bio Text (≤180 chars) | Photo Source URL | Source Citation URL | Status |
|---|---|---|---|---|---|
| Jane Smith | uuid-here | Monroe County educator running for County Council District 3. | https://... | https://... | PENDING |
```

**Status values:** `PENDING` (awaiting review), `APPROVED`, `EDIT` (needs revision), `NO_PHOTO` (approved bio, no photo found)

---

### `.planning/phases/120-contested-race-bio-photo-authoring/120-BIO-METHODOLOGY.md` (planning doc)

**Analog:** None — first bio authoring methodology doc in this codebase.

**Required sections** (from CONTEXT.md D-07 and RESEARCH.md bio tone decisions):
- Bio sourcing hierarchy (single named source rule from D-14)
- Tone and voice spec (~120-180 chars, dry factual, one sentence from D-11/D-12)
- Antipartisan constraint (party omitted unless it is the candidate's literal job title, D-13)
- Fallback for insufficient info ("Candidate for [office title]." from D-15)
- Photo source priority (D-08)
- Photo upload checklist (download → upload to `politician_photos` bucket → INSERT `politician_images` → UPDATE `photo_custom_url`)

---

## Shared Patterns

### DB Pool Initialization
**Source:** `ev-accounts/backend/scripts/audit-112-candidates.ts` lines 18-27
**Apply to:** `import-120-contested-bios-photos.ts`
```typescript
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
```

### Transaction Pattern (BEGIN / COMMIT / ROLLBACK)
**Source:** `ev-accounts/backend/scripts/importElectionData.ts` lines 903-933
**Apply to:** `import-120-contested-bios-photos.ts` (per-candidate transaction)
```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  // ... writes
  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  console.error('[ROLLBACK]', err);
  throw err;
} finally {
  client.release();
}
```
Note: The import script wraps each candidate individually (not all candidates in one transaction) to avoid a single bad candidate blocking the batch.

### Supabase Storage Upload Pattern
**Source:** `EV-Backend/scripts/upload_monroe_council_photos.py` lines 58-65
**Apply to:** `import-120-contested-bios-photos.ts`
```python
# Python reference — port to TypeScript:
client.storage.from_(BUCKET).upload(
    storage_path,
    image_bytes,
    {"content-type": "image/png", "upsert": "true"},  # ALWAYS include content-type
)
cdn_url = client.storage.from_(BUCKET).get_public_url(storage_path)
```
TypeScript equivalent (RESEARCH.md Pattern 2):
```typescript
await supabaseAdmin.storage.from('politician_photos').upload(filePath, imageBytes, {
  contentType: 'image/jpeg',  // or 'image/png' — NEVER omit (Pitfall 7)
  upsert: true,
});
const { data: { publicUrl } } = supabaseAdmin.storage
  .from('politician_photos').getPublicUrl(filePath);
```

### Scoping Query — Contested Races with Missing Content
**Source:** `ev-accounts/backend/scripts/audit-112-headshots.ts` lines 63-83 (adapted)
**Apply to:** Wave 0 scope audit in `import-120-contested-bios-photos.ts` pre-flight
```sql
SELECT
  p.id AS politician_id,
  p.full_name,
  p.slug,
  p.bio_text IS NULL AS missing_bio,
  pi.url IS NULL AS missing_photo,
  r.position_name AS race
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

### Fatal Error + Pool Cleanup Pattern
**Source:** `ev-accounts/backend/scripts/audit-112-candidates.ts` lines 150-154
**Apply to:** `import-120-contested-bios-photos.ts`
```typescript
main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
```

---

## Critical Anti-Patterns (from RESEARCH.md)

These are documented in RESEARCH.md and must be avoided in planning and implementation:

| Anti-Pattern | Where It Would Break | Correct Pattern |
|---|---|---|
| `photo_custom_url`-only update, no `politician_images` row | `PoliticianProfile.jsx` L282-288 — `pol.images[]` checked first | ALWAYS write both: INSERT `politician_images (type='default')` AND UPDATE `photo_custom_url` |
| Omitting `contentType` on Supabase Storage upload | CDN serves image as `text/plain`; browser `<img>` refuses to render | Always pass `{ contentType: 'image/jpeg' }` or `image/png` |
| Hotlinking photo URLs | Campaign site goes down before May 5 | Download → re-upload to `politician_photos` bucket, store CDN URL only |
| Writing `bio_text` without ev-ui patch | Bio in DB, not visible on profile page | Ship `PoliticianProfile.jsx` bio_text render patch via ev-ui auto-bump first |
| Assuming `117-FEASIBILITY.md` exists | File does not exist (Phase 117 never executed) | Run fresh DB scoping query using `audit-112-candidates.ts` pattern |
| Assuming `bio_source_url` column exists | Import script fails: `column "bio_source_url" does not exist` | Store source citations in REVIEW-DATA.md only (no migration needed for ~5-10 candidates) |

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `120-BIO-METHODOLOGY.md` | planning doc | n/a | No prior bio authoring methodology doc exists in this codebase — first of its kind |

---

## Metadata

**Analog search scope:** `ev-accounts/backend/scripts/`, `ev-ui/src/`, `EV-Backend/scripts/`
**Files scanned:** `audit-112-candidates.ts`, `audit-112-headshots.ts`, `importElectionData.ts`, `upload_monroe_council_photos.py`, `PoliticianProfile.jsx`
**Pattern extraction date:** 2026-04-16
