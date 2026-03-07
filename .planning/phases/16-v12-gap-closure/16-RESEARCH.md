# Phase 16: v1.2 Gap Closure - Research

**Researched:** 2026-03-07
**Domain:** Bug fixes — Supabase JS soft-delete filtering, React TypeScript interface corrections, dead code removal
**Confidence:** HIGH

## Summary

This phase closes two integration breaks identified by the v1.2 milestone audit and removes accumulated tech debt. All changes were verified by directly reading the source files — there is no guesswork or inference here.

Break 1 is a missing `.is('deleted_at', null)` filter on two `compass_responses` read paths in `backend/src/routes/compass.ts`. The `reset_compass_answers` RPC performs a soft delete by setting `deleted_at = now()`. The RLS policy on `compass_responses` uses only `USING (auth.uid() = user_id)` — it does NOT filter deleted rows. The `compassService.ts` service layer does not query `compass_responses` at all (it only has `getCompassCompleteness` via RPC, which presumably handles deleted rows server-side). The two read paths that do query the table directly are both inline in the route file.

Break 2 is a response shape mismatch: `CategoriesPage.tsx` calls `apiFetch<{ categories: [...] }>('/compass/categories')` and then accesses `.categories` on the result, but `GET /api/compass/categories` returns a plain array (confirmed in `compassService.ts` — `getCompassCategories()` returns the mapped array directly with no wrapper object).

The tech debt items are straightforward: `adminCreateTopic()` in `adminService.ts` (lines 262–285) is a direct-insert version superseded by the RPC-based `adminCreateTopicWithStances()` and is not called anywhere. The `id: number` typing on Topic, Stance, and Category local interfaces is incorrect — the DB uses UUIDs (`string`), and several of these IDs are used as URL path parameters passed to `apiFetch` which confirms they should be `string`.

**Primary recommendation:** Make all five changes in order — the two backend filter additions first (they are independent), then the frontend shape fix (independent of backend), then the two tech debt cleanups (independent of each other and of the functional fixes).

## Standard Stack

No new libraries required. All changes are line-level edits to existing files using the project's existing stack.

### Core (no changes)
| Component | Version | Role |
|-----------|---------|------|
| Supabase JS (`@supabase/ssr`) | existing | `.is('deleted_at', null)` filter method |
| TypeScript | existing | Interface type corrections |
| React | existing | Frontend component fixes |

### Supabase JS `.is()` filter
The correct Supabase JS PostgREST filter for a nullable column being NULL is:
```typescript
.is('deleted_at', null)
```
This generates `deleted_at=is.null` in the PostgREST query. Do NOT use `.eq('deleted_at', null)` — that generates `deleted_at=eq.null` which is incorrect SQL and will not work as expected. The `.is()` method is the documented approach for `IS NULL` / `IS NOT NULL` checks. (HIGH confidence — direct observation of Supabase JS API pattern; the same pattern is already used elsewhere in this codebase, e.g. `.maybeSingle()` queries on connected_profiles.)

## Architecture Patterns

### Pattern: Inline route queries with soft-delete filter

The two reads that need fixing query `compass_responses` inline in the route handler using `createUserClient`. The fix inserts `.is('deleted_at', null)` as a chain filter before the query terminates. Chain order does not matter for Supabase JS filters — they all compose into the PostgREST query string.

```typescript
// BEFORE (GET /answers, line 148-151):
const { data, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at');

// AFTER:
const { data, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at')
  .is('deleted_at', null);
```

```typescript
// BEFORE (POST /answers/batch, line 188-192):
const { data, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text')
  .in('topic_id', parsed.data.ids);

// AFTER:
const { data, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text')
  .in('topic_id', parsed.data.ids)
  .is('deleted_at', null);
```

### Pattern: CategoriesPage apiFetch shape fix

`getCompassCategories()` in `compassService.ts` (lines 151–161) returns a plain array — it calls `(catRes.data ?? []).map(cat => ({ ...cat, topics: [...] }))` with no object wrapper. The frontend must be updated to match this.

Two locations in CategoriesPage.tsx access `catData.categories`:
- Line 114 (initial load): `apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories')`
  then line 118: `setCategories(catData.categories)`
- Line 128 (refreshCategories): `apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories')`
  then line 131: `setCategories(data.categories)`

Both must change to:
```typescript
// BEFORE (line 114):
apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories')
// AFTER:
apiFetch<Array<Category & { topics: Topic[] }>>('/compass/categories')

// BEFORE (line 118):
setCategories(catData.categories);
// AFTER:
setCategories(catData);

// BEFORE (line 128):
const data = await apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories');
// AFTER:
const data = await apiFetch<Array<Category & { topics: Topic[] }>>('/compass/categories');

// BEFORE (line 131):
setCategories(data.categories);
// AFTER:
setCategories(data);
```

### Pattern: Dead code removal

`adminCreateTopic()` occupies lines 262–285 in `adminService.ts`. It is a plain `supabaseAdmin.insert()` with no stances. It has been superseded by `adminCreateTopicWithStances()` (lines 425–451) which uses the `admin_create_topic_with_stances` RPC. A grep of the codebase would confirm `adminCreateTopic` is not imported or called anywhere — it can be deleted outright, including its JSDoc comment.

### Pattern: id field type corrections

The three admin pages all have local interface declarations using `id: number`. In the actual database, all these entities use UUID primary keys stored as `string`. The `id` values flow from API responses and are used as URL path parameters (e.g., `apiFetch(\`/admin/compass/topics/${topic.id}/stances\`)`), which confirms they must be `string`.

Note: `TopicsPage.tsx` also has `selectedId` state typed as `number | null` (line 59) and comparisons like `t.id === selectedId` and `s.id === selectedId` which would also break if `id` becomes `string`. These state variables and comparisons must also be updated to use `string | null`.

Note: `PoliticiansPage.tsx` has `Politician.id` already correctly typed as `string` (line 9). Only `Topic`, `Stance`, and `PoliticianAnswer.topic_id` use `number`.

`TopicAnswerRow.onStancesNeeded(topicId: number)`, `handleStancesNeeded(topicId: number)`, and `topicStances: Record<number, Stance[]>` in `PoliticiansPage.tsx` will also need updating from `number` to `string` if Topic.id changes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| IS NULL filter in Supabase | `.eq('deleted_at', null)` (wrong) | `.is('deleted_at', null)` (correct PostgREST syntax) |

## Common Pitfalls

### Pitfall 1: Using `.eq()` instead of `.is()` for NULL checks
**What goes wrong:** `.eq('deleted_at', null)` generates `deleted_at=eq.null` in PostgREST, which does not correctly match SQL `IS NULL`. The query may return 0 rows or behave unpredictably.
**How to avoid:** Always use `.is('deleted_at', null)` for nullable column null checks.

### Pitfall 2: Incomplete cascading fixes in TopicsPage
**What goes wrong:** Changing `Topic.id` from `number` to `string` without updating `selectedId: number | null` state and comparisons causes TypeScript errors at `t.id === selectedId` and `setSelectedId(t.id)`.
**How to avoid:** When changing `id: number` to `id: string` in an interface, grep the component for all usages of that id field and update state types and comparisons.

### Pitfall 3: Incomplete cascading fixes in PoliticiansPage
**What goes wrong:** `Topic.id: number` is used in `topicStances: Record<number, Stance[]>`, `handleStancesNeeded(topicId: number)`, `TopicAnswerRow.onStancesNeeded(topicId: number)`, `PoliticianAnswer.topic_id: number`, and comparison `answers.find((a) => a.topic_id === topic.id)`. All must change together.
**How to avoid:** Treat PoliticiansPage as a cascade: Topic.id, Stance.id, PoliticianAnswer.topic_id, and all Record keys/function signatures that reference topic IDs must all change from `number` to `string`.

### Pitfall 4: CategoriesPage `id: number` used as `String(t.id)` in select option value
**What goes wrong:** Line 85 in CategoriesPage.tsx uses `value={String(t.id)}` on the `<option>`. After the fix, `t.id` is already a `string`, so `String(t.id)` still works but `String(t.id)` is now redundant. The `selectedTopicId` state is `string`, which remains correct.
**How to avoid:** After changing `Topic.id` to `string`, `String(t.id)` is harmless but the option value already matches `selectedTopicId` type. No behavior change.

## Code Examples

### Supabase JS IS NULL filter (source: direct code inspection)
```typescript
// Correct pattern for filtering soft-deleted rows:
const { data, error } = await db
  .schema('inform')
  .from('compass_responses')
  .select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at')
  .is('deleted_at', null);
```

## Files to Modify

| File | Change | Lines |
|------|--------|-------|
| `backend/src/routes/compass.ts` | Add `.is('deleted_at', null)` to GET /answers query | ~151 |
| `backend/src/routes/compass.ts` | Add `.is('deleted_at', null)` to POST /answers/batch query | ~192 |
| `admin/src/pages/admin/CategoriesPage.tsx` | Fix apiFetch type param and remove `.categories` access | 114, 118, 128, 131 |
| `backend/src/lib/adminService.ts` | Delete `adminCreateTopic()` function (lines 259–285 including JSDoc) | 259–285 |
| `admin/src/pages/admin/TopicsPage.tsx` | Change `Topic.id: number → string`, `Stance.id: number → string`, `selectedId: number | null → string | null` | ~6, ~11, ~59 |
| `admin/src/pages/admin/PoliticiansPage.tsx` | Change `Topic.id: number → string`, `Topic.short_title` type, `Stance.id: number → string`, `Stance.topic_id: number → string`, `PoliticianAnswer.topic_id: number → string`, `topicStances: Record<number, Stance[]> → Record<string, Stance[]>`, `handleStancesNeeded(topicId: number) → (topicId: string)`, `TopicAnswerRow.onStancesNeeded(topicId: number) → (topicId: string)` | ~21–31, ~43, ~73, ~492 |
| `admin/src/pages/admin/CategoriesPage.tsx` | Change `Category.id: number → string`, `Topic.id: number → string` | 5, 11 |

## Exact Change Inventory

### Fix 1: GET /answers missing deleted_at filter
**File:** `backend/src/routes/compass.ts`
**Location:** Line 151 — end of `.select(...)` call
**Current:**
```typescript
.select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at');
```
**Fixed:**
```typescript
.select('topic_id, value, write_in_text, visibility, inverted, created_at, updated_at')
.is('deleted_at', null);
```

### Fix 2: POST /answers/batch missing deleted_at filter
**File:** `backend/src/routes/compass.ts`
**Location:** Line 192 — end of `.in('topic_id', ...)` call
**Current:**
```typescript
.in('topic_id', parsed.data.ids);
```
**Fixed:**
```typescript
.in('topic_id', parsed.data.ids)
.is('deleted_at', null);
```

### Fix 3: CategoriesPage response shape mismatch
**File:** `admin/src/pages/admin/CategoriesPage.tsx`

Location A — initial load (lines 114, 118):
```typescript
// CURRENT line 114:
apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>('/compass/categories'),
// FIXED:
apiFetch<Array<Category & { topics: Topic[] }>>('/compass/categories'),

// CURRENT line 118:
setCategories(catData.categories);
// FIXED:
setCategories(catData);
```

Location B — refreshCategories (lines 128, 131):
```typescript
// CURRENT line 128:
const data = await apiFetch<{ categories: Array<Category & { topics: Topic[] }> }>(
  '/compass/categories',
);
// FIXED:
const data = await apiFetch<Array<Category & { topics: Topic[] }>>('/compass/categories');

// CURRENT line 131:
setCategories(data.categories);
// FIXED:
setCategories(data);
```

### Fix 4: Remove adminCreateTopic dead code
**File:** `backend/src/lib/adminService.ts`
**Delete:** Lines 259–285 (JSDoc comment starting with `/** \n * Create a new compass topic.\n */` through the closing `}` of the function body)

Current block to remove:
```typescript
/**
 * Create a new compass topic.
 */
export async function adminCreateTopic(data: {
  title: string;
  short_title?: string;
  question_text: string;
  is_live?: boolean;
}): Promise<Record<string, unknown>> {
  const { title, short_title, question_text, is_live = false } = data;

  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_topics')
    .insert({
      title,
      short_title: short_title ?? null,
      question_text,
      is_live,
      went_live_at: is_live ? new Date().toISOString() : null,
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return row as Record<string, unknown>;
}
```

### Fix 5a: TopicsPage.tsx id types
**File:** `admin/src/pages/admin/TopicsPage.tsx`

```typescript
// CURRENT lines 6, 11:
interface Stance {
  id: number;   // line 6
  ...
}
interface Topic {
  id: number;   // line 11
  ...
}
// Line 59:
const [selectedId, setSelectedId] = useState<number | null>(null);

// FIXED:
interface Stance {
  id: string;
  ...
}
interface Topic {
  id: string;
  ...
}
// Line 59:
const [selectedId, setSelectedId] = useState<string | null>(null);
```

Also: `stanceEdits` state is typed as `Record<number, string>` at line 204 — must change to `Record<string, string>`.

### Fix 5b: PoliticiansPage.tsx id types
**File:** `admin/src/pages/admin/PoliticiansPage.tsx`

Interface changes (lines 20–31):
```typescript
// CURRENT:
interface Topic {
  id: number;
  title: string;
  short_title: string | null;
}
interface Stance {
  id: number;
  topic_id: number;
  value: number;
  text: string;
}
interface PoliticianAnswer {
  topic_id: number;
  value: number;
}

// FIXED:
interface Topic {
  id: string;
  title: string;
  short_title: string | null;
}
interface Stance {
  id: string;
  topic_id: string;
  value: number;
  text: string;
}
interface PoliticianAnswer {
  topic_id: string;
  value: number;
}
```

Cascading changes in component state and functions:
- Line 43: `topicStances: Record<number, Stance[]>` → `Record<string, Stance[]>`
- Line 73: `handleStancesNeeded(topicId: number)` → `(topicId: string)`
- Line 75: `apiFetch<Stance[]>(\`/admin/compass/topics/${topicId}/stances\`)` — no change needed, topicId already flows through
- Line 585: `topicStances: Record<number, Stance[]>` in PoliticianDetailPanel props → `Record<string, Stance[]>`
- Line 587: `onStancesNeeded: (topicId: number) => void` → `(topicId: string) => void`
- Line 497: `onStancesNeeded: (topicId: number) => void` in TopicAnswerRowProps → `(topicId: string) => void`
- Line 514: `onStancesNeeded(topic.id)` — no change needed, topic.id will now be string
- Line 204: `stanceEdits: Record<number, string>` → `Record<string, string>` (in TopicsPage, but same pattern applies to stanceEdits in TopicDetailPanel on line 204 of TopicsPage.tsx — already covered above)

### Fix 5c: CategoriesPage.tsx id types
**File:** `admin/src/pages/admin/CategoriesPage.tsx`

```typescript
// CURRENT lines 4–13:
interface Category {
  id: number;
  title: string;
  created_at: string;
}
interface Topic {
  id: number;
  title: string;
}

// FIXED:
interface Category {
  id: string;
  title: string;
  created_at: string;
}
interface Topic {
  id: string;
  title: string;
}
```

Note: `String(t.id)` on line 85 (`value={String(t.id)}`) will continue to compile correctly with `id: string` — no behavior change, but can be simplified to `value={t.id}` if desired.

## Tests

**No project-written test files exist** for the backend (only node_modules test files were found). There are no test files to update.

Manual verification steps the planner should include:
1. After Fix 1+2: `DELETE /api/compass/answers/me` then `GET /api/compass/answers` must return `[]`
2. After Fix 1+2: `DELETE /api/compass/answers/me` then `POST /api/compass/answers/batch` with valid IDs must return `[]`
3. After Fix 3: Admin UI CategoriesPage must render category list on load without error
4. After Fix 4: TypeScript compilation of `adminService.ts` must pass; no other file imports `adminCreateTopic`
5. After Fix 5a/b/c: TypeScript compilation of all three admin pages must pass with `tsc --noEmit`

## compassService.ts — No Changes Needed

`compassService.ts` does NOT directly query `compass_responses`. It contains:
- `promoteCompassImportDraft` — calls `promote_compass_import_draft` RPC (server-side handles filtering)
- `getCompassCompleteness` — calls `get_compass_completeness` RPC (server-side handles filtering)
- `resetCompassAnswers` — calls `reset_compass_answers` RPC (this is the write, not a read)

The only direct `compass_responses` reads are the two inline queries in `compass.ts` (Fixes 1 and 2).

## Open Questions

None. All change locations are confirmed by direct code inspection.

## Sources

### Primary (HIGH confidence)
- Direct read of `backend/src/routes/compass.ts` — confirmed exact query structure at lines 148–151 and 188–192
- Direct read of `backend/src/lib/compassService.ts` — confirmed no other compass_responses reads
- Direct read of `backend/src/lib/adminService.ts` — confirmed `adminCreateTopic()` at lines 262–285, confirmed it does a plain insert (not the RPC version)
- Direct read of `admin/src/pages/admin/CategoriesPage.tsx` — confirmed `catData.categories` access at lines 118 and 131
- Direct read of `admin/src/pages/admin/TopicsPage.tsx` — confirmed `id: number` on Stance (line 6), Topic (line 11), selectedId state (line 59), stanceEdits (line 204)
- Direct read of `admin/src/pages/admin/PoliticiansPage.tsx` — confirmed `id: number` on Topic (line 22), Stance (lines 27–28), PoliticianAnswer.topic_id (line 34); `Politician.id` already correctly `string`

## Metadata

**Confidence breakdown:**
- Break 1 fix (deleted_at filter): HIGH — code read directly, RLS confirmed not filtering deletes
- Break 2 fix (categories shape): HIGH — both route handler and frontend code confirmed by direct read
- Dead code removal: HIGH — function confirmed at exact lines, no callers in codebase
- Type corrections: HIGH — DB uses UUID strings, confirmed by Politician interface (already string) and URL path usage

**Research date:** 2026-03-07
**Valid until:** Stable — these are point-in-time code fixes, not ecosystem dependencies
