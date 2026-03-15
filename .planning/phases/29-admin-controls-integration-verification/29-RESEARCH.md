# Phase 29: Admin Controls & Integration Verification - Research

**Researched:** 2026-03-15
**Domain:** Admin UI extension (React), Express backend (PATCH endpoint), documentation authoring
**Confidence:** HIGH — all findings from direct codebase inspection; no external sources needed

---

## Summary

Phase 29 has three independent workstreams:

1. **Admin VR editor** — Add `verification_rating` + `vq_hold_until` display and edit controls to the existing `AccountDetailPage.tsx`, backed by a new `PATCH /api/admin/accounts/:userId/verification-rating` endpoint.
2. **Integration smoke test runbook** — Author `docs/SMOKE-TEST-INTEG.md` as a manual checklist for CTC (INTEG-01) and VQ (INTEG-02) live verification.
3. **VQ onboarding doc update** — Extend `docs/ONBOARDING-VQ.md` with a new section documenting `POST /api/vq/confirm-stance` to "Stripe API docs for one endpoint" quality.

All three workstreams are fully independent and can be planned as parallel execution tasks. No migrations are needed — the database schema (Phase 27/28) is already complete.

**Primary recommendation:** Three separate tasks. Task 1 = backend endpoint + TypeScript types + UI. Task 2 = SMOKE-TEST-INTEG.md. Task 3 = ONBOARDING-VQ.md update. All autonomous.

---

## Standard Stack

No new libraries. Everything already in the codebase.

### Core (already present)
| Tool | Purpose | Location |
|------|---------|---------|
| React + useState | Edit mode toggle, form state | `admin/src/pages/admin/AccountDetailPage.tsx` |
| Tailwind v4 | Styling, badge colors | `admin/src/index.css` |
| `apiFetch` | Admin API calls | `admin/src/lib/api.ts` |
| Express + Zod | Route + body validation | `backend/src/routes/admin.ts` |
| `supabaseAdmin` (direct) | VR update (no RPC needed — single-table write) | `backend/src/lib/adminService.ts` |
| `logAdminAction` | Audit trail for every admin mutation | `backend/src/lib/adminService.ts` |

---

## Architecture Patterns

### Pattern 1: Admin Mutation Endpoint (PATCH)

The existing `setAccountStanding` pattern shows the correct shape for a single-table admin update:

```typescript
// backend/src/lib/adminService.ts
export async function setAccountStanding(userId, standing) {
  const { error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .update({ account_standing: standing })
    .eq('user_id', userId);
  if (error) throw new Error(error.message);
}
```

The VR update follows the same pattern. Two fields can be updated in one call:
- `verification_rating` (number, validated 0–150)
- `vq_hold_until` (nullable timestamp — set to `null` to clear the hold)

Route layer calls `logAdminAction` after success. Every admin mutation is logged (established pattern, see ADMN-05).

```typescript
// backend/src/routes/admin.ts
router.patch('/accounts/:userId/verification-rating', async (req, res) => {
  // Zod schema: { verification_rating?: number (0-150), clear_hold?: boolean }
  // Call adminService.updateVerificationRating(userId, data)
  // logAdminAction(actorId(req), 'update_verification_rating', userId, { changes })
  // return { ok: true }
});
```

### Pattern 2: Edit-Mode Toggle in AccountDetailPage

The existing page uses local state for edit mode (e.g., `showDemoteConfirm`, `showPromoteModal`). The VR editor follows the same pattern — no modal needed, inline toggle:

```typescript
const [vrEditMode, setVrEditMode] = useState(false);
const [vrDraft, setVrDraft] = useState({ rating: 0, clearHold: false });
const [vrSaving, setVrSaving] = useState(false);
const [vrError, setVrError] = useState<string | null>(null);
```

**View mode** renders: current `verification_rating` value, `vq_hold_until` date or "None", status badges, "Edit" button.

**Edit mode** renders: number input (0–150), "Clear hold" button (conditional on hold being active), "Save" + "Cancel" buttons.

On save: PATCH → success → `fetchAccount()` (existing refresh function) → exit edit mode.

### Pattern 3: Badge Styling

Brand tokens are defined in `admin/src/index.css`. Use:
- "Red Gems unlocked" badge: `bg-ev-red/10 text-ev-red` (consistent with `gem_balance_red` text color in header)
- "Hold active" badge: `bg-orange-100 text-orange-700` (consistent with orange used for demote actions)

Badges render inline next to the field values in both view and edit mode.

### Pattern 4: ConnectedProfile Interface Extension

`AccountDetailPage.tsx` has a local `ConnectedProfile` interface (line 18). It does not yet include `verification_rating` or `vq_hold_until`. Both must be added:

```typescript
interface ConnectedProfile {
  // ... existing fields ...
  verification_rating: number;          // add
  vq_hold_until: string | null;         // add (ISO string or null)
}
```

The `admin_get_account_detail` RPC uses `SELECT * FROM connect.connected_profiles`, so both fields are already returned in the JSON — the TypeScript interface just hasn't declared them yet.

### Pattern 5: VR Section Placement

Place the VR editor inside the "Admin-Only Fields" amber card (`bg-amber-50 border border-amber-200`), since `vq_hold_until` is internal-only (same privacy class as `tolerance_rating`). The `verification_rating` is technically public but for the admin tool it belongs with the other sensitive admin controls. This keeps the user-facing profile header clean.

### Pattern 6: Smoke Test Runbook Format

Reference: `docs/RUNBOOK-TIGER-LOAD.md` — established runbook format for this project:
- `## Overview` at top
- `## Prerequisites` with checklist (`- [ ]` style)
- `## Step N: [Name]` sections with exact commands and expected outputs
- Code blocks with exact payloads (not pseudocode)
- Post-step verification queries

For `SMOKE-TEST-INTEG.md`, use the same format with:
- Two major sections: `## INTEG-01: CTC Integration` and `## INTEG-02: VQ Integration`
- Each section: Prerequisites, Steps, Verification Checklist, Idempotency Replay (VQ only)

### Pattern 7: ONBOARDING-VQ.md Extension

`docs/ONBOARDING-VQ.md` currently has sections for XP Awards, Gem Awards, Reading User State, etc. The new section `## Stance Confirmation` (or `## VQ Result Submission`) inserts as the primary new service-key operation. Structure:
- Endpoint block
- Authentication note (same Bearer + service key pattern as XP)
- Request body schema (table with field, type, constraints, notes)
- Response body (200, 404, 422, 401 with example bodies)
- Side effects section (each effect with exact numbers)
- Edge case examples (rating floor, hold set)
- Idempotency behavior

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| VR update atomicity | Custom BEGIN/COMMIT via `pg` driver | `supabaseAdmin.from().update()` — single-table update is inherently atomic, no transaction needed |
| Audit logging | Custom log table write | `logAdminAction()` already implemented — call it after every mutation |
| Input validation | Manual range checks | Zod schema with `.min(0).max(150)` — same pattern as all other admin routes |
| Hold date display | Custom date formatter | `new Date(vq_hold_until).toLocaleDateString()` — same pattern as existing date fields |
| Admin auth guard | Per-route middleware | `router.use(requireAuth, requireAdmin)` — already applied to all admin routes |

---

## Common Pitfalls

### Pitfall 1: Forgetting to extend ConnectedProfile interface
**What goes wrong:** TypeScript error accessing `account.connected_profile?.verification_rating` — field is returned from API but not declared in the local interface.
**How to avoid:** Update the `ConnectedProfile` interface in `AccountDetailPage.tsx` before adding JSX that reads these fields.

### Pitfall 2: Not calling fetchAccount() after save
**What goes wrong:** UI shows stale data after successful save — edit mode exits but the displayed value doesn't update.
**How to avoid:** On successful PATCH, call `fetchAccount()` (the existing refresh function at line 158 of AccountDetailPage.tsx) before exiting edit mode.

### Pitfall 3: Clearing hold with wrong null representation
**What goes wrong:** Sending `vq_hold_until: ""` or `vq_hold_until: "null"` instead of actual `null` — Supabase updates the column to the string value, breaking IS NULL checks.
**How to avoid:** Backend PATCH handler: when `clear_hold: true`, set `vq_hold_until = null` explicitly (JavaScript `null`, not string). Supabase JS client serializes `null` correctly to SQL NULL.

### Pitfall 4: Missing logAdminAction call
**What goes wrong:** Admin mutation not audited — violates ADMN-05.
**How to avoid:** Every PATCH/POST/DELETE on an admin account endpoint calls `logAdminAction` after success. Audit log entry should include the changed values.

### Pitfall 5: VQ smoke test — idempotency_key collision
**What goes wrong:** Replaying smoke test re-uses same `idempotency_key` from a previous run, so the first call is immediately cached and you can't test the live path.
**How to avoid:** In `SMOKE-TEST-INTEG.md`, instruct tester to use a datestamped key per run: `smoke-test-vq-2026-03-15-001`. New date per run = guaranteed fresh key.

### Pitfall 6: VQ smoke test — test user has vq_hold_until active
**What goes wrong:** Test user happens to be in hold state from prior test, so incorrect-user test doesn't behave as expected (hold is already set, clock doesn't reset visibly).
**How to avoid:** Prerequisites section in smoke test: check `verification_rating` and `vq_hold_until` for test user in admin tool before starting. Admin tool VR editor (built in this phase) can clear the hold if needed.

### Pitfall 7: ONBOARDING-VQ.md — idempotency key uniqueness guidance
**What goes wrong:** VQ developer uses a quest-scoped key (not user-scoped) — two users submitting the same quest use the same key, second call is a replay with no VR/gem effects for the second batch.
**How to avoid:** Document the idempotency key derivation rule clearly: key must be unique per resolution event (not per quest). Recommended pattern: `vq-resolve-{questId}-{resolutionId}` where `resolutionId` is a unique ID for this consensus resolution.

---

## Code Examples

### Admin service function — updateVerificationRating

```typescript
// backend/src/lib/adminService.ts
// Source: pattern from setAccountStanding (line 129)

export async function updateVerificationRating(
  userId: string,
  params: { verificationRating?: number; clearHold?: boolean }
): Promise<void> {
  const update: Record<string, unknown> = {};
  if (params.verificationRating !== undefined) {
    update.verification_rating = params.verificationRating;
  }
  if (params.clearHold) {
    update.vq_hold_until = null;
  }
  if (Object.keys(update).length === 0) return;

  const { error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .update(update)
    .eq('user_id', userId);

  if (error) throw new Error(error.message);
}
```

### Route Zod schema — VR update

```typescript
// Source: pattern from PATCH /api/admin/compass/topics/:id
const UpdateVrSchema = z.object({
  verification_rating: z.number().int().min(0).max(150).optional(),
  clear_hold: z.boolean().optional(),
}).refine(
  (d) => d.verification_rating !== undefined || d.clear_hold === true,
  { message: 'Must provide verification_rating or clear_hold' }
);
```

### UI — VR display with badges (view mode)

```tsx
// Source: brand token pattern from AccountDetailPage.tsx (lines 333-338)
// amber card context = bg-amber-50 border border-amber-200

<div className="flex items-center gap-2">
  <span className="w-36 font-medium text-amber-700">Verification Rating:</span>
  <span className="text-amber-900">{cp.verification_rating}</span>
  {cp.verification_rating >= 90 && (
    <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-ev-red/10 text-ev-red">
      Red Gems unlocked
    </span>
  )}
</div>
<div className="flex items-center gap-2">
  <span className="w-36 font-medium text-amber-700">VQ Hold Until:</span>
  <span className="text-amber-900">
    {cp.vq_hold_until
      ? new Date(cp.vq_hold_until).toLocaleDateString()
      : 'None'}
  </span>
  {cp.vq_hold_until && new Date(cp.vq_hold_until) > new Date() && (
    <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
      Hold active
    </span>
  )}
</div>
```

---

## Key Facts About Phase 28 Output (VQ endpoint)

The planner needs these facts to write accurate ONBOARDING-VQ.md content and smoke test steps.

**Endpoint:** `POST /api/vq/confirm-stance`

**Auth:** Bearer token using the VQ service key (same `GEMS_SERVICE_KEYS` map as `POST /api/gems/award`, key must have `red` gem type permission)

**Request body:**
```json
{
  "politician_id": "uuid",
  "topic_id": "uuid",
  "confirmed_value": 1-5,
  "correct_user_ids": ["uuid", ...],
  "incorrect_user_ids": ["uuid", ...],
  "idempotency_key": "string (max 255)",
  "gems_amount": 1
}
```
`gems_amount` defaults to `1` (Zod default). `correct_user_ids` and `incorrect_user_ids` default to `[]`.

**Response body (200):**
```json
{
  "politician_id": "uuid",
  "topic_id": "uuid",
  "confirmed_value": 3,
  "correct_count": 2,
  "incorrect_count": 1,
  "users": [
    { "user_id": "uuid", "result": "correct", "gems_awarded": 1, "rating_delta": 3, "new_rating": 63 }
  ],
  "unresolved_users": [],
  "replayed": false
}
```
On idempotent replay: same body + `"replayed": true`.

**Side effects:**
- Correct users: +`gems_amount` Red Gems; `verification_rating` += 3 (cap 150)
- Incorrect users: `verification_rating` -= 10 (floor 0); if floor hit, `vq_hold_until` = now + 30 days
- `inform.politician_answers` upserted with `confirmed_value`

**Error responses:**
- `401 { "error": "UNAUTHORIZED" }` — missing/invalid service key
- `422 { "error": "VALIDATION_ERROR", "issues": [...] }` — Zod validation failure
- `422 { "error": "FORBIDDEN_GEM_TYPE", "permitted": [...] }` — key lacks red gem permission
- `422 { "error": "INVALID_VALUE" }` — confirmed_value outside 1–5
- `404 { "error": "QUESTION_NOT_FOUND" }` — politician/topic pair not found

**Idempotency conflict (same key, different payload):** The RPC returns the original cached result for the key regardless of the new payload — no conflict error. The RPC pre-checks by key only; payload is not part of the cache key. (Note for docs: should advise VQ to use unique keys per resolution event, not to rely on "same payload = same result".)

---

## What the Admin Detail API Already Returns

The `admin_get_account_detail` RPC (defined in `backend/migrations/025_rpc_pool_migration.sql`) uses `SELECT * FROM connect.connected_profiles` — so after Phase 27/28 migrations are applied, the response already contains `verification_rating` and `vq_hold_until` inside `connected_profile`. The `AccountDetailPage.tsx` TypeScript interface does not declare them yet (that's the only gap).

**No migration needed for Phase 29.** The backend data is already there.

---

## Open Questions

1. **`gems_amount` in ONBOARDING-VQ.md**
   - What we know: Zod default is `1`. The field is exposed in the request body and VQ can override it.
   - What's unclear: Does VQ always send `1`, or should the doc explain the use case for other values?
   - Recommendation: Document as "the number of Red Gems to award each correct user. Defaults to 1." Let VQ decide what to send.

2. **Idempotency conflict behavior**
   - What we know: The RPC returns the original cached result for a key, regardless of the new payload. It does NOT error on payload mismatch.
   - Gap: CONTEXT.md says to document "same key, different payload → explicit error case." In practice the endpoint returns 200 with the original result, not an error.
   - Recommendation: Document the actual behavior ("returns the original result, ignores the new payload") with a note that this means payload correctness matters — a bad call that gets cached will replay incorrectly. Advise using unique keys per resolution.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `admin/src/pages/admin/AccountDetailPage.tsx` — UI structure, interface shapes, state patterns, badge patterns
- `backend/src/routes/admin.ts` — existing PATCH/POST patterns, `logAdminAction` usage, auth middleware
- `backend/src/lib/adminService.ts` — `setAccountStanding` as the model for `updateVerificationRating`
- `backend/migrations/025_rpc_pool_migration.sql` — `admin_get_account_detail` RPC; confirmed `SELECT *` includes VR fields
- `supabase/migrations/20260315000037_phase27_verification_rating.sql` — VR column range (0–150), default 60, vq_hold_until semantics
- `supabase/migrations/20260315000038_phase28_vq_confirm_stance.sql` — RPC logic, side effect specifics
- `backend/src/routes/vq.ts` — exact Zod schema, error codes, gems_amount default
- `backend/src/lib/vqService.ts` — ConfirmVqStanceResult shape
- `docs/ONBOARDING-VQ.md` — current doc structure, sections to extend
- `docs/ONBOARDING-CTC.md` — parallel doc structure for format reference
- `docs/RUNBOOK-TIGER-LOAD.md` — established runbook format for smoke test doc
- `admin/src/index.css` — brand tokens: ev-red, ev-yellow, ev-teal
- `.planning/STATE.md` — open blockers (CTC_SERVICE_KEY not yet set), pending todos

---

## Metadata

**Confidence breakdown:**
- Admin VR editor (UI + backend): HIGH — existing patterns are directly applicable, no ambiguity
- Smoke test runbook authoring: HIGH — format from existing runbooks, content from Phase 27/28 schemas
- ONBOARDING-VQ.md update: HIGH — Phase 28 endpoint fully built and inspected; one genuine open question on idempotency conflict behavior documented above
- No external library research needed

**Research date:** 2026-03-15
**Valid until:** Indefinitely for this codebase (no external dependencies)
