# Read & Rank: the question is the unit in the admin layer, the topic is still the unit in the game

**Found:** 2026-08-17, while selecting a live econ-dev question for the LA Mayor general race (1814).

## The inconsistency

1377 made the **question** the first-class unit of comparison: `essentials.readrank_questions`,
`quotes.question_id`, and the admin coverage grid all key on the question. One topic can legitimately
host several questions — 1810 did exactly that, splitting LA Mayor's pooled economic-development
question into a film/TV question and a downtown question.

**The player path never followed.** Two places in `backend/src/lib/readrankService.ts` still treat
the topic as the unit:

- `getRaceBlindQuotes` buckets quotes into a `Map` keyed by `lower(topic_key)`, and each bucket
  carries **one** question string from `COALESCE(rq.question_text, rtq.question_text,
  ct.question_text)` — taken from whichever row created the bucket first.
- `getPlayableRaces` measures playability in rankable **topics**:
  `GROUP BY lower(q2.topic_key) HAVING COUNT(DISTINCT politician_id) >= 2`.

And `essentials.quotes` carries a partial unique index from **293**, captioned there as "Enforce at
most one selected per stance":

```
quotes_one_selected_per_stance UNIQUE (politician_id, lower(topic_key)) WHERE readrank_selected
```

## What the index does and does not protect

It looks like a stale stance-era artifact — 293 predates 1377 by ~1084 migrations — and it does
block the *same-candidate* case: one politician cannot hold two selected quotes in one topic.

**But it does not close the hole, because it is keyed on `(politician_id, lower(topic_key))`, not on
the topic alone.** Candidate A selected on question 1 and candidate B selected on question 2 of the
*same topic* satisfies the index perfectly — each politician has exactly one selected quote — and
still produces the corruption. `getRaceBlindQuotes` would:

1. merge both into a single topic card,
2. print one question text chosen **nondeterministically** (the `ORDER BY` is on topic title, so
   intra-topic row order is unspecified),
3. place the two quotes side by side as a head-to-head comparison, though they answer **different
   questions**.

`getPlayableRaces` does not catch it either: its `HAVING COUNT(DISTINCT politician_id) >= 2` sees two
distinct candidates in the merged topic, so the race stays playable and the topic counts as rankable.
The admin grid meanwhile reports *both* questions as `answering=1`, not rankable — so the two layers
disagree, and the game is the one that shows the bogus card.

⚠ 1815's header says the index "is what PREVENTS a corruption". That is too strong — it prevents only
the same-candidate case. This file is the accurate account.

### The concrete trap

For LA Mayor today both candidates are selected on the film question, so any *additional* selection
on downtown hits the index and fails loudly. The dangerous move is a **swap**, which is exactly what
an editor wanting downtown live would naturally do:

> unselect Raman from film → select Raman on downtown

Now film holds only Bass and downtown only Raman. The index is satisfied. The game renders one
econ-dev card pairing Bass's *film* answer against Raman's *downtown* answer under a single
nondeterministically-chosen question. Nothing errors.

## Footprint in prod, measured 2026-08-17

| | |
|---|---|
| Confirmed questions | 2431 |
| Distinct race/topic pairs | 2429 |
| Race/topic pairs hosting **>1** question | **1** — LA Mayor general, `economic-development` (3 questions) |
| Merged-card cases currently live | **0** |

So the corpus is 1:1 everywhere except the one cluster this session touched, and nothing is corrupt
today. The bug is latent and narrowly scoped — but it is armed at exactly the place someone is most
likely to edit next, since downtown is fully prepared and waiting.

A cheap standing check, worth adding as a guard script:

```sql
SELECT rq.race_id, lower(q.topic_key), count(DISTINCT q.question_id)
  FROM essentials.quotes q
  JOIN essentials.readrank_questions rq ON rq.id = q.question_id
 WHERE q.readrank_selected AND q.deidentified_text IS NOT NULL
 GROUP BY 1, 2
HAVING count(DISTINCT q.question_id) > 1;   -- must return 0 rows until the fix lands
```

## Consequence being lived with

The LA Mayor general race has three econ-dev questions and can only publish **one**. 1814 selected
the film question on merit; the downtown pair is fully prepared (Bass `b2d1f06d` selected-ready,
Raman `f7625f7b` de-identification repaired) but **cannot go live** until this is fixed. The pooled
question `ded400bd` is unusable on both sides regardless and is a separate retirement decision.

## Fix, in order

1. **`getRaceBlindQuotes`** — group by `COALESCE(question_id::text, 'topic:' || lower(topic_key))`
   so each question becomes its own card carrying its own question text. The fallback matters:
   compass-era quotes have `question_id IS NULL` and must still group by topic.
2. **`getPlayableRaces`** — count rankable *questions* with the same fallback, so `topic_count` /
   `rankable_topic_count` stop understating a split topic. Check every caller: the name is in the
   API payload and the frontend reads it.
3. **The index** — replace with `(politician_id, question_id) WHERE readrank_selected`, plus a
   second partial index `(politician_id, lower(topic_key)) WHERE readrank_selected AND question_id
   IS NULL` to preserve 293's guarantee for the compass-era rows.
4. **Frontend** — audit anything assuming one card per topic. `admin/src/pages/admin/ReadRankQuotesPage.tsx`
   groups by `topicKey` (`AdminTopicQuotes`), and the game emits `quotes[].topicKey` per quote.
5. **Scoring** — the risky part. Confirm nothing keys results by topic in a way that silently merges
   two questions' rankings, and that per-question scores aggregate as intended.

## Watch out

- Order steps 1–2 **before** 3. Relaxing the index first lets an editor create the merged-card
  corruption with no error.
- 1814's post-verify gate 3 asserts no econ-dev quote is selected outside the film question for these
  candidates. That gate is deliberately redundant with the index today, so an index rework cannot
  void the invariant silently — expect to revisit it when step 3 lands.

---

## Status — done 2026-08-17

Steps 1, 2, 3 and 5 are implemented and tested; step 4 is done for the admin app and **blocked in the
game client**, which is a separate repo. 554 backend tests pass, typecheck clean, 0 lint errors.

| Step | Where | State |
|---|---|---|
| 1. Blind payload per question | `readrankService.ts` `getRaceBlindQuotes` | done |
| 2. Rankable **questions** | `readrankService.ts` `getPlayableRaces` | done |
| 3. Index rework | `backend/migrations/1820_readrank_one_selected_per_question.sql` | **authored, not applied** |
| 4. Frontend audit | `admin/` done · `read-rank/` outstanding | **partial** |
| 5. Scoring | `readrankService.ts` `computeRaceMatch` | done |
| + | `backend/scripts/check-readrank-question-unit.mjs` + CI job | done |

Cards are keyed on `COALESCE(question_id::text, 'topic:' || lower(topic_key))`, exposed as
`questionCardKey()` in TypeScript. The payload gained `topics[].key`, `topics[].questionId` and
`quotes[].cardKey`; `BallotEntry.perTopic[]` gained `key`, `questionId` and `question`. The
`topicCount` / `rankableTopicCount` wire names were **kept** (the game client reads
`rankableTopicCount ?? topicCount`) and now carry question-keyed numbers, with
`questionCount` / `rankableQuestionCount` added as the honest names.

### Two things this doc missed

**a. `selectReadrankQuote` was itself the trigger.** The doc frames the dangerous move as an editor
manually swapping. It was worse: the admin *select* button cleared by
`(politician_id, lower(topic_key))`, so selecting Raman's downtown quote **silently unselected
Raman's film quote** — one click, no error, straight to the merged card. The admin radio groups were
`name={sel-${p.id}-${t.topicKey}}` for the same reason, so the UI physically prevented one selection
per question. Both are now question-scoped (`readrankQuotesService.ts`, `ReadRankQuotesPage.tsx`),
`listReadrankQuotes` groups per question, and `PUT /deselect` takes an optional `question_id`.
This had to land **before** step 3, not after.

**b. Step 3 arms a *client* corruption, so it cannot be applied alone.** `read-rank`'s
`useReadRankStore.ts` builds progress as `topics[t.topicKey] = {...}` — a Record keyed by topicKey —
and routes verdicts via `race.topics[quote.topicKey]`. Two cards sharing a topicKey collide: the
second overwrites the first, `topicOrder` lists the key twice, and one question renders twice while
the other's quotes never appear. Nothing errors. So the ordering is really 1, 2, 5, admin, **client**,
then 3.

### Coordinated change needed in `read-rank` before a split topic goes live

Group on the payload's `key` / `cardKey`, not `topicKey`:

- `src/store/useReadRankStore.ts` — `buildRaceProgress` (`topics[t.topicKey]` → `topics[t.key]`,
  `topicOrder.push(t.key)`), `refreshRaceContent`, and every `race.topics[quote.topicKey]` verdict
  lookup (~:366, :386, :449) → `quote.cardKey`.
- `src/data/api.ts:279` — `isTopicAllowed(t.topicKey)` still gates on the real topic, which is
  correct; leave it.
- `src/utils/alignmentGrid.ts:26`, `src/components/AlignmentPills.tsx:22` — `new Map(entry.perTopic.map(t => [t.topicKey, t]))`
  loses a section; key on `t.key`.
- `src/data/mockData.ts:251` — same, in the mock reveal builder.
- Render `perTopic[].question` where two sections share a `title`.
- Optional: migrate to `rankableQuestionCount` / `questionCount`.

Until that ships, `npm run check:readrank-question-unit --prefix backend` (CI job
"read & rank question unit", master + daily, skips without `DATABASE_URL`) fails the moment two
questions in one race/topic both serve quotes.

### Prod steps not taken here

- **1820 has not been dry-run or applied.** Per CLAUDE.md, wrap the body in `BEGIN; … ROLLBACK;`
  against prod and confirm the rollback reverted first. Creating either unique index errors rather
  than corrupts if live data violates it.
- **The downtown pair is still unselected.** Bass `b2d1f06d` / Raman `f7625f7b` stay parked until
  1820 is applied *and* the client change lands. Seating them makes 1815's Gate 3 false by design —
  it was a point-in-time assertion, and the CI guard is the standing invariant that replaces it.
