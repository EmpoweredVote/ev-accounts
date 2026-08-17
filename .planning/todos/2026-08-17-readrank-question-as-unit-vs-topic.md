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
