# Empower promotion legal-name guard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Empower promotion refuse with `NO_LEGAL_NAME` when there is no usable legal name, instead of silently publishing an empty public name and a bare slug once the identity vault nulls `connected_profiles.legal_name`.

**Architecture:** A backend fail-safe in two guard points — an authoritative refuse in `confirmEmpowerment` (never calls `execute_empowerment` with an empty name) and an `eligible:false` failure in `runPreflight` (upfront signal) — plus a `/confirm` route mapping to HTTP 422. No UI, no schema, no migration.

**Tech Stack:** TypeScript / Express (`backend/src`), Vitest + supertest.

**Spec:** [`docs/superpowers/specs/2026-09-18-empower-promotion-legal-name-guard-design.md`](../specs/2026-09-18-empower-promotion-legal-name-guard-design.md)

## Global Constraints

- **Report to Chris in ASD-STE100 Simplified Technical English** (chat only; code/comments/commits follow repo conventions).
- **Error code is exactly `NO_LEGAL_NAME`**; surfaced as HTTP **422** on `POST /api/empower/confirm`, and as a `failures[]` entry (HTTP 200) on `POST /api/empower/preflight`.
- **Whitespace-only names count as empty** — resolve with `.trim()`.
- **Never call `execute_empowerment` with an empty `p_legal_name`.** Pass the resolved (non-empty) value through unchanged; do not otherwise trim/rewrite the stored name.
- **Scope:** only `backend/src/lib/empowerService.ts`, `backend/src/routes/empower.ts`, and their tests. No `app/`/`admin/` changes, no schema, no migration, no RPC change, no demotion/consent changes.
- **Commit with an explicit pathspec** (`git commit -F <msg> -- <path> …`); never `git add -A`/`.`/`-a` (shared worktree). Trailer exactly `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Toolchain green: `npm run typecheck --prefix backend`, `npm run lint --prefix backend`.
- Run a single test file with `npm test --prefix backend -- <path>`.

## File Structure

- `backend/src/lib/empowerService.ts` — the two guards (Task 1). Existing file; small additions to `confirmEmpowerment` and `runPreflight`.
- `backend/src/lib/empowerService.confirmName.test.ts` — unit tests for the guards (Task 1). Existing file; extend.
- `backend/src/routes/empower.ts` — `/confirm` 422 mapping (Task 2). Existing file; one branch added to the catch.
- `backend/src/routes/empower.test.ts` — route test for the 422 (Task 2). New file; follows the `admin.test.ts` express()+supertest pattern.

---

### Task 1: Service-layer legal-name guard

**Files:**
- Modify: `backend/src/lib/empowerService.ts` (`confirmEmpowerment` ~296-305; `runPreflight` ~188-193)
- Test: `backend/src/lib/empowerService.confirmName.test.ts` (extend)

**Interfaces:**
- Consumes (unchanged signatures): `runPreflight(userId: string, confirmedLegalName?: string): Promise<PreflightResult>`, `confirmEmpowerment(userId: string, consentedItems: string[], confirmedLegalName?: string)`. Both already normalize `const confirmed = confirmedLegalName?.trim() ? confirmedLegalName : undefined;`.
- Produces:
  - `confirmEmpowerment` throws `Error` with `.code = 'NO_LEGAL_NAME'` when no usable name exists, before calling `execute_empowerment`.
  - `runPreflight` returns `{ eligible: false, failures: [{ code: 'NO_LEGAL_NAME', message }] }` (carrying `demotion_context` when present) when no usable name exists.

- [ ] **Step 1: Write the failing tests**

Append to `backend/src/lib/empowerService.confirmName.test.ts`:

```typescript
describe('confirmEmpowerment — legal-name guard', () => {
  beforeEach(() => {
    rpc.mockReset();
    single.mockReset();
    adminRpc.mockReset();
    cacheGet.mockReset();
    cacheSet.mockReset();
    cacheDel.mockReset();
    poolQuery.mockReset();
  });

  it('refuses with NO_LEGAL_NAME and does NOT call execute_empowerment when no name is available', async () => {
    cacheGet.mockResolvedValue('reserved-slug-x'); // past the PREFLIGHT_EXPIRED check
    single.mockResolvedValue({ data: { id: 'cp-9', legal_name: null }, error: null });
    rpc.mockResolvedValue({ data: { id: 'ep-9' }, error: null });
    poolQuery.mockResolvedValue({ rows: [] });

    await expect(confirmEmpowerment('user-9', ['legal_name_public'])).rejects.toMatchObject({
      code: 'NO_LEGAL_NAME',
    });
    expect(rpc.mock.calls.find((c) => c[0] === 'execute_empowerment')).toBeUndefined();
  });

  it('refuses when the confirmed name is whitespace-only and the DB name is null', async () => {
    cacheGet.mockResolvedValue('reserved-slug-y');
    single.mockResolvedValue({ data: { id: 'cp-10', legal_name: null }, error: null });
    rpc.mockResolvedValue({ data: { id: 'ep-10' }, error: null });
    poolQuery.mockResolvedValue({ rows: [] });

    await expect(confirmEmpowerment('user-10', ['legal_name_public'], '   ')).rejects.toMatchObject({
      code: 'NO_LEGAL_NAME',
    });
    expect(rpc.mock.calls.find((c) => c[0] === 'execute_empowerment')).toBeUndefined();
  });
});

describe('runPreflight — legal-name guard', () => {
  beforeEach(() => {
    rpc.mockReset();
    single.mockReset();
    adminRpc.mockReset();
    cacheGet.mockReset();
    cacheSet.mockReset();
    cacheDel.mockReset();
    poolQuery.mockReset();
  });

  it('returns eligible:false NO_LEGAL_NAME (and reserves no slug) when no name is available', async () => {
    adminRpc.mockResolvedValue({
      data: {
        eligible: true,
        connected_profile: { legal_name: null, candidate_role: 'city_council' },
        empowered_profile: null,
        compass_completeness: { required: 5, answered: 5, percent: 100, complete: true },
        is_demoted: false,
      },
      error: null,
    });

    const result = await runPreflight('user-11'); // no confirmed name

    expect(result.eligible).toBe(false);
    if (!result.eligible) {
      expect(result.failures.some((f) => f.code === 'NO_LEGAL_NAME')).toBe(true);
    }
    expect(cacheSet).not.toHaveBeenCalled();
  });

  it('stays eligible when a confirmed name is given even though the DB legal_name is null', async () => {
    adminRpc.mockResolvedValue({
      data: {
        eligible: true,
        connected_profile: { legal_name: null, candidate_role: 'city_council' },
        empowered_profile: null,
        compass_completeness: { required: 5, answered: 5, percent: 100, complete: true },
        is_demoted: false,
      },
      error: null,
    });
    cacheSet.mockResolvedValue(undefined);

    const result = await runPreflight('user-12', 'Ada Lovelace');

    expect(result.eligible).toBe(true);
    if (result.eligible) {
      expect(result.summary.legal_name).toBe('Ada Lovelace');
      expect(result.summary.slug_preview.startsWith('ada-lovelace-')).toBe(true);
    }
  });
});
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `npm test --prefix backend -- src/lib/empowerService.confirmName.test.ts`
Expected: the four new tests FAIL — `confirmEmpowerment` currently calls `execute_empowerment` with `p_legal_name: ''` (no throw), and `runPreflight` currently returns `eligible:true` with an empty name (reserving a `-<suffix>` slug). The pre-existing tests still pass.

- [ ] **Step 3: Add the guard to `confirmEmpowerment`**

In `backend/src/lib/empowerService.ts`, in `confirmEmpowerment`, replace the block that builds `connectedProfile` and calls the RPC (currently around lines 296-305):

```typescript
  const connectedProfile = connectedData as { id: string; legal_name: string | null };

  // 3. Call the execute_empowerment RPC — atomically creates/updates empowered_profiles
  //    and sets compass visibility to public
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_empowerment', {
      p_user_id: userId,
      p_legal_name: confirmed ?? connectedProfile.legal_name ?? '',
      p_connected_profile_id: connectedProfile.id,
      p_reserved_slug: reservedSlug,
    });
```

with:

```typescript
  const connectedProfile = connectedData as { id: string; legal_name: string | null };

  // Fail-safe: never publish an empty public name. With the id_vault enabled a new
  // member's DB legal_name is NULL; if no confirmed name was supplied, refuse rather
  // than writing '' to empowered_profiles. (spec 2026-09-18-empower-promotion-legal-name-guard)
  const legalNameForRpc = confirmed ?? connectedProfile.legal_name ?? '';
  if (!legalNameForRpc.trim()) {
    const err = new Error('A legal name is required to publish an Empowered profile.');
    (err as NodeJS.ErrnoException).code = 'NO_LEGAL_NAME';
    throw err;
  }

  // 3. Call the execute_empowerment RPC — atomically creates/updates empowered_profiles
  //    and sets compass visibility to public
  const { data, error } = await supabaseAdmin
    .schema('empower')
    .rpc('execute_empowerment', {
      p_user_id: userId,
      p_legal_name: legalNameForRpc,
      p_connected_profile_id: connectedProfile.id,
      p_reserved_slug: reservedSlug,
    });
```

- [ ] **Step 4: Add the guard to `runPreflight`**

In the same file, in `runPreflight`, the eligible branch begins with:

```typescript
  // Eligible — reserve slug and build summary
  const connected = result.connected_profile!;
  const empowered = result.empowered_profile ?? null;
  const isDemoted = result.is_demoted ?? false;
  const compassCompleteness = result.compass_completeness!;

  let slugPreview: string;
```

Insert the guard between the `compassCompleteness` line and `let slugPreview: string;`:

```typescript
  const compassCompleteness = result.compass_completeness!;

  // Fail-safe: a public Empowered profile needs a real name. With the id_vault enabled
  // connected.legal_name is NULL for new members; if no confirmed name was supplied,
  // report ineligible rather than reserving an empty-name slug. Placed before the
  // fresh/re-empowerment branch so a re-empowerment cannot blank an existing public
  // name either. (spec 2026-09-18-empower-promotion-legal-name-guard)
  const resolvedName = confirmed ?? connected.legal_name ?? '';
  if (!resolvedName.trim()) {
    return {
      eligible: false,
      failures: [
        { code: 'NO_LEGAL_NAME', message: 'Confirm your legal name to go public as an Empowered profile.' },
      ],
      ...(result.demotion_context ? { demotion_context: result.demotion_context } : {}),
    };
  }

  let slugPreview: string;
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `npm test --prefix backend -- src/lib/empowerService.confirmName.test.ts`
Expected: PASS — the four new tests plus all pre-existing tests in the file.

- [ ] **Step 6: Typecheck and lint**

Run: `npm run typecheck --prefix backend && npm run lint --prefix backend`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
printf '%s\n' \
  'feat(empower): refuse promotion with NO_LEGAL_NAME instead of publishing an empty name' \
  '' \
  'confirmEmpowerment now throws NO_LEGAL_NAME before execute_empowerment when neither a' \
  'confirmed name nor a DB legal_name is available; runPreflight returns eligible:false' \
  'NO_LEGAL_NAME in the same case. Closes the id-vault readiness gap (empty public name/slug).' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/empguard1.txt
git commit -F /tmp/empguard1.txt -- backend/src/lib/empowerService.ts backend/src/lib/empowerService.confirmName.test.ts
```

---

### Task 2: `/confirm` route → 422, and route test

**Files:**
- Modify: `backend/src/routes/empower.ts` (the `POST /confirm` catch block, ~114-128)
- Test: `backend/src/routes/empower.test.ts` (new — express()+supertest, mirrors `admin.test.ts`)

**Interfaces:**
- Consumes: `confirmEmpowerment` throwing an `Error` with `.code = 'NO_LEGAL_NAME'` (Task 1).
- Produces: `POST /api/empower/confirm` responds `422 { code: 'NO_LEGAL_NAME', message }` when that error is thrown.

- [ ] **Step 1: Write the failing route test**

Create `backend/src/routes/empower.test.ts`:

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// empower.ts imports the auth/tier middleware and empowerService at module scope.
// Mock them so the router mounts without real Supabase/DB env (env.js would otherwise
// process.exit(1) under vitest — same convention as admin.test.ts).
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    next();
  },
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

const { mockRunPreflight, mockConfirmEmpowerment, mockExecuteDemotion } = vi.hoisted(() => ({
  mockRunPreflight: vi.fn(),
  mockConfirmEmpowerment: vi.fn(),
  mockExecuteDemotion: vi.fn(),
}));
vi.mock('../lib/empowerService.js', () => ({
  runPreflight: mockRunPreflight,
  confirmEmpowerment: mockConfirmEmpowerment,
  executeDemotion: mockExecuteDemotion,
}));

import empowerRouter from './empower.js';

const app = express();
app.use(express.json());
app.use('/api/empower', empowerRouter);

const fullConsent = {
  consent: { legal_name_public: true, compass_stances_public: true, platform_terms: true },
};

beforeEach(() => {
  mockRunPreflight.mockReset();
  mockConfirmEmpowerment.mockReset();
  mockExecuteDemotion.mockReset();
});

describe('POST /api/empower/confirm — NO_LEGAL_NAME mapping', () => {
  it('maps a NO_LEGAL_NAME error from confirmEmpowerment to 422', async () => {
    const err = new Error('A legal name is required to publish an Empowered profile.');
    (err as NodeJS.ErrnoException).code = 'NO_LEGAL_NAME';
    mockConfirmEmpowerment.mockRejectedValue(err);

    const res = await request(app).post('/api/empower/confirm').send(fullConsent);

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('NO_LEGAL_NAME');
  });

  it('still returns 201 on success', async () => {
    mockConfirmEmpowerment.mockResolvedValue({ empowered_profile: { id: 'ep-1' } });

    const res = await request(app).post('/api/empower/confirm').send(fullConsent);

    expect(res.status).toBe(201);
    expect(res.body.empowered).toBe(true);
  });
});
```

- [ ] **Step 2: Run the route test to verify the 422 case fails**

Run: `npm test --prefix backend -- src/routes/empower.test.ts`
Expected: the `422` test FAILS (the route currently falls through to the generic 500 for an unrecognized error). The `201` success test passes.

- [ ] **Step 3: Add the 422 mapping to the `/confirm` catch**

In `backend/src/routes/empower.ts`, in the `POST /confirm` handler's `catch`, the current block is:

```typescript
      if (errMessage.includes('PREFLIGHT_EXPIRED') || errCode === 'PREFLIGHT_EXPIRED') {
        res.status(409).json({
          code: 'PREFLIGHT_EXPIRED',
          message: 'Preflight has expired. Please run preflight again.',
        });
        return;
      }

      console.error('[POST /empower/confirm] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Empowerment failed' });
```

Insert the `NO_LEGAL_NAME` mapping between the `PREFLIGHT_EXPIRED` block and the `console.error`:

```typescript
      if (errMessage.includes('PREFLIGHT_EXPIRED') || errCode === 'PREFLIGHT_EXPIRED') {
        res.status(409).json({
          code: 'PREFLIGHT_EXPIRED',
          message: 'Preflight has expired. Please run preflight again.',
        });
        return;
      }

      if (errMessage.includes('NO_LEGAL_NAME') || errCode === 'NO_LEGAL_NAME') {
        res.status(422).json({
          code: 'NO_LEGAL_NAME',
          message: 'A legal name is required to publish an Empowered profile.',
        });
        return;
      }

      console.error('[POST /empower/confirm] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Empowerment failed' });
```

- [ ] **Step 4: Run the route test to verify it passes**

Run: `npm test --prefix backend -- src/routes/empower.test.ts`
Expected: PASS — both the 422 and the 201 tests.

- [ ] **Step 5: Final verification — typecheck, lint, both test files**

Run:
```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/.claude/worktrees/stoic-kilby-30506c
npm run typecheck --prefix backend \
  && npm run lint --prefix backend \
  && npm test --prefix backend -- src/lib/empowerService.confirmName.test.ts src/routes/empower.test.ts
```
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
printf '%s\n' \
  'feat(empower): map NO_LEGAL_NAME to 422 on POST /api/empower/confirm' \
  '' \
  'Adds the route mapping for the confirmEmpowerment fail-safe, plus a supertest route' \
  'test (422 on NO_LEGAL_NAME, 201 on success).' \
  '' \
  'Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>' > /tmp/empguard2.txt
git commit -F /tmp/empguard2.txt -- backend/src/routes/empower.ts backend/src/routes/empower.test.ts
```

---

## Notes for the executor

- The `confirmEmpowerment` guard must sit **after** `getReservedSlug` and the `connectedProfile` fetch but **before** the `execute_empowerment` call — so a missing name is a `NO_LEGAL_NAME`, and a missing reservation stays `PREFLIGHT_EXPIRED` (order preserved).
- Do not change `p_legal_name`'s value beyond guaranteeing it is non-empty — pass the resolved string through as-is (keeps the stored name consistent with the preflight slug).
- The `?? ''` tails left in the code after the guards are intentionally dead (the guard guarantees non-empty) and kept for type-friendliness — do not "clean them up" into a different resolution.
- No `app/`/`admin/` change: the member promotion UI does not exist yet; when it is built it will send the confirmed name and these guards are its safety net.
