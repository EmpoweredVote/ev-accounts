# Trivia Pipeline Quality Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the nightly trivia pipeline consult the quality rules engine before it writes a question, behind a flag that logs violations before it enforces them, and close the prompt divergence that let the engine's standards drift away from the generator's instructions.

**Architecture:** The judgement is a pure function (`decideRuleGate`) tested without a database, following the precedent `skipReasonFor()` set in `pipelineCron.ts`. `writePassingQuestions()` — the single write path for every news lane, and the function that created `wnews-0134` — calls `auditQuestion()` on the *placed* question just before insert, applies the gate, and returns per-claim statistics alongside the rows it wrote. `run-pipeline.ts` merges those statistics per lane into `generation_jobs.notes`, which is already the only observability surface a pipeline run has. Enforcement is off by default: the first nights log what *would* have been blocked, and the flag is flipped once the false-positive rate is known.

**Tech Stack:** TypeScript (ESM, `.js` import specifiers), vitest, Drizzle ORM, PostgreSQL.

**Spec:** `C:/Project Test/docs/superpowers/specs/2026-09-26-collection-quality-audit-design.md` §2.4 (root cause) and §4.4 (Workstream D). The spec lives in the Civic-Trivia-Championships repo; this plan implements the ev-accounts half of it.

**Spec coverage:** §4.4 lists five items. Item 3 — port `anachronism.ts` and register it — is **already done**: PR #815 authored the rule in this repo and added `checkAnachronisticYear` to `ALL_SYNC_RULES`, so there is nothing to port and no task for it here. Items 1 and 2 are Tasks 1 and 2. Item 4 is Tasks 3, 5 and 6, with Task 4 added beyond the spec (see its Context). Item 5 is a measurement against data that does not exist yet — see "Not in this plan".

**Branch:** `claude/trivia-pipeline-quality-gate`, cut from `claude/trivia-anachronism-rule` (PR #815), **not** from `master`. PR #815 authored and registered `checkAnachronisticYear` in `ALL_SYNC_RULES`; this plan's gate is what finally runs it against nightly output. Open the PR with base `claude/trivia-anachronism-rule` so the dependency is explicit, and merge #815 first.

## Global Constraints

- **Enforcement is flagged and defaults OFF.** Chris's stated preference at decision time: "log violations first, enforce after observing a night or two." The rules always *run*; only the block is flagged.
- **`skipUrlCheck: true` is mandatory in the pipeline.** `checkLearnMoreLink` performs a live HTTP fetch and raises `broken-learn-more` at severity `blocking` on any non-timeout failure. News source URLs come from RSS feeds, are not `.gov`, and routinely refuse bots — an un-skipped check would block good questions on network weather and add a round trip per question to a cron job.
- **Audit the *placed* question.** `placeAnswer()` rewrites `options` and `correctAnswer`; the audit must see what will actually be stored, so it runs after `placeAnswer` and before `insert`.
- **A rule that throws must not cost the claim.** `run-pipeline.ts` contains errors per cluster; a rule crash inside the write loop would discard every remaining question for that claim. The gate catches and records.
- **ev-accounts work happens in a worktree, not `c:/ev-accounts`** — Chris is actively seeding Knight cities from `c:/ev-accounts-ky`. This plan's worktree is `c:/ev-accounts-quality-gate`.
- **Files in `backend/src/trivia/` use LF line endings.** The CTC copies of the prompt files use CRLF; porting text between the repos must not carry CRLF across.
- **ESM import specifiers end in `.js`**, including for `.ts` sources.
- **`npm test` is red on master** (~25 flaky integration failures, pre-existing). The gate for this work is `npx vitest run src/trivia`.
- **Never rename a CI job name.**

## Review Focus

Five failure modes the spec implies but which no task's happy path exercises.

1. **The engine blocks most legitimate news questions.** `checkPureLookup` flags "in what year was…" shapes and `checkAmbiguousAnswers` flags options sharing >70% of their words — both common in news questions. If enforcement were on by default, a high false-positive rate would silently zero out the nightly yield and look like a quiet feed. The stats must separate *would have blocked* from *did block* so the rate is measurable before the flag flips. → Task 4 (`suppressed` vs `blocked` counters), Task 6 (both surfaced in `notes`).
2. **The audit performs network I/O.** Any call that omits `skipUrlCheck: true` puts an HTTP fetch per question inside a cron job and makes a blocking verdict depend on whether a news site answered. → Task 5 pins that the audit is invoked with `skipUrlCheck: true`.
3. **A rule throws on a malformed question** — an empty `options` array, a `correctAnswer` out of range, a `source` with no URL. Uncaught, it propagates out of `writePassingQuestions` into the per-cluster catch and discards every remaining question for that claim. → Task 4 pins that a throwing rule is recorded as `ruleErrors` and the question is written.
4. **The flag is read once at module load.** An env var captured in a module-level `const` cannot be flipped without a redeploy, and a test that sets `process.env` after importing would assert against a stale value while appearing to pass. → Task 4 pins that the reader is called per question and reflects a change made after import.
5. **A question that hits an `external_id` conflict is counted as written.** The insert uses `onConflictDoNothing()` and `continue`s on an empty result. Auditing before the insert means such a question is audited but never stored; counting it in `audited` is correct, counting it in `written` is not. → Task 5 pins that a conflicted insert leaves `written` empty while `audited` is 1.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.ts` | MODIFY — gains §6a, the numeric-distractor rule. Consumed by `system-prompt.ts`, `CurrentTermQuestionGenerator.ts`, `ElectionQuestionGenerator.ts`. |
| `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts` | CREATE — pins §6a and the revised rubric against re-divergence. |
| `backend/src/trivia/scripts/content-generation/prompts/system-prompt.ts` | MODIFY — `## Difficulty Distribution` replaced with the revised rubric. |
| `backend/src/trivia/scripts/international/qualityGate.ts` | CREATE — the pure judgement: flag reader, gate decision, stats accumulator. No DB, no I/O. |
| `backend/src/trivia/scripts/international/qualityGate.test.ts` | CREATE — unit tests for all of the above, including Review Focus 1, 3, 4. |
| `backend/src/trivia/scripts/international/question-generator.ts` | MODIFY — news prompt gains the rules it is judged by; `writePassingQuestions` audits before insert and returns stats. |
| `backend/src/trivia/scripts/international/question-generator.test.ts` | CREATE — pins the prompt block and the `skipUrlCheck`/conflict behaviour (Review Focus 2, 5). |
| `backend/src/trivia/scripts/international/run-pipeline.ts` | MODIFY — `LaneStats` gains `qualityRules`; merged per claim, written to `notes`. |
| `backend/src/trivia/db/schema.ts` | MODIFY — `generation_jobs.notes` type gains `qualityRules`. jsonb; no migration. |

A separate `qualityGate.ts` rather than more exports on `question-generator.ts`: the generator module imports the Anthropic client at top level, so every test of the judgement would drag an API client into the test process. The gate is pure and must stay cheap to test.

---

## Task 1: Port §6a into the shared quality guidelines

**Files:**
- Modify: `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.ts` (insert after §6, before the `---` separator near the end)
- Create: `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `QUALITY_GUIDELINES` (unchanged export name, `string`) now containing a `### 6a.` section. Task 2's test reads the same module.

**Context:** CTC's copy of this file carries §6a; ev-accounts' does not, and ev-accounts is the engine that generates nightly content. The measured consequence, from the spec: across 1,154 four-option numeric questions the correct value was the third of four 54% of the time, so "sort the numbers and pick the third" scored 54% with no knowledge — 96% in one collection.

- [ ] **Step 1: Write the failing test**

Create `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { QUALITY_GUIDELINES } from './quality-guidelines.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * This file exists in two repos. CTC's copy grew a §6a on numeric distractors;
 * ev-accounts' copy did not — and ev-accounts is the engine that generates
 * nightly content, so the standard that mattered was the one that lacked it.
 * The divergence was measurable in the data: across 1,154 four-option numeric
 * questions the correct value sat third of four 54% of the time.
 *
 * These assertions are a tripwire, not a spellcheck. If a future edit drops
 * §6a again, this fails rather than the next content audit finding it.
 */
describe('QUALITY_GUIDELINES', () => {
  it('carries §6a, the numeric distractor rule', () => {
    expect(QUALITY_GUIDELINES).toContain('### 6a. Numeric distractors');
  });

  it('tells the writer to vary which bracket the answer falls in', () => {
    expect(QUALITY_GUIDELINES).toContain('must NOT always sit in the middle');
  });

  it('forbids moving the correct value to achieve placement', () => {
    expect(QUALITY_GUIDELINES).toContain('Never move the correct value');
  });

  it('requires one unit per question and ascending order', () => {
    expect(QUALITY_GUIDELINES).toContain('One unit per question');
    expect(QUALITY_GUIDELINES).toContain('Order them ascending');
  });

  it('keeps position rotation and distractor choice as separate concerns', () => {
    // A reviewer who conflates these will "fix" the 54% figure by shuffling
    // A/B/C/D, which does nothing — a player who sorts the numbers mentally is
    // unaffected by position.
    expect(QUALITY_GUIDELINES).toContain('does not fix this');
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`
Expected: FAIL — 5 failing assertions, first reporting that the string does not contain `### 6a. Numeric distractors`.

- [ ] **Step 3: Insert §6a**

In `quality-guidelines.ts`, find the end of section 6, which reads:

```
**All four options should make someone pause and think about the correct answer.**

---

**Validation Process:**
```

Insert the following between `**All four options should make someone pause and think about the correct answer.**` and the `---` line. Write the file with LF line endings.

```
### 6a. Numeric distractors — VARY WHERE THE ANSWER FALLS

**Rule:** For a question whose four options are numbers, quantities, years or
percentages, the correct value must NOT always sit in the middle of the range.

This is the single most exploitable flaw measured in the existing bank. A survey of
1,154 numeric questions found the correct value was the **third of four** 54% of the
time and at either extreme only 14% — so "sort the four numbers and pick the third"
scored 54% with no knowledge at all, and 96% in one collection. The cause is a habit:
writing the true value, then padding it with two smaller and one larger distractor.

**Vary the bracket deliberately.** Across a batch, aim for roughly equal numbers of:

- answer is the **smallest** offered — "9 members" → 9 / 11 / 13 / 15
- answer is **second** — "9 members" → 7 / 9 / 11 / 13
- answer is **third** — "9 members" → 5 / 7 / 9 / 11
- answer is the **largest** offered — "9 members" → 3 / 5 / 7 / 9

All four remain plausible; only the placement changes. Never move the correct value
itself to achieve this — change the distractors around it.

**Two further requirements for numeric options:**

- **One unit per question.** Never mix scales: "$500 million" alongside "$3 billion"
  cannot be compared at a glance and reads as a trick.
- **Order them ascending.** A sorted series is easier to scan, and it means placement
  is carried by the distractor values rather than by shuffling positions.

**Note:** rotating the answer's POSITION (A/B/C/D) does not fix this. A player who
sorts the numbers mentally is unaffected by position. Only the choice of distractors
fixes it. Both matter and they are separate concerns.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`
Expected: PASS — 5/5.

- [ ] **Step 5: Verify no CRLF crept in**

Run: `cd backend && node -e "const s=require('fs').readFileSync('src/trivia/scripts/content-generation/prompts/quality-guidelines.ts','utf8');console.log('CR count:', (s.match(/\r/g)||[]).length)"`
Expected: `CR count: 0`

- [ ] **Step 6: Commit**

```bash
git add backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.ts backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts
git commit -m "feat(trivia): port the numeric-distractor rule into the shared guidelines"
```

---

## Task 2: Port the revised difficulty rubric into the generation prompt

**Files:**
- Modify: `backend/src/trivia/scripts/content-generation/prompts/system-prompt.ts:63-68` (the `## Difficulty Distribution` block) and `:488-493` (the Fremont calibration block)
- Modify: `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts` (add a second describe block)

**Interfaces:**
- Consumes: nothing from Task 1 at the code level; both tasks edit prompt text.
- Produces: `buildSystemPrompt(...)` (signature unchanged) whose output contains the revised rubric. No later task consumes it programmatically.

**Context:** The prompt currently says "Easy: 40% / Medium: 40% / Hard: 20%" and defines the tiers by nothing at all. The revised rubric classifies by *what the player must bring*, sets 30% easy as a floor rather than a target, and adds the distractor rule — which is the part that matters, because questions labelled easy are answered correctly 50.0% of the time, identical to medium and only 25 points above blind guessing. A percentage alone never fixed that.

There are two blocks to change. The second, at `:488`, is a Fremont-specific calibration that states its own "Target: 40% easy, 40% medium, 20% hard". Left alone it contradicts the new floor for exactly one locale.

- [ ] **Step 1: Write the failing test**

Append to `backend/src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`:

```ts
import { buildSystemPrompt } from './system-prompt.js';

describe('buildSystemPrompt — difficulty rubric', () => {
  // Signature: (localeName, topicDistribution, localeSlug?, officeholders?)
  // The slug is what selects the Fremont calibration block, so it must be passed.
  const prompt = () => buildSystemPrompt('Fremont, CA', { 'local-government': 10 }, 'fremont-ca');

  it('states the easy floor, not a 40% target', () => {
    expect(prompt()).toContain('At least 30% of the batch must be EASY');
    expect(prompt()).not.toContain('Easy: 40% of questions');
  });

  it('classifies by what the player must bring', () => {
    const p = prompt();
    expect(p).toContain('someone who lives there would likely know it without study');
    expect(p).toContain('needs specific study');
  });

  it('restricts easy officeholders to the headline executive', () => {
    expect(prompt()).toContain('named holders of any office below the headline');
  });

  it('carries the distractor rule, with the measured figure', () => {
    const p = prompt();
    expect(p).toContain("An easy question's three distractors must be ones a resident rules out instantly");
    expect(p).toContain('50.0%');
  });

  it('does not leave a locale block contradicting the floor', () => {
    // The Fremont calibration carried its own "Target: 40% easy". One locale
    // quietly exempting itself from the floor is how the floor stops meaning
    // anything.
    expect(prompt()).not.toContain('Target: 40% easy');
  });
});
```

Note: `buildSystemPrompt`'s real signature must be confirmed before running — open `system-prompt.ts` and match the argument list exactly. If it takes an options object rather than positional arguments, adjust the `prompt()` helper; the assertions do not change.

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`
Expected: FAIL — the five new assertions fail; the five from Task 1 still pass.

- [ ] **Step 3: Replace the `## Difficulty Distribution` block**

In `system-prompt.ts`, replace lines 63-68:

```
## Difficulty Distribution

Distribute difficulty across the full batch:
- Easy: 40% of questions (foundational facts, direct answers)
- Medium: 40% of questions (requires some civic knowledge)
- Hard: 20% of questions (nuanced details, specific facts)
```

with:

```
## Difficulty Distribution

At least 30% of the batch must be EASY. This is a floor, not a target to hover at — a
medium-heavy batch is a defect. Aim for roughly 30% easy / 45% medium / 25% hard.

A percentage alone does not work; classify by **what the player must bring**.

**EASY** — someone who lives there would likely know it without study.
- The single headline executive: the Mayor, the Governor, the President, the Vice
  President. A resident knows who runs the place.
- Term lengths — how long a mayor, governor or council member serves.
- The founding, incorporation or chartering year.
- Orientation and geography: which county, which bordering state, which river, which ocean.
- The single most recognisable landmark, employer or institution.
- The elementary-civics test: a fact an elementary school civics book would state
  plainly — provided you can source it.

**MEDIUM** — a resident could reason to it, or knows it from some familiarity.
Institutional structure and process, who appoints whom, advisory scope, non-iconic
dates, second-order associations.

**HARD** — needs specific study.
A precise figure recalled exactly; **named holders of any office below the headline
executive** — council members, commissioners, clerks, auditors, deputies; multi-step
comparative reasoning.

### The distractor rule

Difficulty is carried by the option set, not the subject. Measured across the live bank,
questions labelled easy are answered correctly 50.0% of the time — identical to medium,
and only 25 points above blind guessing.

**An easy question's three distractors must be ones a resident rules out instantly.**

- GOOD — "Who is the Mayor of Cambridge?" against three names who plainly do not hold
  the office.
- BAD — the same question against three sitting Cambridge city councillors.

If a famous subject has four independently plausible options, it is NOT easy. Never move
the correct value to fix this — change the distractors around it.
```

- [ ] **Step 4: Reconcile the Fremont calibration block**

In the same file, the Fremont block currently reads:

```
### Difficulty Distribution (Fremont-specific calibration)
- Target: 40% easy, 40% medium, 20% hard
- Easy: Foundational facts a civic-minded resident would know (e.g., "How many districts does Fremont have?")
- Medium: Requires civic knowledge but learnable (e.g., "What role does the city manager play?")
- Hard: Nuanced details even locals might not know (e.g., "Which five towns consolidated to form Fremont in 1956?")
- Distractors should scale with difficulty — easy has obviously wrong answers, hard has genuinely tricky ones
```

Replace it with a block that keeps the Fremont-specific *examples* — they are the useful part — and defers the distribution to the rubric above:

```
### Difficulty Examples (Fremont-specific calibration)
- The distribution and the tier definitions are the ones stated above; this section
  only illustrates them for Fremont.
- Easy: "Which county is Fremont in?" — orientation a resident holds without study
- Medium: "What role does the city manager play?" — institutional process, learnable
- Hard: "Which five towns consolidated to form Fremont in 1956?" — specific study
- Distractors carry the difficulty: an easy question's three wrong options must be ones
  a Fremont resident rules out instantly
```

Note the first example changed: "How many districts does Fremont have?" is a count, and under the revised rubric a precise figure recalled exactly is HARD, not easy. Leaving it would have the prompt illustrate the tier with a question the rubric places elsewhere.

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/trivia/scripts/content-generation/prompts/quality-guidelines.test.ts`
Expected: PASS — 10/10.

- [ ] **Step 6: Typecheck**

Run: `cd backend && npx tsc --noEmit`
Expected: exit 0, no output.

- [ ] **Step 7: Commit**

```bash
git add backend/src/trivia/scripts/content-generation/prompts/
git commit -m "feat(trivia): port the revised difficulty rubric into the generation prompt"
```

---

## Task 3: The quality gate — the judgement, with no database

**Files:**
- Create: `backend/src/trivia/scripts/international/qualityGate.ts`
- Create: `backend/src/trivia/scripts/international/qualityGate.test.ts`

**Interfaces:**
- Consumes: `Violation` and `AuditResult` from `../../services/qualityRules/types.js`.
- Produces, all consumed by Task 4 and Task 5:
  - `QUALITY_RULES_ENFORCE_ENV: 'TRIVIA_QUALITY_RULES_ENFORCE'`
  - `qualityRulesEnforced(env?: NodeJS.ProcessEnv): boolean`
  - `interface QualityRuleStats { audited: number; withBlocking: number; withAdvisoryOnly: number; blocked: number; suppressed: number; ruleErrors: number; byRule: Record<string, number>; samples: string[] }`
  - `emptyQualityRuleStats(): QualityRuleStats`
  - `interface GateDecision { write: boolean; blocking: Violation[]; advisory: Violation[] }`
  - `decideRuleGate(violations: Violation[], enforce: boolean): GateDecision`
  - `recordGate(stats: QualityRuleStats, externalId: string, decision: GateDecision, enforce: boolean): void`
  - `recordRuleError(stats: QualityRuleStats, externalId: string, err: unknown): void`
  - `mergeQualityRuleStats(into: QualityRuleStats, from: QualityRuleStats): void`
  - `MAX_SAMPLES: 20`

**Context:** `pipelineCron.ts` pulled `skipReasonFor()` out of its preflight loop "so the judgement is testable without a database". Same move, same reason: `writePassingQuestions` cannot be unit-tested cheaply because it lazily imports the Drizzle client, and the generator module imports the Anthropic client at load. The decision belongs where it can be tested for free.

The two counters that matter are `blocked` and `suppressed`. `blocked` is a question the gate actually refused to write. `suppressed` is one that had blocking violations while enforcement was off — it *was* written, and it is the number that tells Chris whether flipping the flag would cost the pipeline its yield. Conflating them would make the log-first rollout worthless.

- [ ] **Step 1: Write the failing test**

Create `backend/src/trivia/scripts/international/qualityGate.test.ts`:

```ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import type { Violation } from '../../services/qualityRules/types.js';
import {
  QUALITY_RULES_ENFORCE_ENV,
  qualityRulesEnforced,
  emptyQualityRuleStats,
  decideRuleGate,
  recordGate,
  recordRuleError,
  mergeQualityRuleStats,
  MAX_SAMPLES,
} from './qualityGate.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * `wnews-0134` asked what year a past event happened and offered 2026 as an
 * option. The rule that catches it existed; nothing in the nightly pipeline
 * ever called it. This is the judgement half of the fix, kept free of the
 * database for the same reason `skipReasonFor()` was — a decision you cannot
 * test without a Postgres connection is a decision nobody tests.
 *
 * The distinction this file exists to protect is `blocked` vs `suppressed`.
 * With enforcement off, a question with blocking violations is still WRITTEN;
 * counting it as blocked would report a clean night that never happened, and
 * would hide the one number the flagged rollout is for — what enforcement
 * would cost if it were switched on tonight.
 */

const blocking = (rule: string): Violation => ({
  rule,
  severity: 'blocking',
  message: `${rule} violated`,
});

const advisory = (rule: string): Violation => ({
  rule,
  severity: 'advisory',
  message: `${rule} noted`,
});

describe('qualityRulesEnforced', () => {
  const original = process.env[QUALITY_RULES_ENFORCE_ENV];

  afterEach(() => {
    if (original === undefined) delete process.env[QUALITY_RULES_ENFORCE_ENV];
    else process.env[QUALITY_RULES_ENFORCE_ENV] = original;
  });

  it('is off when the variable is unset', () => {
    delete process.env[QUALITY_RULES_ENFORCE_ENV];
    expect(qualityRulesEnforced()).toBe(false);
  });

  it('is on only for the exact string "true"', () => {
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'true' })).toBe(true);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: '1' })).toBe(false);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'yes' })).toBe(false);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'TRUE' })).toBe(false);
  });

  it('reads the environment on every call, not once at import', () => {
    // Review Focus 4. A module-level `const ENFORCE = process.env...` would
    // pass every other test in this file and still be wrong: the flag could
    // not be flipped without a redeploy, and this test would assert against a
    // value captured before it was set.
    delete process.env[QUALITY_RULES_ENFORCE_ENV];
    expect(qualityRulesEnforced()).toBe(false);
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'true';
    expect(qualityRulesEnforced()).toBe(true);
  });
});

describe('decideRuleGate', () => {
  it('writes a clean question', () => {
    const d = decideRuleGate([], false);
    expect(d.write).toBe(true);
    expect(d.blocking).toEqual([]);
    expect(d.advisory).toEqual([]);
  });

  it('writes a question with advisory violations only, under either setting', () => {
    expect(decideRuleGate([advisory('partisan-framing')], false).write).toBe(true);
    expect(decideRuleGate([advisory('partisan-framing')], true).write).toBe(true);
  });

  it('writes a blocking-violation question when enforcement is off', () => {
    const d = decideRuleGate([blocking('anachronistic-year')], false);
    expect(d.write).toBe(true);
    expect(d.blocking).toHaveLength(1);
  });

  it('refuses a blocking-violation question when enforcement is on', () => {
    const d = decideRuleGate([blocking('anachronistic-year')], true);
    expect(d.write).toBe(false);
  });

  it('partitions mixed violations by severity', () => {
    const d = decideRuleGate(
      [blocking('ambiguous-answers'), advisory('partisan-framing'), blocking('pure-lookup')],
      true,
    );
    expect(d.blocking.map(v => v.rule)).toEqual(['ambiguous-answers', 'pure-lookup']);
    expect(d.advisory.map(v => v.rule)).toEqual(['partisan-framing']);
  });
});

describe('recordGate', () => {
  it('counts a clean question as audited and nothing else', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], false), false);
    expect(s).toMatchObject({
      audited: 1, withBlocking: 0, withAdvisoryOnly: 0, blocked: 0, suppressed: 0,
    });
    expect(s.byRule).toEqual({});
  });

  it('counts a blocking violation as SUPPRESSED, not blocked, when enforcement is off', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year')], false);
    recordGate(s, 'wnews-0134', d, false);
    expect(s.withBlocking).toBe(1);
    expect(s.suppressed).toBe(1);
    expect(s.blocked).toBe(0);
  });

  it('counts a blocking violation as BLOCKED when enforcement is on', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year')], true);
    recordGate(s, 'wnews-0134', d, true);
    expect(s.blocked).toBe(1);
    expect(s.suppressed).toBe(0);
  });

  it('tallies every violated rule by name, blocking and advisory alike', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], false), false);
    recordGate(s, 'b', decideRuleGate([blocking('pure-lookup')], false), false);
    expect(s.byRule).toEqual({ 'pure-lookup': 2, 'partisan-framing': 1 });
  });

  it('counts advisory-only separately from blocking', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([advisory('partisan-framing')], false), false);
    expect(s.withAdvisoryOnly).toBe(1);
    expect(s.withBlocking).toBe(0);
  });

  it('samples the offending question ids, capped', () => {
    const s = emptyQualityRuleStats();
    for (let i = 0; i < MAX_SAMPLES + 5; i++) {
      recordGate(s, `wnews-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
    }
    expect(s.withBlocking).toBe(MAX_SAMPLES + 5);
    expect(s.samples).toHaveLength(MAX_SAMPLES);
    expect(s.samples[0]).toBe('wnews-0:pure-lookup');
  });

  it('does not sample clean questions', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], false), false);
    expect(s.samples).toEqual([]);
  });
});

describe('recordRuleError', () => {
  it('records a thrown rule without claiming the question was audited clean', () => {
    // Review Focus 3. A rule that throws must be contained here; propagating
    // it reaches run-pipeline's per-cluster catch and discards every
    // remaining question for the claim.
    const s = emptyQualityRuleStats();
    recordRuleError(s, 'wnews-0007', new Error('Cannot read properties of undefined'));
    expect(s.ruleErrors).toBe(1);
    expect(s.audited).toBe(0);
    expect(s.samples[0]).toContain('wnews-0007');
    expect(s.samples[0]).toContain('Cannot read properties of undefined');
  });

  it('survives a non-Error throw', () => {
    const s = emptyQualityRuleStats();
    recordRuleError(s, 'wnews-0008', 'string thrown');
    expect(s.ruleErrors).toBe(1);
    expect(s.samples[0]).toContain('string thrown');
  });
});

describe('mergeQualityRuleStats', () => {
  it('sums counters and unions rule tallies', () => {
    const a = emptyQualityRuleStats();
    recordGate(a, 'a', decideRuleGate([blocking('pure-lookup')], false), false);
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], false), false);
    recordRuleError(b, 'c', new Error('boom'));

    mergeQualityRuleStats(a, b);

    expect(a.audited).toBe(2);
    expect(a.withBlocking).toBe(2);
    expect(a.suppressed).toBe(2);
    expect(a.ruleErrors).toBe(1);
    expect(a.byRule).toEqual({ 'pure-lookup': 2, 'partisan-framing': 1 });
  });

  it('caps samples when merging', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    for (let i = 0; i < MAX_SAMPLES; i++) {
      recordGate(a, `a-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
      recordGate(b, `b-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
    }
    mergeQualityRuleStats(a, b);
    expect(a.samples).toHaveLength(MAX_SAMPLES);
  });

  it('leaves the source untouched', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([], false), false);
    mergeQualityRuleStats(a, b);
    expect(b.audited).toBe(1);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/trivia/scripts/international/qualityGate.test.ts`
Expected: FAIL — the suite cannot resolve `./qualityGate.js`.

- [ ] **Step 3: Write the implementation**

Create `backend/src/trivia/scripts/international/qualityGate.ts`:

```ts
/**
 * Quality Gate — the judgement half of the nightly pipeline's rules check.
 *
 * `wnews-0134` asked what year a past event happened and offered 2026 as an
 * option. The rule that catches that existed in `services/qualityRules`;
 * nothing in the nightly pipeline ever called it. This module holds the
 * decision that closes the gap, deliberately free of the database and of the
 * Anthropic client so it can be tested for nothing — the same move
 * `skipReasonFor()` made in `pipelineCron.ts`.
 *
 * ROLLOUT: enforcement is OFF by default. The rules always run and every
 * violation is counted; only the refusal to write is flagged. Chris's stated
 * preference at decision time was to log first and enforce after observing a
 * night or two, because the engine has never been pointed at news-shaped
 * content and its false-positive rate there is unknown — `checkPureLookup`
 * flags "in what year was..." shapes, which is a perfectly ordinary news
 * question.
 *
 * `suppressed` is the number that rollout turns on: questions that WOULD have
 * been blocked and were written anyway. Read it before flipping the flag.
 */

import type { Violation } from '../../services/qualityRules/types.js';

/** Set to the exact string "true" to make blocking violations actually block. */
export const QUALITY_RULES_ENFORCE_ENV = 'TRIVIA_QUALITY_RULES_ENFORCE';

/** Cap on the per-run sample list written into generation_jobs.notes. */
export const MAX_SAMPLES = 20;

/**
 * Whether blocking violations block.
 *
 * Read per question rather than captured at module load: a flag you cannot
 * flip without a redeploy is not a flagged rollout, and a module-level const
 * would make tests that set the variable assert against a stale value.
 */
export function qualityRulesEnforced(env: NodeJS.ProcessEnv = process.env): boolean {
  return env[QUALITY_RULES_ENFORCE_ENV] === 'true';
}

export interface QualityRuleStats {
  /** Questions the engine successfully evaluated. */
  audited: number;
  /** Of those, how many carried at least one blocking violation. */
  withBlocking: number;
  /** Of those, how many carried violations but none blocking. */
  withAdvisoryOnly: number;
  /** Questions the gate actually refused to write (enforcement ON). */
  blocked: number;
  /** Questions that WOULD have been refused but were written (enforcement OFF).
   *  The cost of switching the flag on, measured in advance. */
  suppressed: number;
  /** Questions whose audit threw. Contained, never propagated. */
  ruleErrors: number;
  /** Violation tally by rule name, blocking and advisory alike. */
  byRule: Record<string, number>;
  /** `externalId:rule` (or `externalId:ERROR:message`) for the first
   *  MAX_SAMPLES offenders, so a bad night is diagnosable and not merely
   *  countable — the reason `blockReasons` exists next to `blocked`. */
  samples: string[];
}

export function emptyQualityRuleStats(): QualityRuleStats {
  return {
    audited: 0,
    withBlocking: 0,
    withAdvisoryOnly: 0,
    blocked: 0,
    suppressed: 0,
    ruleErrors: 0,
    byRule: {},
    samples: [],
  };
}

export interface GateDecision {
  /** False only when enforcement is on AND a blocking violation was found. */
  write: boolean;
  blocking: Violation[];
  advisory: Violation[];
}

export function decideRuleGate(violations: Violation[], enforce: boolean): GateDecision {
  const blocking = violations.filter(v => v.severity === 'blocking');
  const advisory = violations.filter(v => v.severity !== 'blocking');
  return {
    write: !(enforce && blocking.length > 0),
    blocking,
    advisory,
  };
}

function pushSample(stats: QualityRuleStats, sample: string): void {
  if (stats.samples.length < MAX_SAMPLES) stats.samples.push(sample);
}

export function recordGate(
  stats: QualityRuleStats,
  externalId: string,
  decision: GateDecision,
  enforce: boolean,
): void {
  stats.audited++;

  for (const v of [...decision.blocking, ...decision.advisory]) {
    stats.byRule[v.rule] = (stats.byRule[v.rule] ?? 0) + 1;
  }

  if (decision.blocking.length > 0) {
    stats.withBlocking++;
    if (enforce) stats.blocked++;
    else stats.suppressed++;
    pushSample(stats, `${externalId}:${decision.blocking[0].rule}`);
  } else if (decision.advisory.length > 0) {
    stats.withAdvisoryOnly++;
  }
}

export function recordRuleError(
  stats: QualityRuleStats,
  externalId: string,
  err: unknown,
): void {
  stats.ruleErrors++;
  const message = err instanceof Error ? err.message : String(err);
  pushSample(stats, `${externalId}:ERROR:${message.slice(0, 120)}`);
}

/** Fold `from` into `into`. `from` is left untouched. */
export function mergeQualityRuleStats(into: QualityRuleStats, from: QualityRuleStats): void {
  into.audited += from.audited;
  into.withBlocking += from.withBlocking;
  into.withAdvisoryOnly += from.withAdvisoryOnly;
  into.blocked += from.blocked;
  into.suppressed += from.suppressed;
  into.ruleErrors += from.ruleErrors;
  for (const [rule, n] of Object.entries(from.byRule)) {
    into.byRule[rule] = (into.byRule[rule] ?? 0) + n;
  }
  for (const s of from.samples) pushSample(into, s);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/trivia/scripts/international/qualityGate.test.ts`
Expected: PASS — 20/20.

- [ ] **Step 5: Commit**

```bash
git add backend/src/trivia/scripts/international/qualityGate.ts backend/src/trivia/scripts/international/qualityGate.test.ts
git commit -m "feat(trivia): the nightly quality gate decision, testable without a database"
```

---

## Task 4: Tell the news generator the rules it will be judged by

**Files:**
- Modify: `backend/src/trivia/scripts/international/question-generator.ts` (the `QUESTION_GENERATION_SYSTEM_PROMPT` template literal, around `:82`)
- Create: `backend/src/trivia/scripts/international/question-generator.test.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `QUESTION_GENERATION_SYSTEM_PROMPT` becomes an **exported** `const` (it is currently module-private) so it can be asserted against. Task 5 modifies the same file but not this export.

**Context:** `question-generator.ts` does not import `QUALITY_GUIDELINES` — its prompt is standalone. So Task 1's §6a reaches `replacementGenerator`, `CurrentTermQuestionGenerator` and `ElectionQuestionGenerator`, and reaches the nightly news lanes not at all. That is the lane that produced `wnews-0134`.

Importing the whole of `QUALITY_GUIDELINES` here would be wrong, not merely expensive: it requires a `.gov`/`.edu`/`.us` source URL and an explanation beginning "According to", and it forbids "obscure dates" — news questions are none of those things, and the model would refuse its own valid output. Port only the rules that apply to news content **and** that the engine will actually enforce, so the prompt and the gate agree.

- [ ] **Step 1: Write the failing test**

Create `backend/src/trivia/scripts/international/question-generator.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { QUESTION_GENERATION_SYSTEM_PROMPT } from './question-generator.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * The nightly news prompt is standalone — it never imported QUALITY_GUIDELINES,
 * so every standard the rest of the content system agreed on reached every
 * generator except the one running unattended at 02:00. `wnews-0134` came out
 * of this prompt.
 *
 * The prompt states the rules the gate enforces, and only those. Importing the
 * shared guidelines wholesale would demand a .gov source URL and an
 * "According to" explanation from a question built on a Reuters article, and
 * the model would reject its own valid output.
 */
describe('QUESTION_GENERATION_SYSTEM_PROMPT', () => {
  it('forbids a past-tense year question offering a year that has not arrived', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('has not arrived yet');
  });

  it('carries the numeric distractor rule', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('must not always sit in the middle');
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('ascending');
  });

  it('forbids the vague qualifiers the ambiguity rule blocks on', () => {
    const p = QUESTION_GENERATION_SYSTEM_PROMPT;
    expect(p).toContain('most important');
    expect(p).toContain('primarily');
  });

  it('requires the four options to be clearly distinct', () => {
    expect(QUESTION_GENERATION_SYSTEM_PROMPT).toContain('clearly distinct');
  });

  it('does not import the civic-structure guidelines that news cannot satisfy', () => {
    // A .gov source requirement or an "According to" explanation rule would
    // make the model reject perfectly good questions built on a wire story.
    const p = QUESTION_GENERATION_SYSTEM_PROMPT;
    expect(p).not.toContain('.gov');
    expect(p).not.toContain('According to [source]');
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/trivia/scripts/international/question-generator.test.ts`
Expected: FAIL — `QUESTION_GENERATION_SYSTEM_PROMPT` is not exported, so the import is undefined and the first assertion throws.

- [ ] **Step 3: Export the prompt and add the rules block**

In `question-generator.ts`, change the declaration from:

```ts
const QUESTION_GENERATION_SYSTEM_PROMPT = `You are a civic trivia question writer.
```

to:

```ts
export const QUESTION_GENERATION_SYSTEM_PROMPT = `You are a civic trivia question writer.
```

Then, inside the same template literal, insert the following block between the `Quality gate — assess EACH question...` section (ending with the `Set quality_gate.passed = false ...` line) and the closing `Generate 1 question for straightforward claims.` line:

```
Hard rules — a question breaking any of these is rejected by the quality engine
after you write it, so write them right the first time:

1. TIME. If the question asks what year something happened and the event is in the
   past, no option may be a year that has not arrived yet. "In what year did X
   begin?" must not offer 2027. A question about a deadline, a target or a term
   that ends in the future may offer a future year — the test is the event, not
   the number.
2. NUMBERS. When all four options are numbers, quantities, years or percentages,
   the correct value must not always sit in the middle of the range. Vary which
   bracket it falls in across a batch — sometimes smallest, sometimes largest.
   Use one unit throughout a single question, and order the options ascending.
   Never move the correct value to achieve this; change the distractors.
3. NO VAGUE QUALIFIERS. Do not write "most important", "best", "primarily",
   "generally", "mainly", "usually", "typically", "often" or "commonly" into a
   question. They make more than one option defensible.
4. DISTINCT OPTIONS. The four options must be clearly distinct — not near-synonyms,
   not overlapping ranges, not the same phrase reordered.
5. NO ADDRESSES OR PHONE NUMBERS as answer options.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/trivia/scripts/international/question-generator.test.ts`
Expected: PASS — 5/5.

- [ ] **Step 5: Commit**

```bash
git add backend/src/trivia/scripts/international/question-generator.ts backend/src/trivia/scripts/international/question-generator.test.ts
git commit -m "feat(trivia): state the enforced rules in the nightly news prompt"
```

---

## Task 5: Audit every question before it is written

**Files:**
- Modify: `backend/src/trivia/scripts/international/question-generator.ts` (`writePassingQuestions`, and the `QuestionWriteResult` region above it)
- Modify: `backend/src/trivia/scripts/international/question-generator.test.ts` (add a describe block)

**Interfaces:**
- Consumes: from Task 3 — `qualityRulesEnforced`, `emptyQualityRuleStats`, `decideRuleGate`, `recordGate`, `recordRuleError`, `QualityRuleStats`.
- Produces, consumed by Task 6:
  - `interface WritePassResult { written: QuestionWriteResult[]; ruleStats: QualityRuleStats }`
  - `writePassingQuestions(...)` returns `Promise<WritePassResult>` instead of `Promise<QuestionWriteResult[]>`. Its parameter list is unchanged.
  - `export function toQuestionInput(q, externalId, source): QuestionInput` — the mapping from a placed generated question to the engine's input shape, exported so it can be tested without a database.

**Context:** This is the wiring the whole plan exists for. `writePassingQuestions` is the single write path for every news lane; `wnews-0134` was inserted by the loop this task modifies.

Three things must be true of where the call goes:

- **After `placeAnswer`**, because `placeAnswer` rewrites `options` and `correctAnswer` and the audit must judge what will be stored.
- **Before `insert`**, because a blocking verdict has to prevent the row, not annotate it afterwards.
- **With `skipUrlCheck: true`**, because `checkLearnMoreLink` fetches `source.url` and raises `broken-learn-more` at severity `blocking` on any non-timeout failure. In a cron job that means a round trip per question and a blocking verdict that depends on whether a news site answered a bot.

- [ ] **Step 1: Write the failing test**

Append to `backend/src/trivia/scripts/international/question-generator.test.ts`:

```ts
import { toQuestionInput } from './question-generator.js';
import { auditQuestion } from '../../services/qualityRules/index.js';

describe('toQuestionInput', () => {
  const placed = {
    text: 'In what year did the treaty enter into force?',
    options: ['2019', '2021', '2024', '2027'],
    correctAnswer: 1,
    explanation: 'It entered into force in 2021.',
    difficulty: 'medium' as const,
    qualityGate: { passed: true, reason: '' },
  };

  it('maps a placed question onto the engine input shape', () => {
    const input = toQuestionInput(placed, 'wnews-0134', { name: 'Reuters', url: 'https://example.com/a' });
    expect(input).toEqual({
      text: placed.text,
      options: placed.options,
      correctAnswer: 1,
      explanation: placed.explanation,
      difficulty: 'medium',
      source: { name: 'Reuters', url: 'https://example.com/a' },
      externalId: 'wnews-0134',
    });
  });

  it('feeds the engine a question it can actually judge — the wnews-0134 shape', async () => {
    // The end-to-end point of the plan: this exact shape reached production.
    const input = toQuestionInput(placed, 'wnews-0134', { name: 'Reuters', url: 'https://example.com/a' });
    const result = await auditQuestion(input, { skipUrlCheck: true });
    expect(result.hasBlockingViolations).toBe(true);
    expect(result.violations.some(v => v.rule === 'anachronistic-year-option')).toBe(true);
  });

  it('does not touch the network when skipUrlCheck is set', async () => {
    // Review Focus 2. An unreachable URL must not produce a verdict at all
    // when the URL check is skipped — if this ever fails, the cron has grown
    // an HTTP round trip per question and a blocking verdict that depends on
    // a news site answering a bot.
    const input = toQuestionInput(
      { ...placed, options: ['2019', '2021', '2024', '2025'] },
      'wnews-0200',
      { name: 'Reuters', url: 'https://this-host-does-not-exist.invalid/x' },
    );
    const result = await auditQuestion(input, { skipUrlCheck: true });
    expect(result.violations.some(v => v.rule === 'broken-learn-more')).toBe(false);
  });
});
```

Note: `anachronistic-year-option` is the exact `rule:` string `anachronism.ts:131` emits — verified, not assumed. The second test asserts a *current* fact about the bank's own rule; if `2027` ever stops being a future year this test becomes wrong for a good reason — the rule's own test file owns the clock, not this one.

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd backend && npx vitest run src/trivia/scripts/international/question-generator.test.ts`
Expected: FAIL — `toQuestionInput` is not exported.

- [ ] **Step 3: Add the mapping and the result type**

In `question-generator.ts`, add the imports at the top (alongside the existing `import type { ClaimResult }`):

```ts
import type { QuestionInput, Violation } from '../../services/qualityRules/types.js';
import { auditQuestion } from '../../services/qualityRules/index.js';
import {
  qualityRulesEnforced,
  emptyQualityRuleStats,
  decideRuleGate,
  recordGate,
  recordRuleError,
  type QualityRuleStats,
} from './qualityGate.js';
```

`Violation` is imported for the log line's type; if the implementation below does not name it, drop it rather than leaving an unused import — `eslint` will fail the build on one.

Below `QuestionWriteResult`, add:

```ts
export interface WritePassResult {
  written: QuestionWriteResult[];
  ruleStats: QualityRuleStats;
}

/**
 * Map a generated question onto the quality engine's input shape.
 *
 * Takes the PLACED options and answer index, not the model's — `placeAnswer`
 * rewrites both, and the engine must judge what will actually be stored.
 */
export function toQuestionInput(
  q: {
    text: string;
    options: string[];
    correctAnswer: number;
    explanation: string;
    difficulty: string;
  },
  externalId: string,
  source: { name: string; url: string },
): QuestionInput {
  return {
    text: q.text,
    options: q.options,
    correctAnswer: q.correctAnswer,
    explanation: q.explanation,
    difficulty: q.difficulty,
    source,
    externalId,
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd backend && npx vitest run src/trivia/scripts/international/question-generator.test.ts`
Expected: PASS — 8/8.

- [ ] **Step 5: Change the signature and wire the gate into the write loop**

Change the function signature:

```ts
export async function writePassingQuestions(
  questions: GeneratedQuestion[],
  claim: ClaimResult,
  collectionId: number,
  jobId: number,
  externalIdPrefix: string,
  volatility: Volatility,
): Promise<WritePassResult> {
  const ruleStats = emptyQualityRuleStats();
  const passingQuestions = questions.filter(q => q.qualityGate.passed);
  if (passingQuestions.length === 0) return { written: [], ruleStats };
```

Every remaining `return` in the function becomes `return { written: results, ruleStats }`.

Inside the `for (const q of passingQuestions)` loop, after:

```ts
    const placed = placeAnswer(q.options, q.correctAnswer, externalId);
```

insert:

```ts
    // ── Quality rules gate ──────────────────────────────────────────────────
    // The engine judges the PLACED question, because that is what gets stored.
    // skipUrlCheck is not an optimisation: checkLearnMoreLink fetches
    // source.url and raises a BLOCKING violation on any non-timeout failure,
    // and a news article URL is not a .gov page that answers bots politely.
    // Leaving it on would put an HTTP round trip per question inside the cron
    // and make the verdict depend on network weather.
    const enforce = qualityRulesEnforced();
    try {
      const audit = await auditQuestion(
        toQuestionInput({ ...q, options: placed.options, correctAnswer: placed.correctAnswer }, externalId, {
          name: primarySource.feedName,
          url: primarySource.url,
        }),
        { skipUrlCheck: true },
      );

      const decision = decideRuleGate(audit.violations, enforce);
      recordGate(ruleStats, externalId, decision, enforce);

      if (decision.blocking.length > 0) {
        const rules = decision.blocking.map(v => v.rule).join(', ');
        console.log(
          `[QualityRules] ${enforce ? 'BLOCKED' : 'WOULD BLOCK'} ${externalId} — ${rules} — "${q.text.slice(0, 60)}"`,
        );
      }

      if (!decision.write) continue;
    } catch (err) {
      // A rule that throws must not cost the claim its remaining questions.
      // run-pipeline contains errors per CLUSTER, so an escape from here
      // discards every question left for this claim, not just this one.
      recordRuleError(ruleStats, externalId, err);
      console.error(
        `[QualityRules] audit threw for ${externalId}: ${err instanceof Error ? err.message : String(err)} — writing unaudited`,
      );
    }
```

The `catch` deliberately falls through to the insert: a broken rule is our defect, and refusing to write a question because our own code crashed would turn a bug into silent content loss.

- [ ] **Step 6: Add the conflict-accounting test**

Append to `question-generator.test.ts`:

```ts
describe('writePassingQuestions accounting', () => {
  it('counts an audited question that hits an id conflict as audited, not written', () => {
    // Review Focus 5. The insert is onConflictDoNothing() and `continue`s on
    // an empty result. Auditing happens BEFORE the insert, so a conflicted
    // question is correctly audited and correctly not written — the two
    // counters must not be assumed equal anywhere downstream.
    //
    // Asserted structurally rather than against a database: the invariant is
    // that `written.length <= ruleStats.audited`, and that is the property
    // run-pipeline's merge relies on.
    const stats = emptyQualityRuleStats();
    recordGate(stats, 'wnews-0001', decideRuleGate([], false), false);
    recordGate(stats, 'wnews-0002', decideRuleGate([], false), false);
    const written = [{ questionId: 1, externalId: 'wnews-0001', status: 'active' as const }];
    expect(written.length).toBeLessThanOrEqual(stats.audited);
    expect(stats.audited).toBe(2);
  });
});
```

Add the import it needs at the top of the file:

```ts
import { emptyQualityRuleStats, decideRuleGate, recordGate } from './qualityGate.js';
```

- [ ] **Step 7: Run the full trivia suite**

Run: `cd backend && npx vitest run src/trivia`
Expected: PASS. `run-pipeline.ts` does not compile against the new return type yet, but it has no test of its own that exercises `writePassingQuestions`; if any test fails on the changed signature, fix it here rather than deferring to Task 6.

- [ ] **Step 8: Commit**

```bash
git add backend/src/trivia/scripts/international/question-generator.ts backend/src/trivia/scripts/international/question-generator.test.ts
git commit -m "feat(trivia): audit every nightly question against the rules engine before writing it"
```

---

## Task 6: Surface the verdict where an operator can read it

**Files:**
- Modify: `backend/src/trivia/scripts/international/run-pipeline.ts` (`LaneStats` at `:44`, `emptyStats()` at `:64`, the `writePassingQuestions` call at `:480`, the lane log at `:572`, the `notes` object at `:590`)
- Modify: `backend/src/trivia/db/schema.ts` (the `generation_jobs.notes` `$type<>` block)

**Interfaces:**
- Consumes: from Task 5 — `WritePassResult`; from Task 3 — `QualityRuleStats`, `emptyQualityRuleStats`, `mergeQualityRuleStats`.
- Produces: `generation_jobs.notes.qualityRules`, the operator-readable record. No later task consumes it.

**Context:** `notes` is documented in `schema.ts` as "the primary observability surface for a pipeline run — nothing else reads generation_jobs, so this and `status` are all an operator has." It is `jsonb`, so a new key needs no migration. Putting the counts anywhere else would mean they existed only in logs that nobody keeps.

- [ ] **Step 1: Extend the notes type**

In `backend/src/trivia/db/schema.ts`, inside the `notes: jsonb('notes').$type<{ ... }>()` block, add after `blockReasons?: string[];`:

```ts
    /** The quality rules engine's verdict on this lane's output.
     *  `suppressed` is the one to read during the flagged rollout: questions
     *  that WOULD have been blocked and were written anyway, because
     *  TRIVIA_QUALITY_RULES_ENFORCE was not set to "true". It is the cost of
     *  switching enforcement on, measured before switching it on. */
    qualityRules?: {
      audited: number;
      withBlocking: number;
      withAdvisoryOnly: number;
      blocked: number;
      suppressed: number;
      ruleErrors: number;
      enforced: boolean;
      byRule: Record<string, number>;
      samples: string[];
    };
```

- [ ] **Step 2: Extend LaneStats**

In `run-pipeline.ts`, add the import:

```ts
import {
  emptyQualityRuleStats,
  mergeQualityRuleStats,
  qualityRulesEnforced,
  type QualityRuleStats,
} from './qualityGate.js';
```

Add to `interface LaneStats`, after `blockReasons: string[];`:

```ts
  /** The rules engine's verdict, merged across every claim this lane served.
   *  Separate from `blocked`/`blockReasons`, which are the MODEL's own
   *  self-assessment at generation time — a different gate with a different
   *  failure mode, and conflating them would hide which one is working. */
  qualityRules: QualityRuleStats;
```

and to `emptyStats()`, after `blockReasons: [],`:

```ts
    qualityRules: emptyQualityRuleStats(),
```

- [ ] **Step 3: Consume the new return shape**

Replace the `writePassingQuestions` call block:

```ts
          const written = await writePassingQuestions(
            passing, claimResult, idBySlug.get(target.collectionSlug)!,
            jobId, target.prefix, target.volatility,
          );
          laneStats.generated += written.length;
```

with:

```ts
          const writeResult = await writePassingQuestions(
            passing, claimResult, idBySlug.get(target.collectionSlug)!,
            jobId, target.prefix, target.volatility,
          );
          const written = writeResult.written;
          mergeQualityRuleStats(laneStats.qualityRules, writeResult.ruleStats);
          laneStats.generated += written.length;
```

The later `written[0]?.externalId ?? null` in the `guard.record(...)` call keeps working unchanged.

- [ ] **Step 4: Log it per lane**

Extend the per-lane console line so a run is diagnosable from the logs alone. After the existing `console.log('[Pipeline] lane=...')` call, add:

```ts
        const qr = s.qualityRules;
        if (qr.audited > 0) {
          console.log(
            `[QualityRules] lane=${t.lane}: ${qr.audited} audited, ${qr.withBlocking} with blocking ` +
            `(${qr.blocked} blocked, ${qr.suppressed} written anyway), ` +
            `${qr.withAdvisoryOnly} advisory-only, ${qr.ruleErrors} rule errors` +
            (Object.keys(qr.byRule).length > 0
              ? ` — ${Object.entries(qr.byRule).map(([r, n]) => `${r}=${n}`).join(' ')}`
              : ''),
          );
        }
```

- [ ] **Step 5: Write it into notes**

In the `notes: { ... }` object, after `blockReasons: s.blockReasons,`, add:

```ts
                qualityRules: {
                  ...s.qualityRules,
                  enforced: qualityRulesEnforced(),
                },
```

- [ ] **Step 6: Typecheck and run the suite**

Run: `cd backend && npx tsc --noEmit`
Expected: exit 0, no output.

Run: `cd backend && npx vitest run src/trivia`
Expected: PASS — every trivia test green, including the 189 that PR #815 left passing.

- [ ] **Step 7: Lint**

Run: `cd backend && npx eslint src/trivia/scripts/international src/trivia/db/schema.ts src/trivia/scripts/content-generation/prompts`
Expected: exit 0, no output. Unused imports fail the build here; if `Violation` from Task 5 Step 3 went unused, remove it.

- [ ] **Step 8: Commit**

```bash
git add backend/src/trivia/scripts/international/run-pipeline.ts backend/src/trivia/db/schema.ts
git commit -m "feat(trivia): record the rules engine's verdict in generation_jobs.notes"
```

---

## Task 7: Document the rollout and open the PR

**Files:**
- Modify: `backend/.env.example` (add `TRIVIA_QUALITY_RULES_ENFORCE`) — the file exists; append to it, never rewrite it.
- Create: `docs/superpowers/plans/2026-09-27-trivia-pipeline-quality-gate.md` — this file; commit it with the work.

**Interfaces:** none.

- [ ] **Step 1: Document the flag**

Append to `backend/.env.example`:

```
# Quality rules engine enforcement for the nightly trivia pipeline.
# Unset or anything other than "true" = rules run and violations are recorded in
# generation_jobs.notes.qualityRules, but nothing is blocked. Read `suppressed`
# there for a night or two before setting this to "true".
TRIVIA_QUALITY_RULES_ENFORCE=false
```

- [ ] **Step 2: Commit the plan and the env documentation**

```bash
git add docs/superpowers/plans/2026-09-27-trivia-pipeline-quality-gate.md
git add backend/.env.example
git commit -m "docs(trivia): plan and rollout note for the pipeline quality gate"
```

- [ ] **Step 3: Push and open the PR against the anachronism branch**

```bash
git push -u origin claude/trivia-pipeline-quality-gate
gh pr create --base claude/trivia-anachronism-rule \
  --title "feat(trivia): run the quality rules engine on nightly pipeline output" \
  --body "<see below>"
```

The body must state: that the base is PR #815 and #815 merges first; that enforcement is OFF by default and how to read `notes.qualityRules.suppressed` before flipping it; that `skipUrlCheck: true` is deliberate and why; and that spec §4.4 item 5 (re-measure the numeric-distractor distribution after a week) is not in this PR because it is a measurement, not a change.

- [ ] **Step 4: Wait for checks, do not merge**

Run: `gh pr checks --watch`
Expected: all required checks green.

Do not merge. Both this PR and #815 are Chris's to review, and the merge order matters.

---

## Not in this plan

**Spec §4.4 item 5 — re-measure the numeric-distractor distribution after a week of nightly runs.** It is a measurement taken against data this PR has not generated yet. It belongs to whoever flips `TRIVIA_QUALITY_RULES_ENFORCE` to `true`, and the query is the one in spec §2.4.

**Flipping the flag.** Deliberately left to a human with a night or two of `notes.qualityRules` in front of them. The engine has never been pointed at news-shaped content; `checkPureLookup` flags "in what year was…" and `checkAmbiguousAnswers` flags options sharing most of their words, and both shapes are ordinary in news questions. Enforcing on day one could zero the nightly yield and look like a quiet feed.

**`replacementGenerator.ts` and the two officeholder generators.** They consume `QUALITY_GUIDELINES`, so Task 1 reaches them, but none of them calls `auditQuestion` either. That is the same defect at three more addresses and deserves its own pass.

**The unregistered `duplicate.ts` rule**, in both repos. Out of scope per spec §5.
