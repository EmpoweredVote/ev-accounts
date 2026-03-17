# Integration Smoke Test Runbook

**Audience:** Chris (ops)
**Last updated:** 2026-03-16
**Purpose:** Manual checklist for verifying that CTC and VQ service integrations are live end-to-end against the production Accounts API. Run after service keys are configured in Render environments.

---

## Overview

| Test | Integration | What It Verifies |
|------|-------------|-----------------|
| INTEG-01 | CTC → Accounts | Game event → XP award + Yellow Gem record |
| INTEG-02 | VQ → Accounts | Stance confirmation → Red Gem + Verification Rating change |

**Requirements:**
- Admin tool access at `https://accounts.empowered.vote/admin`
- Production API URL: `https://ev-accounts-api.onrender.com`
- A test Connected user account (note their UUID — call it `<TEST_USER_UUID>` below)

---

## INTEG-01: CTC Integration

### Prerequisites

- `TRIVIA_SERVICE_KEY` set in the accounts API Render environment (this is the key CTC uses for XP awards)
- The CTC key value also registered in accounts API `GEMS_SERVICE_KEYS` env var with `yellow` gem type permission (for gem awards)
- A test Connected user account exists (note their UUID)

> **Blocker:** Until `TRIVIA_SERVICE_KEY` is configured in the accounts API Render environment, Step 1 will return 401. See Open Blockers in `.planning/STATE.md`.

### Step 1: Verify XP endpoint accepts the service key

Replace `<TRIVIA_SERVICE_KEY>` with the actual key value and `<TEST_USER_UUID>` with your test user's UUID. Replace `<YYYY-MM-DD>` with today's date.

```bash
curl -s -X POST https://ev-accounts-api.onrender.com/api/xp/award \
  -H "X-Service-Key: <TRIVIA_SERVICE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "<TEST_USER_UUID>",
    "source": "civic_trivia_championship_score",
    "amount": 100,
    "idempotency_key": "smoke-test-ctc-xp-<YYYY-MM-DD>-001"
  }' | jq .
```

**Expected response (200):**

```json
{
  "total_xp": 100,
  "level": 1,
  "is_duplicate": false
}
```

`total_xp` will be higher than 100 if the test user already has XP. `is_duplicate: false` confirms this was a fresh award.

### Step 2: Trigger a real CTC game event

Play a full CTC game as the test user (or use CTC's test harness if available). A complete game should produce both XP and Yellow Gems via service key calls to accounts.

If CTC has a test mode that fires game-completion events without playing a full game, use that — the accounts API only validates the service key and source, not the game state.

### Step 3: Verify in admin tool

1. Open the admin tool: `https://accounts.empowered.vote/admin`
2. Find the test user by username or UUID
3. Open their detail page

Check:

- [ ] XP History section shows a new `civic_trivia_championship_score` entry with the expected amount
- [ ] Yellow gem balance increased from pre-test value

### Verification Checklist

- [ ] Step 1 returns 200 with `is_duplicate: false`
- [ ] `total_xp` in Step 1 response reflects the award
- [ ] XP transaction visible in admin ledger with source `civic_trivia_championship_score`
- [ ] Yellow gem balance increased (admin Gem Balances section)
- [ ] No errors in Render logs during the test window (check Accounts API logs in Render dashboard)

---

## INTEG-02: VQ Stance Confirmation Integration

### Prerequisites

- A VQ key registered in accounts API `GEMS_SERVICE_KEYS` env var with `red` gem type permission (JSON format: `{"<vq-key-value>": ["red"]}`)
- VQ's Render environment configured with the same key value
- A test Connected user account with:
  - `verification_rating` between 10 and 147 (avoids floor/cap edge cases for clean +3 verification)
  - No active `vq_hold_until` (Admin-Only Fields card shows "None")
- A valid `politician_id` and `topic_id` UUID pair in the production DB (look up via the Compass admin tool)

### Step 1: Check preconditions in admin tool

1. Open the test user's detail page in the admin tool
2. Expand the Admin-Only Fields card

Note current values:

- [ ] `verification_rating` is between 10 and 147 — record the exact value: `____`
- [ ] `vq_hold_until` is null / "None"

### Step 2: Send a test stance confirmation

Replace all placeholder values before running. `<YYYY-MM-DD>` = today's date.

```bash
curl -s -X POST https://ev-accounts-api.onrender.com/api/vq/confirm-stance \
  -H "X-Service-Key: <VQ_SERVICE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "politician_id": "<POLITICIAN_UUID>",
    "topic_id": "<TOPIC_UUID>",
    "confirmed_value": 3,
    "correct_user_ids": ["<TEST_USER_UUID>"],
    "incorrect_user_ids": [],
    "idempotency_key": "smoke-test-vq-<YYYY-MM-DD>-001",
    "gems_amount": 1
  }' | jq .
```

### Step 3: Verify the response shape

**Expected response (200):**

```json
{
  "politician_id": "<POLITICIAN_UUID>",
  "topic_id": "<TOPIC_UUID>",
  "confirmed_value": 3,
  "correct_count": 1,
  "incorrect_count": 0,
  "users": [
    {
      "user_id": "<TEST_USER_UUID>",
      "result": "correct",
      "gems_awarded": 1,
      "rating_delta": 3,
      "new_rating": "<original_rating + 3>"
    }
  ],
  "unresolved_users": []
}

```

Confirm `new_rating` equals the value you recorded in Step 1 plus 3.

### Step 4: Verify in admin tool

Refresh the test user's detail page:

- [ ] Gem Balances section shows Red gem balance increased by 1
- [ ] Admin-Only Fields card shows `verification_rating` increased by 3 from the Step 1 value

### Step 5: Test idempotency replay

Send the **exact same request** from Step 2 again — same `idempotency_key`, same payload.

```bash
curl -s -X POST https://ev-accounts-api.onrender.com/api/vq/confirm-stance \
  -H "X-Service-Key: <VQ_SERVICE_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "politician_id": "<POLITICIAN_UUID>",
    "topic_id": "<TOPIC_UUID>",
    "confirmed_value": 3,
    "correct_user_ids": ["<TEST_USER_UUID>"],
    "incorrect_user_ids": [],
    "idempotency_key": "smoke-test-vq-<YYYY-MM-DD>-001",
    "gems_amount": 1
  }' | jq .
```

**Expected:** Same response body as Step 3, but with `"replayed": true` added to the top-level object.

Verify no change in admin tool:

- [ ] Red gem balance is **unchanged** from Step 4 value (no second gem awarded)
- [ ] `verification_rating` is **unchanged** from Step 4 value (no second +3)

### Verification Checklist

- [ ] Step 2 returns 200 with correct response shape
- [ ] `replayed: false` on first call
- [ ] Red gem balance +1 in admin tool (Step 4)
- [ ] `verification_rating` +3 in admin tool (Step 4)
- [ ] Replay (Step 5) returns same body with `replayed: true`
- [ ] Replay does NOT change gem balance or `verification_rating` (admin tool confirms)
- [ ] No errors in Render logs during test window

### Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Step 2 returns 401 | Service key mismatch | Check that the key in VQ's Render env exactly matches the value in accounts API `GEMS_SERVICE_KEYS` — keys are compared as exact strings |
| Step 2 returns 422 `FORBIDDEN_GEM_TYPE` | Key lacks `red` permission | Chris must update accounts API `GEMS_SERVICE_KEYS` env var to include `red` type for the VQ key |
| Step 2 returns 404 `QUESTION_NOT_FOUND` | Invalid politician/topic pair | Look up a valid pair from the Compass admin tool |
| Step 2 returns 422 `VALIDATION_ERROR` | Malformed request body | Check `issues` array in response — likely a UUID format error or missing required field |
| Replay returns 200 but `replayed: false` | Wrong idempotency key | Verify the `idempotency_key` value is identical in both requests (same date string) |
