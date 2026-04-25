# Phase 123: Photo Coverage Expansion - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 3 (1 audit run/adapt, 1 new import script, 1 review-data doc)
**Analogs found:** 2 / 2 (code files — review-data doc is markdown, no code analog needed)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `ev-accounts/backend/scripts/audit-123-photo-gap.ts` (or re-run `audit-112-headshots.ts`) | script / audit | batch read (DB-only) | `ev-accounts/backend/scripts/audit-112-headshots.ts` | exact |
| `ev-accounts/backend/scripts/import-123-photo-expansion.ts` | script / importer | batch write + file I/O (HTTP fetch + Storage upload + SQL dual-write) | `ev-accounts/backend/scripts/import-120-contested-bios-photos.ts` | exact (photo-only subset) |
| `ev-accounts/backend/scripts/import-123-data.json` | data | static input | `ev-accounts/backend/scripts/import-120-data.json` (implied sibling) | exact |
| `.planning/phases/123-photo-coverage-expansion/123-REVIEW-DATA.md` | doc / review table | human-in-the-loop approval | `.planning/phases/120-contested-race-bio-photo-authoring/120-REVIEW-DATA.md` (implied) | n/a (doc) |

## Pattern Assignments

### `audit-123-photo-gap.ts` (script, batch read)

**Analog:** `ev-accounts/backend/scripts/audit-112-headshots.ts`

**Header / dotenv / pg.Pool init** (lines 1-30):
```typescript
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');
```

**Photo-gap core query** (lines 63-83) — adapt to drop the May-5-2026 IN filter and broaden to all linked candidates:
```sql
SELECT
  rc.full_name,
  rc.politician_id,
  CASE WHEN rc.politician_id IS NOT NULL THEN 'linked' ELSE 'stub' END AS is_linked,
  pi.url AS cdn_photo,
  rc.photo_url AS stub_photo,
  CASE
    WHEN pi.url IS NOT NULL THEN 'cdn'
    WHEN rc.photo_url IS NOT NULL THEN 'local'
    ELSE 'none'
  END AS photo_source
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = rc.politician_id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'   -- REMOVE / BROADEN for 123
  AND rc.candidate_status = 'active'
ORDER BY rc.full_name
```

For Phase 123, filter predicate becomes: `rc.politician_id IS NOT NULL AND pi.url IS NULL` (all linked candidates missing `type='default'` row). Drop the election-date/state restriction unless scoping is explicitly desired.

**CSV output pattern** (lines 101-114):
```typescript
process.stdout.write('full_name,politician_id,is_linked,photo_source,cdn_url,stub_photo_url\n');
for (const row of rows) {
  const escapedName = `"${row.full_name.replace(/"/g, '""')}"`;
  const politicianId = row.politician_id ?? '';
  process.stdout.write(`${escapedName},${politicianId},${row.is_linked},${row.photo_source},${cdnUrl},${stubPhotoUrl}\n`);
}
```

**Error/exit pattern** (lines 122-126):
```typescript
main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
```

---

### `import-123-photo-expansion.ts` (script, batch write + file I/O)

**Analog:** `ev-accounts/backend/scripts/import-120-contested-bios-photos.ts`

**Strip all bio-related logic** — Phase 123 is photo-only (D-09). Keep the photo-upload + dual-write machinery verbatim.

**Imports + client init** (lines 17-50):
```typescript
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';
import pg from 'pg';
import { createClient } from '@supabase/supabase-js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const isCommit = process.argv.includes('--commit');
const isDryRun = !isCommit;

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

const BUCKET = 'politician_photos';
```

**Simplified CandidateImport type** (adapt lines 56-62) — drop `bio_text`, keep ID/name/slug/photo:
```typescript
interface CandidateImport {
  politician_id: string;
  full_name: string;
  slug: string;
  photo_source_url: string | null;   // null => NO_PHOTO (skip; rely on initials fallback)
}
```

**UUID validator + image helpers** (lines 68-97) — copy verbatim:
```typescript
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function isUuid(value: string): boolean { return UUID_RE.test(value); }

async function fetchImageBytes(url: string): Promise<Buffer> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status} fetching image: ${url}`);
  const arrayBuffer = await response.arrayBuffer();
  return Buffer.from(arrayBuffer);
}

function detectExt(url: string): { ext: string; contentType: string } {
  const match = url.toLowerCase().match(/\.(png|gif|webp|jpg|jpeg)(?:\?|$)/);
  const raw = match?.[1] ?? 'jpg';
  const ext = raw === 'jpeg' ? 'jpg' : raw;
  const contentType =
    ext === 'png' ? 'image/png'
    : ext === 'gif' ? 'image/gif'
    : ext === 'webp' ? 'image/webp'
    : 'image/jpeg';
  return { ext, contentType };
}
```

**Pre-flight unique-constraint detection** (lines 103-118) — copy verbatim; drives ON CONFLICT vs DELETE+INSERT branch.

**Core per-candidate transaction with dual-write** (lines 207-282) — this is the load-bearing excerpt:
```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');

  if (needsPhoto && candidate.photo_source_url) {
    const imageBytes = await fetchImageBytes(candidate.photo_source_url);
    const { ext, contentType } = detectExt(candidate.photo_source_url);
    const filePath = `phase_123/${candidate.slug}.${ext}`;   // CHANGE prefix for 123

    // NEVER omit contentType -- Pitfall 7
    const { error: uploadError } = await supabaseAdmin.storage
      .from(BUCKET)
      .upload(filePath, imageBytes, { contentType, upsert: true });
    if (uploadError) throw new Error(`Storage upload failed: ${uploadError.message}`);

    const { data: { publicUrl } } = supabaseAdmin.storage.from(BUCKET).getPublicUrl(filePath);

    // Primary render path -- politician_images row
    if (hasUniqueConstraint) {
      await client.query(
        `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')
         ON CONFLICT (politician_id, type) DO UPDATE SET url = EXCLUDED.url`,
        [candidate.politician_id, publicUrl],
      );
    } else {
      await client.query(
        `DELETE FROM essentials.politician_images
         WHERE politician_id = $1 AND type = 'default'`,
        [candidate.politician_id],
      );
      await client.query(
        `INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
         VALUES ($1, $2, 'default', 'sourced')`,
        [candidate.politician_id, publicUrl],
      );
    }

    // Fallback render path -- photo_custom_url (Pitfall 2)
    await client.query(
      `UPDATE essentials.politicians SET photo_custom_url = $1 WHERE id = $2`,
      [publicUrl, candidate.politician_id],
    );
  }

  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  console.error(`[error] ${candidate.full_name}:`, (err as Error).message);
  stats.errors++;
} finally {
  client.release();
}
```

**Pre-flight existence check** (lines 162-181) — simplify for photo-only: only query `has_photo`, skip `bio_text`/`slug` reads unless slug is still needed to build the upload path.

**Validation pattern** (lines 140-159) — keep UUID + slug checks; drop bio length check.

**Main driver + stats reporting** (lines 314-357) — copy structure, reduce Stats to `{ processed, photosUploaded, skipped, errors }`:
```typescript
const dataPath = path.resolve(__dirname, 'import-123-data.json');
if (!fs.existsSync(dataPath)) throw new Error(`Data file not found: ${dataPath}`);
const importData: CandidateImport[] = JSON.parse(fs.readFileSync(dataPath, 'utf-8'));
console.log(`Loaded ${importData.length} candidate(s) from import-123-data.json`);

const hasUniqueConstraint = await detectUniqueConstraint();
for (const candidate of importData) {
  await processCandidate(candidate, hasUniqueConstraint, stats);
}
console.log(`[done] ${stats.processed} processed, ${stats.photosUploaded} uploaded, ${stats.skipped} skipped, ${stats.errors} errors`);
if (isDryRun) console.log('[DRY RUN] No changes written to DB. Rerun with --commit to apply.');
await pool.end();
```

**NO_PHOTO handling** (NEW — not in analog): when `photo_source_url` is null per D-04, log `[skip] ${name} NO_PHOTO` and increment `stats.skipped`. No DB write; frontend falls back to initials automatically (see CONTEXT Integration Points).

---

## Shared Patterns

### `--commit` flag convention
**Source:** `import-120-contested-bios-photos.ts` line 33-34
**Apply to:** `import-123-photo-expansion.ts`
```typescript
const isCommit = process.argv.includes('--commit');
const isDryRun = !isCommit;
```
Default is dry-run; writes only occur under `--commit`. Audit script uses the inverse `--dry-run` flag (stdout CSV is the default).

### dotenv + pg.Pool bootstrap
**Source:** Both analogs (audit-112 lines 20-29, import-120 lines 17-43)
**Apply to:** Both new scripts
```typescript
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
```

### Transaction-per-candidate
**Source:** `import-120-contested-bios-photos.ts` lines 208-307
**Apply to:** `import-123-photo-expansion.ts`
Each candidate gets its own `BEGIN` / `COMMIT` / `ROLLBACK` on a dedicated client from the pool. A failed upload or SQL error isolates the failure to that candidate — the loop continues.

### Dual photo write (Pitfall 2)
**Source:** `import-120-contested-bios-photos.ts` lines 250-280
**Apply to:** `import-123-photo-expansion.ts`
Every successful upload MUST write BOTH: (a) `essentials.politician_images` row (`type='default'`, `photo_license='sourced'`) via ON CONFLICT upsert or DELETE+INSERT, AND (b) `essentials.politicians.photo_custom_url` UPDATE.

### contentType on Supabase upload (Pitfall 7)
**Source:** `import-120-contested-bios-photos.ts` lines 236-241
**Apply to:** `import-123-photo-expansion.ts`
Always pass `contentType` in the Supabase `.upload()` options. Omitting it causes browsers to refuse to render the `<img>`. Use `detectExt(url)` to derive it from the source URL extension.

### Unique-constraint auto-detect → upsert vs delete+insert
**Source:** `import-120-contested-bios-photos.ts` lines 103-118, 251-272
**Apply to:** `import-123-photo-expansion.ts`
Query `pg_constraint` once at startup; branch per-candidate INSERT logic based on whether a 2-column unique constraint exists on `essentials.politician_images`.

### Fatal-error tail
**Source:** Both analogs (audit-112 lines 122-126, import-120 lines 359-363)
**Apply to:** Both new scripts
```typescript
main().catch((err) => {
  console.error('Fatal error:', (err as Error).message);
  pool.end().catch(() => undefined);
  process.exit(1);
});
```

## No Analog Found

None — both code files have exact analogs in `ev-accounts/backend/scripts/`. The REVIEW-DATA markdown doc follows a prior-phase doc convention (Phase 120) and is not a code file.

## Metadata

**Analog search scope:** `ev-accounts/backend/scripts/` (CONTEXT.md explicitly named both analogs)
**Files read:** 3 (CONTEXT.md, audit-112-headshots.ts, import-120-contested-bios-photos.ts)
**Pattern extraction date:** 2026-04-17
