# Decision: the four "scope-mismatched" pairs

Tranche 3 flagged four pairs as unanswerable by construction and said they needed a policy decision rather
than more research. **They did not need a new policy. The platform already encodes the answer, in
`inform.compass_topic_roles`, and I had not looked there.** Three of the four are settled by it; the
fourth was not a scope problem at all.

## The mechanism I should have checked first

`inform.compass_topic_roles (topic_id, role_scope, is_required)` is the live tier model. The API derives
three booleans from it at the boundary (`compassService.ts`), and the rule that matters is:

> `applies_federal = hasAnyRoleRows ? topicRoles.some(r => r.role_scope === 'federal') : true`
> — *"A topic with no rows defaults to all three tiers = true (cross-cutting)."*

The frontend then filters a profile's compass by the office's tier (`deriveScopedTopics` in `Results.jsx`
and `ElectionsView.jsx`): `NATIONAL_*` → `applies_federal`, `STATE_*` → `applies_state`, `JUDICIAL` →
`applies_judicial`, local types → `applies_local`, and it keeps only `t[key] !== false`.

⚠ `compass_topics.office_scope` is a **dead column** for this purpose — NULL on all 44 live topics, selected
by the backend, never read by the frontend. Do not build on it.

## The verdicts

| pair | topic's role rows | applies to a Representative? | decision |
|---|---|---|---|
| Hoyle / Transportation Priorities | `local`, `state` | **no** | **SETTLED BLANK — out of scope** |
| Salinas / Transportation Priorities | `local`, `state` | **no** | **SETTLED BLANK — out of scope** |
| Kamlager-Dove / Economic Development Incentives | `local`, `state` | **no** | **SETTLED BLANK — out of scope** |
| Hoyle / State Redistricting and Gerrymandering | `federal`, `state` | **yes** | **not a scope problem — ordinary evidence blank** |

**Transportation Priorities and Economic Development Incentives carry no `federal` role row**, so
`applies_federal` is already `false` and both topics are already filtered off a member of Congress's
compass. The city-scoped question text ("Where should **your city** focus its transportation investment?")
matches the tier model exactly. These three pairs are closed permanently: the rows migration 1537 retired
should never have existed, Kamlager-Dove's zero candidates were never an evidence gap, and **no further
research is warranted on any of them.**

🔴 **I was wrong about Hoyle / State Redistricting.** It has a `federal` role row, so the platform
deliberately asks it of federal officials, and a member of Congress can hold a real position on who draws
maps. The topic *title* says "State" but the scope model says federal applies. It is an **ordinary
evidence-insufficiency blank** — her only evidence is the Freedom to Vote Act omnibus plus DC statehood,
and chairs 1 ("no elected officials at any level") and 2 ("equal representation from both major parties")
are indistinguishable on it. Tranche 3's `BLANK_SCOPE` verdict is corrected to `BLANK_SKIP` here.

## 🔴 Two chairs migration 1541 applied are INERT — they cannot display

The same check, applied to what I had just written, found two of the nine restored chairs sit on topics
that `applies_federal = false` excludes for a Representative (`district_type = NATIONAL_LOWER`, verified
for both people):

| row applied by 1541 | topic's role rows | consequence |
|---|---|---|
| **Val Hoyle / Affordable Housing = 3** | `local` only | filtered off her profile |
| **Ayanna Pressley / Criminal Justice Approach = 1** | `judicial` only | filtered off her profile |

They are not *wrong* — the adjudication behind them stands, and nothing incorrect renders. They are
**inert**: written, invisible, and they still inflate the untiered `answer_count` in `getCandidates`, so
Hoyle reads as 7 stances when only 5 of them can surface. That is the same shape as the Beverly Hills
"claims coverage it does not have" fix.

**This is pre-existing and corpus-wide, not something 1541 introduced.** Counting answers whose topic
excludes the holder's tier:

| holder tier | answers on inapplicable topics |
|---|---|
| state | ~1,975 (Affordable Housing alone: **712**) |
| local | ~696 (Taxation: 135, Immigration: 95) |
| federal | ~640 (Affordable Housing: **194**, Criminal Justice: **77**) |
| **total** | **~3,300** |

Of the 194 federal Affordable Housing answers, 193 predate mine; of the 77 federal Criminal Justice
answers, 76 do.

### ✅ RESOLVED for these two topics — migration 1543, applied

Operator chose reading **(B)**: the role table was under-scoped. Migration 1543 adds the missing `federal`
rows to `inform.compass_topic_roles` for both topics. **No stance data changed** — `politician_answers`
stayed at 33,175 and `politician_context` at 33,721, asserted by a guard.

| | before | after |
|---|---|---|
| Affordable Housing | `local` | `local` + **`federal`** |
| Criminal Justice Approach | `judicial` | `judicial` + **`federal`** |
| federal answers able to display | 0 of 271 | **271** (194 housing + 77 criminal justice) |
| out-of-tier answers, all tiers | 3,325 | **3,054** |
| federal required topics | 24 | **26** |

Verified on the live API (`/api/compass/topics`): both now return `applies_federal: true`, while
Transportation Priorities and Economic Development Incentives correctly still return `false`.

🔴 **The one real risk, measured before writing rather than after.** `is_required` feeds a *hard gate*:
`get_compass_completeness` counts only `is_required = true` rows, and `run_empower_preflight` turns an
incomplete compass into `eligible: false` with `CALIBRATION_INCOMPLETE`. Adding required topics moves the
federal bar from 24 to 26, which would strip eligibility from a candidate sitting at exactly 24. Production
check: **0 of 12 connected profiles have `candidate_role` set and there are 0 empowered profiles**, so
nobody can be demoted today — preflight fails earlier on `ROLE_NOT_SET` for all of them. `is_required=true`
was therefore both safe and consistent with all 80 pre-existing rows (not one `false` exists).
⚠ Expected, not a bug: the first federal-role candidate will see `required` = 26. If that is unwanted, flip
these two rows to `is_required=false` — the display flags ignore `is_required`, so the topics stay visible
while leaving the completeness denominator alone.

### What remains, and why I did not extend it further

### ✅ Also resolved: `Affordable Housing` at STATE tier — migration 1544, applied

Same decision, same shape. `Affordable Housing` had only `local` before 1543 and `federal+local` after it,
leaving **712 state-legislator housing stances invisible — the single largest out-of-tier bucket in the
corpus**, bigger than everything 1543 fixed. States run the LIHTC allocating agencies, set landlord-tenant
and rent-control law, and preempt or enable local zoning, so the row was missing rather than the stances
wrong. 1544 adds it. No stance data changed (33,175 / 33,721 asserted).

`Affordable Housing` is now `federal + state + local` and deliberately **not** `judicial`. Verified live:
`applies_federal/state/local = true`, `applies_judicial = false`. State required topics **26 → 27**.

⚠ With all three tiers present, DISPLAY behaviour is identical to a topic having no rows at all (none
defaults to all-true) — but the rows are not redundant, because they are what puts the topic in each tier's
**required** set for compass completeness.

### ✅ Also resolved: `Criminal Justice Approach` at STATE tier — migration 1545, applied

Third in the series, same reasoning. The topic was `judicial`-only until 1543 added `federal`; it still had
no `state` row, leaving **140 state-legislator stances invisible**. States own most of the criminal justice
system — they write the sentencing codes, run the prisons and parole boards, and set bail and juvenile law.
Now `federal + state + judicial`, verified live. State required topics **27 → 28**. No stance data changed.

⚠ **It deliberately has no `local` row, so 37 local-tier answers on it remain out of scope** and were not
addressed. Whether a local official should be asked *"when someone breaks the law, what matters most?"*
depends on **which** local office — a county sheriff or DA plausibly yes, a city zoning board no — so it
cannot be settled by the topic alone the way the state row could.

## Running total and what is left

| | out-of-tier answers |
|---|---|
| before 1543 | 3,325 |
| after 1543 (federal housing + criminal justice, 271) | 3,054 |
| after 1544 (state housing, 712) | 2,342 |
| **after 1545 (state criminal justice, 140)** | **2,202** |

**1,123 previously-invisible stances now surface**, across three migrations that changed no stance data at all.

The remaining 2,202, largest buckets first:

| holder tier | topic | topic's scope | answers | likely call |
|---|---|---|---|---|
| state | Local Immigration Enforcement | local | 263 | arguable — states pass sanctuary preemption |
| state | Public Safety Approach | local | 249 | arguable |
| state | United States Tariff Policy | fed | 141 | **retire** — states set no tariffs |
| local | Taxation and Public Spending | fed+state | 135 | arguable — many cities set property tax |
| state | Residential Zoning | local | 107 | arguable — states increasingly preempt zoning |
| state | Social Security | fed | 104 | **retire** — not a state programme |
| federal | Judicial Interpretation | judicial-only | 61 | arguable |
| local | Criminal Justice Approach | fed+state+judicial | 37 | depends on WHICH local office |

**The easy additions are done.** What is left is genuinely harder, and in a specific way: the two clear
*retirements* (Tariff Policy 141, Social Security 104 — neither is a state function) are straightforward, but
everything else turns on **which offices within a tier**, not on the topic. `Local Immigration Enforcement`
and `Residential Zoning` are real state questions in preemption fights and not otherwise; `Taxation and
Public Spending` fits a city that sets property tax rates and not a school board; `Criminal Justice Approach`
fits a county sheriff or DA and not a city clerk.

That means the remaining backlog probably cannot be cleared by adding tier rows at all — a per-office
dimension the current model does not have would be needed, or the rows get retired. **That is a design
question, not a data question**, and it is where this should stop until someone decides it.

**Recommended next step:** decide the arguable rows per topic, not globally, then add a gate in the shape of
`check-stance-sources.mjs` keyed on out-of-tier count so the number cannot regrow once settled. The gate must
classify tiers with **`upper(governments.type)`** — values are `NATIONAL`/`STATE`/`LOCAL` plus
`City`/`County`/`School District`/`Township`/`Village`/`Town` and one stray lowercase `federal`, and a
case-sensitive comparison silently buckets every official as local.
