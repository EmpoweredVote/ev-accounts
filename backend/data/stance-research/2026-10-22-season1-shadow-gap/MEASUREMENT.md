# The Season 1 shadow gap — what voters are actually served

**Read-only. Nothing was written to the database.** Measured 2026-10-22 against production.

Prompted by an operator observation while merging two duplicate person rows: *"We should ideally be
doing this work on the live season, not much help to do it off the old seasons other than to port it
over."* That is right, and nobody had measured how much there is to port.

---

## ▶▶ THE HEADLINE: ABOUT 90% OF EVERY PUBLISHED ANSWER COMES FROM THE CLOSED SEASON

Season 1 is **closed** and immutable (ADR 0005 §1.6). Season 2 is **open**. A Season 2 row shadows
the Season 1 row for the same (politician, topic) on read; where there is no Season 2 row, **Season 1
is what a voter sees**.

| | (politician, topic) pairs |
|---|---|
| **Serving from Season 1 only — nothing shadows them** | **30,190** |
| Published in Season 2 | 3,512 |
| …of which also exist in Season 1 (shadowing working) | 2,818 |
| …Season 2 only | 694 |

**The live season covers about 10% of what is on the site.** 4,005 people serve at least one answer
from Season 1 alone; 2,363 people have any Season 2 answer at all.

⚠ This is a COVERAGE measurement, not a quality one. It says nothing about whether the 30,190 are
well evidenced — that is the separate audit programme (migrations 1920-1933). A row can be in this
count and be perfectly sound.

---

## THE BUCKETS — AND `rung_map` DECIDES THEM, NOT THE REVISION ID

🔴 **CORRECTED. The first cut of this document bucketed on "did `topic_revision_id` change" and
concluded 16,379 rows need re-reading. That is wrong, and wrong in the expensive direction.**
`compass_topic_revisions.rung_map` exists precisely to state how an old rung corresponds to a new
one, and for all but three topics it is the identity map — including topics whose `change_class` is
`substantive`. A revision bump is not evidence that the rungs moved; `rung_map` is.

| bucket | pairs | what porting one costs |
|---|---|---|
| Same revision | 12,134 | **DIRECT PORT.** Same question, same rungs. |
| Revised, `rung_map` IDENTITY | **16,140** | **DIRECT PORT.** The revision asserts rung N means rung N. |
| **→ directly portable** | **28,274** | |
| Revised, rung **REMAPPED** | 211 | Apply the map, then sanity-check. Affordable Housing, Bail and Pretrial Decisions, Same-Sex Marriage. |
| Revised, rung **INVALIDATED** | 28 | **RE-READ — there is no target rung.** All Same-Sex Marriage at old rung 3. |
| Topic ABSENT from Season 2 | 1,677 | NEITHER. No Season 2 question exists. |

**The genuine re-read queue is 239 rows, not 16,379.** The two non-identity maps are:

```
Affordable Housing  rev 3   {1→1, 2→3, 3→4, 4→5, 5→5}
Same-Sex Marriage   rev 2   {1→2, 2→3, 3→INVALIDATED, 4→4, 5→5}
```

🔑 **The 28 invalidated rows are the interesting ones.** Same-Sex Marriage rung 3 has no Season 2
equivalent — the revision deleted that position rather than moving it. Those 28 people hold a stance
the live question no longer offers, and they cannot be ported at all. Note the resonance with
migration 1925, which blanked 53 Same-Sex Marriage chairs for a different reason: this topic's
ladder has been the most unstable in the corpus.

⚠ What this bucketing does NOT establish is that a direct port is *warranted* — only that the rung
survives translation. Whether the row's evidence seats that rung is the separate test below, and it
is the one that actually gates a write.

### ⚠ The 1,677 absent rows are the known `immigration` orphan, measured independently

Every one of the 1,677 is **Immigration and Treatment of Immigrants**, which is not carried into
Season 2 at all. This reproduces the figure already recorded in the Season 3 agenda (~1,678) from a
different direction, which is worth having: it was not derived from that note.

There is no Season 2 question these can be ported to. Their disposition belongs to the Season 3
topic decisions, not to a porting pass.

---

## RETIREMENT DOES NOT SHRINK THIS

Split by whether the topic's `topic_revision_id` moved, which is the cut this table was built on
before `rung_map` was taken into account. The reachability conclusion is unaffected by that
correction — the rows are the same rows either way.

| bucket (by revision id) | total | on an ACTIVE person | on a SEATED officeholder | on a retired row |
|---|---|---|---|---|
| revision changed | 16,379 | 16,266 | 13,808 | 113 |
| same revision | 12,134 | 12,048 | 9,950 | 86 |
| absent from S2 | 1,677 | 1,666 | 1,290 | 11 |

**29,980 of 30,190 sit on active people and 25,048 on sitting officeholders.** Only 210 are on
retired rows. The exposure is live.

---

## PER TOPIC

### Revised but directly portable — rung_map is the identity (16,140)

| topic | pairs | | topic | pairs |
|---|---|---|---|---|
| Climate Change and Environmental Protection | 1,884 | | Social Security | 592 |
| Civil Rights and Social Justice | 1,553 | | Homelessness Response | 438 |
| Voting Rights and Electoral Integrity | 1,514 | | Growth and Development Pace | 428 |
| Deportation Priorities | 1,340 | | Misinformation and Algorithms in Democracy | 367 |
| School Vouchers & Public Education Funding | 1,225 | | Environmental Protection vs. Development | 357 |
| Medicare / Medicaid | 1,131 | | Criminal Justice Approach | 287 |
| Campaign Finance Reform | 835 | | Data Center Development & Energy Costs | 282 |
| Childcare Affordability & Access | 773 | | Rent Regulation | 228 |
| Economic Development Incentives | 693 | | City Sanitation and Cleanliness | 113 |
| Religious Freedom | 676 | | Judicial Interpretation | 71 |
| Criminalization of Homelessness | 634 | | Access to Justice | 48 |
| Artificial Intelligence Oversight | 603 | | Transparency in Legal Proceedings | 34 |
| | | | Judicial & Prosecutorial Discretion | 22 |
| | | | Police Accountability | 12 |

### 🔴 NOT portable mechanically — the whole re-read queue (239)

The three topics whose `rung_map` is not the identity. These are the only rows in the corpus where
the Season 1 rung does not survive translation into Season 2.

| topic | rows | rung_map | what it means |
|---|---|---|---|
| Same-Sex Marriage | 147 | `{1→2, 2→3, 3→INVALIDATED, 4→4, 5→5}` | 119 remap; **28 sit at old rung 3, which Season 2 deleted** |
| Affordable Housing | 86 | `{1→1, 2→3, 3→4, 4→5, 5→5}` | all 86 remap; note 4 and 5 both collapse to 5 |
| Bail and Pretrial Decisions | 6 | non-identity | all 6 remap |

**211 remapped + 28 invalidated = 239.** The 28 are the only rows here that cannot be ported at any
price: there is no Season 2 rung to carry them to.

### Same revision — directly portable (12,134)

| topic | pairs | | topic | pairs |
|---|---|---|---|---|
| Taxation and Public Spending | 1,958 | | Local Immigration Enforcement | 553 |
| Reproductive Rights and Abortion Access | 1,869 | | Ukraine - Russia Conflict | 462 |
| Healthcare Access | 1,757 | | Transportation Priorities | 444 |
| Fossil Fuel Policy | 1,326 | | Residential Zoning | 439 |
| Transgender Athletes | 850 | | Jail Capacity and Incarceration Alternatives | 301 |
| Public Safety Approach | 832 | | Prosecution Priorities | 20 |
| State Redistricting and Gerrymandering | 662 | | | |
| United States Tariff Policy | 661 | | | |

🔑 **Four topics carry 57% of the SAME-REVISION slice** — Taxation, Reproductive Rights, Healthcare Access and Fossil Fuel Policy total 6,910 of 12,134. Scoping a port pass to one topic is tractable where "port Season 1" is not.
Across the whole portable set of 28,274, the five largest topics — those four plus Climate Change at
1,884 — account for 8,794. A port pass scoped to one topic is a tractable unit of work in a way
"port Season 1" is not.

---

## ⚠ A TENSION TO SETTLE BEFORE ANY BULK PORT

Migrations 1925, 1926, 1928 and 1931 have been **blanking Season 2 rows** whose evidence does not
seat the rung. A bulk port pushes volume through the very gate that work has been clearing.

So a port must carry the EVIDENCE test, not just the value: `audit-chair-evidence.mjs` is a pre-write
gate, and a row whose reasoning names no instrument should not become a Season 2 answer merely
because it was already a Season 1 answer. **Porting is not free, and "it was already published" is
not evidence.** On the eight rows that prompted this measurement, three had an unchanged ladder and
all three were sourced to ontheissues.org with no instrument named — they would have failed.

---

## NO DISPOSITION IS MADE

This is a measurement. What to do with 30,190 rows belongs to the operator. The obvious shapes:

- **Port queue first, by topic.** 28,274 rows port directly by rung_map, gated on evidence.
- **The 239 that cannot be ported mechanically** — 211 remapped, 28 invalidated. Small enough to read by hand, and the 28 need a real decision.
- **The 1,677 immigration rows** are a Season 3 topic decision, not a porting problem.

---

## METHOD, so it can be re-run rather than trusted

```sql
WITH s1 AS (
  SELECT politician_id, topic_id, topic_revision_id
    FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'   -- Season 1 (closed)
     AND value IS DISTINCT FROM 0),                            -- 0 = blank/suppressed
s2 AS (
  SELECT politician_id, topic_id
    FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'   -- Season 2 (open)
     AND value IS DISTINCT FROM 0),
only1 AS (
  SELECT s1.* FROM s1
   WHERE NOT EXISTS (SELECT 1 FROM s2
                      WHERE s2.politician_id = s1.politician_id
                        AND s2.topic_id = s1.topic_id))
SELECT CASE WHEN sq.topic_revision_id IS NULL                        THEN 'ABSENT from S2'
            WHEN sq.topic_revision_id <> only1.topic_revision_id     THEN 'ladder REVISED'
            ELSE 'ladder unchanged' END AS status,
       count(*)
  FROM only1
  LEFT JOIN inform.season_questions sq
    ON sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND sq.topic_id = only1.topic_id
 GROUP BY status;
```

To bucket by what actually matters, join the Season 2 revision and read its `rung_map`:

```sql
  CASE WHEN sq.topic_revision_id IS NULL                      THEN 'ABSENT from S2'
       WHEN sq.topic_revision_id = only1.topic_revision_id    THEN 'same revision (direct port)'
       WHEN tr.rung_map = '{"1":1,"2":2,"3":3,"4":4,"5":5}'::jsonb
                                                              THEN 'revised, identity (direct port)'
       WHEN tr.rung_map -> (only1.value::int)::text = '"invalidated"'::jsonb
                                                              THEN 'revised, rung INVALIDATED'
       ELSE 'revised, rung REMAPPED' END
  ...
  LEFT JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
```

🔴 **THE TRAP THAT MADE THE FIRST VERSION OF THIS DOCUMENT WRONG: a revision bump is not a ladder
change.** Bucketing on `topic_revision_id <> topic_revision_id` put 16,379 rows in a "needs
re-reading" queue. `rung_map` says 16,140 of them map rung-for-rung and port directly. The real
queue is 239. `change_class = 'substantive'` does not imply the rungs moved either — most
substantive revisions here carry the identity map. **Read `rung_map`; do not infer from the
revision id or the change class.**

⚠ **A second trap, in the shadowing test itself.** Computing "does a Season 2 row exist"
with a window function over a result set already filtered to Season 1 makes the answer always zero,
so every row reads as unshadowed and the bucket totals come out against 33,008 rows instead of
30,190. The Season 2 presence test must be a separate scan, as above. The first cut of this
measurement had that bug and the numbers were corrected before publication.

⚠ `value = 0` means blank/suppressed, not "answered zero" — every count here filters it out, so these
are PUBLISHED answers only.

⚠ One row per (politician, topic, season) is guaranteed by the primary key, so pair counts and row
counts agree; that is why every per-topic `pairs` figure equals its distinct-people figure.
