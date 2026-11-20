# County Banner Review Surface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the operator one durable, resumable surface for choosing and cropping county banners at national scale, and give every candidate a location that was either measured or evidenced.

**Architecture:** Two tables in `essentials` hold candidates and per-county decisions. A state's JSON rows from plan 1 are imported once: review frames go to Supabase storage, candidates and sweep accounting go to Postgres, and decisions already made are never touched. An admin page reads a state, shows up to five options per county with both crop levers live, and writes each decision through the API — reporting every save from the database's own answer, never from the client's optimism. Files with no coordinates, two thirds of the corpus, reach the operator through a separate caption lane that is recorded apart from the geometry lane and never summed with it.

**Tech Stack:** Postgres (`essentials` schema, RLS), Supabase Storage, Express/TypeScript strict, Vite + React + Tailwind (admin app), vitest.

**Spec:** `docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md`

**Plan 2 of 4.** Plan 1 (merged, #1561) produces the candidates. Plan 3 delivers keeps into the Essentials repo and carries `focus` into Civic Spaces. Plan 4 renders the map tier.

## Global Constraints

- **Never create a table or view in `public`.** Both tables go in `essentials`.
- The migration that creates a table **also**, in the same file: grants explicit privileges to only the roles that need them, runs `enable row level security`, and creates its policies.
- The migration slot is **`CC_0457`**, already reserved. File: `backend/migrations/CC_0457_county_banner_review.sql`. **One migration per file, never concatenate.**
- Nothing in this plan overwrites an existing value; the tables do not exist before it. State that in the migration header.
- The stored asset is **1700 × 540** (3.148:1). Desktop renders a **6:1** band = **52.5%** of asset height. Mobile renders **13:4 (3.25:1)** = **96.9%** of the asset. **Certify on the band and on the asset.**
- **`focus` is a CSS `object-position` string such as `'50% 30%'`** and must be copied, not just the `src`. A pipeline that carries the filename and drops the focus silently re-centres every banner the operator cropped.
- **A county marked "needs another look" ships BLANK**, never with the best available option. Standing ruling, Chris Cantrell, 2026-11-19.
- **Attribution is a hard gate:** a file whose author and licence cannot be read is not a candidate. Plan 1 already drops these; this plan must not reintroduce them.
- **Licence capture:** every candidate stores the **file description page** it was licensed from, never the raw upload URL.
- **Saving is reported, never assumed.** The surface must: show a per-item save stamp (saved, with a time, or NOT SAVED with the reason); show a page-level line from load saying whether saving is switched on at all; treat a failed read as a reason to stop the operator; and separate loading from ready-to-write so one unreadable row cannot disable writing for everything else.
- **Geometry rows and caption rows are recorded separately and never summed.**
- **A detector reporting "nothing found" is untrusted until a control has been watched failing.**
- Wikimedia 429s a generic `User-Agent`; send a named client string, never a person's contact details. `npm run check:user-agents --prefix backend` must stay clean.
- **Supabase Storage needs both `apikey` and `Authorization` headers.** Never print a secret's value.
- Commit with an explicit pathspec: `git commit -F msg -- <path>`.

## Review Focus

1. **A re-import after a second sweep must not erase decisions already made.** The operator will re-sweep a state after round 2. Candidates refresh; `status`, `chosen_title`, `vertical_anchor`, `focus`, `decided_at` and `decided_by` must survive untouched. Test in Task 3.
2. **`focus` must survive the round trip byte-identical.** A decision saved as `'50% 30%'` must come back as `'50% 30%'` through the service and the endpoint — not re-parsed into numbers and reformatted, which is how a re-centre hides. Test in Tasks 4 and 5.
3. **A caption-located candidate chosen without the operator's own sight must be refused by the service**, not merely hidden by the page. A UI-only gate is no gate; the page is not the only caller. Test in Task 4.
4. **A county with zero candidates must say which kind of zero it is** — never swept, swept and genuinely empty, or swept with lost categories. These are three different findings and plan 1 already distinguishes them; the surface must not flatten them. Test in Task 7.
5. **A frame URL that 404s must be visible as a failure, not as an empty box.** The operator approving alt text is the headshot-contact-sheet failure, already paid for once. Test in Task 7.

## File Structure

**Database**
- Create `backend/migrations/CC_0457_county_banner_review.sql` — `essentials.county_banner_candidates` and `essentials.county_banner_review`.

**Pipeline** (`backend/scripts/county-banners/`, extending plan 1)
- Create `frames.ts` — the storage bucket and frame upload.
- Create `import-state.ts` — reads a state's JSON directory, uploads frames, upserts rows.
- Create `caption.ts` — the caption location rule.
- Modify `build-state-candidates.ts` — persist the uncoordinated files, not only their count.
- Modify `locate.ts` — place names for a county, reporting when we have no place list.
- Modify `backend/package.json` — one new npm script.

**Backend API**
- Create `backend/src/lib/countyBannerReviewService.ts` — list, read, decide, writability probe.
- Modify `backend/src/routes/admin.ts` — four endpoints under `/admin/county-banners`.

**Admin UI** (`admin/src/pages/admin/`)
- Create `countyBannerCrop.ts` — pure crop geometry. No React, fully unit-tested.
- Create `CountyBannerReviewPage.tsx` — the surface.
- Modify `admin/src/App.tsx` — the route.
- Modify `admin/src/pages/admin/AdminLayout.tsx` — the nav item.

## Calls made while planning, for the reviewer to check

- **The surface is an admin page, not an artifact.** Operator's decision, 2026-11-20. Five review pages already follow this pattern.
- **The caption lane is in scope, with the full rule** — caption, a second independent source, and the operator's own sight. Operator's decision, 2026-11-20.
- **Review frames live in a new public Supabase bucket `county_banner_frames`.** They are free-licensed images and the page must load them without signed URLs. My call.
- **Our own place polygons cannot carry the caption rule.** Measured 2026-11-20 on prod: 52 states have county polygons, **32 have `G4110` place polygons**, and Nebraska and Delaware — the two states already swept — have **none**. A place-list check would have returned nothing in 20 states and read as "no caption evidence". So the place list is used where it exists, its absence is **reported to the operator on the row**, and the weight sits where the spec put it: the second source and the operator's sight. My call.
- **First state is Delaware (3 counties), then states in ascending county count.** Proves the surface on a state small enough to review in minutes before Texas's 254. My call.

## Not in this plan

Each of these is a spec requirement that belongs to another plan, listed so the reviewer can tell a deliberate omission from a gap.

- **Round 2 itself** — state historical societies, USGS, NPS, Library of Congress, county and city sites. The caption lane here is the *rule* round 2 will need; the extra sources are plan 3's or a plan of their own. Delaware's 151 uncoordinated Commons files are enough to prove the rule.
- **Delivery into the Essentials repo** — `buildingImages.js`, the credit line and the coverage row. Plan 3. Nothing in this plan writes a banner anywhere a voter can see.
- **Carrying `focus` into Civic Spaces** — `HeroBanner.tsx`, `banners.generated.ts`, `generate-banners.mjs`. Plan 3, cross-repo.
- **The map tier** for counties that produce no keep. Plan 4.
- **City-over-county precedence** — already implemented. `CURATED_COUNTY` is read only when no city banner matched, at `buildingImages.js:2364`. Nothing to build.
- **A county-seat source.** Plan 1's `countyCategoryRoots` takes a seat name and is passed `null`, so seat photographs are reached through the county category's subcategories instead. Adding a seat source would widen recall; it is not needed for the surface to work and is not in scope here.

---

### Task 1: The two tables

**Files:**
- Create: `backend/migrations/CC_0457_county_banner_review.sql`

**Interfaces:**
- Produces: `essentials.county_banner_candidates` keyed `(geoid, commons_title)`; `essentials.county_banner_review` keyed `geoid`. Every later task reads these column names.

- [ ] **Step 1: Write the migration header**

A `-- CC_0457 —` title line, then: why the table exists, what one row asserts, and the two rules the schema itself enforces (a keep names a candidate and carries a focus; a needs-another-look names none). State that nothing is overwritten and no row is deleted, because the tables do not exist before this file. Match the house style of `backend/migrations/CC_0344_office_swearing_in.sql`.

- [ ] **Step 2: Write `essentials.county_banner_candidates`**

Columns: `geoid text NOT NULL`, `commons_title text NOT NULL`, `rank_position int NOT NULL`, `frame_url text NOT NULL`, `source_page_url text NOT NULL`, `width int NOT NULL`, `height int NOT NULL`, `licence text NOT NULL`, `author text NOT NULL`, `located_by text NOT NULL`, `lat double precision`, `lon double precision`, `caption_text text`, `caption_source_url text`, `confirming_source_url text`, `place_list_available boolean`, `created_at timestamptz NOT NULL DEFAULT now()`.

Primary key `(geoid, commons_title)`. Constraints:
- `located_by IN ('geometry','caption')`
- `located_by <> 'geometry' OR (lat IS NOT NULL AND lon IS NOT NULL)`
- `located_by <> 'caption' OR (btrim(coalesce(caption_text,'')) <> '' AND btrim(coalesce(caption_source_url,'')) <> '' AND btrim(coalesce(confirming_source_url,'')) <> '')`
- `btrim(author) <> '' AND btrim(licence) <> ''` — attribution is a hard gate, so an empty string must not pass NOT NULL
- `source_page_url NOT LIKE '%upload.wikimedia.org%'` — the licence-capture rule, made structural

`COMMENT ON COLUMN ... .source_page_url` saying it is the file description page, never the raw upload URL, and why.

- [ ] **Step 3: Write `essentials.county_banner_review`**

Columns: `geoid text PRIMARY KEY`, `state_usps text NOT NULL`, `county_name text NOT NULL`, `status text NOT NULL DEFAULT 'pending'`, `chosen_title text`, `vertical_anchor numeric`, `focus text`, `caption_sighted boolean NOT NULL DEFAULT false`, `swept boolean NOT NULL`, `files_swept int NOT NULL DEFAULT 0`, `categories_found int NOT NULL DEFAULT 0`, `category_errors int NOT NULL DEFAULT 0`, `geometry_candidates int NOT NULL DEFAULT 0`, `caption_candidates int NOT NULL DEFAULT 0`, `rejected jsonb NOT NULL DEFAULT '{}'::jsonb`, `decided_at timestamptz`, `decided_by text`, `imported_at timestamptz NOT NULL DEFAULT now()`.

Constraints:
- `status IN ('pending','keep','needs_another_look')`
- `status <> 'keep' OR (chosen_title IS NOT NULL AND focus IS NOT NULL AND vertical_anchor IS NOT NULL)`
- `status <> 'needs_another_look' OR chosen_title IS NULL` — **the blank ruling, enforced by the schema**
- `vertical_anchor IS NULL OR (vertical_anchor >= 0 AND vertical_anchor <= 1)`
- Foreign key `(geoid, chosen_title)` references `county_banner_candidates (geoid, commons_title)`, `ON DELETE RESTRICT` — a decision cannot name a candidate that is not there, and a re-import cannot delete a chosen one out from under a decision.

A table comment stating that `geometry_candidates` and `caption_candidates` are counted separately and must never be summed, and that `caption_sighted` is enforced by the service, not by a CHECK, because the condition crosses tables.

- [ ] **Step 4: Grants, RLS and policies**

`ALTER TABLE ... ENABLE ROW LEVEL SECURITY` on both. `GRANT SELECT, INSERT, UPDATE` on both to `ev_api` (the importer and the API both connect as `ev_api`; neither deletes). `GRANT ALL` to `service_role`. One `FOR ALL` policy per table for each role, `USING (true) WITH CHECK (true)`, named `county_banner_candidates_api` / `_service` and `county_banner_review_api` / `_service`.

- [ ] **Step 5: Write the post-verify gate**

A `DO $$ ... $$` block that `RAISE EXCEPTION`s unless: both tables exist, each has RLS on, each has at least 2 policies, `county_banner_candidates` has 5 CHECK constraints and `county_banner_review` has 4, and both are empty. Gate the **shape this file creates**, never a total another session can move.

- [ ] **Step 6: Dry-run against prod**

Run: `node backend/scripts/dry-run-migration.mjs backend/migrations/CC_0457_county_banner_review.sql`
Expected: `DRY RUN OK`. Then confirm the rollback actually reverted: query `information_schema.tables` for both names and expect 0 rows. **A dry run that reports OK on a file whose body did not run proves nothing** — check the table count, not the exit code.

- [ ] **Step 7: Apply to prod**

Run: `node backend/scripts/apply-migration-file.mjs backend/migrations/CC_0457_county_banner_review.sql`
Expected: the post-verify passes. Then re-query `information_schema.tables` and expect both.

- [ ] **Step 8: Commit**

```bash
git commit -F msg -- backend/migrations/CC_0457_county_banner_review.sql
```

---

### Task 2: Frame storage

**Files:**
- Create: `backend/scripts/county-banners/frames.ts`
- Test: `backend/scripts/county-banners/frames.test.ts`

**Interfaces:**
- Produces: `BUCKET = 'county_banner_frames'`; `ensureBucket(deps?: FrameDeps): Promise<void>`; `uploadFrame(localPath: string, key: string, deps?: FrameDeps): Promise<string>` returning the public URL; `FrameDeps = { fetchImpl?: typeof fetch; readFile?: (p: string) => Buffer }`.

- [ ] **Step 1: Write the failing tests**

```ts
it('sends both apikey and Authorization', async () => { /* capture headers from a stub fetchImpl; expect both present and equal */ });
it('sends x-upsert so a re-run replaces rather than 409s', ...);
it('returns the public URL built from the object path, not the host', ...);  // .../object/public/county_banner_frames/<key>
it('throws naming the key when the upload is not ok', ...);
it('treats a 409 from ensureBucket as already-exists, not an error', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run scripts/county-banners/frames.test.ts` (from `backend/`)
Expected: FAIL — `Cannot find module './frames.js'`

- [ ] **Step 3: Implement `frames.ts`**

`uploadFrame` POSTs to `${SUPABASE_URL}/storage/v1/object/${BUCKET}/${key}` with `apikey`, `Authorization: Bearer`, `Content-Type: image/jpeg`, `x-upsert: true`. `ensureBucket` POSTs `/storage/v1/bucket` with `{ id: BUCKET, name: BUCKET, public: true }` and accepts an already-exists response. Build the public URL by **path**, never by host — storage answers on two hostnames and a host-based rule once misclassified 1,279 of our own mirrored images.

- [ ] **Step 4: Run them and watch them pass**

Run: `npx vitest run scripts/county-banners/frames.test.ts`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

---

### Task 3: Import a state

**Files:**
- Create: `backend/scripts/county-banners/import-state.ts`
- Test: `backend/scripts/county-banners/import-state.test.ts`
- Modify: `backend/package.json` — add `"banners:import": "node --import ./scripts/lib/main-checkout-fallback.mjs --import tsx scripts/county-banners/import-state.ts"`

**Interfaces:**
- Consumes: `CountyFile` from `build-state-candidates.ts`; `uploadFrame` from `frames.ts`; `QueryFn` from `locate.ts`.
- Produces: `importState(stateUsps: string, dir: string, deps: ImportDeps): Promise<ImportSummary>`; `ImportDeps = { query: QueryFn; upload?: (localPath: string, key: string) => Promise<string> }`; `ImportSummary = { counties: number; candidates: number; framesUploaded: number; decisionsPreserved: number; unreadable: string[] }`.

- [ ] **Step 1: Write the failing tests**

```ts
it('upserts one review row per county with the sweep accounting', ...);
it('writes candidates keyed on (geoid, commons_title) with rank_position from the array order', ...);
it('stores the file description page, never the upload URL, as source_page_url', ...);
it('PRESERVES an existing decision on re-import', async () => {
  // review row already status:'keep', chosen_title:'File:A.jpg', focus:'50% 30%', decided_at set
  // re-import the same state with refreshed candidates
  // expect status, chosen_title, vertical_anchor, focus, decided_at, decided_by all unchanged
  // expect files_swept and county_name refreshed
});
it('counts a county it could not read into unreadable, and keeps going', ...);
it('records geometry_candidates and caption_candidates separately, never summed', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run scripts/county-banners/import-state.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement `importState`**

Read every `<geoid>.json` in `dir`. For each county: upload the rendered frames from `dir/img/` as `<geoid>-<rank>.jpg`, then upsert. The candidate upsert is `ON CONFLICT (geoid, commons_title) DO UPDATE` on every column. **The review upsert is `ON CONFLICT (geoid) DO UPDATE SET` on `state_usps, county_name, swept, files_swept, categories_found, category_errors, geometry_candidates, caption_candidates, rejected, imported_at` and nothing else** — the decision columns are absent from the SET list, which is what makes Review Focus 1 true. An unreadable or truncated JSON file is collected into `unreadable` and does not stop the state.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (6 tests)

- [ ] **Step 5: Import Delaware live, then plant a control**

Run the importer against the Delaware directory from plan 1. Expected: 3 counties, candidates > 0, frames uploaded, `unreadable` empty. Then record a decision by hand (`UPDATE ... SET status='keep', chosen_title=<a real one>, focus='50% 30%', vertical_anchor=0.5, decided_at=now()`), re-run the import, and **read the row back**: the decision must be exactly as written and `imported_at` must have moved. A re-import that silently wiped it would otherwise look like a clean run.

- [ ] **Step 6: Commit**

---

### Task 4: The review service

**Files:**
- Create: `backend/src/lib/countyBannerReviewService.ts`
- Test: `backend/src/lib/countyBannerReviewService.test.ts`

**Interfaces:**
- Produces:
  - `listStates(): Promise<StateSummary[]>` — `{ stateUsps, counties, pending, keep, needsAnotherLook }`
  - `getStateCounties(stateUsps: string): Promise<CountyReviewRow[]>` — each row carries its candidates
  - `recordDecision(geoid: string, decision: Decision, actor: string): Promise<CountyReviewRow>`
  - `isWritable(): Promise<boolean>`
  - `Decision = { status: 'keep' | 'needs_another_look'; chosenTitle: string | null; verticalAnchor: number | null; focus: string | null; captionSighted: boolean }`
  - Rows are **camelCase**, matching `ResearchReviewRow` in `researchEvidenceService.ts`, and the SQL aliases to them:
    - `CountyReviewRow = { geoid: string; stateUsps: string; countyName: string; status: 'pending' | 'keep' | 'needs_another_look'; chosenTitle: string | null; verticalAnchor: number | null; focus: string | null; captionSighted: boolean; swept: boolean; filesSwept: number; categoriesFound: number; categoryErrors: number; geometryCandidates: number; captionCandidates: number; rejected: Record<string, number>; decidedAt: string | null; decidedBy: string | null; candidates: CandidateRow[] }`
    - `CandidateRow = { commonsTitle: string; rankPosition: number; frameUrl: string; sourcePageUrl: string; width: number; height: number; licence: string; author: string; locatedBy: 'geometry' | 'caption'; captionText: string | null; captionSourceUrl: string | null; confirmingSourceUrl: string | null; placeListAvailable: boolean | null }`

- [ ] **Step 1: Write the failing tests**

```ts
it('refuses a keep that names no candidate', ...);            // 'a keep must name the chosen candidate'
it('refuses a keep with no focus', ...);
it('refuses a needs_another_look that names a candidate', ...); // the blank ruling
it('refuses a vertical anchor outside 0..1', ...);
it('refuses a caption-located choice when captionSighted is false', ...);  // Review Focus 3
it('accepts a caption-located choice when captionSighted is true', ...);
it('returns focus byte-identical to what was written', async () => {
  const saved = await recordDecision('10001', { ...keep, focus: '50% 30%' }, 'tester');
  expect(saved.focus).toBe('50% 30%');   // Review Focus 2 — not 0.5/0.3 reformatted
});
it('returns decided_at from the database row, not from the caller', ...);
it('isWritable answers from has_table_privilege, writing nothing', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run src/lib/countyBannerReviewService.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement the service**

Follow `backend/src/lib/researchEvidenceService.ts`: named exports, SQL in this file, no client usage in the route. `recordDecision` validates first, then writes, then **returns the row the database produced** — the save stamp the page shows comes from `decided_at` in that returned row. The caption gate reads the chosen candidate's `located_by` in the same statement that writes, so a candidate flipped to `caption` between page load and save cannot slip through. `isWritable` runs `SELECT has_table_privilege('essentials.county_banner_review','UPDATE')` — a probe that writes nothing.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

---

### Task 5: The endpoints

**Files:**
- Modify: `backend/src/routes/admin.ts` — add a `// County banner review` section following the `research-review` block at the end
- Test: `backend/src/routes/admin.test.ts`

**Interfaces:**
- Consumes: every export of `countyBannerReviewService.ts`.
- Produces: `GET /admin/county-banners/states`, `GET /admin/county-banners/health`, `GET /admin/county-banners/:state`, `POST /admin/county-banners/:geoid/decision`.

- [ ] **Step 1: Write the failing tests**

```ts
it('GET /admin/county-banners/states requires admin', ...);
it('GET /admin/county-banners/health reports writable', ...);
it('POST .../decision returns 400 with the service message when the decision is refused', ...);
it('POST .../decision returns the saved row with focus unchanged', ...);   // Review Focus 2
it('POST .../decision returns 404 for an unknown geoid', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run src/routes/admin.test.ts -t "county-banners"`
Expected: FAIL

- [ ] **Step 3: Implement the four handlers**

Validate the POST body with `zod` as the neighbouring handlers do. A service refusal is a **400 carrying the service's own message**, not a 500 — the operator must read why the save was refused, which is the "NOT SAVED with the reason" requirement. Unexpected errors stay 500 with a logged prefix.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

---

### Task 6: Crop geometry

**Files:**
- Create: `admin/src/pages/admin/countyBannerCrop.ts`
- Test: `admin/src/pages/admin/countyBannerCrop.test.ts`

**Interfaces:**
- Produces: `ASSET_W = 1700`, `ASSET_H = 540`, `ASSET_RATIO`, `DESKTOP_RATIO = 6`, `MOBILE_RATIO = 13 / 4`; `Rect = { x: number; y: number; w: number; h: number }`; `assetRect(srcW: number, srcH: number, verticalAnchor: number): Rect`; `bandRect(ratio: number, focus: string): Rect`; `parseFocus(focus: string): { x: number; y: number } | null`; `formatFocus(x: number, y: number): string`.

- [ ] **Step 1: Write the failing tests**

```ts
it('cuts the asset flush to the top at anchor 0', () => {
  expect(assetRect(3400, 2000, 0)).toEqual({ x: 0, y: 0, w: 3400, h: 1080 });
});
it('cuts it flush to the bottom at anchor 1', () => {
  expect(assetRect(3400, 2000, 1)).toEqual({ x: 0, y: 920, w: 3400, h: 1080 });
});
it('centres at anchor 0.5', () => { expect(assetRect(3400, 2000, 0.5).y).toBe(460); });
it('ignores the anchor on a source wider than the asset ratio', () => {
  // 4000x500 has no vertical slack; the crop is height-limited and centred horizontally
  const r = assetRect(4000, 500, 0);
  expect(r.h).toBe(500);
  expect(r.w).toBeCloseTo(1574.07, 2);
  expect(r.y).toBe(0);
});
it('places the 6:1 desktop band by focus', () => {
  const r = bandRect(DESKTOP_RATIO, '50% 30%');
  expect(r.h).toBeCloseTo(283.33, 2);     // 1700/6
  expect(r.y).toBeCloseTo(77.0, 1);       // 0.30 * (540 - 283.33)
  expect(r.x).toBe(0);
});
it('centres the desktop band at 50%', () => { expect(bandRect(DESKTOP_RATIO, '50% 50%').y).toBeCloseTo(128.33, 2); });
it('the mobile band is 96.9% of the asset', () => {
  expect(bandRect(MOBILE_RATIO, '50% 50%').h / ASSET_H).toBeCloseTo(0.969, 3);
});
it('parseFocus returns null for a string it cannot read', () => {
  expect(parseFocus('50% 30')).toBeNull();
  expect(parseFocus('centre')).toBeNull();
});
it('formatFocus round-trips through parseFocus', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run src/pages/admin/countyBannerCrop.test.ts` (from `admin/`)
Expected: FAIL — module not found

- [ ] **Step 3: Implement the module**

`assetRect` is width-limited when the source is taller than 3.148:1 and height-limited when it is wider; the anchor moves the crop through whichever slack exists and has no effect when there is none. `bandRect` follows CSS `object-fit: cover` semantics: the percentage places that share of the overflow before the box.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

---

### Task 7: The review page

**Files:**
- Create: `admin/src/pages/admin/CountyBannerReviewPage.tsx`
- Test: `admin/src/pages/admin/CountyBannerReviewPage.test.tsx`
- Modify: `admin/src/App.tsx` — `<Route path="county-banners" element={<CountyBannerReviewPage />} />` under the `/admin` layout
- Modify: `admin/src/pages/admin/AdminLayout.tsx` — `{ label: 'County Banners', to: '/admin/county-banners' }`

**Interfaces:**
- Consumes: `apiFetch`; every export of `countyBannerCrop.ts`; the four endpoints from Task 5.

- [ ] **Step 1: Write the failing tests**

```ts
it('shows the page-level saving line from load', ...);              // health says writable / NOT writable
it('stops the operator when the state read fails', ...);            // an error panel, no county cards
it('shows a per-county save stamp with the time from the response', ...);
it('shows NOT SAVED with the server message when a decision is refused', ...);
it('keeps the other counties writable when one row fails to load', ...);  // loading is separate from ready-to-write
it('says which kind of zero an empty county is', () => {
  // swept:false -> 'not swept yet'
  // swept:true, 0 candidates, category_errors 0 -> 'swept, no usable photograph'
  // swept:true, category_errors > 0 -> 'swept with N categories lost'
});                                                                  // Review Focus 4
it('marks a frame that failed to load as broken, not blank', ...);   // Review Focus 5 — onError, never an empty box
it('shows the 6:1 band and the full asset together for the selected option', ...);
it('disables keep for a caption-located option until the sighted box is ticked', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Run: `npx vitest run src/pages/admin/CountyBannerReviewPage.test.tsx`
Expected: FAIL

- [ ] **Step 3: Implement the page**

A state picker, then one card per county: up to five option thumbnails, and for the selected option a live preview showing the full 1700×540 asset **and** the 6:1 desktop band together, driven by `assetRect` and `bandRect`. Two sliders: vertical anchor (0–1) and focus (the `object-position` percentages). Keep and "needs another look" buttons. Caption-lane options carry the caption, both source links, and a sighted checkbox; where `place_list_available` is false, say so on the row — we could not check this state against our own place list. Every save posts and then renders the returned row's `decided_at`; a failure renders the server's message. The page-level line comes from `/health` on load.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (9 tests)

- [ ] **Step 5: Show the production render**

Build the admin app and screenshot the Delaware page at desktop and at phone width. **Measure, do not eyeball:** confirm the rendered band is 52.5% of the rendered asset height. Put the screenshots in the task's commit message.

- [ ] **Step 6: Commit**

---

### Task 8: The caption lane

**Files:**
- Modify: `backend/scripts/county-banners/build-state-candidates.ts` — persist the uncoordinated files
- Modify: `backend/scripts/county-banners/locate.ts` — place names for a county
- Create: `backend/scripts/county-banners/caption.ts`
- Test: `backend/scripts/county-banners/caption.test.ts`
- Modify: `backend/scripts/county-banners/import-state.ts` — write caption rows

**Interfaces:**
- Consumes: `CandidateFile`, `QueryFn`.
- Produces:
  - `listPlacesInCounty(stateFips: string, geoid: string, query: QueryFn): Promise<{ places: string[]; placeListAvailable: boolean }>` in `locate.ts`
  - `PlaceNames = { county: string; state: string; places: string[]; placeListAvailable: boolean }`
  - `captionNamesPlace(caption: string, names: PlaceNames): string | null` in `caption.ts`
  - `confirmByCaption(file: CandidateFile, names: PlaceNames, deps: { fetchText: (url: string) => Promise<string> }): Promise<CaptionResult>`
  - `CaptionResult = { located: boolean; reason: string; matchedPlace?: string; captionText?: string; captionSourceUrl?: string; confirmingSourceUrl?: string }`
  - `CountyFile` gains `unlocatedFiles: CandidateFile[]`; `CandidateFile` gains `caption: string | null` and `sourceUrl: string | null`

- [ ] **Step 1: Write the failing tests**

```ts
it('listPlacesInCounty reports placeListAvailable false for a state with no place polygons', ...);
// 🔴 measured 2026-11-20: 20 of 52 states have none, Nebraska and Delaware among them
it('matches a caption naming the county', ...);
it('matches a caption naming a place inside the county', ...);
it('matches a caption naming the file\'s own source category leaf when we have no place list', ...);
it('refuses a caption that names the place but not the state', ...);     // 'Dawson' is in six states
it('refuses when the confirming source shares a registrable domain with the caption source', ...);
it('refuses when the confirming page does not contain the matched place name', ...);
it('returns located:false with a reason, never throws, when the confirming fetch fails', ...);
it('build-state-candidates persists unlocatedFiles alongside the unlocated count', ...);
it('import-state writes caption rows with located_by caption and all three evidence fields', ...);
```

- [ ] **Step 2: Run them and watch them fail**

Expected: FAIL

- [ ] **Step 3: Implement**

`listPlacesInCounty` selects `G4110` names whose centroid is contained by the county polygon, and returns `placeListAvailable: false` when the state has no `G4110` rows at all — **the distinction between "no places in this county" and "no place data for this state" is the whole point of the flag**, and without it the detector reports nothing found in 20 states and looks like evidence. `captionNamesPlace` folds accents and compares case-insensitively, requiring both a place token and the state token. `confirmByCaption` requires the confirming URL's registrable domain to differ from the caption source's, fetches it, and requires the matched place name to appear in the text — it reads the page to **confirm a name we already hold**, and never sources a name from it.

- [ ] **Step 4: Run them and watch them pass**

Expected: PASS (10 tests)

- [ ] **Step 5: Watch the control fail before trusting the lane**

Run the caption lane over Delaware's 151 uncoordinated files. Then plant a control: feed it a file whose caption names a place in a **different** state and confirm `located:false` with a reason naming the state mismatch. Remove it and confirm a real match still passes. A lane that has only ever said yes, or only ever said no, proves nothing.

- [ ] **Step 6: Re-import Delaware and read the two lanes apart**

Expected: `geometry_candidates` unchanged from Task 3, `caption_candidates` > 0, and the two never added together anywhere in the output. Decisions from Task 3 still intact.

- [ ] **Step 7: Commit**

---

## Done when

- `npm run banners:import --prefix backend -- DE <dir>` imports Delaware, twice, without touching a decision.
- The admin page lists Delaware, shows both crop levers live against the band and the asset, and records a keep whose `focus` comes back byte-identical.
- A county marked "needs another look" holds no chosen candidate, in the database, enforced by a CHECK.
- A caption-located candidate cannot be kept without the operator's sight, enforced by the service.
- `npm run check:user-agents --prefix backend` is clean; the full suite is green except the six failures already pre-existing on master.
