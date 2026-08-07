# Orphan `inform.politician_context` rows — diagnosis, 2026-08-07

Closes the "546 orphan context rows — undiagnosed" item carried in the re-research worklist.
**Nothing was written to the database for this investigation. Read-only.**

## The count is 542, not 546

| | |
|---|---|
| `politician_context` total | 33,300 |
| `politician_answers` total | 32,758 |
| context rows with no answer | **542** |
| answers with no context | **0** |

Answers are a strict subset of context. The 546 in the worklist was measured before migrations
1549+ landed; four have since resolved. Anyone re-measuring should expect drift, not a discrepancy.

## The 542 split cleanly, and 404 are already adjudicated

```
542 orphans
├── 404  empty `sources`   → LEGITIMATE, closed 2026-08-07
└── 138  with sources      → the actual cohort
     ├──  80  dated documented blanks
     └──  58  substantive characterisations
```

The 404 coincide **exactly** with the empty-`sources` cohort ruled legitimate in
`project_empty_sources_are_legitimate`: all 404 empty-source context rows are orphans, and
**0 empty-source rows have an answer**. That is not a coincidence — it is the definition of an
honest documented blank ("we looked, found nothing, here is what we checked"). A blank has no
chair, so it has no answer row. They are supposed to be orphans.

**This means the 404 and the orphan count were never two findings. They were one finding counted
twice**, and the larger half was closed the same day the worklist item was written.

### The 80 dated blanks are the same class, just cited

Reasoning opens `Researched <date>` and states the absence outright:

> "Researched 2026-05-13. Checked: LAist voter guide, LACBA JEEC (Not Qualified). … No substantive
> judicial philosophy statements available for placement." — Robert Draper / Criminal Justice

> "Researched 2026-05-12 — no scorable public record found." — Manny Singh / Residential Zoning

These carry a source because the researcher cited what they *checked*. Same honest blank as the
404; the only difference is diligence in recording the negative. **Not a defect.**

Cohorts: the 2026-05-11..13 Collin County / Anna / Prosper / Bloomington / LA-judges work.

### The 58 substantive characterisations are the real finding

Reasoning that describes a position with no chair recorded. Examples:

> "Progressive on housing affordability. Plans to cap rents and ease tax burdens…" — Tish Hyman / Housing

> "Her **leans-slow-growth score** reflects Prosper's broader council posture…" — Amy Bartley / Growth Pace

Bartley's row *narrates a score that does not exist*. Two rows do this. That is the signature of a
partial write: the researcher scored the topic, the prose was stored, the answer was not.

25 politicians, 24 live topics, spanning at least three separate seeding waves (LA City
Attorney/Mayor candidates, Collin County TX towns, federal candidates) — so this is a systemic
write pattern, not one bad batch.

## Root cause

**`politician_context` has no referential dependency on `politician_answers`.** Verified:

```
politician_context_pkey                  PRIMARY KEY (politician_id, topic_id)
politician_context_politician_id_fkey    FK → essentials.politicians(id)
politician_context_topic_id_fkey         FK → inform.compass_topics(id) ON DELETE CASCADE
```

No FK to answers, no CHECK, no trigger. Both write paths insert context independently and neither
requires an answer to exist:

- `adminService.ts:565` — `adminSetPoliticianContext`, bare upsert
- `compassContributor.ts:500` — sources PUT, upserts context with `reasoning = ''`

So any pass that writes context and fails to write the answer leaves a permanent orphan.

### Why nothing ever caught it

`scripts/check-stance-sources.mjs:213` drives the gate from
`FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc`.

**Orphans are outside the gate's universe by construction.** No threshold, no new check on the
existing query, and no amount of ratcheting could ever surface them — the same shape as the
landing-page gate blind spot recorded in 1558.

### Hypotheses tested and eliminated

| hypothesis | result |
|---|---|
| Retirement migrations deleted answers but left context | **Dead.** All 24 migrations that delete answers also delete context. |
| Answers exist with `value = 0` and are filtered at read | **Dead.** 0 zero-value answers; all values 1–5. |
| Orphan topics are retired / not live | **Dead.** All 58 are on `is_live = true` topics. |
| Written through the admin UI | **Dead.** `admin_audit_log` has zero `politician_context` / `politician_answers` / stance actions. |
| Answers were retired and archived | **Dead.** None of the 58 appear in any rollback record; only a read-only reachability audit mentions them. |

## Voter visibility: ZERO. None of the 542 are reachable.

Three paths serve context; all three are closed for orphans.

1. **`/compass/politicians/:id/citations` → Citations.jsx.** `Citations.jsx:112` renders `reasoning`
   under "Why this position?" *independently of* `has_stance`, so an orphan **would** print with a
   "Position under review" chip above it. But the query drives
   `FROM inform.politician_context_evidence` — and **0 of the 138 have an evidence row.**
2. **`/compass/politicians/:id/:topicId/context` → ev-ui `StanceAccordion.jsx:157`.** Lazy-fetched on
   row expand. But `CompassCard.jsx:195-200` builds the row list as
   `allPolTopics = scopedTopics.filter(t => polAnsweredIds.has(t.id))` — **answered topics only**, so
   an orphan topic never gets a row to expand and is never fetched.
3. **`/compass/politicians/:id/context` → `getPoliticianContextAll`.** Returns every context row for
   a politician with no answer join — the widest exposure. **No consumer**: zero call sites in
   `essentials/src` or `ev-ui/src`.

**Correction to the framing that opened this task:** these are not a live voter-facing defect. I
described them that way before tracing the render path, and it was wrong.

## The actual risk is latent, and it is real

The reasoning is not published — but it is **pre-positioned to publish**. The moment an answer is
written for one of these 58 pairs, `Citations.jsx` and `StanceAccordion` begin rendering
prose nobody re-read, under the voter-facing heading "Why this position?".

**That is exactly what a re-research pass does.** Assigning a chair to (Marcus Ray, Taxes) would
silently publish:

> "His Finance Committee role and consistent skepticism toward development approvals **suggest** a
> fiscally conservative orientation"

— a textbook attribute-prior row, the class migration 1521 retired.

Scanning the 58 for already-condemned language:

| marker | rows |
|---|---|
| inference verbs (`suggests` / `indicates` / `signals` / `appears to`) | 6 |
| argues-from-absence | 3 |
| narrates a score that does not exist | 2 |

Overlapping, so the at-risk subset is under 11 of 58. Consistent with rule #1 — the majority of the
58 are ordinary sourced characterisations. **This is a reading queue, not a delete list.**

## Recommended, in priority order

1. **Add an `ORPHAN_CONTEXT` check to the gate.** It cannot be a new branch on the existing query —
   the universe is wrong. It needs its own `FROM politician_context LEFT JOIN politician_answers`
   query. Report-only at first; the count is 542 and 404 of those are legitimate, so a
   fail-the-build threshold would need to be scoped to sourced non-blank rows (58).
2. **Fold the 58 into the re-research worklist as a pre-condition**, not a separate job. When any
   cluster touches one of these 25 politicians, the existing reasoning must be re-read *before* a
   chair is assigned — never inherited silently.
3. **Do not repair or delete anything now.** Nothing is published, so there is no live harm and no
   deadline. Deleting is the one irreversible step, and 47+ of the 58 look fine.
4. Consider requiring an answer before context can be written, longer term. Not urgent: it would
   break the 404 legitimate blanks, which are context-without-answer *by design*.

## Verification performed

- Counts, splits and constraint list read directly from production via MCP.
- All 58 class-B rows read in full, not sampled — the regex split was checked by eye, not trusted.
  (Two rows my regex sent to class B are arguably blanks: Bryant Acosta ×2 say "not publicly
  available" yet still assert "appears to support". They are inference rows either way.)
- Render path traced end to end through `compassService.ts` → `compass.ts` → `Citations.jsx` /
  `CompassCard.jsx` → `StanceAccordion.jsx`.
