---
phase: 123-photo-coverage-expansion
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - ev-accounts/backend/scripts/import-123-photo-expansion.ts
  - ev-accounts/backend/scripts/import-123-data.json
findings:
  critical: 0
  warning: 2
  info: 5
  total: 7
status: issues_found
---

# Phase 123: Code Review Report

**Reviewed:** 2026-04-17
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the Phase 123 photo import script and its data sidecar. The script is structurally sound — the dry-run/commit flag, per-candidate transaction with ROLLBACK, dual write (politician_images + photo_custom_url), and Storage upsert are all correctly implemented. The `detectUniqueConstraint` pre-flight check and slug-derivation fallback follow established patterns.

Two warnings are present: the unique constraint detection query is insufficiently specific and could silently select the wrong ON CONFLICT target, and the `withPhotos` filtered variable is computed but never used as the loop scope. Five info items cover JSON parse error handling, extension detection, slug write documentation accuracy, and two garbled slugs in the data file for politicians with accented names.

No critical issues. All 54 current data records have `photo_source_url: null`, so the script is a no-op on commit until URLs are populated — this appears intentional for the current phase state.

## Warnings

### WR-01: `detectUniqueConstraint` matches any 2-column unique constraint, not specifically `(politician_id, type)`

**File:** `ev-accounts/backend/scripts/import-123-photo-expansion.ts:131-144`
**Issue:** The query checks `array_length(conkey, 1) = 2` — any 2-column unique constraint on `essentials.politician_images` qualifies. If the table has a different 2-column unique constraint (e.g., `(politician_id, url)`), the function returns `true` and the script attempts `ON CONFLICT (politician_id, type) DO UPDATE` at line 273. PostgreSQL will reject this at runtime with an error like "there is no unique constraint matching the given keys for referenced table" — caught per-candidate and rolled back, but the operator gets no actionable hint about the root cause.

**Fix:** Pin the query to the specific column names:
```sql
SELECT 1
FROM pg_constraint c
JOIN pg_attribute a1 ON a1.attrelid = c.conrelid AND a1.attnum = ANY(c.conkey) AND a1.attname = 'politician_id'
JOIN pg_attribute a2 ON a2.attrelid = c.conrelid AND a2.attnum = ANY(c.conkey) AND a2.attname = 'type'
WHERE c.conrelid = 'essentials.politician_images'::regclass
  AND c.contype = 'u'
  AND array_length(c.conkey, 1) = 2
LIMIT 1
```
Alternatively, log the constraint name when found so the operator can verify visually.

---

### WR-02: `withPhotos` filtered array is computed and logged but the loop iterates `importData` (dead variable)

**File:** `ev-accounts/backend/scripts/import-123-photo-expansion.ts:329-345`
**Issue:** `const withPhotos = importData.filter(...)` is computed at line 329 and used only in the log message at line 331. The processing loop at line 344 iterates `importData` (all entries). The `processCandidate` function does handle NO_PHOTO entries correctly via the skip path, so behavior is correct — but the variable name implies it scopes the work. A future maintainer editing the loop might replace `importData` with `withPhotos` and accidentally skip the slug-write candidates that have no photo URL.

**Fix:** Either iterate `withPhotos` in the loop (and handle slug-only candidates separately), or drop the variable and just log the count inline:
```typescript
const withPhotoCount = importData.filter((c) => !!c.photo_source_url).length;
console.log(
  `Loaded ${importData.length} candidate(s); ${withPhotoCount} have a photo URL to upload`,
);

for (const candidate of importData) {
  await processCandidate(candidate, hasUniqueConstraint, stats);
}
```

## Info

### IN-01: `JSON.parse` on the data file has no try/catch — error message will be cryptic on malformed input

**File:** `ev-accounts/backend/scripts/import-123-photo-expansion.ts:328`
**Issue:** `JSON.parse(raw)` throws a `SyntaxError` on malformed JSON. The outer `main().catch()` at line 363 catches it, but the logged message will be something like "Unexpected token < in JSON at position 0" with no indication which file is corrupt.
**Fix:** Wrap with a descriptive rethrow:
```typescript
let importData: PhotoImport[];
try {
  importData = JSON.parse(raw);
} catch (e) {
  throw new Error(`Failed to parse ${dataPath}: ${(e as Error).message}`);
}
```

---

### IN-02: `detectExt` uses URL path only — no validation against HTTP Content-Type header

**File:** `ev-accounts/backend/scripts/import-123-photo-expansion.ts:111-124`
**Issue:** Extension is detected from the URL string. Images served through CDNs or with query strings (e.g., `...?size=large`) may lack a file extension, and the fallback is `'jpg'`. The actual Content-Type from the HTTP response is available on the `response` object returned by `fetchImageBytes` but is discarded. Uploading a PNG as `image/jpeg` causes browser rendering issues.
**Fix:** Thread the response headers through or check Content-Type as a fallback:
```typescript
async function fetchImageBytes(url: string): Promise<{ bytes: Buffer; contentType: string | null }> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status} fetching image: ${url}`);
  const arrayBuffer = await response.arrayBuffer();
  return { bytes: Buffer.from(arrayBuffer), contentType: response.headers.get('content-type') };
}
```
Then prefer the HTTP Content-Type over the URL extension when available.

---

### IN-03: Header comment says slugs are written "before the Storage upload path is constructed" but `write_slug` flag must be explicitly set in JSON

**File:** `ev-accounts/backend/scripts/import-123-photo-expansion.ts:9-12` and `220`
**Issue:** The file-level comment states "For candidates without a slug, one is derived from full_name and written to politicians.slug." However, `needsSlug` at line 220 requires `candidate.write_slug === true`. Since `write_slug` is absent from all 54 current data records (the field is optional), no slug will be DB-written even if the DB row currently has no slug. The storage path still uses the derived slug correctly, so photos upload fine — but the slug is not persisted to the politicians table.
**Fix:** Either update the comment to clarify that `write_slug: true` must be explicitly set in the JSON, or document in the data file schema which candidates need the flag. No code change required if the intent is opt-in.

---

### IN-04: Slug "jorge-nuo" for "Jorge Nuño" — accent stripping produces unrecognizable slug

**File:** `ev-accounts/backend/scripts/import-123-data.json:281`
**Issue:** The slug `jorge-nuo` was produced by stripping the `ñ` from "Nuño". The result is not a recognizable transliteration and could be mistaken for a different person. The same pattern applies to `martha-snchez` (line 293, "Martha Sánchez" → `martha-snchez`).
**Fix:** Before the accent-stripping step in `deriveSlug`, apply Unicode normalization + decomposition to convert accented characters to their ASCII base equivalents:
```typescript
function deriveSlug(fullName: string): string {
  return fullName
    .normalize('NFD')                    // decompose é → e + combining accent
    .replace(/[\u0300-\u036f]/g, '')     // strip combining diacritical marks
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-');
}
```
This would produce `jorge-nuno` and `martha-sanchez`. The two affected slugs in the data file would need to be updated to match.

---

### IN-05: All 54 data records have `photo_source_url: null` — script is a no-op on commit

**File:** `ev-accounts/backend/scripts/import-123-data.json:1-332`
**Issue:** Every entry in the current data file has `"photo_source_url": null`. Running with `--commit` will process 54 candidates and skip all of them. This appears intentional for the current phase state (no photo URLs sourced yet), but should be confirmed before running in commit mode to avoid a false sense of completion.
**Fix:** No code change needed. Confirm this is expected phase state. When photo URLs are added, re-run the dry-run first to verify the upload count matches expectations before committing.

---

_Reviewed: 2026-04-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
