# Phase 173: Discovery-Sweep Anthropic Cost & Reliability Hardening - Research

**Researched:** 2026-07-23
**Domain:** Anthropic SDK error handling, cron-job cost control, Node.js/TypeScript backend reliability
**Confidence:** HIGH

## Summary

This phase hardens the existing weekly discovery-sweep cron (`backend/src/cron/discoverySweep.ts` -> `discoveryCron.ts` -> `discoveryService.ts` -> `discoveryAgentRunner.ts`) against three related cost/reliability failure modes surfaced in the 2026-07-23 cron audit: (1) the sweep currently has no pre-flight check and will iterate every jurisdiction even when Anthropic is completely unusable (missing key or exhausted credit), producing 144x "credit balance too low" + 45x key-not-configured log floods; (2) the `withRetry` wrapper's `isTransient()` regex is message-string-based and imprecise, and the phase must guarantee non-retryable Anthropic errors (auth/billing/permission) never multiply spend; (3) `discoveryAgentRunner.ts` currently **throws** when a model turn ends without invoking `report_candidates`, which is a benign, expected outcome (the model searched, found nothing crisp, and stopped) but today gets treated as a hard per-jurisdiction failure (21x observed).

All three fixes are pure application-code changes to a single call chain — no schema change, no new dependency (the `@anthropic-ai/sdk` package is already installed at `^0.91.0`, actual installed version `0.91.0`; `node-cron` is already installed). The Anthropic SDK's typed `APIError` class hierarchy and the current (2026-07-23-verified) official error-code table are the load-bearing facts for OPS-01/OPS-02: credit exhaustion is **HTTP 402, `error.type: "billing_error"`** — not a 429 and not a 5xx, and the installed SDK version (0.91.0) has **no dedicated `BillingError` subclass** for status 402, so a 402 response surfaces as the generic `Anthropic.APIError` base class, not a named subclass. Auth failures are 401 (`AuthenticationError`, `error.type: "authentication_error"`); insufficient permission is 403 (`PermissionDeniedError`, `error.type: "permission_error"`). There is no Anthropic API endpoint that reports remaining credit balance — the Admin Usage & Cost API only reports historical token/cost usage (and requires a separate `sk-ant-admin...` key that does not exist in this codebase's `env.ts`), so a true "check balance before spending" pre-flight is not achievable without an actual API call. The recommended pre-flight mechanism is therefore a **cheap canary Messages call** (minimal `max_tokens`, no tools) made once per sweep, before the jurisdiction loop.

**Primary recommendation:** Add a one-time canary check (`checkAnthropicAvailability()`) at the top of `runDiscoverySweep()` that (a) checks `env.ANTHROPIC_API_KEY` is set, and (b) if set, makes one minimal `client.messages.create()` call; if that call throws an `Anthropic.APIError` with `status` in `{401, 402, 403}`, abort the sweep before touching any jurisdiction and send exactly one operator alert via the existing `sendEmail()`. Separately, rewrite `isTransient()` in `discoveryCron.ts` to check `err instanceof Anthropic.APIError` and branch on `.status` (401/402/403 => never retry; 429/5xx => retry; anything else network-shaped => retry via the existing message regex as a fallback for non-SDK errors). Change `discoveryAgentRunner.ts`'s terminal `throw new Error('Claude did not invoke report_candidates...')` into a normal `return { candidates: [], stopReason: lastStopReason, ... }` — this is a one-line-scope change because `discoveryService.ts` already handles `candidatesFound === 0` as a valid, non-failing outcome (it has an *existing* "zero-candidate regression alert" code path that only fires when a *previous* run found >0, which is exactly the desired "log it, don't fail" semantics).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cron scheduling (Sunday 02:00 UTC registration) | API / Backend (in-process node-cron) | — | Single Render web-service process; no separate scheduler infra exists (confirmed in cron audit) |
| Sweep orchestration, run lock, retry policy | API / Backend (`discoveryCron.ts`) | — | Owns cross-jurisdiction sequencing and the retry/backoff policy |
| Anthropic pre-flight / credit-availability check | API / Backend (`discoveryCron.ts`, new) | Anthropic API (external) | The check is a thin wrapper making one real API call; no separate service needed |
| Per-jurisdiction discovery pipeline (staging, confidence scoring, auto-upsert) | API / Backend (`discoveryService.ts`) | Database / Storage (`essentials.candidate_staging`, `essentials.discovery_runs`) | Business logic + persistence; unaffected by this phase except benefiting from the zero-candidate contract change |
| Anthropic Messages API call + tool-use loop | API / Backend (`discoveryAgentRunner.ts`) | Anthropic API (external, server-side `web_search`) | Sole point of contact with the Anthropic SDK — correctly isolated already |
| Operator alerting | API / Backend (`emailService.ts` -> Resend) | — | Existing `sendEmail()` is fire-and-forget and already used for failure/regression alerts; reuse for the new "sweep skipped" alert |
| Cron cadence / horizon documentation | API / Backend (code comments + this research) | — | No new tier; a pure documentation/confirmation deliverable (OPS-04) |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Pre-flight Anthropic key+credit check before spending; abort sweep + single operator alert if unusable | See "Key Unknown 1" below: no balance-check endpoint exists; recommend a cheap canary Messages call executed once in `runDiscoverySweep()` before the jurisdiction loop, gated first by the existing `env.ANTHROPIC_API_KEY` presence check (zero-cost) |
| OPS-02 | Do NOT retry non-retryable Anthropic errors (credit/quota/auth 401/403) in `withRetry` | See "Key Unknown 2": 402/`billing_error` is the exact confirmed shape for credit exhaustion (not 429, not 5xx); current `isTransient()` regex does not match "402" or "billing_error" text today, but is fragile and message-based — replace with an `instanceof Anthropic.APIError` + `.status` check |
| OPS-03 | A model turn ending without `report_candidates` = clean zero-candidate result (log/count as zero, not thrown, not retried) | See "Key Unknown 3": change the terminal `throw` in `discoveryAgentRunner.ts`'s `runDiscoveryAgent()` loop to a normal return; `discoveryService.ts` already has a correct, non-failing zero-candidate path |
| OPS-04 | Confirm + document Sunday 02:00 UTC cadence and `SWEEP_HORIZON_DAYS=180` as a deliberate cost choice | See "Key Unknown 4": both constants located precisely (`discoverySweep.ts:22`, `discoveryCron.ts:32`); the exact jurisdiction-count-in-horizon is a live prod-data question flagged for the operator, not researched here |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@anthropic-ai/sdk` | `^0.91.0` (installed: `0.91.0`; latest on npm registry: `0.113.0`) [VERIFIED: npm view] | Anthropic Messages API client — already the sole integration point in `discoveryAgentRunner.ts` | Already in use; this phase does not need a version bump to get the error-class hierarchy it needs (`APIError`, `AuthenticationError`, `PermissionDeniedError`, `RateLimitError` all exist unchanged in 0.91.0 — confirmed by reading the installed `node_modules/@anthropic-ai/sdk/core/error.d.ts`) |
| `node-cron` | `^4.2.1` (already installed) | In-process weekly scheduling | Already in use project-wide (confirmed by cron audit); no change needed |

No new packages are introduced by this phase.

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `vitest` | `^2.1.0` (installed) | Test runner for the new unit tests this phase requires | Already the project's only test runner (`package.json` scripts: `test`, `test:unit`, `test:watch`) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Cheap canary Messages call (recommended) | Anthropic Admin Usage & Cost API (`/v1/organizations/usage_report/messages`) | Rejected: requires provisioning and storing a brand-new `sk-ant-admin...` key (not present in `env.ts` today, real infra/secrets work), AND it only reports historical usage/cost — it does **not** expose remaining credit balance, so it cannot actually answer "is there money left" |
| Cheap canary Messages call (recommended) | Fail-fast on the first jurisdiction only (no separate pre-flight) | Rejected as the sole mechanism: the first jurisdiction's call still spends a full paid discovery call (web_search + report_candidates) before the failure is detected — does not meet OPS-01's "does not iterate jurisdictions" / "before it spends any paid call" requirement. Could be layered as defense-in-depth after the canary, but the canary must run first. |
| `instanceof Anthropic.APIError` + `.status` check | Continuing to regex-match `err.message` for `429`/`5\d\d`/`rate.?limit` | Rejected: fragile (matches only accidentally, breaks silently if Anthropic changes wording), and does not exist as a real bug fix — it happens to already exclude 402/401/403 text today, so keeping it does not satisfy "explicitly do not retry" as a verifiable, intentional guarantee |

**Installation:** None required — no new packages.

**Version verification:** `npm view @anthropic-ai/sdk version` returned `0.113.0` (latest on registry) [VERIFIED: npm view, run 2026-07-23]; installed version confirmed via `node_modules/@anthropic-ai/sdk/package.json` is `0.91.0`. The error-class hierarchy this phase depends on (`APIError`, `AuthenticationError` (401), `PermissionDeniedError` (403), `RateLimitError` (429), `InternalServerError` (5xx), and the generic fallback for unmapped statuses including 402) is verified present and unchanged by directly reading the installed `node_modules/@anthropic-ai/sdk/core/error.d.ts` and `error.js` — **not** inferred from training data. A version bump is not required for this phase; note it as an optional follow-up if the planner wants current SDK features (unrelated to OPS-01..04).

## Package Legitimacy Audit

Not applicable — this phase installs no new packages. `@anthropic-ai/sdk` and `node-cron` are pre-existing dependencies already vetted in prior phases; no new `npm install` occurs.

## Architecture Patterns

### System Architecture Diagram

```
Sunday 02:00 UTC (node-cron, in-process on Render backend)
        |
        v
discoverySweep.ts  --calls-->  runDiscoverySweep()  [discoveryCron.ts]
        |
        v
  acquireRunLock()  -- fails? --> log + return (another run in progress)
        |
        v
  +-------------------------------------------+
  | NEW: checkAnthropicAvailability()          |   <-- OPS-01
  |   1. env.ANTHROPIC_API_KEY set?            |
  |      no -> abort, ONE alert email, return  |
  |   2. cheap canary client.messages.create() |
  |      (max_tokens minimal, no tools)        |
  |      APIError w/ status in {401,402,403}?  |
  |      yes -> abort, ONE alert email, return |
  |      other error -> log warning, PROCEED   |
  |      (do not block sweep on ambiguous err) |
  +-------------------------------------------+
        |  (only reached if Anthropic is usable)
        v
  SELECT discovery_jurisdictions
    WHERE election_date in horizon (SWEEP_HORIZON_DAYS=180)  <-- OPS-04
        |
        v
  for (jurisdiction of jurisdictions)   <-- sequential, never Promise.all
        |
        v
    withRetry(() => runDiscoveryForJurisdiction(...))
        |                                        \
        |                                         \-- isTransient(err) rewritten  <-- OPS-02
        |                                             instanceof Anthropic.APIError?
        |                                               status in {401,402,403} -> NEVER retry
        |                                               status 429 or >=500     -> retry (existing backoff)
        |                                             else: message-regex network-fault fallback
        v
  runDiscoveryForJurisdiction()  [discoveryService.ts]
        |
        +--> fetchPageContent() (optional pre-fetch, Playwright-based)
        |
        v
  runDiscoveryAgent()  [discoveryAgentRunner.ts]
        |
        v
  Anthropic Messages API loop (tool_choice: any -> web_search | report_candidates)
        |
        +-- report_candidates called --> return { candidates: [...], stopReason }
        |
        +-- pause_turn (server-side web_search ran) --> append + continue (existing, unchanged)
        |
        +-- NEW: any other stop_reason w/o report_candidates
        |         --> return { candidates: [], stopReason }   <-- OPS-03 (was: throw)
        |
        v
  discoveryService.ts: stage candidates, score confidence, auto-upsert eligible ones,
  write essentials.discovery_runs row (status='completed' even when candidates=0),
  fire zero-candidate REGRESSION alert only if previous run found >0 (EXISTING, unchanged)
        |
        v
  discoveryCron.ts: accumulate autoUpserted / uncertainPending / failedJurisdictions
        |
        v
  ONE sweep-summary email at the end (existing, unchanged) via sendEmail()
        |
        v
  releaseRunLock()  (finally block, existing, unchanged)
```

### Recommended Project Structure

No new files or directories. All changes are in-place edits to the existing four files:

```
backend/src/
├── cron/
│   └── discoverySweep.ts        # unchanged (cron registration only)
├── lib/
│   ├── discoveryCron.ts         # EDIT: add checkAnthropicAvailability() call + rewrite isTransient()
│   ├── discoveryService.ts      # NO EDIT expected (zero-candidate path already correct)
│   ├── discoveryAgentRunner.ts  # EDIT: terminal throw -> return zero-candidate result; export the canary helper
│   └── env.ts                   # NO EDIT (ANTHROPIC_API_KEY already optional + present)
└── routes/
    └── discoveryDashboard.ts    # NO EDIT expected (manual trigger path benefits for free)
```

### Pattern 1: Fail-fast pre-flight gate before a batch/loop of paid external-API calls

**What:** Before iterating N items that each cost money, make exactly one cheap, representative call to confirm the paid service is reachable and authorized; abort the whole batch on a conclusive negative signal, but do not abort on an inconclusive one (network blip, 5xx).

**When to use:** Any cron/batch job where per-item external-API failures are expected to correlate (one root cause — bad key, no credit — causing every item to fail identically), and where the per-item cost of finding that out is non-trivial.

**Example:**
```typescript
// Source: pattern derived from Anthropic API error-code table
// (https://platform.claude.com/docs/en/api/errors, verified 2026-07-23)
// and this codebase's existing env.ts / discoveryAgentRunner.ts guard.
import Anthropic from '@anthropic-ai/sdk';
import { env } from './env.js';

export type AnthropicAvailability =
  | { available: true }
  | { available: false; reason: 'missing_key' | 'unusable'; detail: string };

export async function checkAnthropicAvailability(): Promise<AnthropicAvailability> {
  if (!env.ANTHROPIC_API_KEY) {
    return { available: false, reason: 'missing_key', detail: 'ANTHROPIC_API_KEY is not configured.' };
  }

  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  try {
    // Minimal, cheap canary call — no tools, tiny max_tokens.
    await client.messages.create({
      model: 'claude-haiku-4-5', // cheapest model; this call's only job is to prove the key+credit are usable
      max_tokens: 1,
      messages: [{ role: 'user', content: 'ping' }],
    });
    return { available: true };
  } catch (err) {
    if (err instanceof Anthropic.APIError && err.status !== undefined && [401, 402, 403].includes(err.status)) {
      return { available: false, reason: 'unusable', detail: `${err.status} ${err.type ?? ''}: ${err.message}` };
    }
    // Any other error (network blip, 5xx, timeout) is inconclusive — do NOT block the sweep on it.
    // Re-throw is also acceptable here for the caller to log-and-proceed; see Pitfall 3 below.
    throw err;
  }
}
```

### Pattern 2: Typed error discrimination instead of message-string regex

**What:** Branch retry/non-retry decisions on `instanceof SdkErrorClass` and typed `.status` / `.type` fields, not on substring-matching the human-readable `.message`.

**When to use:** Any place a codebase currently does `/regex/.test(err.message)` to classify an SDK error — this is a general anti-pattern the SDK's own docs warn against ("Catch the SDK's typed classes rather than string-matching error messages").

**Example:**
```typescript
// Source: shared/error-codes.md (this skill) + platform.claude.com/docs/en/api/errors (verified 2026-07-23)
import Anthropic from '@anthropic-ai/sdk';

function isRetryable(err: unknown): boolean {
  if (err instanceof Anthropic.APIError) {
    // Auth / billing / permission are NEVER retryable — retrying spends money on a guaranteed-to-fail call.
    if (err.status === 401 || err.status === 402 || err.status === 403) return false;
    // Rate limit and server errors ARE retryable (existing backoff behavior, now made explicit).
    if (err.status === 429 || (typeof err.status === 'number' && err.status >= 500)) return true;
    // Other 4xx (400 bad request, 404, 409, 422, 413) are not transient — a retry will fail identically.
    return false;
  }
  // Non-SDK errors (DB connection, fetchPageContent, etc.) — keep the existing network-fault heuristic.
  const msg = err instanceof Error ? err.message : String(err);
  return /ECONNRESET|ETIMEDOUT|ENOTFOUND|fetch failed/i.test(msg);
}
```

### Pattern 3: Benign no-result outcome instead of thrown error

**What:** When an agentic tool-use loop can legitimately "find nothing" without any actual failure (correct behavior, just an empty result), return a typed empty/zero result from the function rather than throwing — let the caller's existing "zero results" handling do its job.

**When to use:** Any LLM tool-use loop where "the model decided not to call the reporting tool" is a valid, expected outcome of the *task* (e.g., a source page had zero candidates) and not evidence of a *bug*.

**Example (the actual before/after for `discoveryAgentRunner.ts`):**
```typescript
// BEFORE (backend/src/lib/discoveryAgentRunner.ts:202-205) — current code, verified by direct read
throw new Error(
  '[discoveryAgentRunner] Claude did not invoke report_candidates. ' +
    'Raw stop_reason: ' + String(lastStopReason)
);

// AFTER — treat as a clean, logged, zero-candidate result
console.warn(
  '[discoveryAgentRunner] Model turn ended without invoking report_candidates; ' +
    'treating as a zero-candidate result. stop_reason=' + String(lastStopReason)
);
return {
  model: lastModel,
  inputTokens: totalInputTokens,
  outputTokens: totalOutputTokens,
  candidates: [],
  stopReason: lastStopReason,
};
```

This works because `discoveryService.ts:283-666` (`runDiscoveryForJurisdiction`) already treats `agentResult.candidates.length === 0` as a **valid completed run** (not a failure) — it writes `discovery_runs.status = 'completed'` with `candidates_found = 0`, and the *only* email it sends in that case is the pre-existing "zero-candidate regression alert" (`discoveryService.ts:593-620`), which itself **only fires when the immediately-prior completed run found > 0 candidates**. A jurisdiction whose source page genuinely has nothing new will therefore stay completely silent after this change — exactly the desired behavior. No change to `discoveryService.ts` is required for OPS-03.

### Anti-Patterns to Avoid

- **Do not classify Anthropic errors by regex on `err.message`.** The exact wording of "credit balance too low" is not a stable API contract (see Common Pitfalls below — the same message text has been observed for at least three different root causes in the wild). Use `instanceof Anthropic.APIError` + `.status`/`.type`.
- **Do not put the credit-availability check inside the per-jurisdiction loop.** It must run exactly once, before the loop, or it does not satisfy "does not iterate jurisdictions" — running it once per jurisdiction would itself become an extra paid call per jurisdiction, defeating the purpose.
- **Do not treat every canary-call failure as "Anthropic is unusable."** A canary call can also fail for reasons that say nothing about whether the *real* per-jurisdiction calls will succeed (a single dropped connection, a transient 529 overloaded_error). Only 401/402/403 are conclusive; treat everything else as inconclusive and let the sweep proceed (the existing per-jurisdiction retry/failure handling remains the safety net for those).
- **Do not silently swallow the OPS-03 case.** Log a `console.warn` (not silence) so operators can still audit which jurisdictions are consistently returning nothing (which may indicate a real upstream source change worth a human look, distinct from the current "hard failure" framing).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting Anthropic-side auth/billing/permission failures | A custom regex over `err.message` (partially exists today) | `err instanceof Anthropic.APIError` + `.status` (401/402/403) | The SDK already exposes typed, versioned status codes and an `error.type` string field designed exactly for this; message text is not a stable contract |
| Checking remaining Anthropic account credit | A scraper/heuristic against the Console UI, or a home-rolled balance-tracking ledger in the DB | A cheap canary Messages call (there is genuinely no balance-check endpoint — confirmed via official docs + community reports) | Anthropic does not expose remaining balance via any documented API, even the Admin Usage & Cost API — building a home-rolled balance tracker would drift from the real account state (webhooks, other consumers of the same key, etc.) and is out of scope for this phase |
| Retry/backoff for genuinely transient errors | A new hand-rolled retry library | Keep the existing `withRetry` + `RETRY_DELAYS_MS` exponential backoff (1s/2s/4s) — only fix its **classification** function | The mechanism is already correct; only the "should I retry this?" predicate needs to change |

**Key insight:** Every piece of this phase is a *classification* fix (which errors get retried, which errors abort the sweep, which model outcomes count as failures), not a *new mechanism*. Resist the temptation to introduce a new retry library, a new alerting channel, or a new balance-tracking table — the existing `withRetry`, `sendEmail`, and `discovery_runs` audit trail are all fit for purpose once the classification logic is corrected.

## Common Pitfalls

### Pitfall 1: Assuming "credit balance too low" always means HTTP 402
**What goes wrong:** A search of public reports (GitHub issues on `anthropics/claude-code`) shows the literal string "Credit balance is too low" has been observed as a symptom of at least three distinct root causes historically, including cases reported as HTTP 400 in some client contexts.
**Why it happens:** The human-readable message is not versioned the way `error.type` and the HTTP status are; different SDKs/wrappers/proxies (Claude Code vs. the raw Messages API vs. third-party gateways) may present the underlying failure differently, and community reports predate the current documented shape.
**How to avoid:** Trust the **currently documented, freshly-verified** shape for the raw Messages API used by this codebase: **402, `error.type: "billing_error"`** [CITED: platform.claude.com/docs/en/api/errors, fetched 2026-07-23]. Branch on `.status` and `.type`, never on message substring, so a future wording change cannot silently break the classification.
**Warning signs:** If a canary/production call throws an `Anthropic.APIError` with `.status === 400` and a message resembling billing language, treat it conservatively as unusable too (do not assume only 401/402/403 are possible) — but log the exact `.status`/`.type`/`.message` so the assumption can be corrected once real prod data is seen.

### Pitfall 2: The existing `isTransient()` regex does not actually retry credit/auth errors today — but the requirement should not rely on that being an accident
**What goes wrong:** Reading `discoveryCron.ts:86-89` literally, `/\b429\b|\b5\d\d\b|ECONNRESET|ETIMEDOUT|ENOTFOUND|fetch failed|rate.?limit/i` does not match the string `"402 Your credit balance is too low..."` nor `"401 ..."` nor `"403 ..."` nor the plain-JS-Error message `"[discoveryAgentRunner] ANTHROPIC_API_KEY is not configured..."`. Taken at face value, these errors are **already not retried** under the current code (they fail `isTransient()` and the loop `break`s immediately).
**Why it happens:** The regex was almost certainly written to catch 429/5xx/network faults and simply never had a 402/401/403 case added or removed — its current "correct" behavior for credit/auth errors appears to be incidental, not intentional/tested.
**How to avoid:** Do not treat "the regex doesn't currently match" as satisfying OPS-02. Replace the message-regex approach entirely with the explicit `instanceof Anthropic.APIError` + `.status` check in Pattern 2 above, so the non-retry behavior for 401/402/403 is **guaranteed by type**, not by an accidental absence of matching substrings. Add a unit test asserting this explicitly (see Validation Architecture below) — this is the only way to close the gap between "happens to work today" and "guaranteed to work."
**Warning signs:** If a future edit to the regex (e.g., someone adds `\b40\d\b` while fixing an unrelated bug) silently starts retrying 401/402/403 errors, that would reintroduce the exact multiplier bug this phase closes. A type-based check does not have this failure mode.

### Pitfall 3: Treating any canary-call failure as "Anthropic is unusable" causes false-positive whole-sweep skips
**What goes wrong:** If the canary check is implemented to abort the sweep on *any* thrown error (not just 401/402/403), a single transient network blip or a momentary 529 overloaded_error during the canary call would skip the **entire week's sweep** for every jurisdiction — a much worse outcome than the status quo (where individual jurisdictions retry and mostly succeed).
**Why it happens:** It's tempting to wrap the canary call in a blanket try/catch and treat any exception as "unusable" for simplicity.
**How to avoid:** Only treat `Anthropic.APIError` instances with `.status` in `{401, 402, 403}` as conclusive "unusable" signals. Any other error from the canary call (network error, 5xx, timeout, `APIConnectionError`) should be logged as a warning and the sweep should **proceed** — the existing per-jurisdiction retry logic remains the safety net for genuinely transient conditions.
**Warning signs:** A sweep-summary email arriving with zero jurisdictions processed on a week when the account was actually fine — check the pre-flight's classification logic first.

### Pitfall 4: Assuming the manual dashboard trigger route needs its own OPS-01 preflight
**What goes wrong:** `discoveryDashboard.ts`'s `POST /discovery/trigger/:id` calls `runDiscoveryForJurisdiction` directly (not through `runDiscoverySweep`), so it does not automatically inherit the new sweep-level pre-flight check.
**Why it happens:** OPS-01 is scoped to "the weekly discovery sweep" specifically (per the requirement text and the phase goal), and the manual trigger is a single-jurisdiction, human-initiated action where the existing `discoveryAgentRunner.ts` missing-key guard (line 105-109) already throws a clear, immediate, single error with no batch amplification risk.
**How to avoid:** Do not scope-creep OPS-01 into the manual dashboard route. Verify (do not modify) that the existing missing-key guard in `discoveryAgentRunner.ts` continues to function correctly for the manual path after the OPS-02/OPS-03 edits, and that OPS-03's zero-candidate change also improves the manual path for free (a manually-triggered run against a quiet jurisdiction will now complete cleanly instead of showing a "failed" status with a confusing message).
**Warning signs:** If a plan task tries to add the canary check to `discoveryDashboard.ts`, flag it as out-of-scope unless CONTEXT.md/discuss-phase explicitly widens the requirement.

## Code Examples

### Full before/after for `discoveryAgentRunner.ts`'s terminal throw (OPS-03)

```typescript
// Source: backend/src/lib/discoveryAgentRunner.ts:191-206 (verified by direct read)

// BEFORE:
    // pause_turn means the model executed a server-side tool and paused.
    // Append its response and continue so it can process results.
    if (response.stop_reason === 'pause_turn') {
      messages.push({ role: 'assistant', content: response.content });
      continue;
    }

    // Any other stop reason (end_turn, max_tokens, etc.) without report_candidates = failure.
    break;
  }

  throw new Error(
    '[discoveryAgentRunner] Claude did not invoke report_candidates. ' +
      'Raw stop_reason: ' + String(lastStopReason)
  );

// AFTER:
    // pause_turn means the model executed a server-side tool and paused.
    // Append its response and continue so it can process results.
    if (response.stop_reason === 'pause_turn') {
      messages.push({ role: 'assistant', content: response.content });
      continue;
    }

    // Any other stop reason (end_turn, max_tokens, etc.) without report_candidates
    // is a BENIGN outcome (per OPS-03) — the model searched and found nothing
    // reportable, or exhausted its turn budget. Log and return zero candidates
    // rather than throwing; discoveryService.ts already treats zero candidates
    // as a valid completed run.
    console.warn(
      '[discoveryAgentRunner] Model turn ended without invoking report_candidates; ' +
        'treating as a zero-candidate result. stop_reason=' + String(lastStopReason)
    );
    return {
      model: lastModel,
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      candidates: [],
      stopReason: lastStopReason,
    };
  }

  // MAX_TURNS exhausted without report_candidates and without a final non-pause_turn
  // response (shouldn't normally happen since every loop iteration either returns or
  // continues, but kept as a defensive fallback matching the original function's contract).
  console.warn(
    '[discoveryAgentRunner] Exhausted MAX_TURNS without invoking report_candidates; ' +
      'treating as a zero-candidate result. stop_reason=' + String(lastStopReason)
  );
  return {
    model: lastModel,
    inputTokens: totalInputTokens,
    outputTokens: totalOutputTokens,
    candidates: [],
    stopReason: lastStopReason,
  };
}
```

Note: the `break` statement inside the `for` loop must become a `return` (as shown) rather than falling through to code after the loop, OR the post-loop `throw` must become a `return` with the same shape — either restructuring is acceptable as long as every non-`pause_turn`, non-`report_candidates` exit path returns a zero-candidate result instead of throwing. The planner/executor should pick whichever reads more cleanly against the existing loop structure.

### `discoveryCron.ts` integration point for the pre-flight (OPS-01)

```typescript
// Source: backend/src/lib/discoveryCron.ts:191-215 (verified by direct read) — insertion point

export async function runDiscoverySweep(): Promise<void> {
  if (!acquireRunLock()) {
    console.warn('[discoveryCron] Skipping sweep — another run is already in progress');
    return;
  }

  try {
    // NEW: OPS-01 pre-flight — abort before any jurisdiction is touched if Anthropic is unusable.
    const availability = await checkAnthropicAvailability();
    if (!availability.available) {
      console.error('[discoveryCron] Aborting sweep — Anthropic unavailable:', availability.detail);
      const adminEmail = process.env.ADMIN_EMAIL;
      if (adminEmail) {
        await sendEmail({
          to: adminEmail,
          subject: `Discovery sweep SKIPPED — Anthropic unavailable (${availability.reason})`,
          html: `<div style="font-family: system-ui, sans-serif; max-width: 560px;">
            <h2>Discovery sweep skipped</h2>
            <p>The weekly discovery sweep did not run because Anthropic is currently unusable:</p>
            <pre style="background:#f5f5f5;padding:10px;border-radius:4px;white-space:pre-wrap;">${escapeHtml(availability.detail)}</pre>
            <p>No jurisdictions were processed — no paid calls were made.</p>
          </div>`,
        });
      } else {
        console.warn('[discoveryCron] ADMIN_EMAIL not set; skip-alert not sent (see error log above)');
      }
      return; // finally block below still releases the lock
    }

    const horizon = new Date();
    horizon.setUTCDate(horizon.getUTCDate() + SWEEP_HORIZON_DAYS);
    // ... existing jurisdiction query + loop, unchanged ...
  } finally {
    releaseRunLock();
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `web_search_20250305` server-side tool (currently used in `discoveryAgentRunner.ts:120`) | `web_search_20260209` (dynamic filtering) on newer Claude models | Dynamic filtering variant introduced for Opus 4.6+/Sonnet 4.6+ tier models | **Not in scope for this phase** — flagged as an observation only. `discoveryAgentRunner.ts` currently hardcodes `model: 'claude-sonnet-4-6'` (line 145) which is still an actively-supported model per the current model catalog; upgrading the model or the web-search tool variant is an unrelated, separate improvement and should not be bundled into this reliability-hardening phase unless the operator explicitly wants it. |
| N/A | N/A | N/A | Nothing else in this call chain is affected by broader Anthropic API changes; this phase's scope is strictly error-classification and control-flow, not model/tool upgrades. |

**Deprecated/outdated:** None relevant to this phase's scope.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A minimal canary Messages call (max_tokens: 1, no tools, `claude-haiku-4-5`) is cheap enough to run unconditionally once per sweep without being a meaningful cost concern | Pattern 1 / Code Examples | If wrong, the fix trades "144 credit-exhaustion failures/week" for "1 extra tiny paid call/week even when things are fine" — this is an intentional, clearly favorable tradeoff, but the exact per-call cost was not measured against a live account in this research (no prod API calls were made) |
| A2 | Treating only HTTP 401/402/403 as "conclusively unusable" (and everything else as "proceed, let per-jurisdiction retry handle it") is the correct scope for the pre-flight | Pattern 1, Pitfall 3 | If Anthropic's real production failure mode for this account is something outside 401/402/403 (e.g., a 400 with `error.type: "billing_error"` in some edge case, or an organization-level suspension surfacing differently), the pre-flight would miss it and the sweep would still iterate all jurisdictions. Recommend logging the raw `.status`/`.type` on every canary failure so this can be tightened from real data after first deploy. |
| A3 | No plan task needs to touch `discoveryDashboard.ts` (the manual on-demand trigger route) | Pitfall 4 | If the operator actually wants the manual trigger to also pre-flight (e.g., an admin clicking "run now" on a dead key), this phase's scope would need to widen — flagged explicitly as an open question below |

## Open Questions

1. **Exact count of `discovery_jurisdictions` currently within the 180-day `SWEEP_HORIZON_DAYS` window (OPS-04)**
   - What we know: `SWEEP_HORIZON_DAYS = 180` is a hardcoded constant at `discoveryCron.ts:32`; the query at `discoveryCron.ts:201-208` selects jurisdictions with `election_date > now() AND election_date <= horizon`.
   - What's unclear: The live row count in prod — this is a pure data question, and per the task's explicit instruction this research did **not** query prod to avoid unnecessary DB load / going outside the research scope. The cron audit's "144x credit balance too low" count over an unspecified window implies dozens of jurisdictions are in-scope per sweep, but the exact current number should be confirmed by the operator (or the executor, read-only) before finalizing whether 180 days / weekly cadence remains the right choice.
   - Recommendation: The plan should include a lightweight read-only verification step (e.g., `SELECT count(*) FROM essentials.discovery_jurisdictions WHERE election_date > now() AND election_date <= now() + interval '180 days'`) as part of OPS-04's "confirm intended" deliverable, run by the executor against prod at plan/execute time, not during this research pass.

2. **Should the pre-flight canary call use `claude-haiku-4-5` (cheapest) or the same model as production (`claude-sonnet-4-6`)?**
   - What we know: A canary call's only job is to prove the *account* (key + credit) is usable, not to prove the specific production model is reachable — 401/402/403 errors are account-level, not model-level, so a cheaper model answers the same question at a fraction of the cost.
   - What's unclear: Whether `claude-haiku-4-5` is provisioned/enabled for this Anthropic organization's workspace the same way `claude-sonnet-4-6` is (unlikely to differ, since these are standard models on any account, but not verified against this specific account).
   - Recommendation: Default to `claude-haiku-4-5` per this research's example code; if the executor discovers the account restricts available models, fall back to the production model (`claude-sonnet-4-6`) for the canary — either choice satisfies OPS-01's intent.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@anthropic-ai/sdk` (npm package) | All of OPS-01/02/03 | Yes (installed) [VERIFIED: read `node_modules/@anthropic-ai/sdk/package.json`] | `0.91.0` | N/A — already a hard dependency of the existing code |
| `ANTHROPIC_API_KEY` (env var, Render backend) | OPS-01 canary call | Presence not verified in this research pass (config is Render-dashboard-managed, not in-repo) [ASSUMED based on the phase's own premise — a configured-but-exhausted key is the documented failure mode being fixed] | — | The pre-flight itself is the fallback: if unset, the sweep aborts cleanly with one alert instead of 45x per-jurisdiction failures |
| `ADMIN_EMAIL` (env var) | OPS-01 skip-alert, existing failure/regression alerts | Presence not verified (Render-dashboard-managed) [ASSUMED — existing code at `discoveryCron.ts:272` already reads it optionally] | — | If unset, `discoveryCron.ts` already logs a console message instead of emailing (existing behavior, preserved for the new skip-alert too) |
| `RESEND_API_KEY` (env var, used inside `sendEmail()`) | Actual email delivery for the new skip-alert | Presence not verified (Render-dashboard-managed) [ASSUMED] | — | `emailService.ts:8-11` already no-ops with a console warning if unset — no code change needed, this is inherited for free |

**Missing dependencies with no fallback:** None — every dependency in this phase already has an existing, safe fallback path in the current code.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest `^2.1.0` (installed; `vitest.config.ts` at repo root of `backend/`) |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `cd backend && npx vitest run src/lib/discoveryCron.test.ts src/lib/discoveryAgentRunner.test.ts` |
| Full suite command | `cd backend && npm test` (runs `vitest run`, includes `src/**/*.{test,spec}.{ts,js}`) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|-------------|
| OPS-01 | Missing `ANTHROPIC_API_KEY` aborts the sweep with zero jurisdictions processed and exactly one alert email | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "missing key"` | ❌ Wave 0 |
| OPS-01 | A canary call throwing a 401/402/403 `Anthropic.APIError` aborts the sweep with zero jurisdictions processed and exactly one alert email | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "unusable credit"` | ❌ Wave 0 |
| OPS-01 | A canary call throwing a non-401/402/403 error (e.g. a 529 or network error) does NOT abort the sweep (jurisdictions still process) | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "inconclusive canary"` | ❌ Wave 0 |
| OPS-02 | `isRetryable`/`isTransient` returns `false` for `Anthropic.APIError` instances with status 401, 402, and 403 | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "non-retryable"` | ❌ Wave 0 |
| OPS-02 | `isRetryable`/`isTransient` returns `true` for status 429 and for a representative 5xx (e.g. 500, 529) | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "retryable"` | ❌ Wave 0 |
| OPS-02 | `withRetry` does not call the retried function a second time when the first attempt throws a 402 `Anthropic.APIError` | unit | `npx vitest run src/lib/discoveryCron.test.ts -t "withRetry does not multiply"` | ❌ Wave 0 |
| OPS-03 | `runDiscoveryAgent` returns `{ candidates: [], stopReason }` (does not throw) when the model's final response has `stop_reason: 'end_turn'` and no `report_candidates` tool_use block | unit | `npx vitest run src/lib/discoveryAgentRunner.test.ts -t "end_turn without report_candidates"` | ❌ Wave 0 |
| OPS-03 | `runDiscoveryForJurisdiction` completes with `status: 'completed'` and `candidatesFound: 0` (not `'failed'`) when `runDiscoveryAgent` returns zero candidates | integration | `npx vitest run src/lib/discoveryService.test.ts -t "zero candidates is not a failure"` | ❌ Wave 0 (new file; existing `discoveryService.ts` behavior already correct, just needs a regression test locking it in) |
| OPS-04 | N/A — documentation/confirmation only, no new automated test | manual-only | N/A (code comment + STATE.md/roadmap note is the deliverable) | — |

### Sampling Rate
- **Per task commit:** `cd backend && npx vitest run src/lib/discoveryCron.test.ts src/lib/discoveryAgentRunner.test.ts` (and `discoveryService.test.ts` once added)
- **Per wave merge:** `cd backend && npm test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `backend/src/lib/discoveryCron.test.ts` — new file; covers OPS-01 (canary gating) and OPS-02 (retry classification). Mock `@anthropic-ai/sdk` (`vi.mock('@anthropic-ai/sdk', ...)` per this codebase's existing mocking convention — see `src/lib/essentialsBrowseService.test.ts` and `src/lib/electionsMapService.test.ts` for the `vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }))` pattern this project already uses; the Anthropic SDK mock follows the same shape, mocking the default-exported class's `messages.create` method), mock `./discoveryService.js`, mock `./emailService.js`, mock `./env.js` to control `ANTHROPIC_API_KEY` presence.
- [ ] `backend/src/lib/discoveryAgentRunner.test.ts` — new file; covers OPS-03 (zero-candidate return path). Mock `@anthropic-ai/sdk` to return controlled `stop_reason` sequences (`pause_turn` then `end_turn` with no tool_use block, etc.) and mock `./env.js` for `ANTHROPIC_API_KEY`.
- [ ] `backend/src/lib/discoveryService.test.ts` — new file (does not exist today); a focused regression test asserting the existing zero-candidate handling in `runDiscoveryForJurisdiction` stays correct after OPS-03 changes the caller's contract (mock `./discoveryAgentRunner.js`, `./db.js`, `./emailService.js`, `./fetchPageContent.js`).
- [ ] Framework install: none — `vitest` is already installed and configured.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Marginal | The pre-flight canary call reuses the existing `env.ANTHROPIC_API_KEY` — no new credential handling introduced; the key is never logged (only `.status`/`.type`/redacted `.message` should be logged, never the key itself) |
| V3 Session Management | No | N/A — this is a server-to-server cron path, no user sessions involved |
| V4 Access Control | No | No new routes or endpoints; `discoveryDashboard.ts` access control (`requireAuth` + `requireAdmin`) is unchanged |
| V5 Input Validation | No | No new user-facing input; the canary call's prompt is a hardcoded literal ("ping"), not derived from any external input |
| V6 Cryptography | No | No new cryptographic operations |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Logging the raw Anthropic API key or full error body (which could contain account-identifying details) in the skip-alert email or console logs | Information Disclosure | Log/email only `.status`, `.type`, and `.message` (already the existing pattern in `discoveryService.ts`'s failure-email code, which truncates messages to 200-500 chars and never logs the API key) — the code examples above follow this same discipline |
| A malicious or compromised jurisdiction config (`discovery_jurisdictions.source_url`) somehow influencing the canary call | Tampering | Not applicable — the canary call is a fixed, hardcoded prompt with no jurisdiction-specific input; it runs once per sweep before any jurisdiction data is even loaded |

## Sources

### Primary (HIGH confidence)
- [Anthropic API errors documentation](https://platform.claude.com/docs/en/api/errors) — fetched 2026-07-23 via WebFetch; authoritative for the full HTTP status -> error.type table, including confirming 402/`billing_error` for billing issues and 403/`permission_error` for permission issues. [CITED: platform.claude.com/docs/en/api/errors]
- `node_modules/@anthropic-ai/sdk/core/error.d.ts` and `error.js` (installed package, version 0.91.0) — read directly; confirms the exact class hierarchy (`APIError`, `BadRequestError` 400, `AuthenticationError` 401, `PermissionDeniedError` 403, `NotFoundError` 404, `ConflictError` 409, `UnprocessableEntityError` 422, `RateLimitError` 429, `InternalServerError` >=500) and confirms status 402 is **not** mapped to a named subclass in this installed version — it falls through to the generic `APIError` base class. [VERIFIED: direct file read of installed SDK source]
- Direct reads of `backend/src/cron/discoverySweep.ts`, `backend/src/lib/discoveryCron.ts`, `backend/src/lib/discoveryService.ts`, `backend/src/lib/discoveryAgentRunner.ts`, `backend/src/lib/env.ts`, `backend/src/lib/emailService.ts`, `backend/src/routes/discoveryDashboard.ts` — all line numbers cited above are from these direct reads. [VERIFIED: direct file reads]
- `npm view @anthropic-ai/sdk version` — confirms latest registry version `0.113.0` vs. installed `0.91.0`. [VERIFIED: npm registry]

### Secondary (MEDIUM confidence)
- [Anthropic Usage and Cost Admin API documentation summary](https://platform.claude.com/docs/en/manage-claude/usage-cost-api) (via WebSearch synthesis, not directly fetched in full) — confirms the endpoint tracks historical usage/cost by workspace/key/model, requires a separate `sk-ant-admin...` key, and does **not** expose remaining credit balance. [CITED: WebSearch summary of platform.claude.com/docs/en/manage-claude/usage-cost-api]

### Tertiary (LOW confidence)
- GitHub issue reports (`anthropics/claude-code` issues #1491, #4207, #867, #54839, #34522, #5300; `anthropics/claude-code-action` #1224) describing "Credit balance is too low" appearing for multiple distinct root causes, and at least one report describing it as a 400 in a specific client context — used only to motivate Pitfall 1 (don't trust message text as a stable signal), not as the basis for any implementation decision. [ASSUMED — community reports, not official documentation; the implementation in this research is based entirely on the HIGH-confidence primary sources above]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; existing installed SDK's error hierarchy read directly from source, not inferred
- Architecture: HIGH — every file, line number, and existing behavior cited in this research was read directly from the actual source files in this repo during this research session
- Pitfalls: HIGH for the isTransient-regex analysis (directly verified against the actual regex and actual documented error shapes) and MEDIUM for the "message text is historically unstable" claim (based on community reports, used only as motivation, not as a load-bearing implementation fact)

**Research date:** 2026-07-23
**Valid until:** 30 days (stable domain — SDK error-class shapes and HTTP status codes are a slow-moving contract; re-verify if the Anthropic API error-code table changes or if `@anthropic-ai/sdk` is upgraded past 0.91.0 before this phase executes)
