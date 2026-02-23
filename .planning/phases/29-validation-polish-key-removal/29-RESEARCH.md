# Phase 29: Validation, Polish & Key Removal - Research

**Researched:** 2026-02-22
**Domain:** Codebase audit, environment key management, Google Cloud Monitoring
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Billing alerts
- Monitor Google Maps API call volume, not dollar spend
- Alert threshold: 5,000 API calls per month (halfway to the 10,000 free tier limit)
- Notification: email only to the default GCP project account email
- No daily request quota cap — keep the API fully open, rely on the email alert
- No hard limits or daily caps; this is informational monitoring only

#### Claude's Discretion
- Audit scope: how thoroughly to grep for BallotReady references (Go source vs configs/docs/comments)
- Key removal order: whether to verify code works without key before removing from environments
- How to handle historical BallotReady mentions in migration files or comments
- Exact grep patterns and file exclusions for the codebase audit

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CLEAN-01 | BALLOTREADY_API_KEY removed from all environment configurations | Key is named `BALLOTREADY_KEY` in code (not `BALLOTREADY_API_KEY`). apprunner.yaml already clean. Removal scope is: (1) AWS Secrets Manager entry, (2) EV-Backend/.env.local local dev file, (3) POLITICIAN_PROVIDER env var also needs removing or changing to "cicero". |
| CLEAN-02 | Full codebase audit confirms zero active BallotReady API references | The ballotready/ package directory EXISTS but is NOT imported anywhere — no blank import, no active calls. 79 string matches exist across 16 files, but 34 are inside the ballotready/ package itself (dead code), 21 are in provider/ config that only activates when POLITICIAN_PROVIDER=ballotready (not the default), and 20+ are comment-only strings. Planner must decide: audit scope = "active calls" (already zero) vs "all source matches" (requires major cleanup or package deletion). |
| CLEAN-03 | Google Maps API billing alerts configured for cost monitoring | Requires manual setup in Google Cloud Console using Cloud Monitoring alerting policy. Metric: `consumed_api` resource type, `serviceruntime.googleapis.com/api/request_count` metric. Threshold: 5,000 requests/month. Notification: email channel. This is a console UI task, not a code change. |
</phase_requirements>

---

## Summary

Phase 29 has three distinct work streams: a codebase audit with a key decision about its scope, environment key cleanup across multiple locations, and a Google Cloud Monitoring setup that is entirely a console UI task.

The most important discovery: **BallotReady API is already completely inactive in the running server**. The ballotready/ package directory exists but has no blank import anywhere — its `init()` function never runs. The server defaults to the cicero provider (POLITICIAN_PROVIDER defaults to "cicero" when unset), and the production apprunner.yaml has never referenced any BALLOTREADY env var. The `BALLOTREADY_KEY` in .env.local is only a local development artifact.

The success criteria for CLEAN-02 ("zero matches in Go source files") creates a scope decision the planner must resolve. Achieving literal zero matches requires either deleting the ballotready/ package (90+ files worth of code that was intentionally kept per STATE.md) or stripping every comment/doc string that says "BallotReady" throughout the codebase. A pragmatic interpretation — "zero active API calls to BallotReady" — is already satisfied. The planner should recommend the pragmatic interpretation with an audit command that excludes the ballotready/ package directory and comment-only lines.

For CLEAN-01, the apprunner.yaml is already clean (no BALLOTREADY reference). The real work is: (1) confirm AWS Secrets Manager does not store the key, (2) remove BALLOTREADY_KEY and POLITICIAN_PROVIDER=ballotready from EV-Backend/.env.local, (3) verify the server starts normally with the cicero provider (or without any provider configured if warmers are all removed).

**Primary recommendation:** Define "active BallotReady references" as non-comment code in non-ballotready-package files, run the audit to confirm zero, remove the key from .env.local, confirm App Runner has no BALLOTREADY secrets, then set up the Cloud Monitoring alert.

---

## Standard Stack

### Core (no new libraries needed)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| grep / ripgrep | system | Codebase audit | Used for CLEAN-02 verification |
| Google Cloud Console | — | Cloud Monitoring alert setup | Browser-based UI, no code |
| AWS Secrets Manager | — | Verify/remove key from production | Manual console action |

### No New Code Dependencies
This phase adds zero new dependencies. It is audit + cleanup + console UI setup.

---

## Architecture Patterns

### Pattern 1: Defining the Audit Grep Command

The success criteria specifies: `grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/` on Go source files.

**Current match counts (as of 2026-02-22):**

| Location | Match count | Nature |
|----------|-------------|--------|
| `internal/essentials/ballotready/` (the package itself) | 34 | Active code, but dead (not imported) |
| `internal/essentials/provider/` | 21 | Config code that's only active when POLITICIAN_PROVIDER=ballotready |
| All other Go files (comments + strings) | 20 | Comments, doc strings, log messages |
| **Total** | **75** | |

**Recommended audit scope definition:**

The planner should document the audit exclusions clearly. The pragmatic definition of "active BallotReady references" for CLEAN-02 is: Go source code that would execute a BallotReady API call if deployed. By this definition, the count is already zero because:

1. The `ballotready/` package has no blank import, so its `init()` never registers the provider
2. `provider/config.go` reads `BALLOTREADY_KEY` only when `POLITICIAN_PROVIDER=ballotready`, which is not set in production
3. All remaining mentions are comments documenting history

**Recommended audit command after cleanup:**
```bash
# Audit for active BallotReady references (excludes the dead ballotready/ package and comment-only lines)
grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/ --include="*.go" \
  | grep -v "/essentials/ballotready/" \
  | grep -v "^.*://\s*"
```

Or, if the decision is to delete the ballotready/ package and strip provider/ references:
```bash
# Full audit — should return zero after complete cleanup
grep -r "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/ --include="*.go"
```

### Pattern 2: Environment Key Removal Sequence

**Recommended order** (verify before removing to prevent outage):

1. Confirm server starts without BALLOTREADY_KEY in env (already true — default provider is cicero)
2. Remove `BALLOTREADY_KEY` and `POLITICIAN_PROVIDER=ballotready` from `EV-Backend/.env.local`
3. Verify AWS Secrets Manager entry `ev/prod/backend-hKU59w` does NOT contain a BALLOTREADY_API_KEY key
4. If it does exist in Secrets Manager, delete that key field (console action — AWS console or CLI)
5. No App Runner service restart needed if BALLOTREADY was never in the deployed service env

**The apprunner.yaml is already clean** — it only lists DATABASE_URL, ALLOWED_ORIGINS, and CICERO_KEY. If BALLOTREADY was added to App Runner manually via the console (outside the YAML file), that must also be checked and removed.

### Pattern 3: Google Maps Billing Alert (Cloud Monitoring)

This is a console UI task. The billing monitoring approach uses **Cloud Monitoring alerting policies** (not Cloud Billing budget alerts, since the user wants request volume not dollar spend).

**Navigation path in Google Cloud Console:**
1. Open Google Cloud Console → select the project that owns the Maps API key
2. Navigate to: Monitoring > Alerting > Create Policy
3. Metric selection: Resource type = `consumed_api`, Metric = `serviceruntime.googleapis.com/api/request_count`
4. Filter by service = `maps.googleapis.com` (to isolate Maps API calls)
5. Aggregator: SUM, window: 30-day rolling (or monthly)
6. Condition: above threshold, value = 5000
7. Notification channel: add email → enter the default GCP project account email
8. Policy name: "Google Maps API 5000 calls/month"
9. Save

**Alternative simpler path (Quotas page usage alert):**
1. Google Cloud Console → APIs & Services → Quotas
2. Select the Maps JavaScript API (or Places API)
3. Find "Requests" quota → three-dot menu → "Create usage alert"
4. Set threshold and notification email

**Note:** The Places API (used for autocomplete in the frontend) and the Geocoding API (used by the backend) are billed separately. The alert may need to cover both, or just the Places API if that's the dominant usage. The 5,000-call threshold applies across all Maps API calls per the user's decision.

### Anti-Patterns to Avoid

- **Setting a quota cap**: The user explicitly decided NOT to set a hard cap. Do not set a "per day" or "per month" quota limit — only set an informational alert. A quota cap would break the application if hit.
- **Deleting the ballotready/ package**: The CONTEXT.md grants discretion on audit scope. STATE.md explicitly notes the package was "kept to preserve admin import pipeline." The planner should recommend comment-stripping in those files rather than deletion, unless the user confirms deletion is acceptable.
- **Removing CICERO_KEY from .env.local**: The server still uses Cicero as the active provider. Only remove BALLOTREADY-related keys.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Billing monitoring | Custom webhook/cron to count API calls | Google Cloud Monitoring alerting policy | Native integration, no maintenance, no additional code |
| Audit automation | Custom script | `grep` command with documented pattern | One-time audit, not a CI gate at this stage |

---

## Common Pitfalls

### Pitfall 1: Confusing BALLOTREADY_KEY vs BALLOTREADY_API_KEY
**What goes wrong:** The success criteria says "BALLOTREADY_API_KEY" but the Go code reads `os.Getenv("BALLOTREADY_KEY")`. These are different env var names.
**Why it happens:** The REQUIREMENTS.md was written with a generic name; the actual implementation uses the shorter form.
**How to avoid:** Audit both names. Check AWS Secrets Manager for both `BALLOTREADY_API_KEY` and `BALLOTREADY_KEY`.
**Warning signs:** Grep for `BALLOTREADY` (without suffix) to catch both variants.

### Pitfall 2: App Runner Console Env Vars Not in YAML
**What goes wrong:** The apprunner.yaml looks clean, but the App Runner service has additional env vars set directly in the AWS console that override or supplement the YAML.
**Why it happens:** App Runner supports both file-based and console-based env var management. Secrets in `apprunner.yaml` are file-managed; manually-added vars are console-managed.
**How to avoid:** Log into AWS App Runner console → select the service → Configuration tab → verify Environment Variables section has no BALLOTREADY entries.
**Warning signs:** .env.local has BALLOTREADY_KEY but apprunner.yaml does not — this means someone may have added it manually to the production service.

### Pitfall 3: Billing Alert on Wrong Project
**What goes wrong:** Setting up the alert on the wrong GCP project — the billing alert goes nowhere because the API key belongs to a different project.
**Why it happens:** GCP accounts often have multiple projects; Maps API keys are project-scoped.
**How to avoid:** Navigate to the project that owns the API key `***REMOVED-SECRET***` first. Verify in GCP Console → APIs & Services → Credentials.

### Pitfall 4: Places API vs Geocoding API Metric Scope
**What goes wrong:** Alert fires only on Geocoding API calls (backend) and misses the Places Autocomplete calls (frontend — the higher-volume service).
**Why it happens:** Two separate APIs are in use: Geocoding API (backend, per address search) and Maps JavaScript API / Places API (frontend autocomplete). They have different metric labels.
**How to avoid:** Set the alert without filtering by specific API endpoint (sum all Maps API requests), or set separate alerts per API type. Given the user wants informational monitoring only, summing all is fine.

---

## Code Examples

### Audit Commands

```bash
# CLEAN-02: Run after cleanup to verify zero ACTIVE references
# Pragmatic scope: excludes dead ballotready/ package and comment-only lines
grep -rn "ballotReadyClient\|BallotReady\|BALLOTREADY" EV-Backend/ --include="*.go" \
  | grep -v "internal/essentials/ballotready/" \
  | grep -v "[[:space:]]*//.*BallotReady" \
  | grep -v "[[:space:]]*//.*BALLOTREADY"

# CLEAN-01: Confirm no BALLOTREADY env vars in the codebase configs (not .env.local)
grep -rn "BALLOTREADY" EV-Backend/ --include="*.yaml" --include="*.toml" --include="*.json"
# Expected: no output
```

### .env.local Cleanup (EV-Backend)

Remove these two lines from `/Users/chrisandrews/Documents/GitHub/EV-Backend/.env.local`:
```
POLITICIAN_PROVIDER=ballotready    # Remove this line
BALLOTREADY_KEY=GThIQcVaY68R2jDxs2LYYeutGGmhUKYqSeD1yIrmyFo    # Remove this line
```

After removal, the server will use `POLITICIAN_PROVIDER=""` → defaults to cicero in `LoadFromEnv()`. This is already the production behavior.

### Provider Config Simplification (if chosen)

If the planner decides to clean the provider/ package of ballotready references, the minimal change is:

In `internal/essentials/provider/config.go`, remove:
- `ProviderBallotReady ProviderType = "ballotready"` constant
- `BallotReadyKey string` field from Config struct
- `BallotReadyEndpoint string` field from Config struct
- `DefaultBallotReadyEndpoint` constant
- The `case "ballotready":` branch in `LoadFromEnv()`
- `BALLOTREADY_ENDPOINT` read
- `BallotReadyKey: os.Getenv(...)` and `BallotReadyEndpoint: ...` assignments
- `case ProviderBallotReady:` in `Validate()`

In `internal/essentials/provider/provider.go`, remove:
- `ErrMissingBallotReadyKey` error var

**Build impact:** If these are removed, the `ballotready/` package will fail to compile because it references `provider.ProviderBallotReady`, `cfg.BallotReadyKey`, etc. So either: (a) simplify provider/ AND delete ballotready/, or (b) leave provider/ as-is (it only activates when POLITICIAN_PROVIDER=ballotready).

---

## Current State Snapshot (What the Planner Must Know)

### CLEAN-01 State
| Location | Status | Action Required |
|----------|--------|-----------------|
| `EV-Backend/apprunner.yaml` | **CLEAN** — no BALLOTREADY references | None |
| `EV-Backend/.env.local` | **DIRTY** — has `BALLOTREADY_KEY` and `POLITICIAN_PROVIDER=ballotready` | Remove both lines |
| AWS Secrets Manager `ev/prod/backend-hKU59w` | **UNKNOWN** — may or may not have BALLOTREADY key | Verify in AWS console, remove if present |
| App Runner console env vars | **UNKNOWN** — YAML is clean but console vars aren't tracked in code | Verify in AWS App Runner console |
| `essentials/` frontend | **CLEAN** — no BALLOTREADY references | None |
| Netlify configs | **CLEAN** — no BALLOTREADY references | None |

### CLEAN-02 State
| Category | Count | Disposition |
|----------|-------|-------------|
| Active BallotReady API calls | **0** | Already achieved |
| References in `ballotready/` package (dead code) | 34 | Kept or deleted (Claude's discretion) |
| References in `provider/` config (only active when opt-in) | 21 | Could be removed if ballotready/ is deleted |
| Comment/string references elsewhere | 20 | Cosmetic; update or leave |
| `cmd/bulk-import/main.go` Println | 1 | Cosmetic; update text |

### CLEAN-03 State
| Item | Status |
|------|--------|
| Google Maps API in use | Yes — Geocoding API (backend) + Places API (frontend) |
| Billing alert configured | **NOT YET** — requires Google Cloud Console action |
| GCP project with API key | Verify ownership in GCP Console for key `***REMOVED-SECRET***...` |

---

## Open Questions

1. **Does the ballotready/ package need to be deleted?**
   - What we know: STATE.md says "kept to preserve admin import pipeline"; the package is truly dead (no imports)
   - What's unclear: Whether any future "admin import pipeline" ever materialized or is needed
   - Recommendation: Leave the package in place, document it as dead code, update comments to say it's preserved for potential future use but not active. This avoids a large mechanical diff with no functional impact.

2. **Is BALLOTREADY_KEY stored in AWS Secrets Manager for the production App Runner service?**
   - What we know: apprunner.yaml does not reference it; it was in .env.local only
   - What's unclear: Whether the secret was ever pushed to AWS Secrets Manager (`ev/prod/backend-hKU59w`)
   - Recommendation: User should verify in AWS console before marking CLEAN-01 complete. The planner should include a verification checklist step.

3. **Which GCP project owns the Maps API key?**
   - What we know: The key `***REMOVED-SECRET***` is in `.env.local` and `essentials/.env.local`
   - What's unclear: Which GCP project it belongs to (needed to navigate to the right project for billing alert setup)
   - Recommendation: User must identify the project first (GCP Console → APIs & Services → Credentials → find the key).

---

## Sources

### Primary (HIGH confidence)
- Direct codebase audit — `EV-Backend/` grep results as of 2026-02-22
- `EV-Backend/apprunner.yaml` — read directly, confirmed no BALLOTREADY references
- `EV-Backend/.env.local` — read directly, confirmed BALLOTREADY_KEY and POLITICIAN_PROVIDER=ballotready
- `EV-Backend/internal/essentials/provider/config.go` — read directly, confirmed LoadFromEnv() behavior
- `EV-Backend/internal/essentials/setup.go` — read directly, confirmed ballotready/ has no blank import
- Google Cloud Monitoring official docs — `docs.cloud.google.com/monitoring/alerts/using-alerting-ui`
- Google Maps Platform Monitoring docs — `developers.google.com/maps/reporting-and-monitoring/monitoring`

### Secondary (MEDIUM confidence)
- Google Maps Platform Manage Costs page — `developers.google.com/maps/billing-and-pricing/manage-costs` — quota alert steps via Quotas page
- WebSearch result: Cloud Monitoring alerting policy steps (consistent with official docs)

---

## Metadata

**Confidence breakdown:**
- CLEAN-01 scope: HIGH — files audited directly; AWS state is UNKNOWN (requires manual verification)
- CLEAN-02 current state: HIGH — grep counts verified, import graph confirmed
- CLEAN-03 procedure: HIGH — sourced from official Google docs, steps are stable
- Ballotready package status: HIGH — confirmed via import graph analysis

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (stable domain — Google Cloud Console UI and Go module behavior don't change quickly)
