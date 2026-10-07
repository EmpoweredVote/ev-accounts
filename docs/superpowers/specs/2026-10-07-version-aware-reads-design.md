# Version-aware reads — a chair shows only on the ladder version it was written for

**Status:** design, for approval. **No read path is changed by this document.**
**Author:** Chris Andrews' session, 2026-10-07.
**Owner of the seasons design (loop in before changing read semantics):** Chris Cantrell — ADR 0005, ADR 0006, and
the handoff in [`2026-09-25-season-carry-forward-handoff.md`](2026-09-25-season-carry-forward-handoff.md).

## 1. Problem

Every voter read shows each politician's newest **published** season answer per topic (`SEASON_IS_PUBLISHED`,
`DISTINCT ON … ORDER BY s.number DESC`). A person with no row in the open season therefore shows their older
chair, rendered against the **open season's** ladder text.

- For a *clarifying* rewording (same `version`), that is acceptable. The rungs keep their meaning.
- For a *substantive* rewrite (`version` bumped), the voter sees a position against a sentence it was never
  evidenced against. That is the confabulation failure CLAUDE.md warns about, produced by a read path.

Season 3 will rewrite many ladders. The defect grows with every season unless the read path learns the rule.

## 2. Measured on production (read-only, 2026-10-07)

Seasons: S1 closed, S2 open, S3 draft. "Visible chair" = the row a voter read returns today: newest published
season per (politician, topic), `value <> 0`.

| | Chairs | |
|---|---:|---|
| Visible chairs, all topics | 33,012 | |
| — on a topic the open season does not ask | 1,678 | outside this rule (§3.3) |
| — written for the **same** version as the served ladder | 17,124 | |
| — written for a **different** version | **14,210** | **43% of visible chairs** |

All 14,210 are Season 1 chairs under Season 2 (S2 chairs always match; S2's 614 blanks are `value = 0`).
No row has a NULL `topic_revision_id` (the column is `NOT NULL`).

By topic (all served v2, written v1): climate-change 1,842 · civil-rights 1,536 · voting-rights 1,475 ·
deportation 1,319 · school-vouchers 1,216 · campaign-finance 834 · childcare 761 · religious-freedom 683 ·
economic-development 668 · homelessness 637 · ai-regulation 597 · social-security 589 ·
homelessness-response 440 · growth-and-development 428 · misinformation 364 · local-environment 345 ·
the seven judicial topics 476 together.

By person: of 4,223 politicians with at least one visible chair, **3,240 would lose some chairs and 268 would
lose all of them.**

Other facts the rule depends on:

- **CC_0058** re-pointed 2,685 Housing and Same-Sex Marriage answers by inserting *Season 2 rows*. They carry the
  Season 2 pin, so they match the served version and stay visible. Neither topic appears in the list above.
- Only **2 of 140** revisions carry a non-identity `rung_map` (the same two). Every other substantive revision has
  the default identity map, so `rung_map` cannot yet say which rungs survived. The rule is therefore per
  **version**, not per rung (§6).
- The Season 3 draft pins the **same version** as Season 2 on all 60 topics (0 bumped). Opening S3 as pinned
  hides nothing new. The rule starts to bite on S3 only when a ladder rewrite bumps a version.

## 3. The rule

> **A chair shows only on the ladder version it was written for.** Same `version` = clarifying and editorial
> changes carry. A different `version` = the chair does not show.

### 3.1 Definition

For an answer `a` on topic `T`:

- *written version* = `version` of the revision `a.topic_revision_id`.
- *served version* = `version` of the revision pinned by the **open** season for `T`
  (`season_questions.topic_revision_id`; the same version `servedRevisionLateral` resolves).
- `a` **matches** when the two are equal.

### 3.2 Placement — the filter goes outside the newest-season collapse

Order of operations in every read: **(1) collapse to the newest published season, (2) drop on version mismatch,
(3) drop `value = 0`.** CLAUDE.md's guard-placement rule applies unchanged. Inside the collapse, a mismatched
newest row would be skipped and the query would fall back to an *older* season's rung, serving a position
against a ladder it was never an answer to. That is the failure the collapse exists to prevent.

Consequences:

- A person with only a Season 1 row (v1) and a served v2 → collapse yields S1 → mismatch → **no chair**.
- A person with an S2 row → collapse yields S2 → match → chair. Their S1 row is never consulted.
- A person with an S2 blank (`value = 0`) → collapse yields the blank → blank rules apply as today.
- Never fall back from a mismatched newest row to an older matching one.

### 3.3 Topics the open season does not ask

Season 2 dropped some topics (for example immigration). ADR 0005 §3.4 says reads still serve those answers.
There is no served ladder to disagree with, so **the rule does not apply**: the predicate is true when the open
season has no pin for the topic. This keeps the 1,678 chairs as they are today. If no season is open (a
changeover gap), the predicate is also true everywhere — reads degrade to today's behaviour, never to empty.

### 3.4 Shared predicate

One helper in `seasonService.ts`, next to `SEASON_IS_PUBLISHED` and `servedRevisionLateral`:

```sql
-- answerAlias a: the politician_answers row after the newest-season collapse
( NOT EXISTS (SELECT 1 FROM inform.season_questions oq
                JOIN inform.seasons os ON os.id = oq.season_id AND os.status = 'open'
               WHERE oq.topic_id = a.topic_id)
  OR EXISTS (SELECT 1 FROM inform.season_questions oq
               JOIN inform.seasons os ON os.id = oq.season_id AND os.status = 'open'
               JOIN inform.compass_topic_revisions opin ON opin.id = oq.topic_revision_id
               JOIN inform.compass_topic_revisions wr   ON wr.id   = a.topic_revision_id
              WHERE oq.topic_id = a.topic_id AND wr.version = opin.version) )
```

Every site below inlines the collapse today. Each must select `a.topic_revision_id` through its collapse and
apply the helper in the outer `WHERE`. One shared fragment prevents ten copies drifting.

## 4. What voters see instead

**An empty spoke, the same as a blank.** This is consistent with the Q2 blank ruling (2026-10-07): a blank shows
an empty spoke only — no value, no reasoning, no citations, no "Position under review".

- No notice is added by this change. The "last reviewed in season N / research in progress" notice is the
  separate half of seasons-design migration step 4 and handoff Q1/Q2. This rule is its prerequisite, not a
  replacement. If Cantrell rules for a notice, the helper can return the mismatch as a flag instead of dropping
  the row.
- A voter's own compass is unaffected by this change (`compass_responses_effective` already drops answers that no
  longer stand — CC_0062).

## 5. Effect per read

| Read | Change |
|---|---|
| `getPoliticianAnswers`, `getBatchPoliticianAnswers`, `getCandidateAnswers` researched path | Mismatched chairs drop; the spoke is empty. |
| `getCompassPoliticians`, candidate lists | `answer_count` and `answered_topic_ids` count only matching chairs. The "has any answer" join gate stays unguarded (existing `@zero-scope` reasoning), so the 268 people left with none still list, with an honest empty compass. **Decision needed: keep, or hide them.** |
| `compareWithPoliticians` | A mismatched chair is not a shared topic. It drops from numerator **and** denominator, so it neither scores nor penalises. Scores of re-evidenced people are unchanged; scores of S1-only people rest on fewer topics. |
| `getPoliticianContext`, `getPoliticianContextAll` | Reasoning is dropped when the same-season answer is a mismatch, exactly as it already is for `value = 0`. Reasoning is written against one ladder; it must not outlive the chair. |
| `getPoliticianCitations` | The block is dropped on mismatch (same predicate as the existing `pa.value <> 0` guard, outside the `pa` LATERAL). **This also removes an inconsistency:** the block today shows the S1 chair against its *own* v1 ladder (`stance_text`, `all_stances`), while the compass spoke shows it against v2. After the change both agree: nothing. |
| `compassStatsService` (`POLITICIAN_COUNTS_SQL`, `POLITICIAN_TOTALS_SQL`) | Distribution bars and totals count only matching chairs. Today a v1 rung-3 chair is bucketed under the v2 rung-3 label. The bars shrink, and become true. |
| `DISPLAYED_VALUES_SQL`, `researchEvidenceService.reviewReadJoins` (admin "Voters see now") | Must change in lockstep. A chair voters no longer see is not a chair a Season 2 write *replaces*, so the `replaces-published-chair` review reason must stop firing for it. Test 290–306 in `researchEvidenceService.test.ts` asserts today's behaviour and is rewritten. |
| "Ever researched" reads (`@season-scope: all-seasons`, coverage rollups) | **No change.** Research happened. They keep `@zero-scope: counts-blanks` semantics. |

A hidden chair is **not deleted**. Season 1 rows stay as history (CLAUDE.md, CC_0058). When a person is
re-researched in Season 2, their new row matches and shows.

## 6. What this rule does not do

- **No per-rung carry.** A v2 whose rung 5 is unchanged still hides the old rung 5. `rung_map` would allow it, but
  98% of revisions carry the default identity map, so it records no decision. Handoff Q3 (record real
  `rung_map` values, `"invalidated"` per rung) stays open. This rule is deliberately the conservative floor.
- **No re-mapping of old rungs onto new ones.** CC_0058 did that for two topics by an explicit decision; it is not
  a read-time behaviour.
- **No change to what the open season pins or how answers are written** (ADR 0005 §5, ADR 0006 §5).

## 7. Risks and rollout

- **Visible shrink on deploy.** 14,210 chairs (43%) disappear from voter reads at once; 268 politicians go to an
  empty compass. This is the honest state, but it is a large product change. The operator should choose the
  timing against research throughput (the `--season` research work running in parallel refills Season 2 rows).
- **Query cost.** The predicate adds two indexed `season_questions` probes per surviving row. Measure on prod
  with `EXPLAIN` on `compareWithPoliticians` and the stats CTEs before merging.
- **Fail direction.** A bug in the predicate hides chairs; it never shows a wrong one. A missing `season_questions`
  row for a served topic reads as "not asked" and shows today's behaviour.
- **Guard.** Add a static check that any `FROM inform.politician_answers` voter read carries the helper or an
  `-- @version-scope:` marker, in the same shape as `@zero-scope`. Otherwise the next new read repeats the bug.

## 8. Decisions requested

1. Approve the rule (§3), including §3.3 (unasked topics unchanged).
2. Empty spoke with no notice for now (§4), or return a mismatch flag for a later notice.
3. The 268 politicians left with no visible chair (§5): keep listed, or hide.
4. Rollout timing (§7).
5. **Chris Cantrell** reviews §3 and §5 before implementation. He owns the seasons design and has the open
   handoff questions Q1–Q5 that overlap this rule (Q2 option (c) "hidden until re-researched" is exactly this).
