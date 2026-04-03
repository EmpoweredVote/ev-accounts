# Phase 51: Essentials XP Source Provisioning - Research

**Researched:** 2026-04-02
**Domain:** Service key provisioning, environment variable configuration, integration documentation
**Confidence:** HIGH

---

## Summary

Phase 51 is a config + docs phase with zero application code changes. All backend
wiring for the Essentials XP service key is already complete and deployed. The gap
is operational: `ESSENTIALS_SERVICE_KEY` has never been assigned a real secret value
in the Render dashboard for `ev-accounts-api`, and the integration guide does not
clearly document which env var name or XP source string the Essentials team must use.

The backend already:
- Defines `ESSENTIALS_SERVICE_KEY` in `backend/.env.example`
- Maps `ESSENTIALS_SERVICE_KEY` → `['essentials-rep-lookup']` in `serviceKeyAuth.ts`
- Lists `'essentials-rep-lookup'` in `XP_SOURCES` in `xpService.ts`
- Validates the source via `z.enum(XP_SOURCES)` and checks `permittedSources` in `xp.ts`

The only work: generate a secret, set it in Render, update `.env.example` comment,
add a focused XP provisioning section to `docs/ESSENTIALS-INTEGRATION.md`, then
run a curl smoke test to confirm the key is accepted end-to-end.

**Primary recommendation:** Generate a strong random secret for `ESSENTIALS_SERVICE_KEY`,
set it in Render, add one targeted section to the integration doc that names the env
var and XP source string explicitly, and verify with a curl call before closing the phase.

---

## Standard Stack

No new libraries. This phase uses only existing infrastructure.

### Existing Components Already Implemented

| Component | File | What It Does |
|-----------|------|-------------|
| `serviceKeyAuth.ts` | `backend/src/middleware/serviceKeyAuth.ts` | Reads env var at module load; maps key → permitted sources; returns 401 on missing/bad key |
| `xpService.ts` | `backend/src/lib/xpService.ts` | Defines `XP_SOURCES` const array; `'essentials-rep-lookup'` is entry 4 |
| `xp.ts` route | `backend/src/routes/xp.ts` | `POST /api/xp/award` — validates body against `XP_SOURCES`, checks `permittedSources` from middleware |
| `.env.example` | `backend/.env.example` | Already has `ESSENTIALS_SERVICE_KEY=your-essentials-service-key` with no additional comment |
| Integration guide | `docs/ESSENTIALS-INTEGRATION.md` | Section 8 names `ESSENTIALS_SERVICE_KEY` once but no dedicated XP-key documentation block |

### Secret Generation

```bash
# Generate a strong 32-byte hex secret (no new library needed)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## Architecture Patterns

### How Service Key Auth Works (verified from source)

At `serviceKeyAuth.ts` module load, `SERVICE_KEY_MAP` is built from env vars:

```typescript
// Only added if env var is defined and non-empty
if (env.ESSENTIALS_SERVICE_KEY) {
  SERVICE_KEY_MAP[env.ESSENTIALS_SERVICE_KEY] = ['essentials-rep-lookup'];
}
```

Implication: if `ESSENTIALS_SERVICE_KEY` is unset in Render, the key is simply absent
from the map. Any request with that header value returns 401 — the endpoint is
effectively disabled. Setting the env var in Render and redeploying enables it.

### POST /api/xp/award Authorization Flow (verified from source)

1. `requireServiceKey` middleware validates `X-Service-Key` header → attaches `permittedSources`
2. Route validates body against `z.enum(XP_SOURCES)` — rejects unknown source strings with 422
3. Route checks `permittedSources.includes(source)` — rejects a valid key using a wrong source with 422 `SOURCE_NOT_PERMITTED`
4. `awardXp()` delegates to `award_xp` Postgres RPC — idempotency enforced at DB layer

### Render Environment Variable Configuration

Render environment variables are set per-service in the Render dashboard:
- Service: `ev-accounts-api`
- Environment group or per-service env var: `ESSENTIALS_SERVICE_KEY`
- After setting, Render redeploys automatically (or trigger manually)
- The new value is live after the deploy completes

No code deploy is required — env var changes trigger a redeploy of the existing build.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Secret generation | Custom entropy source | `crypto.randomBytes(32).toString('hex')` | Node built-in, cryptographically secure |
| Key distribution | Embed in docs | Share via secure channel (1Password/Render dashboard directly) | Keys should not be committed to git |

---

## Common Pitfalls

### Pitfall 1: `.env.example` comment is sparse

**What goes wrong:** The current `.env.example` line is `ESSENTIALS_SERVICE_KEY=your-essentials-service-key`
with no comment explaining what XP source it authorizes or how it is used.

**How to avoid:** Add an inline comment:
```
# XP service key for the Essentials app — authorizes source: "essentials-rep-lookup"
ESSENTIALS_SERVICE_KEY=your-essentials-service-key
```

**Warning signs:** Other keys in the file (`QUEST_SERVICE_KEY`, `TRIVIA_SERVICE_KEY`) also lack
comments on their authorized sources — the pattern should be consistent.

### Pitfall 2: Integration doc names the env var inconsistently

**What goes wrong:** `docs/ESSENTIALS-INTEGRATION.md` Section 8 says:
> "The `ESSENTIALS_SERVICE_KEY` env var slot exists; the Accounts team sets its value and shares it with you."

But the POST /api/xp/award example code at line 469 shows `process.env.ESSENTIALS_SERVICE_KEY` 
directly — which is correct. However, there is no dedicated "XP Service Key Setup" section 
that consolidates: env var name, authorized XP source string, and example curl test. The 
Essentials dev must piece this together from multiple paragraphs.

**How to avoid:** Add a focused "XP Service Key" subsection under Section 8 that states:
- Env var to request: `ESSENTIALS_SERVICE_KEY`
- Authorized source string: `"essentials-rep-lookup"`
- Example curl call with both pieces together

### Pitfall 3: Smoke test requires a real Connected user UUID

**What goes wrong:** `POST /api/xp/award` requires `user_id` to be a UUID for a user with
a `connect.connected_profiles` row. A random UUID or a non-Connected user returns 403
`NOT_CONNECTED`. The smoke test must use a real Connected user's UUID.

**How to avoid:** Use a known test user (e.g., Chris's UUID `4e6dde8f...`) for the smoke test.
The idempotency key should be test-specific so it does not pollute real XP history — use a
clearly-marked test key like `essentials:smoke-test:phase51:{uuid}`.

### Pitfall 4: Render redeploy is required after setting the env var

**What goes wrong:** Setting the env var in Render without a deploy means the running process
still has the old (unset) value. `SERVICE_KEY_MAP` is built at module load time — a restart
is required to pick up the new key.

**How to avoid:** After setting the var, trigger or wait for a Render deploy before running
the smoke test. Render auto-deploys on env var save by default, but confirm the deploy
completed before testing.

---

## Code Examples

### Curl Smoke Test

```bash
# Replace with real values before running
ESSENTIALS_KEY="<provisioned-key-value>"
CONNECTED_USER_UUID="4e6dde8f-..."   # A real Connected user UUID

curl -s -w "\nHTTP %{http_code}" \
  -X POST https://accounts.empowered.vote/api/xp/award \
  -H "Content-Type: application/json" \
  -H "X-Service-Key: $ESSENTIALS_KEY" \
  -d "{
    \"user_id\": \"$CONNECTED_USER_UUID\",
    \"source\": \"essentials-rep-lookup\",
    \"amount\": 10,
    \"idempotency_key\": \"essentials:smoke-test:phase51:$CONNECTED_USER_UUID\"
  }"

# Expected: HTTP 200, body contains is_duplicate: false (first call) or true (repeat)
```

### .env.example Comment Pattern (for consistency with other keys)

```bash
# XP service keys — one per feature repo; each key authorizes specific XP source(s)
QUEST_SERVICE_KEY=your-quest-service-key           # source: "validation_quest_completion"
TRIVIA_SERVICE_KEY=your-trivia-service-key         # source: "civic_trivia_championship_score"
ADMIN_SERVICE_KEY=your-admin-service-key           # source: "admin_gift"
ESSENTIALS_SERVICE_KEY=your-essentials-service-key # source: "essentials-rep-lookup"
```

### Integration Doc Addition — XP Service Key Section

The following should be added to `docs/ESSENTIALS-INTEGRATION.md` Section 8 after the
"Coordination Required" block, as a dedicated subsection:

```markdown
### XP Service Key

The Essentials backend uses `ESSENTIALS_SERVICE_KEY` to award XP via `POST /api/xp/award`.

**Setup steps:**
1. Request key provisioning from the Accounts team (Render dashboard — `ev-accounts-api`)
2. Add to Essentials backend env: `ESSENTIALS_SERVICE_KEY=<value from Accounts team>`
3. Use in award calls: `'X-Service-Key': process.env.ESSENTIALS_SERVICE_KEY`
4. Source string: `"essentials-rep-lookup"` — use exactly this string in `source` field

**Verify the key is working (replace values before running):**
```bash
curl -X POST https://accounts.empowered.vote/api/xp/award \
  -H "Content-Type: application/json" \
  -H "X-Service-Key: $ESSENTIALS_SERVICE_KEY" \
  -d '{"user_id":"<connected-user-uuid>","source":"essentials-rep-lookup","amount":10,"idempotency_key":"essentials:key-test:<uuid>"}'
```
Expected: HTTP 200 with `"is_duplicate": false`.
```

---

## State of the Art

| Old State | Current State | Impact |
|-----------|--------------|--------|
| `ESSENTIALS_SERVICE_KEY` unprovisioned — endpoint disabled | Set value in Render → endpoint enabled, Essentials can award XP | Unblocks Essentials XP integration |
| Integration doc lacks dedicated XP key section | Add explicit subsection with env var name + source string | Essentials team has clear reference |

---

## Open Questions

None. All unknowns are resolved:

1. **Is the code already complete?** Yes — verified in `serviceKeyAuth.ts`, `xpService.ts`, `xp.ts`.
2. **What env var name?** `ESSENTIALS_SERVICE_KEY` — confirmed in source and `.env.example`.
3. **What XP source string?** `"essentials-rep-lookup"` — confirmed in `XP_SOURCES` const.
4. **What does the doc currently say?** Section 8 partially covers this but lacks a focused block.
5. **What user UUID for smoke test?** Use a known Connected user (e.g., Chris `4e6dde8f-...`).

---

## Sources

### Primary (HIGH confidence)

- `backend/src/middleware/serviceKeyAuth.ts` — verified `ESSENTIALS_SERVICE_KEY` mapping and `SERVICE_KEY_MAP` build logic
- `backend/src/lib/xpService.ts` — verified `XP_SOURCES` const includes `'essentials-rep-lookup'`
- `backend/src/routes/xp.ts` — verified `AwardXpBodySchema`, `permittedSources` check, error codes
- `backend/.env.example` — verified current state of env var comment
- `docs/ESSENTIALS-INTEGRATION.md` — verified what is and isn't documented about the XP key

---

## Metadata

**Confidence breakdown:**
- Current code state: HIGH — directly read from source files
- Render deployment behavior: HIGH — standard Render env var behavior, no ambiguity
- Doc gap identification: HIGH — read full integration doc, gap is clear
- Smoke test approach: HIGH — follows established pattern from other service keys

**Research date:** 2026-04-02
**Valid until:** Stable indefinitely — no external libraries, no version risk
