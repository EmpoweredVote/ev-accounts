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

### Why I have not acted on it

There are two coherent readings and they call for **opposite** actions, so this is a product decision:

- **(A) The role table is right.** Then these ~3,300 rows are dead weight inflating coverage counts, and
  the fix is to retire them — starting with, but not limited to, my two.
- **(B) The role table is under-scoped.** Congress legislates housing (LIHTC, Section 8) and criminal
  justice constantly, so arguably `Affordable Housing` and `Criminal Justice Approach` should carry
  `federal` rows. Adding them would surface 271 existing rows plus my two, with no data change.

I lean **(B)** for those two specific topics on the merits, and **(A)** for genuinely municipal topics like
`City Sanitation and Cleanliness`. But (B) changes what 271 profiles display and (A) deletes thousands of
rows, and neither is inferable from the data — so **nothing has been changed** and both my rows stand as
applied, consistent with their 269 peers.

**Recommended next step:** decide (A) or (B) per topic, not globally, and treat the ~3,300-row count as its
own workstream with a gate — the same shape as `check-stance-sources.mjs` — so the number cannot grow
again once settled.
