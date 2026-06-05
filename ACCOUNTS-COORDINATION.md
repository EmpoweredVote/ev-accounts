# Validation Quests → Accounts Team Coordination

**From:** Validation Quests (empowered-validation-quests.onrender.com)
**To:** Claude working in empowered-accounts
**Date:** 2026-03-08
**Context:** v1.2 frontend is complete and live. Three open items require input or action from the accounts team.

---

## Item 1 — Confirm `validation_quest_completion` XP source key

**What we need:** Confirmation that `validation_quest_completion` is a registered, authorized source key for the `connect.award_xp` RPC.

**Current state:** `ENABLE_XP_AWARDS` is set to `false` in the Validation Quests Render environment. The XP award code is fully wired and tested but intentionally disabled pending this confirmation. Once confirmed, Chris will flip `ENABLE_XP_AWARDS=true` in the Render dashboard — no code change required.

**What we call:**
```typescript
await supabaseService
  .schema('connect')
  .rpc('award_xp', {
    p_user_id: userId,
    p_source: 'validation_quest_completion',
    p_amount: xpAmount,
    p_idempotency_key: `vq-submit-${submissionId}`,
    p_metadata: { quest_id: questId, submission_id: submissionId }
  });
```

**What we need to know:**
- Is `validation_quest_completion` registered as a valid source key?
- If not, what source key should Validation Quests use?
- Is there a registry of authorized source keys, or is any string valid?

---

## Item 2 — XP level formula for XPBar display

**What we need:** The formula that maps raw XP to a level and progress-within-level, so the XPBar component can show a meaningful fill percentage.

**Current state:** The frontend fetches `connected_profile.xp` from `GET /api/account/me` and displays it as raw `"XP: 1,234"`. The XPBar fill is hardcoded to 0% because the level formula is unknown. This looks broken in the UI.

**What would help:**

Either:

**Option A — Formula** (preferred):
```
Level N requires X total XP. Level N+1 requires Y total XP.
Fill = (currentXP - levelStartXP) / (levelEndXP - levelStartXP)
```
If there's a simple progression (e.g., each level = 500 XP, or exponential curve), just tell us the formula and we'll implement it client-side.

**Option B — API endpoint**:
If you already expose or plan to expose a `/api/account/me` field like `{ xp_level: 7, xp_progress: 0.63 }`, we'll consume that instead.

**Option C — No levels yet**:
If XP levels aren't designed yet, tell us and we'll remove the bar entirely and just show the raw number. That's fine — we just need to know.

---

## Item 3 — Veracity Rating integration design

**What we need:** Agreement on how Validation Quests' per-user veracity data flows into the platform-wide Veracity Rating.

**Background:** Validation Quests maintains its own `validation_quests.user_veracity_profiles` table per user:
```
accuracy_rate        NUMERIC   -- rolling time-decayed accuracy percentage
total_submissions    INTEGER
correct_submissions  INTEGER
review_required      BOOLEAN   -- sticky flag for serial incorrect submitters
restriction_state    ENUM      -- 'active' | 'review' | 'suspended'
```

This data represents a user's fact-verification accuracy record. The platform's Veracity Rating (shown publicly next to every post) is meant to reflect accuracy of contributed information over time.

**The open question:** Does Validation Quests' `accuracy_rate` / `restriction_state` feed into the platform Veracity Rating, and if so, how?

**Options we see:**
1. **We push:** VQ calls an accounts API endpoint (or RPC) after each consensus finalization with a delta — `{ user_id, accuracy_delta, source: 'validation_quest' }`. Accounts team owns the aggregation.
2. **You pull:** Accounts team builds a scheduled job that reads `validation_quests.user_veracity_profiles` directly via service role and incorporates it into platform Veracity Rating.
3. **Separate systems:** VQ veracity stays isolated for now (affects only VQ participation restrictions); no integration with platform Veracity Rating until v2. This is the current de-facto state.

Option 3 is fine for now. We just need a decision so we don't design around an assumption that turns out to be wrong.

---

## FYI — Integration guide has a stale gem RPC name

This is informational only; Validation Quests has already resolved it on our side.

The `empowered-accounts-integration-guide.md` documents `award_gems` as the gem award RPC:
```typescript
await supabaseAdmin.rpc('award_gems', { ... });
```

The actual working RPC is `connect.credit_gems` with a different signature:
```typescript
await supabaseAdmin
  .schema('connect')
  .rpc('credit_gems', {
    p_user_id,
    p_gem_type,
    p_amount,
    p_transaction_type,
    p_source_ref
  });
```

Worth updating the integration guide so future features don't hit the same silent failure we did. The `award_gems` function does not exist on the platform.

---

## Summary

| Item | Blocking? | What we need |
|------|-----------|--------------|
| XP source key confirmation | Yes — `ENABLE_XP_AWARDS` is off | Confirm `validation_quest_completion` is valid, or tell us the right key |
| XP level formula | No — UI degraded, not broken | Formula, endpoint, or confirmation that levels aren't designed yet |
| Veracity Rating integration | No — isolated for now | Just need a direction so we don't design against wrong assumptions |
| Gem RPC doc inconsistency | No — we already fixed it | Update `empowered-accounts-integration-guide.md` when convenient |

---

*Validation Quests — v1.1 live at https://empowered-validation-quests.onrender.com*
*Frontend — v1.2 live at https://validation-quests-frontend.onrender.com*
